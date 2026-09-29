extends Node
## Usato SOLO dal server dedicato. La chiave segreta arriva dall'ambiente.
## La lobby resta indipendente da nome/avatar del profilo.
const Account = preload("res://scenes/balatro/scripts/account_session.gd")
signal credited(receipt: Dictionary)
var pending: Dictionary = {}
var sending := false

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = 15
	timer.timeout.connect(_flush)
	add_child(timer)
	timer.start()

func enabled() -> bool:
	return not OS.get_environment("SUPABASE_SECRET_KEY").is_empty()

func _http(path: String, headers: PackedStringArray, method: int, body: String = "") -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 12
	add_child(http)
	var error := http.request(Account.PROJECT_URL + path, headers, method, body)
	if error != OK:
		http.queue_free()
		return {}
	var response: Array = await http.request_completed
	http.queue_free()
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] != 200:
		return {}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	return data if data is Dictionary else {}

func verify(jwt: String) -> String:
	if not enabled() or jwt.is_empty() or jwt.length() > 16384:
		return ""
	# Supabase verifica firma, scadenza e identita': mai fidarsi di un UID inviato dal client.
	var data := await _http("/auth/v1/user", PackedStringArray([
		"apikey: " + Account.PUBLIC_KEY, "Authorization: Bearer " + jwt]), HTTPClient.METHOD_GET)
	return str(data.get("id", ""))

func start_match(room: Dictionary) -> void:
	var bytes := Crypto.new().generate_random_bytes(16)
	bytes[6] = (bytes[6] & 15) | 64
	bytes[8] = (bytes[8] & 63) | 128
	var hex := bytes.hex_encode()
	room.reward_match = "%s-%s-%s-%s-%s" % [hex.substr(0,8),hex.substr(8,4),hex.substr(12,4),hex.substr(16,4),hex.substr(20)]
	room.reward_users = {}
	var distinct: Dictionary = {}
	for i in range(room.people.size()):
		var person: Dictionary = room.people[i]
		var uid := str(person.get("account_id", ""))
		if not person.bot and person.peer > 0 and not uid.is_empty():
			distinct[uid] = true
			room.reward_users[i] = uid
	room.reward_eligible = enabled() and int(room.options.get("starting_cards", 5)) == 5 and distinct.size() >= 3 and distinct.size() == room.reward_users.size()
	room.reward_sent = {}

func observe(room: Dictionary) -> void:
	if not room.get("reward_eligible", false) or room.rules == null:
		return
	for slot in room.reward_users:
		var uid: String = room.reward_users[slot]
		if room.reward_sent.has(uid):
			continue
		var victory: bool = room.rules.phase == "finished" and room.rules.winner == slot
		if not victory and room.rules.players[slot].active:
			continue
		# Una disconnessione non e' eliminazione: il premio arriva solo dal risultato delle regole.
		room.reward_sent[uid] = true
		var key: String = room.reward_match + ":" + uid
		pending[key] = {"p_match_id": room.reward_match, "p_user_id": uid,
			"p_outcome": "victory" if victory else "elimination"}
	_flush()

func _flush() -> void:
	if sending or not enabled():
		return
	sending = true
	for key in pending.keys():
		var secret := OS.get_environment("SUPABASE_SECRET_KEY")
		var data := await _http("/rest/v1/rpc/bisca_award_match", PackedStringArray([
			"apikey: " + secret,
			"Content-Type: application/json"]), HTTPClient.METHOD_POST, JSON.stringify(pending[key]))
		if not data.is_empty():
			pending.erase(key)
			credited.emit(data)
	sending = false
