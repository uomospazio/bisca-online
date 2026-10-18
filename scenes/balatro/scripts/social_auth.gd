extends Node
## Browser OAuth + PKCE. Pending secrets are memory-only and never logged.
signal completed(result: Dictionary)
const REDIRECT := "com.bisca.game://auth/callback"
var account: Node
var bridge: Object
var pending := false
var exchanging := false
var verifier := ""
var flow := ""
var account_owner := ""
var linking := false
var generation := 0
var deadline := 0

func _ready() -> void:
	account = get_parent()
	if Engine.has_singleton("BiscaVoice"):
		var candidate = Engine.get_singleton("BiscaVoice")
		if candidate.has_method("open_auth") and candidate.has_method("drain_auth"):
			bridge = candidate

static func base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

static func callback_params(url: String) -> Dictionary:
	if not url.begins_with(REDIRECT + "?") or url.length() > 8192:
		return {}
	var result := {}
	var query := url.get_slice("#",0).substr(REDIRECT.length()+1)
	for pair in query.split("&"):
		if not pair.contains("="):
			return {}
		var key := pair.get_slice("=", 0).uri_decode()
		if result.has(key):
			return {}
		result[key] = pair.substr(pair.find("=") + 1).uri_decode()
	# Supabase may append its marker/error metadata in the fragment. Never
	# accept a token or authentication code from there: login remains PKCE.
	var fragment := url.get_slice("#",1) if url.contains("#") else ""
	var seen := {}
	for pair in fragment.split("&",false):
		var key := pair.get_slice("=",0).uri_decode()
		if key not in ["sb","error","error_code","error_description"] or seen.has(key): return {}
		seen[key] = true
		var value := pair.substr(pair.find("=")+1).uri_decode() if pair.contains("=") else ""
		if key=="sb": continue
		if result.has(key) and result[key]!=value: return {}
		result[key] = value
	return result

func start(provider: String, link_current: bool) -> void:
	if pending:
		return
	if provider not in ["google", "apple"] or bridge == null:
		completed.emit({"ok": false, "message": "Accesso disponibile nella nuova build Android/iOS con il bridge aggiornato."})
		return
	if account._busy or (link_current and not account.is_authenticated()):
		completed.emit({"ok": false, "message": "Attendi la connessione account e riprova."})
		return
	generation += 1
	var attempt := generation
	pending = true
	linking = link_current
	account_owner = account.user_id
	verifier = base64url(Crypto.new().generate_random_bytes(32))
	flow = Crypto.new().generate_random_bytes(24).hex_encode()
	deadline = Time.get_ticks_msec() + 300000
	var redirect := REDIRECT + "?flow=" + flow
	var query := "provider=%s&redirect_to=%s&code_challenge=%s&code_challenge_method=s256" % [provider, redirect.uri_encode(), base64url(verifier.sha256_buffer())]
	var url: String = account.PROJECT_URL + "/auth/v1/authorize?" + query
	if linking:
		var response: Dictionary = await account._auth_action("user/identities/authorize?" + query + "&skip_http_redirect=true", HTTPClient.METHOD_GET, {})
		if attempt != generation:
			return
		if not response.get("ok", false):
			_finish({"ok": false, "message": "Collegamento non riuscito. Verifica provider e Manual Linking su Supabase; se l'identità è già usata, scegli Accedi a un altro account."})
			return
		url = str(response.get("data", {}).get("url", ""))
	if not url.begins_with("https://"):
		_finish({"ok": false, "message": "URL di autenticazione non valido."})
		return
	bridge.open_auth(url)

func cancel() -> void:
	if pending:
		_finish({"ok": false, "message": "Accesso annullato. Account precedente conservato."})

func _process(_delta: float) -> void:
	if not pending or exchanging:
		return
	if Time.get_ticks_msec() > deadline:
		_finish({"ok": false, "message": "Accesso scaduto. Riprova."})
		return
	var value: String = bridge.drain_auth()
	if value.is_empty():
		return
	if value in ["cancel", "error"]:
		_finish({"ok": false, "message": "Accesso annullato o browser non disponibile."})
		return
	var params := callback_params(value)
	if params.is_empty() or not params.has("flow"):
		_finish({"ok":false,"message":"Ritorno dal browser non valido. Riprova l'accesso; verifica il redirect configurato su Supabase."})
		return
	if params.get("flow", "") != flow:
		return # Ignore unsolicited/stale callbacks.
	if params.has("error") or str(params.get("code", "")).is_empty():
		var reason := str(params.get("error_code",params.get("error","codice mancante")))
		# Only a short error identifier, never the callback URL, code or tokens.
		if RegEx.create_from_string("^[a-zA-Z0-9_]{1,80}$").search(reason)==null: reason="errore provider"
		_finish({"ok": false, "message": "Accesso non completato (%s). Riprova o verifica il provider su Supabase." % reason})
		return
	_exchange(str(params.code))

func _exchange(code: String) -> void:
	exchanging = true
	var attempt := generation
	# Token refresh may already be in flight when the browser returns.
	var wait_until := Time.get_ticks_msec() + 20000
	while account._busy and Time.get_ticks_msec() < wait_until:
		await get_tree().create_timer(0.1).timeout
		if attempt != generation:
			return
	if account.user_id != account_owner:
		_finish({"ok": false, "message": "Account cambiato durante l'accesso. Riprova."})
		return
	var response: Dictionary = await account._auth_action("token?grant_type=pkce", HTTPClient.METHOD_POST, {"auth_code": code, "code_verifier": verifier}, false)
	if attempt != generation:
		return
	if account.user_id != account_owner:
		_finish({"ok": false, "message": "Account cambiato durante l'accesso. Riprova."})
		return
	if not response.get("ok", false):
		_finish({"ok": false, "message": "Accesso non riuscito o scaduto. Riprova."})
		return
	if not account._accept_session(response.data, not linking, false):
		_finish({"ok": false, "message": "Sessione non salvata o identità diversa. Account precedente conservato."})
		return
	_finish({"ok": true})

func _finish(result: Dictionary) -> void:
	generation += 1
	pending = false
	exchanging = false
	verifier = ""
	flow = ""
	if bridge != null and bridge.has_method("cancel_auth"):
		bridge.cancel_auth()
	completed.emit(result)
