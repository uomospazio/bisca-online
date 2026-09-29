extends Node
## Identita' Supabase persistente, distinta dal posto nella lobby.
## Non assegna premi e non modifica nome/avatar scelti per la partita.

signal changed
const PROJECT_URL := "https://yaphzyncmzrbrruzcarn.supabase.co"
const PUBLIC_KEY := "sb_publishable_LaM_a9sRS2fdTbdrqR_S-A_eLAU1R9L"
const SESSION_FILE := "user://bisca_account.cfg"

var user_id := ""
var status := "offline"
var last_error := ""
var email := ""
var anonymous := true
var email_verified := false
var pending_email := ""
var password_ready := false
var _access_token := ""
var _refresh_token := ""
var _expires_at := 0
var _busy := false
var _request: HTTPRequest
var _renew: Timer
var _cache := ConfigFile.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# I server e i test headless non devono creare utenti reali.
	if DisplayServer.get_name() == "headless" or OS.get_cmdline_user_args().has("--server"):
		return
	_request = HTTPRequest.new()
	# Sul Web la decompressione e' gia' gestita dal browser.
	_request.accept_gzip = not OS.has_feature("web")
	_request.timeout = 15.0
	add_child(_request)
	_renew = Timer.new()
	_renew.one_shot = true
	add_child(_renew)
	_renew.timeout.connect(connect_account)
	var result := _cache.load(SESSION_FILE)
	if result != OK and result != ERR_FILE_NOT_FOUND:
		_fail("Salvataggio account non leggibile: nessun nuovo account creato.")
		return
	user_id = str(_cache.get_value("session", "user_id", ""))
	_refresh_token = str(_cache.get_value("session", "refresh_token", ""))
	pending_email = str(_cache.get_value("session", "pending_email", ""))
	password_ready = bool(_cache.get_value("session", "password_ready", false))
	connect_account()

func connect_account() -> void:
	if _busy or _request == null:
		return
	# Se esiste gia' un'identita', non sostituirla in caso di sessione invalida.
	if _refresh_token.is_empty() and not user_id.is_empty():
		_fail("Sessione account da recuperare.")
		return
	_busy = true
	status = "connecting"
	last_error = ""
	changed.emit()
	var path := "/auth/v1/signup" if _refresh_token.is_empty() else "/auth/v1/token?grant_type=refresh_token"
	var payload: Dictionary = {} if _refresh_token.is_empty() else {"refresh_token": _refresh_token}
	var error := _request.request(PROJECT_URL + path, PackedStringArray([
		"apikey: " + PUBLIC_KEY, "Content-Type: application/json"
	]), HTTPClient.METHOD_POST, JSON.stringify(payload))
	if error != OK:
		_fail("Account non raggiungibile; puoi continuare a giocare offline.")
		return
	var response: Array = await _request.request_completed
	_busy = false
	if int(response[0]) != HTTPRequest.RESULT_SUCCESS:
		_fail("Connessione account non riuscita; sessione conservata.")
		return
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if not data is Dictionary or int(response[1]) < 200 or int(response[1]) >= 300:
		_fail("Accesso account non riuscito (HTTP %s). Controlla che Anonymous Sign-Ins sia attivo." % response[1])
		return
	var account: Dictionary = data.get("user", {})
	if str(account.get("id", "")).is_empty() or str(data.get("refresh_token", "")).is_empty() or str(data.get("access_token", "")).is_empty():
		_fail("Risposta account incompleta; sessione conservata.")
		return
	if not user_id.is_empty() and user_id != str(account.id):
		_fail("Identita' inattesa: sessione precedente conservata.")
		return
	user_id = str(account.id)
	_read_user(account)
	_access_token = str(data.access_token)
	_refresh_token = str(data.refresh_token)
	_expires_at = int(Time.get_unix_time_from_system()) + int(data.get("expires_in", 3600))
	_cache.set_value("session", "user_id", user_id)
	_cache.set_value("session", "refresh_token", _refresh_token)
	_cache.set_value("session", "pending_email", pending_email)
	_cache.set_value("session", "password_ready", password_ready)
	if _cache.save(SESSION_FILE) != OK:
		_fail("Account connesso, ma salvataggio locale non riuscito.")
		return
	status = "connected"
	_renew.start(maxf(30.0, float(_expires_at) - Time.get_unix_time_from_system() - 60.0))
	changed.emit()
	print("BISCA: account ospite connesso; sessione salvata.")

func _fail(message: String) -> void:
	_busy = false
	status = "offline"
	last_error = message
	changed.emit()
	push_warning(message)

func is_authenticated() -> bool:
	return status == "connected" and Time.get_unix_time_from_system() < _expires_at

## Solo per richieste HTTPS al nostro progetto; non salvare o stampare questi header.
func database_headers() -> PackedStringArray:
	return PackedStringArray(["apikey: " + PUBLIC_KEY,
		"Authorization: Bearer " + _access_token, "Content-Type: application/json"])

func _read_user(data: Dictionary) -> void:
	email = str(data.get("email", ""))
	anonymous = bool(data.get("is_anonymous", true))
	email_verified = data.get("email_confirmed_at") != null
	if email_verified:
		pending_email = ""

## Richieste esplicite dal pannello. Nessuna password viene salvata o loggata.
func _auth_action(path: String, method: int, body: Dictionary, authorized := true) -> Dictionary:
	if _busy or _request == null:
		return {"ok": false, "message": "Attendi la connessione account e riprova."}
	if authorized and not is_authenticated():
		return {"ok": false, "message": "Account offline. Riconnetti e riprova."}
	_busy = true
	var headers := database_headers() if authorized else PackedStringArray(["apikey: " + PUBLIC_KEY, "Content-Type: application/json"])
	var err := _request.request(PROJECT_URL + "/auth/v1/" + path, headers, method,
		"" if method == HTTPClient.METHOD_GET else JSON.stringify(body))
	if err != OK:
		_busy = false
		return {"ok": false, "message": "Connessione non riuscita. Riprova."}
	var response: Array = await _request.request_completed
	_busy = false
	# Come Supabase Auth: una sessione gia' revocata/non valida non deve
	# impedire l'uscita locale esplicitamente richiesta dall'utente.
	if path == "logout?scope=local" and response[0] == HTTPRequest.RESULT_SUCCESS and response[1] in [401, 403, 404]:
		return {"ok": true, "data": {}}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300:
		var code := str(data.get("error_code", "")) if data is Dictionary else ""
		var message := "Operazione non riuscita (HTTP %s). Riprova." % response[1]
		if code in ["invalid_credentials", "email_not_confirmed"]:
			message = "Email/password errate oppure email non confermata."
		elif code in ["email_exists", "user_already_exists"]:
			message = "Email gia' usata: scegli ACCEDI. I profili non vengono uniti."
		elif code in ["otp_expired", "otp_disabled"]:
			message = "Codice non valido o scaduto. Richiedine uno nuovo."
		elif response[1] == 429:
			message = "Troppe richieste. Attendi prima di riprovare."
		elif code == "weak_password":
			message = "Password troppo debole: usa almeno 8 caratteri, lettere e numeri."
		return {"ok": false, "message": message}
	return {"ok": true, "data": data if data is Dictionary else {}}

func link_email(address: String) -> Dictionary:
	var result := await _auth_action("user", HTTPClient.METHOD_PUT, {"email": address.strip_edges()})
	if result.ok:
		pending_email = address.strip_edges()
		_cache.set_value("session", "pending_email", pending_email)
		_cache.save(SESSION_FILE)
	return result

func check_email_confirmation() -> Dictionary:
	# La conferma avviene nel browser. Leggi l'utente dal server, non fidarti
	# del pulsante o dei dati locali/JWT precedenti all'apertura del link.
	var result := await _auth_action("user", HTTPClient.METHOD_GET, {})
	if not result.ok:
		return result
	var user: Dictionary = result.data
	if str(user.get("id", "")) != user_id:
		return {"ok": false, "message": "Identita' inattesa. Account precedente conservato."}
	if user.get("email_confirmed_at") == null or str(user.get("email", "")).is_empty() or bool(user.get("is_anonymous", true)):
		return {"ok": false, "message": "Email non ancora confermata. Apri il link nell'email e poi riprova."}
	if not pending_email.is_empty() and str(user.email).to_lower() != pending_email.to_lower():
		return {"ok": false, "message": "Conferma prima il nuovo indirizzo email richiesto."}
	_read_user(user)
	_cache.set_value("session", "pending_email", "")
	if _cache.save(SESSION_FILE) != OK:
		return {"ok": false, "message": "Email confermata, ma salvataggio locale non riuscito. Riprova."}
	changed.emit()
	return {"ok": true}

func set_password(password: String) -> Dictionary:
	if not email_verified or password.length() < 8:
		return {"ok": false, "message": "Conferma prima l'email e usa almeno 8 caratteri."}
	var result := await _auth_action("user", HTTPClient.METHOD_PUT, {"password": password})
	if result.ok:
		password_ready = true
		_read_user(result.data)
		_cache.set_value("session", "password_ready", true)
		_cache.save(SESSION_FILE)
		changed.emit()
	return result

func sign_in(address: String, password: String) -> Dictionary:
	var result := await _auth_action("token?grant_type=password", HTTPClient.METHOD_POST,
		{"email": address.strip_edges(), "password": password}, false)
	if result.ok:
		if not _accept_session(result.data, true):
			return {"ok": false, "message": "Impossibile salvare la sessione. Account precedente conservato."}
	return result

## Chiamata solo dopo conferma esplicita: nessuna cancellazione dell'account cloud.
func continue_as_new_guest() -> Dictionary:
	var result := await _auth_action("signup", HTTPClient.METHOD_POST, {}, false)
	if not result.ok:
		return result
	var user: Dictionary = result.data.get("user", {})
	if not bool(user.get("is_anonymous", false)) or str(user.get("id", "")) == user_id:
		return {"ok": false, "message": "Risposta ospite inattesa. Sessione precedente conservata."}
	if not _accept_session(result.data, true):
		return {"ok": false, "message": "Impossibile salvare il nuovo ospite. Sessione precedente conservata."}
	return {"ok": true}

func _accept_session(data: Dictionary, allow_switch: bool) -> bool:
	var user: Dictionary = data.get("user", {})
	var next_id := str(user.get("id", ""))
	if next_id.is_empty() or str(data.get("refresh_token", "")).is_empty() or str(data.get("access_token", "")).is_empty():
		return false
	if not allow_switch and next_id != user_id:
		return false
	var next_cache := ConfigFile.new()
	next_cache.set_value("session", "user_id", next_id)
	next_cache.set_value("session", "refresh_token", data.refresh_token)
	var next_password_ready := not bool(user.get("is_anonymous", true)) and (allow_switch or password_ready)
	next_cache.set_value("session", "password_ready", next_password_ready)
	if next_cache.save(SESSION_FILE) != OK:
		return false
	_cache = next_cache
	user_id = next_id
	password_ready = next_password_ready
	if allow_switch:
		pending_email = ""
	_read_user(user)
	_access_token = str(data.access_token)
	_refresh_token = str(data.refresh_token)
	_expires_at = int(Time.get_unix_time_from_system()) + int(data.get("expires_in", 3600))
	status = "connected"
	last_error = ""
	_renew.start(maxf(30.0, float(_expires_at) - Time.get_unix_time_from_system() - 60.0))
	changed.emit()
	return true

func sign_out() -> Dictionary:
	if anonymous or not password_ready:
		return {"ok": false, "message": "Collega prima email e password per non perdere l'ospite."}
	var result := await _auth_action("logout?scope=local", HTTPClient.METHOD_POST, {})
	if not result.ok:
		return result
	var empty := ConfigFile.new()
	if empty.save(SESSION_FILE) != OK:
		return {"ok": false, "message": "Impossibile cancellare la sessione locale."}
	_cache = empty
	_renew.stop()
	user_id = ""
	_refresh_token = ""
	_access_token = ""
	email = ""
	pending_email = ""
	anonymous = true
	email_verified = false
	password_ready = false
	status = "offline"
	changed.emit()
	connect_account()
	return {"ok": true}
