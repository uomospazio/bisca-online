extends Node

signal changed
var people: Array = []
var my_slot := -1
var status := "Chat vocale disattivata."
var enabled := false
var pending := false
var muted := false
var volumes: Dictionary = {}
var bridge: JavaScriptObject
var network_session: Node
var current_room := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if OS.get_cmdline_user_args().has("--server"):
		set_process(false)
		return

	network_session = get_node("/root/NetworkSession")
	network_session.updated.connect(_on_network_updated)
	network_session.connection_lost.connect(stop)

	if OS.has_feature("web"):
		print("VOICE: inizializzazione Web")

		var path := "res://scenes/balatro/scripts/voice_transport.js"

		if not FileAccess.file_exists(path):
			print("VOICE ERROR: voice_transport.js NON trovato")
			status = "Errore: modulo chat vocale non trovato."
			changed.emit()
			return

		var js_code := FileAccess.get_file_as_string(path)

		print("VOICE: JS trovato, lunghezza = ", js_code.length())

		if js_code.is_empty():
			print("VOICE ERROR: voice_transport.js è vuoto")
			status = "Errore: modulo chat vocale vuoto."
			changed.emit()
			return

		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://scenes/balatro/scripts/livekit-client.umd.js"), true)
		JavaScriptBridge.eval(js_code, true)

		bridge = JavaScriptBridge.get_interface("BiscaVoice")

		if bridge == null:
			print("VOICE ERROR: window.BiscaVoice non esiste")
			status = "Errore inizializzazione chat vocale."
			changed.emit()
			return

		print("VOICE OK: BiscaVoice inizializzato")
		status = "Chat vocale pronta."

		get_node("/root/GameSettings").changed.connect(_sync_master)
		_sync_master()

	else:
		status = "Chat vocale disponibile nella versione browser HTTPS (PC e mobile)."

	changed.emit()

func available() -> bool:
	return bridge != null

func _call(method: String, args: Array = []) -> void:
	if bridge != null:
		var encoded: Array[String] = []
		for arg in args:
			encoded.append(JSON.stringify(arg))
		JavaScriptBridge.eval("window.BiscaVoice.%s(%s)" % [method, ",".join(encoded)], true)

func _sync_master() -> void:
	_call("setMaster", [float(get_node("/root/GameSettings").values.main) / 100.0])

func _on_network_updated(state: Dictionary) -> void:
	var room := str(state.get("code", ""))
	if room != current_room:
		volumes.clear()
	current_room = room
	people = state.get("people", []).duplicate(true)
	my_slot = int(state.get("you", -1))
	var roster: Array = []
	for slot in range(people.size()):
		var person: Dictionary = people[slot]
		person["slot"] = slot
		person["id"] = str(person.get("voice_id", ""))
		if not person.id.is_empty():
			roster.append(person)
	if my_slot >= 0 and my_slot < people.size():
		_call("update", [room, people[my_slot].id, roster])
	changed.emit()

func activate() -> void:
	if my_slot < 0 or my_slot >= people.size() or people[my_slot].id.is_empty():
		status = "Chat vocale non disponibile: aggiorna anche il server della partita."
		changed.emit()
		return
	open_panel()

func open_panel() -> void:
	if bridge != null:
		_call("openPanel")
	else:
		var dialog := AcceptDialog.new()
		dialog.title = "CHAT VOCALE"
		dialog.dialog_text = status
		add_child(dialog)
		dialog.confirmed.connect(dialog.queue_free)
		dialog.canceled.connect(dialog.queue_free)
		dialog.popup_centered(Vector2i(520, 180))

func toggle_audio() -> void:
	if enabled or pending:
		stop()
	elif bridge == null:
		open_panel()
	elif my_slot < 0 or my_slot >= people.size() or people[my_slot].get("id", "").is_empty():
		status = "Entra prima in una lobby multiplayer."
		changed.emit()
	else:
		pending = true
		status = "Connessione alla chat vocale…"
		changed.emit()
		_call("start")

func stop() -> void:
	_call("stop")
	enabled = false
	pending = false
	muted = false
	status = "Chat vocale disattivata."
	changed.emit()

func leave() -> void:
	_call("closePanel")
	stop()
	current_room = ""
	people.clear()
	volumes.clear()
	my_slot = -1
	_call("update", ["", "", []])
	changed.emit()

func set_muted(value: bool) -> void:
	muted = value
	_call("setMuted", [value])
	changed.emit()

func player_volume(id: String) -> float:
	return float(volumes.get(id, 100.0))

func set_player_volume(id: String, value: float) -> void:
	volumes[id] = clampf(value, 0.0, 100.0)
	_call("setVolume", [id, volumes[id] / 100.0])

func handle_signal(_sender_slot: int, data: Dictionary) -> void:
	_call("receive", [data])

func _process(_delta: float) -> void:
	if bridge == null:
		return
	var events = JSON.parse_string(str(bridge.drain()))
	if not events is Array:
		return
	for event in events:
		if event.op == "token":
			if network_session.multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				network_session.request_voice_token.rpc_id(1, int(event.id))
			else:
				_call("credentials", [event.id, {"error": "Connessione alla partita assente."}])
		elif event.op == "volume":
			volumes[str(event.id)] = float(event.value)
			changed.emit()
		elif event.op == "signal":
			if network_session.multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
				network_session.voice_signal.rpc_id(1, int(event.slot), event.data)
		elif event.op == "status":
			status = str(event.text)
			enabled = bool(event.enabled)
			pending = bool(event.get("pending", false))
			muted = bool(event.muted)
			changed.emit()

func _exit_tree() -> void:
	_call("stop")
