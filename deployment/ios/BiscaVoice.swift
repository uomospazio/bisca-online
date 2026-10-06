import Foundation
import AVFoundation
import UIKit
import PhotosUI
import LiveKit
import AuthenticationServices

/// OAuth uses the system authentication browser, never an embedded WebView.
@objc(BiscaAuthNative) public final class BiscaAuthNative: NSObject, ASWebAuthenticationPresentationContextProviding, @unchecked Sendable {
    @objc public static let shared = BiscaAuthNative()
    private let lock = NSLock()
    private var result = ""
    private var session: ASWebAuthenticationSession?
    private var generation = 0
    private func finish(_ value: String) {
        lock.lock(); result = value; lock.unlock()
    }
    @objc public func drain() -> String {
        lock.lock(); defer { lock.unlock() }
        let value = result; result = ""; return value
    }
    @objc public func open(_ value: String) {
        DispatchQueue.main.async {
            self.generation += 1
            let attempt = self.generation
            self.session?.cancel()
            self.finish("")
            guard let url = URL(string: value), url.scheme == "https" else { self.finish("error"); return }
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: "com.bisca.game") { url, error in
                DispatchQueue.main.async {
                    guard attempt == self.generation else { return }
                    self.session = nil
                    self.finish(url?.absoluteString ?? (error == nil ? "error" : "cancel"))
                }
            }
            session.presentationContextProvider = self
            self.session = session
            if !session.start() { self.session = nil; self.finish("error") }
        }
    }
    @objc public func cancel() {
        DispatchQueue.main.async {
            self.generation += 1
            self.session?.cancel(); self.session = nil; self.finish("")
        }
    }
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }.first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}

/// Separate queue: voice polling must never consume a selected profile photo.
@objc(BiscaPhotoNative) public final class BiscaPhotoNative: NSObject, PHPickerViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, @unchecked Sendable {
    @objc public static let shared = BiscaPhotoNative()
    private let lock = NSLock()
    private var result = ""
    @MainActor private var camera: UIImagePickerController?
    @MainActor private var picker: PHPickerViewController?

    private func finish(_ value: String) {
        lock.lock(); result = value; lock.unlock()
    }

    @objc public func drain() -> String {
        lock.lock(); defer { lock.unlock() }
        let value = result; result = ""; return value
    }

    @objc public func open() {
        DispatchQueue.main.async {
            guard self.picker == nil else { return }
            self.finish("")
            let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                .first { $0.activationState == .foregroundActive }
            guard var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                self.finish("error"); return
            }
            while let presented = controller.presentedViewController { controller = presented }
            var configuration = PHPickerConfiguration()
            configuration.filter = .images
            configuration.selectionLimit = 1
            let picker = PHPickerViewController(configuration: configuration)
            picker.delegate = self
            self.picker = picker
            controller.present(picker, animated: true)
        }
    }

    @objc public func openCamera() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                guard granted, UIImagePickerController.isSourceTypeAvailable(.camera), self.camera == nil else {
                    self.finish("error"); return
                }
                let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
                    .first { $0.activationState == .foregroundActive }
                guard var controller = scene?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                    self.finish("error"); return
                }
                while let presented = controller.presentedViewController { controller = presented }
                self.finish("")
                let camera = UIImagePickerController()
                camera.sourceType = .camera
                camera.delegate = self
                self.camera = camera
                controller.present(camera, animated: true)
            }
        }
    }

    public func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
        camera = nil
        finish("cancel")
    }

    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        picker.dismiss(animated: true)
        camera = nil
        guard let image = info[.originalImage] as? UIImage else { finish("error"); return }
        loadPhoto(NSItemProvider(object: image))
    }

    public func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        DispatchQueue.main.async {
            picker.dismiss(animated: true)
            self.picker = nil
        }
        guard let provider = results.first?.itemProvider else { finish("cancel"); return }
        loadPhoto(provider)
    }

    private func loadPhoto(_ provider: NSItemProvider) {
        guard provider.canLoadObject(ofClass: UIImage.self) else { finish("error"); return }
        provider.loadObject(ofClass: UIImage.self) { object, _ in
            guard let image = object as? UIImage, image.size.width > 0, image.size.height > 0 else {
                self.finish("error"); return
            }
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            format.opaque = true
            let avatar = UIGraphicsImageRenderer(size: CGSize(width: 192, height: 192), format: format).image { context in
                UIColor.white.setFill()
                context.fill(CGRect(x: 0, y: 0, width: 192, height: 192))
                let scale = 192 / min(image.size.width, image.size.height)
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                image.draw(in: CGRect(x: (192 - size.width) / 2, y: (192 - size.height) / 2, width: size.width, height: size.height))
            }
            guard let data = avatar.jpegData(compressionQuality: 0.65) else { self.finish("error"); return }
            self.finish(data.base64EncodedString())
        }
    }
}

/// Godot may call from its rendering thread. Only the event queue crosses threads;
/// all mutable transport state and SDK operations are owned by the main actor.
@objc(BiscaVoiceNative) public final class BiscaVoiceNative: NSObject, @unchecked Sendable {
    @objc public static let shared = BiscaVoiceNative()
    private let lock = NSLock()
    private var events: [[String: Any]] = []
    @MainActor private lazy var transport = VoiceTransport(output: self)

    fileprivate func emit(_ event: [String: Any]) {
        lock.lock(); defer { lock.unlock() }
        if events.count == 256 { events.removeFirst() }
        events.append(event)
    }

    @objc public func drain() -> String {
        lock.lock(); let batch = events; events.removeAll(keepingCapacity: true); lock.unlock()
        guard let data = try? JSONSerialization.data(withJSONObject: batch) else { return "[]" }
        return String(decoding: data, as: UTF8.self)
    }

    @objc public func invoke(_ method: String, argsJSON: String) {
        // FIFO dispatch preserves update/start/stop ordering from the Godot thread.
        DispatchQueue.main.async {
            guard let data = argsJSON.data(using: .utf8),
                  let args = (try? JSONSerialization.jsonObject(with: data)) as? [Any] else {
                self.transport.status("Argomenti vocali non validi."); return
            }
            self.transport.invoke(method, args)
        }
    }
}

@MainActor private final class VoiceTransport: NSObject, RoomDelegate {
    private let output: BiscaVoiceNative
    private var lobby = "", me = ""
    private var people = Set<String>()
    private var volumes: [String: Double] = [:]
    private var master = 1.0
    private var enabled = false, pending = false, muted = false
    private var generation = 0, requestID = 0
    private var waiting: Int?
    private var credentialTimer: Task<Void, Never>?
    private var operation: Task<Void, Never>?
    private var cleanup: Task<Void, Never>?
    private var muteOperation: Task<Void, Never>?
    private var subscriptions: Task<Void, Never>?
    private var subscriptionRevision = 0
    private var session: Room?
    private var audioBeforeVoice: (AVAudioSession.Category, AVAudioSession.Mode, AVAudioSession.CategoryOptions, TimeInterval)?

    init(output: BiscaVoiceNative) {
        self.output = output
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(background),
                                              name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(interruption(_:)),
                                              name: AVAudioSession.interruptionNotification, object: nil)
    }
    @objc private func background() { stop() }
    @objc private func interruption(_ notification: Notification) {
        if (notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt) == AVAudioSession.InterruptionType.began.rawValue {
            stop(); status("Audio interrotto. Premi ATTIVA AUDIO per riprovare.")
        }
    }
    func status(_ text: String) {
        output.emit(["op": "status", "text": text, "enabled": enabled, "pending": pending, "muted": muted])
    }
    private func number(_ value: Any) -> Double? {
        guard let value = value as? NSNumber, CFGetTypeID(value) != CFBooleanGetTypeID(), value.doubleValue.isFinite else { return nil }
        return max(0, min(1, value.doubleValue))
    }
    func invoke(_ method: String, _ args: [Any]) {
        switch method {
        case "start" where args.isEmpty: start()
        case "stop" where args.isEmpty: stop()
        case "update" where args.count == 3:
            guard let room = args[0] as? String, let id = args[1] as? String,
                  let roster = args[2] as? [[String: Any]] else { return }
            if room != lobby || id != me { stop(); volumes.removeAll() }
            lobby = room; me = id
            people = Set(roster.compactMap { person in
                guard let peer = person["id"] as? String, peer != id,
                      person["bot"] as? Bool != true, person["connected"] as? Bool == true else { return nil }
                return peer
            })
            applyVolumes(); reconcileSubscriptions()
        case "credentials" where args.count == 2:
            guard let id = args[0] as? Int, let data = args[1] as? [String: Any] else { return }
            credentials(id, data)
        case "setMuted" where args.count == 1:
            guard let value = args[0] as? Bool else { return }
            muted = value; reconcileMute()
        case "setVolume" where args.count == 2:
            guard let id = args[0] as? String, let value = number(args[1]) else { return }
            volumes[id] = value; applyVolumes()
        case "setMaster" where args.count == 1:
            guard let value = number(args[0]) else { return }
            master = value; applyVolumes()
        default: break
        }
    }
    private func active(_ room: Room, _ epoch: Int) -> Bool { session === room && generation == epoch }
    private func start() {
        guard !pending && !enabled else { return }
        guard !lobby.isEmpty && !me.isEmpty else { status("Entra prima in una lobby multiplayer."); return }
        let keepMuted = muted
        stop()
        muted = keepMuted
        pending = true
        let epoch = generation, previousCleanup = cleanup
        status("Consenti il microfono per attivare la chat vocale…")
        operation = Task {
            await previousCleanup?.value
            guard epoch == generation, !Task.isCancelled else { return }
            guard Bundle.main.object(forInfoDictionaryKey: "NSMicrophoneUsageDescription") != nil else {
                stop(); status("Permesso microfono mancante nella configurazione iOS."); return
            }
            let allowed = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { continuation.resume(returning: $0) }
            }
            guard epoch == generation, !Task.isCancelled else { return }
            guard allowed else { stop(); status("Microfono negato: abilitalo nelle Impostazioni iOS."); return }
            requestID += 1; waiting = requestID
            let id = requestID
            output.emit(["op": "token", "id": id])
            credentialTimer = Task {
                do { try await Task.sleep(nanoseconds: 12_000_000_000) } catch { return }
                guard epoch == generation, waiting == id else { return }
                stop(); status("Il server non risponde alla richiesta vocale. Aggiorna anche il server Bisca.")
            }
        }
    }
    private func credentials(_ id: Int, _ data: [String: Any]) {
        guard waiting == id, pending else { return }
        waiting = nil; credentialTimer?.cancel(); credentialTimer = nil
        // Credentials and SDK errors never enter logs or the event stream.
        guard data["error"] == nil else { stop(); status("Accesso vocale rifiutato dal server Bisca."); return }
        guard let url = data["url"] as? String, let parsed = URLComponents(string: url),
              parsed.scheme == "wss", parsed.host?.isEmpty == false,
              let token = data["token"] as? String, !token.isEmpty else {
            stop(); status("Configurazione vocale non valida."); return
        }
        let epoch = generation
        let audio = AVAudioSession.sharedInstance()
        audioBeforeVoice = (audio.category, audio.mode, audio.categoryOptions, audio.preferredIOBufferDuration)
        // Both Godot and WebRTC use the application's AVAudioSession. Keep it
        // active when voice stops, and restore the game's category after teardown.
        AudioManager.shared.audioSession.isAutomaticDeactivationEnabled = false
        AudioManager.shared.audioSession.isSpeakerOutputPreferred = true
        let room = Room(delegate: self)
        session = room
        operation = Task {
            do {
                try await room.connect(url: url, token: token, connectOptions: ConnectOptions(autoSubscribe: false))
                guard active(room, epoch), !Task.isCancelled else { await room.disconnect(); return }
                try await room.localParticipant.setMicrophone(enabled: !muted)
                guard active(room, epoch), !Task.isCancelled else { await room.disconnect(); return }
                pending = false; enabled = true
                reconcileMute(); reconcileSubscriptions()
                status("Chat vocale connessa. Anche gli altri giocatori devono attivarla.")
            } catch {
                guard active(room, epoch) else { await room.disconnect(); return }
                stop(); status("Connessione vocale fallita. Controlla la rete e riprova.")
            }
        }
    }
    private func stop() {
        generation += 1; waiting = nil; credentialTimer?.cancel(); credentialTimer = nil
        pending = false; enabled = false; muted = false
        let old = session; session = nil
        let audioSettings = audioBeforeVoice; audioBeforeVoice = nil
        let previous = cleanup, work = operation, mute = muteOperation, subs = subscriptions
        operation = nil; muteOperation = nil; subscriptions = nil
        work?.cancel(); mute?.cancel(); subs?.cancel()
        // Disconnect immediately to interrupt connect; disconnect again after in-flight
        // publish/mute work finishes. A new start waits for this complete barrier.
        cleanup = Task {
            await previous?.value
            await old?.disconnect()
            await work?.value; await mute?.value; await subs?.value
            await old?.disconnect()
            if let settings = audioSettings {
                let audio = AVAudioSession.sharedInstance()
                do {
                    try audio.setCategory(settings.0, mode: settings.1, options: settings.2)
                    try audio.setPreferredIOBufferDuration(settings.3)
                } catch {
                    status("Uscita audio non ripristinata. Riapri il gioco se non senti i suoni.")
                }
            }
        }
        status("Chat vocale disattivata.")
    }
    private func reconcileMute() {
        guard enabled, let room = session, muteOperation == nil else { return }
        let epoch = generation
        muteOperation = Task {
            defer { if active(room, epoch) { muteOperation = nil } }
            while active(room, epoch), !Task.isCancelled {
                let target = muted
                do { try await room.localParticipant.setMicrophone(enabled: !target) }
                catch {
                    guard active(room, epoch) else { return }
                    stop(); status("Errore microfono. Chat vocale disattivata."); return
                }
                guard active(room, epoch) else { return }
                if target == muted {
                    status(muted ? "Microfono silenziato. Puoi ascoltare gli altri." : "Chat vocale attiva."); return
                }
            }
        }
    }
    private func peerID(_ participant: RemoteParticipant) -> String {
        String((participant.identity?.stringValue ?? "").split(separator: ".").first ?? "")
    }
    private func applyVolumes() {
        guard let room = session else { return }
        for participant in room.remoteParticipants.values {
            let id = peerID(participant)
            for publication in participant.trackPublications.values {
                (publication.track as? RemoteAudioTrack)?.volume = people.contains(id) ? (volumes[id] ?? 1) * master : 0
            }
        }
    }
    private func reconcileSubscriptions() {
        subscriptionRevision += 1
        guard let room = session, enabled, subscriptions == nil else { return }
        let epoch = generation
        subscriptions = Task {
            defer { if active(room, epoch) { subscriptions = nil } }
            while active(room, epoch), !Task.isCancelled {
                let revision = subscriptionRevision
                for participant in room.remoteParticipants.values {
                    for publication in participant.trackPublications.values {
                        guard active(room, epoch), !Task.isCancelled else { return }
                        guard let publication = publication as? RemoteTrackPublication else { continue }
                        let allowed = people.contains(peerID(participant)) && publication.kind == .audio
                        do { try await publication.set(subscribed: allowed) }
                        catch { if active(room, epoch) { status("Ascolto vocale non disponibile per un partecipante.") } }
                    }
                }
                applyVolumes()
                if revision == subscriptionRevision { return }
            }
        }
    }
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didPublishTrack publication: RemoteTrackPublication) {
        Task { @MainActor in guard session === room else { return }; reconcileSubscriptions() }
    }
    nonisolated func room(_ room: Room, participant: RemoteParticipant, didSubscribeTrack publication: RemoteTrackPublication) {
        Task { @MainActor in guard session === room else { return }; applyVolumes() }
    }
    nonisolated func room(_ room: Room, didStartReconnectWithMode mode: ReconnectMode) {
        Task { @MainActor in guard session === room else { return }; status("Riconnessione vocale in corso…") }
    }
    nonisolated func room(_ room: Room, didCompleteReconnectWithMode mode: ReconnectMode) {
        Task { @MainActor in guard session === room else { return }; reconcileSubscriptions(); status("Chat vocale connessa.") }
    }
    nonisolated func room(_ room: Room, didDisconnectWithError error: LiveKitError?) {
        Task { @MainActor in
            guard session === room, !pending else { return }
            stop(); status("Chat vocale disconnessa. Premi ATTIVA AUDIO per riprovare.")
        }
    }
}
