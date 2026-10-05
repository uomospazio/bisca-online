package com.uomospazio.bisca.voice

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.graphics.Bitmap
import android.provider.MediaStore
import android.util.Base64
import java.io.ByteArrayOutputStream
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.livekit.android.ConnectOptions
import io.livekit.android.LiveKit
import io.livekit.android.events.RoomEvent
import io.livekit.android.events.collect
import io.livekit.android.room.Room
import io.livekit.android.room.participant.RemoteParticipant
import io.livekit.android.room.track.RemoteAudioTrack
import io.livekit.android.room.track.RemoteTrackPublication
import io.livekit.android.room.track.Track
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.UsedByGodot
import org.json.JSONArray
import org.json.JSONObject
import java.util.ArrayDeque
import java.util.concurrent.atomic.AtomicBoolean

/** Native Android transport implementing the same JSON adapter used by the iOS bridge. */
class BiscaVoicePlugin(godot: Godot) : GodotPlugin(godot) {
    private val hostHandler = Handler(Looper.getMainLooper())
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Main.immediate)
    private val eventLock = Any()
    private val events = ArrayDeque<JSONObject>()
    private val destroyed = AtomicBoolean(false)

    // All transport state below is confined to the Android host/main thread.
    private var room: Room? = null
    private var eventJob: Job? = null
    private var connectJob: Job? = null
    private var cleanupJob: Job? = null
    private var roomName = ""
    private var selfId = ""
    private var allowedPeers = emptySet<String>()
    private val peerVolumes = mutableMapOf<String, Double>()
    private var masterVolume = 1.0
    private var isEnabled = false
    private var isPending = false
    private var isMuted = false
    private var generation = 0
    private var nextRequestId = 0
    private var waitingRequestId: Int? = null

    override fun getPluginName() = "BiscaVoice"

    private val photoLock = Any()
    private var photoResult = ""
    private var cameraPending = false
    private val cameraRequest = 4817

    @UsedByGodot
    fun drain_photo(): String = synchronized(photoLock) {
        val result = photoResult
        photoResult = ""
        result
    }

    private fun photoResult(value: String) = synchronized(photoLock) { photoResult = value }

    @UsedByGodot
    fun open_camera() {
        hostHandler.post {
            if (cameraPending || destroyed.get()) return@post
            val host = activity
            if (host == null) { photoResult("error"); return@post }
            photoResult("")
            try {
                // The camera app returns a preview, sufficient for our 192px avatar.
                // No broad storage or camera permission is needed by this app.
                cameraPending = true
                host.startActivityForResult(Intent(MediaStore.ACTION_IMAGE_CAPTURE), cameraRequest)
            } catch (_: Exception) {
                cameraPending = false
                photoResult("error")
            }
        }
    }

    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != cameraRequest || !cameraPending) return
        cameraPending = false
        if (resultCode != Activity.RESULT_OK) { photoResult("cancel"); return }
        try {
            @Suppress("DEPRECATION")
            val original = data?.extras?.get("data") as? Bitmap
            if (original == null) { photoResult("error"); return }
            val side = minOf(original.width, original.height)
            val cropped = Bitmap.createBitmap(original, (original.width - side) / 2, (original.height - side) / 2, side, side)
            val avatar = Bitmap.createScaledBitmap(cropped, 192, 192, true)
            val bytes = ByteArrayOutputStream()
            avatar.compress(Bitmap.CompressFormat.JPEG, 65, bytes)
            photoResult(Base64.encodeToString(bytes.toByteArray(), Base64.NO_WRAP))
        } catch (_: Exception) { photoResult("error") }
    }

    @UsedByGodot
    fun invoke(method: String, argsJson: String) {
        hostHandler.post {
            if (destroyed.get()) return@post
            val args = try {
                JSONArray(argsJson)
            } catch (_: Exception) {
                status("Argomenti vocali non validi.")
                return@post
            }
            when (method) {
                "update" -> updateRoom(args)
                "start" -> start()
                "stop" -> stop()
                "credentials" -> acceptCredentials(args)
                "setMuted" -> {
                    isMuted = args.optBoolean(0, false)
                    setMicrophoneState()
                }
                "setVolume" -> {
                    val id = args.optString(0, "")
                    val gain = safeGain(args.opt(1)) ?: return@post
                    peerVolumes[id] = gain
                    applyVolumes()
                }
                "setMaster" -> {
                    masterVolume = safeGain(args.opt(0)) ?: return@post
                    applyVolumes()
                }
                // Web-only panel calls are deliberately harmless on native platforms.
                "closePanel", "receive" -> Unit
            }
        }
    }

    @UsedByGodot
    fun drain(): String {
        val batch = synchronized(eventLock) {
            val copy = JSONArray()
            while (events.isNotEmpty()) copy.put(events.removeFirst())
            copy.toString()
        }
        return batch
    }

    override fun onMainRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (requestCode != permissionRequestCode || requestCode == INVALID_PERMISSION_REQUEST) return
        val granted = permissions.indices.any { index ->
            permissions[index] == Manifest.permission.RECORD_AUDIO &&
                grantResults.getOrNull(index) == PackageManager.PERMISSION_GRANTED
        }
        if (!isPending) return
        if (granted) requestToken()
        else fail("Permesso microfono negato: abilitalo nelle Impostazioni Android.")
    }

    override fun onMainPause() {
        hostHandler.post { stop() }
    }

    override fun onGodotTerminating() {
        hostHandler.post {
            destroyed.set(true)
            stop()
            scope.launch {
                cleanupJob?.join()
                scope.cancel()
            }
        }
    }

    private var permissionRequestCode = INVALID_PERMISSION_REQUEST

    private fun updateRoom(args: JSONArray) {
        val newRoom = args.optString(0, "")
        val newSelf = args.optString(1, "")
        val roster = args.optJSONArray(2) ?: JSONArray()
        if (newRoom != roomName || newSelf != selfId) {
            stop()
            peerVolumes.clear()
        }
        roomName = newRoom
        selfId = newSelf
        val nextPeers = mutableSetOf<String>()
        for (index in 0 until roster.length()) {
            val player = roster.optJSONObject(index) ?: continue
            val id = player.optString("id", "")
            if (id.isNotBlank() && id != selfId && !player.optBoolean("bot", false) && player.optBoolean("connected", false)) {
                nextPeers.add(id)
            }
        }
        allowedPeers = nextPeers
        reconcileSubscriptions()
        applyVolumes()
    }

    private fun start() {
        if (isEnabled || isPending) return
        if (roomName.isBlank() || selfId.isBlank()) {
            status("Entra prima in una lobby multiplayer.")
            return
        }
        generation++
        permissionRequestCode = MICROPHONE_REQUEST_BASE + (generation % 10000)
        isPending = true
        status("Consenti il microfono per attivare la chat vocale…")

        val activity = activity
        if (activity == null) {
            fail("Impossibile richiedere il microfono su questo dispositivo.")
            return
        }
        val granted = if (Build.VERSION.SDK_INT < 23) true else
            activity.checkSelfPermission(Manifest.permission.RECORD_AUDIO) == PackageManager.PERMISSION_GRANTED
        if (granted) {
            requestToken()
        } else {
            activity.requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), permissionRequestCode)
        }
    }

    private fun requestToken() {
        if (!isPending) return
        nextRequestId++
        waitingRequestId = nextRequestId
        emit(JSONObject().put("op", "token").put("id", nextRequestId))
    }

    private fun acceptCredentials(args: JSONArray) {
        val requestId = args.optInt(0, -1)
        if (requestId < 0 || waitingRequestId != requestId || !isPending) return
        waitingRequestId = null
        val credentials = args.optJSONObject(1) ?: run {
            fail("Credenziali vocali non valide.")
            return
        }
        if (credentials.has("error")) {
            fail("Accesso vocale rifiutato dal server Bisca.")
            return
        }
        val url = credentials.optString("url", "")
        val token = credentials.optString("token", "")
        if (!url.startsWith("wss://") || token.isBlank()) {
            fail("Configurazione vocale non valida.")
            return
        }
        val epoch = generation
        val previousCleanup = cleanupJob
        connectJob = scope.launch {
            previousCleanup?.join()
            if (!isCurrent(epoch)) return@launch
            val host = activity ?: run {
                fail("Impossibile avviare la chat vocale su questo dispositivo.")
                return@launch
            }
            val newRoom = LiveKit.create(host.applicationContext)
            room = newRoom
            eventJob = launch {
                newRoom.events.collect { event ->
                    if (!isCurrent(epoch) || room !== newRoom) return@collect
                    when (event) {
                        is RoomEvent.TrackPublished -> reconcileSubscriptions()
                        is RoomEvent.ParticipantConnected -> reconcileSubscriptions()
                        is RoomEvent.TrackSubscribed -> applyVolumes()
                        is RoomEvent.Reconnecting -> status("Riconnessione vocale in corso…")
                        is RoomEvent.Reconnected -> {
                            reconcileSubscriptions()
                            status("Chat vocale connessa.")
                        }
                        is RoomEvent.Disconnected, is RoomEvent.FailedToConnect -> {
                            if (isEnabled || isPending) fail("Connessione vocale interrotta. Riprova.")
                        }
                        else -> Unit
                    }
                }
            }
            try {
                newRoom.connect(url, token, ConnectOptions(autoSubscribe = false))
                if (!isCurrent(epoch) || room !== newRoom) {
                    newRoom.disconnect()
                    return@launch
                }
                if (!newRoom.localParticipant.setMicrophoneEnabled(!isMuted)) {
                    throw IllegalStateException("microphone publish failed")
                }
                if (!isCurrent(epoch)) {
                    newRoom.disconnect()
                    return@launch
                }
                isPending = false
                isEnabled = true
                reconcileSubscriptions()
                applyVolumes()
                status("Chat vocale connessa. Anche gli altri giocatori devono attivarla.")
            } catch (_: CancellationException) {
                newRoom.disconnect()
            } catch (_: Exception) {
                if (isCurrent(epoch)) fail("Connessione vocale fallita. Controlla la rete e riprova.")
                else newRoom.disconnect()
            }
        }
    }

    private fun setMicrophoneState() {
        val currentRoom = room
        if (!isEnabled || currentRoom == null) {
            pushStatus()
            return
        }
        val epoch = generation
        connectJob?.cancel()
        connectJob = scope.launch {
            try {
                currentRoom.localParticipant.setMicrophoneEnabled(!isMuted)
                if (isCurrent(epoch) && room === currentRoom) pushStatus()
            } catch (_: Exception) {
                if (isCurrent(epoch)) fail("Errore microfono. Chat vocale disattivata.")
            }
        }
    }

    private fun reconcileSubscriptions() {
        val currentRoom = room ?: return
        if (!isEnabled && !isPending) return
        currentRoom.remoteParticipants.values.forEach { participant ->
            val id = peerId(participant)
            participant.trackPublications.values
                .filterIsInstance<RemoteTrackPublication>()
                .forEach { publication ->
                    publication.setSubscribed(id in allowedPeers && publication.kind == Track.Kind.AUDIO)
                }
        }
    }

    private fun applyVolumes() {
        val currentRoom = room ?: return
        currentRoom.remoteParticipants.values.forEach { participant ->
            val id = peerId(participant)
            val allowed = id in allowedPeers
            participant.trackPublications.values
                .filterIsInstance<RemoteTrackPublication>()
                .forEach { publication ->
                    (publication.track as? RemoteAudioTrack)?.setVolume(
                        if (allowed) (peerVolumes[id] ?: 1.0) * masterVolume else 0.0
                    )
                }
        }
    }

    private fun peerId(participant: RemoteParticipant): String =
        (participant.identity?.value ?: "").substringBefore('.')

    private fun stop() {
        generation++
        permissionRequestCode = INVALID_PERMISSION_REQUEST
        waitingRequestId = null
        isPending = false
        isEnabled = false
        isMuted = false
        val oldRoom = room
        room = null
        eventJob?.cancel()
        eventJob = null
        connectJob?.cancel()
        val previousCleanup = cleanupJob
        cleanupJob = scope.launch {
            previousCleanup?.join()
            try {
                oldRoom?.localParticipant?.setMicrophoneEnabled(false)
            } catch (_: Exception) {
                // Disconnect below is still required even if the device permission was revoked.
            }
            oldRoom?.disconnect()
        }
        connectJob = null
        pushStatus("Chat vocale disattivata.")
    }

    private fun fail(message: String) {
        stop()
        pushStatus(message)
    }

    private fun isCurrent(epoch: Int) = generation == epoch && !destroyed.get()

    private fun safeGain(value: Any?): Double? {
        val number = value as? Number ?: return null
        val gain = number.toDouble()
        return if (gain.isFinite()) gain.coerceIn(0.0, 1.0) else null
    }

    private fun status(message: String) {
        emit(
            JSONObject()
                .put("op", "status")
                .put("text", message)
                .put("enabled", isEnabled)
                .put("pending", isPending)
                .put("muted", isMuted)
        )
    }

    private fun pushStatus(message: String? = null) {
        status(message ?: when {
            isPending -> "Connessione alla chat vocale…"
            isMuted -> "Microfono silenziato. Puoi ascoltare gli altri."
            isEnabled -> "Chat vocale attiva."
            else -> "Chat vocale disattivata."
        })
    }

    private fun emit(event: JSONObject) {
        synchronized(eventLock) {
            if (events.size >= MAX_EVENTS) events.removeFirst()
            events.addLast(event)
        }
    }

    companion object {
        private const val MICROPHONE_REQUEST_BASE = 52000
        private const val INVALID_PERMISSION_REQUEST = -1
        private const val MAX_EVENTS = 256
    }
}
