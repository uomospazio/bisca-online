extends Node
## SOLO ANNUNCI DI TEST. Premi autorizzati dal server solo per tester espliciti.
## Non sostituire gli ID con annunci reali senza consenso UMP e verifica SSV.
signal changed
const ANDROID_UNIT := "ca-app-pub-3940256099942544/5224354917"
const IOS_UNIT := "ca-app-pub-3940256099942544/1712485313"
const SAVE := "user://rewarded_ads_test.cfg"
var busy := false
var message := ""
var _initialized := false
var _serial := 0
var _ad: RewardedAd
var _pending: Dictionary = {}
var _completed: Dictionary = {}
var _account: Node
var _earned := false

static func new_id() -> String:
	var h := Crypto.new().generate_random_bytes(16).hex_encode()
	return "%s-%s-%s-%s-%s" % [h.substr(0, 8), h.substr(8, 4), h.substr(12, 4), h.substr(16, 4), h.substr(20, 12)]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_account = get_node("/root/AccountSession")
	var config := ConfigFile.new()
	if config.load(SAVE) == OK:
		_pending = config.get_value("ads", "pending", {})
		_completed = config.get_value("ads", "completed", {})
	_account.changed.connect(func(): changed.emit())

func supported() -> bool:
	return OS.get_name() in ["Android", "iOS"] and Engine.has_singleton("PoingGodotAdMobRewardedAd")

func _key(placement: String, context: String) -> String:
	return str(_account.user_id) + ":" + placement + ":" + context

func claimed(placement: String, context: String) -> bool:
	return placement in ["solo", "multi"] and _completed.has(_key(placement, context))

func pending_for_account() -> bool:
	return not _pending.is_empty() and str(_pending.get("owner", "")) == str(_account.user_id)

func request_reward(placement: String, context := "") -> void:
	if busy or not placement in ["shop", "refresh", "solo", "multi"]:
		return
	if not _account.is_authenticated():
		_set_message("Connettiti a Internet per ricevere il premio.")
		return
	if pending_for_account():
		busy = true
		await _claim()
		return
	if not _pending.is_empty():
		_set_message("Recupera prima il premio dell'account precedente.")
		return
	if claimed(placement, context) or (placement in ["solo", "multi"] and context.is_empty()):
		_set_message("Premio già ricevuto o partita non disponibile.")
		return
	if not supported():
		_set_message("Video disponibili nelle build Android e iOS con AdMob.")
		return
	busy = true
	_serial += 1
	var serial := _serial
	var owner := str(_account.user_id)
	_earned = false
	_set_message("Verifica premio...")
	var check: Dictionary = await _rpc("bisca_ad_test_eligible", {"p_placement": placement, "p_context": context})
	if not check.get("ok", false) or owner != str(_account.user_id):
		_finish(str(check.get("message", "Account cambiato.")))
		return
	_set_message("Caricamento video di test...")
	if not _initialized:
		MobileAds.initialize()
		_initialized = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_failed_to_load = func(_error: LoadAdError):
		if serial == _serial: _finish("Video non disponibile. Riprova tra poco.")
	callback.on_ad_loaded = func(ad: RewardedAd):
		if serial != _serial or owner != str(_account.user_id):
			ad.destroy()
			if serial == _serial: _finish("Account cambiato.")
			return
		_ad = ad
		var full := FullScreenContentCallback.new()
		full.on_ad_failed_to_show_full_screen_content = func(_error: AdError):
			if serial == _serial: _finish("Impossibile aprire il video. Nessun premio consumato.")
		full.on_ad_dismissed_full_screen_content = func():
			# Le callback native sono differite: attendi anche il segnale premio.
			await get_tree().create_timer(0.5).timeout
			if serial != _serial: return
			if _earned:
				await _claim()
			else:
				_finish("Video interrotto: nessuna ricompensa.")
		ad.full_screen_content_callback = full
		var listener := OnUserEarnedRewardListener.new()
		listener.on_user_earned_reward = func(_reward: RewardedItem):
			_record_earned(serial, owner, placement, context)
		ad.show(listener)
	RewardedAdLoader.new().load(ANDROID_UNIT if OS.get_name() == "Android" else IOS_UNIT, AdRequest.new(), callback)
	await get_tree().create_timer(45.0).timeout
	if serial == _serial and _ad == null:
		_finish("Caricamento scaduto. Riprova.")

func _record_earned(serial: int, owner: String, placement: String, context: String) -> void:
	if serial != _serial or _earned: return
	_earned = true
	_pending = {"owner": owner, "p_claim": new_id(), "p_placement": placement, "p_context": context}
	_save()

func _claim() -> void:
	if not pending_for_account():
		_finish("Premio conservato: torna all'account che ha visto il video.")
		return
	_set_message("Registrazione premio...")
	var pending := _pending.duplicate()
	var payload := pending.duplicate()
	payload.erase("owner")
	var result: Dictionary = await _rpc("bisca_claim_test_ad", payload)
	if not result.get("ok", false):
		if str(result.get("code", "")) in ["DAILY_REFRESH_USED", "ALREADY_CLAIMED"]:
			# Un altro dispositivo può avere già ottenuto lo stesso bonus.
			_completed[str(pending.owner) + ":" + str(pending.p_placement) + ":" + str(pending.p_context)] = true
			_pending.clear()
			_save()
			if pending.p_placement == "refresh" and str(_account.user_id) == str(pending.owner):
				get_node("/root/ShopManager").invalidate_daily()
			_finish(str(result.message))
			return
		_finish(str(result.get("message", "")) + " Premi un pulsante video per recuperare, senza un altro annuncio.")
		return
	_completed[str(pending.owner) + ":" + str(pending.p_placement) + ":" + str(pending.p_context)] = true
	_pending.clear()
	_save()
	if str(_account.user_id) == str(pending.owner):
		var profile := get_node("/root/AccountProfile")
		if str(profile.profile.get("id", "")) == str(pending.owner):
			profile.profile.credits = int(result.credits)
			profile.changed.emit()
		if pending.p_placement == "refresh":
			get_node("/root/ShopManager").invalidate_daily()
	_finish("Shop aggiornato!" if pending.p_placement == "refresh" else "+%d monete ricevute!" % int(result.get("amount", 0)))

func _rpc(endpoint: String, payload: Dictionary) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 20
	add_child(http)
	var err := http.request(_account.PROJECT_URL + "/rest/v1/rpc/" + endpoint, _account.database_headers(), HTTPClient.METHOD_POST, JSON.stringify(payload))
	var response: Array = []
	if err == OK: response = await http.request_completed
	http.queue_free()
	if response.size() != 4 or response[0] != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "message": "Connessione non disponibile."}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if response[1] == 200 and data is Dictionary: return data
	var code := str(data.get("message", "")) if data is Dictionary else ""
	var messages := {"TESTER_REQUIRED": "Account non ancora abilitato ai premi di test.", "DAILY_REFRESH_USED": "Refresh già usato oggi (reset a mezzanotte UTC).", "MATCH_NOT_RECORDED": "Risultato partita non ancora sincronizzato. Riprova tra poco.", "ALREADY_CLAIMED": "Premio già ricevuto per questa partita."}
	return {"ok": false, "code": code, "message": messages.get(code, "Premio non disponibile: verifica la migrazione 016 sul server.")}

func _finish(text: String) -> void:
	_serial += 1
	if _ad != null: _ad.destroy()
	_ad = null
	busy = false
	_set_message(text)

func _set_message(text: String) -> void:
	message = text
	changed.emit()

func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("ads", "pending", _pending)
	config.set_value("ads", "completed", _completed)
	config.save(SAVE)
