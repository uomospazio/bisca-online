extends Node
## Solo RPC controllate dal server. Nessuna copia persistente tra account.
signal changed
var entries: Array = []
var error := ""
var busy := false
var _owner := ""
var _generation := 0
var _account: Node

func _ready() -> void:
	_account = get_node("/root/AccountSession")
	_account.changed.connect(_account_changed)
	var timer := Timer.new()
	timer.wait_time = 30
	timer.timeout.connect(refresh)
	add_child(timer)
	if DisplayServer.get_name() != "headless":
		timer.start()
		_account_changed()

func _account_changed() -> void:
	if _owner != str(_account.user_id):
		_owner = str(_account.user_id)
		_generation += 1
		entries.clear()
		error = ""
		changed.emit()
	refresh()

func call_api(function: String, payload: Dictionary = {}) -> Dictionary:
	if not _account.is_authenticated():
		return {"ok": false, "message": "Account offline."}
	var generation := _generation
	var owner := str(_account.user_id)
	var request := HTTPRequest.new()
	request.timeout = 15
	request.accept_gzip = not OS.has_feature("web")
	add_child(request)
	var code := request.request(_account.PROJECT_URL + "/rest/v1/rpc/" + function,
		_account.database_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
	var response: Array = []
	if code == OK:
		response = await request.request_completed
	request.queue_free()
	if generation != _generation or owner != str(_account.user_id):
		return {"ok": false, "message": "Account cambiato."}
	if response.is_empty() or response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300:
		return {"ok": false, "message": "Operazione non riuscita: controlla connessione e SQL 006_friends.sql (massimo 50 richieste in sospeso)."}
	var body: String = response[3].get_string_from_utf8()
	return {"ok": true, "data": JSON.parse_string(body) if not body.is_empty() else null}

func refresh() -> void:
	if busy or _account == null or not _account.is_authenticated():
		return
	busy = true
	var generation := _generation
	var result := await call_api("bisca_friends_presence")
	var invites := await call_api("bisca_list_invites") if result.ok else {}
	busy = false
	if generation != _generation:
		refresh.call_deferred()
		return
	if result.ok and result.data is Array:
		entries = result.data
		if invites.get("ok",false) and invites.get("data") is Array:
			for invite in invites.data:
				for row in entries:
					if str(row.id) == str(invite.sender):
						row["invite_code"] = str(invite.room_code)
		error = ""
	else:
		error = result.get("message", "Risposta amici non valida.")
	changed.emit()

func pending_count() -> int:
	return entries.filter(func(row): return (row.status == "pending" and row.incoming) or row.has("invite_code")).size()

func display_name(row: Dictionary) -> String:
	var username := str(row.username) if row.get("username") != null else ""
	var code := str(row.public_id) if row.get("public_id") != null else ""
	return username + ("  #" + code if not code.is_empty() else "") if not username.is_empty() else ("#" + code if not code.is_empty() else "Profilo senza codice")
