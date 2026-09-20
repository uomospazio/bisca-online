extends Node

signal updated(state: Dictionary)
signal clock_updated(seconds: float)
signal problem(message: String)
signal connection_lost

const Rules = preload("res://scenes/balatro/scripts/match_rules.gd")
var bot_policy = preload("res://scenes/balatro/scripts/bot_policy.gd").new()
const PORT := 8910
var dedicated := false
var rooms: Dictionary = {}
var members: Dictionary = {}
var room_code := ""
var token := ""
var endpoint := "127.0.0.1"
var latest: Dictionary = {}
var pending: Dictionary = {}
var tick := 0.0
var retry := 0.0
var connection_deadline := 0
var connection_generation := 0
var voice_rate: Dictionary = {}

func default_endpoint() -> String:
	return str(ProjectSettings.get_setting("bisca/network/server_url", "")) if OS.has_feature("web") else "127.0.0.1"

func _ready() -> void:
	dedicated = OS.get_cmdline_user_args().has("--server")
	multiplayer.peer_disconnected.connect(_disconnected)
	multiplayer.connected_to_server.connect(func():
		connection_deadline = 0
		request.rpc_id(1, pending)
	)
	multiplayer.connection_failed.connect(_lost)
	multiplayer.server_disconnected.connect(_lost)
	if dedicated:
		var use_websocket := OS.get_cmdline_user_args().has("--websocket")
		var peer: MultiplayerPeer
		var err: Error
		if use_websocket:
			var socket := WebSocketMultiplayerPeer.new()
			socket.max_queued_packets = 128
			err = socket.create_server(int(OS.get_environment("GODOT_WS_PORT")) if OS.has_environment("GODOT_WS_PORT") else PORT)
			peer = socket
		else:
			var enet := ENetMultiplayerPeer.new()
			err = enet.create_server(PORT, 128)
			peer = enet
		if err != OK:
			push_error("Server cannot listen: %s" % err)
			get_tree().quit(1)
			return
		multiplayer.multiplayer_peer = peer
		print("BISCA server ready: ", "WebSocket" if use_websocket else "ENet")
	else:
		endpoint = default_endpoint()
		var cfg := ConfigFile.new()
		if not OS.has_environment("BISCA_NETWORK_TEST") and cfg.load("user://rejoin.cfg") == OK:
			room_code = cfg.get_value("session", "room", "")
			token = cfg.get_value("session", "token", "")
			endpoint = cfg.get_value("session", "endpoint", endpoint)
		if OS.has_feature("web") and not endpoint.begins_with("wss://") and not endpoint.begins_with("ws://"):
			endpoint = default_endpoint()

func connect_room(address: String, command: Dictionary) -> void:
	command = command.duplicate(true)
	# Entering the same code after a reload must reclaim our seat, not try
	# to add a new player to a match that is already running.
	if command.get("op", "") == "join" and not token.is_empty() and str(command.get("code", "")).strip_edges().to_upper() == room_code and address.strip_edges() == endpoint:
		command = {"op": "rejoin", "code": room_code, "token": token}
	var voice := get_node_or_null("/root/VoiceChat")
	if voice:
		voice.leave()
	connection_generation += 1
	var generation := connection_generation

	endpoint = address.strip_edges()

	if endpoint.is_empty():
		endpoint = default_endpoint()

	retry = 0.0
	connection_deadline = 0

	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

	if command.get("op", "") in ["create", "join"]:
		room_code = ""
		token = ""
		latest.clear()

	if OS.has_feature("web") \
	and not endpoint.begins_with("wss://") \
	and not endpoint.begins_with("ws://"):
		problem.emit("Server online non configurato: serve un indirizzo wss://")
		return

	pending = command

	if endpoint.begins_with("ws://") or endpoint.begins_with("wss://"):

		if endpoint.begins_with("wss://"):
			problem.emit(
				"Connessione al server... il primo accesso può richiedere circa un minuto."
			)

		var socket := WebSocketMultiplayerPeer.new()

		socket.handshake_timeout = 90.0

		var err := socket.create_client(endpoint)

		if err != OK:
			problem.emit("Impossibile connettersi al server")
			if command.get("op", "") == "rejoin" and not token.is_empty():
				retry = 2.0
			return

		multiplayer.multiplayer_peer = socket

		connection_deadline = Time.get_ticks_msec() + 95000

		problem.emit("Connessione al server in corso...")
		return

func _ensure_local_server() -> bool:
	# A running server already owns this UDP port. Otherwise start the same
	# dedicated server used for LAN tests, independently from the game window.
	var probe := UDPServer.new()
	if probe.listen(PORT) != OK:
		return true
	probe.stop()
	var arguments := PackedStringArray(["--headless"])
	if OS.has_feature("editor"):
		arguments.append_array(["--path", ProjectSettings.globalize_path("res://")])
	arguments.append_array(["--", "--server"])
	if OS.create_process(OS.get_executable_path(), arguments) < 0:
		problem.emit("Impossibile avviare il server locale")
		return false
	return true

func send(command: Dictionary) -> void:
	if multiplayer.multiplayer_peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED:
		request.rpc_id(1, command)

func leave() -> void:
	var voice := get_node_or_null("/root/VoiceChat")
	if voice:
		voice.leave()
	connection_generation += 1
	send({"op": "leave"})
	room_code = ""
	token = ""
	latest.clear()
	retry = 0
	connection_deadline = 0
	_save()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()

func _save() -> void:
	if OS.has_environment("BISCA_NETWORK_TEST"):
		return
	var cfg := ConfigFile.new()
	cfg.set_value("session", "room", room_code)
	cfg.set_value("session", "token", token)
	cfg.set_value("session", "endpoint", endpoint)
	cfg.save("user://rejoin.cfg")

func _lost() -> void:
	connection_deadline = 0
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	connection_lost.emit()
	problem.emit("Connessione persa. Tentativo di riconnessione…" if not token.is_empty() else "Server non raggiungibile: controlla l'indirizzo e che il server sia acceso.")
	if not token.is_empty():
		retry = 2.0

func _disconnected(peer_id: int) -> void:
	voice_rate.erase(peer_id)
	if not dedicated or not members.has(peer_id):
		return
	var ref: Dictionary = members[peer_id]
	members.erase(peer_id)
	var room: Dictionary = rooms[ref.code]
	# A late disconnect from the replaced connection must not evict the
	# player who has already reclaimed this seat.
	if room.people[ref.slot].peer != peer_id:
		return
	room.people[ref.slot].peer = 0
	room.touched = Time.get_ticks_msec()
	_broadcast(room)

func _rejoin_slot(room: Dictionary, credential: String) -> int:
	if credential.is_empty():
		return -1
	for i in range(room.people.size()):
		var person: Dictionary = room.people[i]
		if not person.bot and person.token == credential:
			return i
	return -1

func _peer_connected(peer_id: int) -> bool:
	if peer_id <= 0 or not multiplayer.get_peers().has(peer_id):
		return false
	var transport := multiplayer.multiplayer_peer
	if transport is WebSocketMultiplayerPeer:
		return transport.get_peer(peer_id).get_ready_state() == WebSocketPeer.STATE_OPEN
	return transport is ENetMultiplayerPeer and transport.get_peer(peer_id).get_state() == ENetPacketPeer.STATE_CONNECTED

func _process(delta: float) -> void:
	if not dedicated:
		if connection_deadline > 0 and Time.get_ticks_msec() >= connection_deadline:
			multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
			_lost()
		if retry > 0:
			retry -= delta
			if retry <= 0:
				connect_room(endpoint, {"op": "rejoin", "code": room_code, "token": token})
		return
	tick += delta
	if tick < 0.1:
		return
	tick = 0
	var now := Time.get_ticks_msec()
	for code in rooms.keys():
		var room: Dictionary = rooms[code]
		if now - room.touched > 3600000:
			var connected := false
			for person in room.people:
				connected = connected or person.peer != 0
			if not connected:
				rooms.erase(code)
				continue
		if room.rules == null:
			continue
		var rules = room.rules
		var remaining: float = maxf(0, room.deadline - now) / 1000.0
		for person in room.people:
			if _peer_connected(person.peer):
				clock.rpc_id(person.peer, remaining if room.stage == "turn" and rules.phase != "finished" else -1.0)
		if now < room.deadline or rules.phase == "finished" and room.stage == "turn":
			continue
		if room.stage == "deal":
			_set_turn(room)
		elif room.stage == "trick":
			rules.advance_trick()
			if rules.phase in ["round_complete", "finished"]:
				room.stage = "damage"
				room.deadline = now + 3500
			else:
				_set_turn(room)
		elif room.stage == "damage":
			if rules.phase == "round_complete":
				rules.begin_round()
				room.stage = "deal"
				room.deadline = now + 4500
			else:
				room.stage = "turn"
		else:
			var actor: int = rules.current
			var automated: bool = room.people[actor].bot or room.people[actor].peer == 0
			var view: Dictionary = rules.view_for(actor)
			if rules.phase == "prediction":
				var bid: int = bot_policy.choose_bid(view, actor) if automated else rules.legal_bids(actor).pick_random()
				rules.predict(actor, bid)
			elif rules.phase == "play":
				var move: Dictionary = bot_policy.choose_play(view, actor) if automated else {"index": randi_range(0, rules.players[actor].hand.size() - 1), "high": randf() < 0.5}
				rules.play(actor, move.index, move.high)
			_after_action(room)
		_broadcast(room)

func _set_turn(room: Dictionary) -> void:
	room.stage = "turn"
	var actor: int = room.rules.current
	var delay := 30000
	if actor >= 0 and room.people[actor].bot:
		delay = 900
	if room.rules.hand_size == 1 and room.rules.phase == "play":
		delay = 600
	room.deadline = Time.get_ticks_msec() + delay

func _after_action(room: Dictionary) -> void:
	if room.rules.phase == "trick_complete":
		room.stage = "trick"
		room.deadline = Time.get_ticks_msec() + 2400
	else:
		_set_turn(room)

func _reject(peer: int, message: String) -> void:
	rejected.rpc_id(peer, message)
	if members.has(peer):
		_broadcast(rooms[members[peer].code])

@rpc("any_peer", "call_remote", "reliable")
func request(command: Dictionary) -> void:
	if not dedicated:
		return
	var peer := multiplayer.get_remote_sender_id()
	var op := str(command.get("op", ""))
	if op in ["create", "join", "rejoin"]:
		if members.has(peer):
			return
		var code := str(command.get("code", "")).strip_edges().to_upper()
		if op == "create":
			if rooms.size() >= 100:
				_reject(peer, "Server pieno")
				return
			code = Crypto.new().generate_random_bytes(3).hex_encode().to_upper()
			while rooms.has(code):
				code = Crypto.new().generate_random_bytes(3).hex_encode().to_upper()
			rooms[code] = {"code": code, "people": [], "rules": null, "capacity": 8, "bots": bool(command.get("bots", false)), "bot_count": clampi(int(command.get("bot_count", 2)), 1, 7), "options": {"lives": clampi(int(command.get("lives", 3)), 1, 10), "starting_cards": clampi(int(command.get("starting_cards", 5)), 1, 5)}, "stage": "lobby", "deadline": 0, "rev": 0, "touched": Time.get_ticks_msec()}
		if not rooms.has(code):
			_reject(peer, "Stanza non trovata")
			return
		var room: Dictionary = rooms[code]
		var slot := -1
		if op == "rejoin":
			slot = _rejoin_slot(room, str(command.get("token", "")))
			if slot < 0:
				_reject(peer, "Posto non disponibile per il rientro")
				return
			# Mobile networks can leave the old socket apparently connected.
			# Possession of the private seat token authorizes replacing it.
			var old_peer: int = room.people[slot].peer
			if old_peer > 0 and old_peer != peer:
				members.erase(old_peer)
				voice_rate.erase(old_peer)
				if multiplayer.get_peers().has(old_peer):
					multiplayer.disconnect_peer(old_peer)
		else:
			if room.rules != null or room.people.size() >= room.capacity:
				_reject(peer, "Stanza piena o partita già iniziata")
				return
			slot = room.people.size()
			var display_name := str(command.get("name", "Giocatore")).strip_edges().substr(0, 16)
			room.people.append({"name": display_name if not display_name.is_empty() else "Giocatore", "peer": 0, "bot": false, "token": Crypto.new().generate_random_bytes(32).hex_encode()})
		room.people[slot].peer = peer
		members[peer] = {"code": code, "slot": slot}
		room.touched = Time.get_ticks_msec()
		joined.rpc_id(peer, code, room.people[slot].token)
		_broadcast(room)
		return
	if not members.has(peer):
		return
	var member: Dictionary = members[peer]
	var room: Dictionary = rooms[member.code]
	var slot: int = member.slot
	if op == "leave":
		_disconnected(peer)
		return
	if op == "kick":
		if slot != 0 or room.rules != null:
			_reject(peer, "Solo il creatore può rimuovere giocatori")
			return
		var kicked_slot := int(command.get("slot", -1))
		if kicked_slot <= 0 or kicked_slot >= room.people.size() or room.people[kicked_slot].bot:
			return
		var kicked_peer: int = room.people[kicked_slot].peer
		room.people.remove_at(kicked_slot)
		if kicked_peer > 0:
			members.erase(kicked_peer)
			multiplayer.disconnect_peer(kicked_peer)
		for i in range(room.people.size()):
			if room.people[i].peer > 0 and members.has(room.people[i].peer):
				members[room.people[i].peer].slot = i
		_broadcast(room)
		return
	if op in ["start", "restart"]:
		if slot != 0 or (op == "start" and room.rules != null) or (op == "restart" and (room.rules == null or room.rules.phase != "finished")):
			_reject(peer, "Solo il creatore può avviare la stanza")
			return
		if op == "start" and room.bots:
			var bots_to_add := mini(int(room.get("bot_count", 2)), int(room.capacity) - room.people.size())
			for _i in range(bots_to_add):
				room.people.append({"name": "Bot %d" % room.people.size(), "peer": 0, "bot": true, "token": ""})
		if room.people.size() < 2:
			_reject(peer, "Servono almeno due giocatori o i bot")
			return
		room.rules = Rules.new()
		room.rules.configure(room.get("options", {}))
		room.rules.start(room.people.size())
		room.stage = "deal"
		room.deadline = Time.get_ticks_msec() + 4500
		_broadcast(room)
		return
	if room.rules == null or room.stage != "turn" or room.rules.current != slot or int(command.get("rev", -1)) != room.rev or Time.get_ticks_msec() >= room.deadline:
		_reject(peer, "Azione scaduta o turno non tuo")
		return
	var accepted := false
	if op == "predict":
		accepted = room.rules.predict(slot, int(command.get("bid", -1)))
	elif op == "play" and room.rules.hand_size > 1:
		var index: int = room.rules.players[slot].hand.find(int(command.get("card", -1)))
		accepted = room.rules.play(slot, index, bool(command.get("high", true)))
	if accepted:
		_after_action(room)
		_broadcast(room)
	else:
		_reject(peer, "Scelta non valida")

func _broadcast(room: Dictionary) -> void:
	room.rev += 1
	for p in room.people:
		if not p.has("voice_id"):
			# Public stable identity: never expose the private rejoin token.
			p["voice_id"] = Crypto.new().generate_random_bytes(8).hex_encode()
	for id in range(room.people.size()):
		var person: Dictionary = room.people[id]
		if not _peer_connected(person.peer):
			continue
		var state := {"code": room.code, "you": id, "rev": room.rev, "stage": room.stage, "capacity": room.capacity, "bots": room.bots, "people": []}
		for p in room.people:
			state.people.append({"name": p.name, "connected": p.peer > 0, "bot": p.bot, "voice_id": p.voice_id})
		if room.rules != null:
			state.merge(room.rules.view_for(id))
			state["completed_tricks"] = room.rules.completed_tricks
			state["last_winner"] = room.rules.last_winner
			state["round_result"] = room.rules.round_result.duplicate(true)
			state["remaining"] = room.rules.remaining_deck.size()
			state["order"] = room.rules.order.duplicate()
		snapshot.rpc_id(person.peer, state)

@rpc("authority", "call_remote", "reliable")
func snapshot(state: Dictionary) -> void:
	latest = state
	updated.emit(state)

@rpc("authority", "call_remote", "reliable")
func joined(code: String, credential: String) -> void:
	room_code = code
	token = credential
	retry = 0
	connection_deadline = 0
	_save()

@rpc("authority", "call_remote", "reliable")
func rejected(message: String) -> void:
	problem.emit(message)

@rpc("authority", "call_remote", "unreliable_ordered")
func clock(seconds: float) -> void:
	clock_updated.emit(seconds)

# =========================================================
# VOICE CHAT - WebRTC signaling
# =========================================================

@rpc("any_peer", "call_remote", "reliable")
func voice_signal(target_slot: int, data: Dictionary) -> void:
	if not dedicated:
		return

	var sender_peer := multiplayer.get_remote_sender_id()

	if not members.has(sender_peer):
		return

	var sender_member: Dictionary = members[sender_peer]
	var room_code_for_sender: String = sender_member.code

	if not rooms.has(room_code_for_sender):
		return

	var room: Dictionary = rooms[room_code_for_sender]
	if data.get("room", "") != room.code or not _valid_voice_payload(data):
		return
	if target_slot == int(sender_member.slot):
		return
	var second := int(Time.get_ticks_msec() / 1000)
	var rate: Dictionary = voice_rate.get(sender_peer, {"second": second, "count": 0})
	if rate.second != second:
		rate = {"second": second, "count": 0}
	rate.count += 1
	voice_rate[sender_peer] = rate
	if rate.count > 100:
		return

	if target_slot < 0 or target_slot >= room.people.size():
		return

	var target: Dictionary = room.people[target_slot]
	var sender: Dictionary = room.people[int(sender_member.slot)]
	if data.get("to_id", "") != target.get("voice_id", "") or data.get("from_id", "") != sender.get("voice_id", ""):
		return

	if target.bot:
		return

	var target_peer: int = target.peer

	if target_peer <= 0:
		return

	receive_voice_signal.rpc_id(
		target_peer,
		int(sender_member.slot),
		data
	)

func _valid_voice_payload(data: Dictionary) -> bool:
	if not data.get("epoch") is String or data.epoch.length() > 64 or data.epoch.is_empty():
		return false
	if JSON.stringify(data).length() > 70000:
		return false
	match data.get("type", ""):
		"ready", "off", "retry":
			return true
		"description":
			var description = data.get("description")
			return description is Dictionary and description.get("type") in ["offer", "answer"] and description.get("sdp") is String and description.sdp.length() <= 65536
		"candidate":
			var candidate = data.get("candidate")
			return candidate is Dictionary and candidate.get("candidate") is String and candidate.candidate.length() <= 4096
	return false


@rpc("authority", "call_remote", "reliable")
func receive_voice_signal(sender_slot: int, data: Dictionary) -> void:
	var voice_chat := get_node_or_null("/root/VoiceChat")

	if voice_chat:
		voice_chat.handle_signal(sender_slot, data)
