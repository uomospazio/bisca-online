extends Node
## SOLO ANNUNCI DI TEST. Premi autorizzati dal server solo per tester espliciti.
## Non sostituire gli ID con annunci reali senza consenso UMP e verifica SSV.
signal changed
const ANDROID_UNIT := "ca-app-pub-3940256099942544/5224354917"
const IOS_UNIT := "ca-app-pub-3940256099942544/1712485313"
const SAVE := "user://rewarded_ads_test.cfg"

# SOLO PER TEST UMP. Rimettere false prima della build di produzione.
const UMP_DEBUG_FORCE_EEA := true
const UMP_TEST_DEVICE_ID := "66350DC7-1D59-4CF7-BF79-7CF5FEB25942"
var busy := false
var message := ""
var _initialized := false
var _serial := 0
var _ad: RewardedAd
var _pending: Dictionary = {}
var _completed: Dictionary = {}
var _account: Node
var _earned := false

# UMP / privacy consent state.
var consent_ready := false
var privacy_message := ""
var _consent_started := false
var _consent_info: ConsentInformation

func _ump_log(text: String) -> void:
	print("[BISCA UMP] " + text)

func _ump_dump_state(where: String) -> void:
	if _consent_info == null:
		_ump_log(where + " | consent_info=NULL")
		return
	_ump_log(
		where
		+ " | consent_status=" + str(_consent_info.get_consent_status())
		+ " | form_available=" + str(_consent_info.get_is_consent_form_available())
		+ " | privacy_options=" + str(_consent_info.get_privacy_options_requirement_status())
	)

# Poing 5.1 espone enum GDScript con ordine Android-style:
# UNKNOWN=0, NOT_REQUIRED=1, REQUIRED=2, OBTAINED=3.
# L'SDK UMP nativo iOS usa invece:
# UNKNOWN=0, REQUIRED=1, NOT_REQUIRED=2, OBTAINED=3.
# I log su iPhone mostrano i valori nativi, quindi su iOS li interpretiamo
# esplicitamente per evitare di inizializzare gli ads quando il consenso è richiesto.
func _consent_is_required() -> bool:
	if _consent_info == null:
		return false
	var raw := int(_consent_info.get_consent_status())
	if OS.get_name() == "iOS":
		return raw == 1
	return raw == int(ConsentInformation.ConsentStatus.REQUIRED)

func _consent_is_not_required() -> bool:
	if _consent_info == null:
		return false
	var raw := int(_consent_info.get_consent_status())
	if OS.get_name() == "iOS":
		return raw == 2
	return raw == int(ConsentInformation.ConsentStatus.NOT_REQUIRED)

func _consent_is_obtained() -> bool:
	if _consent_info == null:
		return false
	return int(_consent_info.get_consent_status()) == 3

func _privacy_options_are_required() -> bool:
	if _consent_info == null:
		return false
	var raw := int(_consent_info.get_privacy_options_requirement_status())
	if OS.get_name() == "iOS":
		return raw == 1
	return raw == int(ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)

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
	_ump_log("ready | os=" + OS.get_name() + " | rewarded_supported=" + str(supported()) + " | privacy_supported=" + str(privacy_supported()))
	if supported():
		call_deferred("_start_consent_flow")

func supported() -> bool:
	return OS.get_name() in ["Android", "iOS"] and Engine.has_singleton("PoingGodotAdMobRewardedAd")


func privacy_supported() -> bool:
	return (
		OS.get_name() in ["Android", "iOS"]
		and Engine.has_singleton("PoingGodotAdMobConsentInformation")
		and Engine.has_singleton("PoingGodotAdMobUserMessagingPlatform")
	)

func privacy_options_required() -> bool:
	if not privacy_supported() or _consent_info == null:
		return false
	return _privacy_options_are_required()

func show_privacy_options() -> void:
	if not privacy_supported():
		privacy_message = "Le opzioni privacy sono disponibili nell'app Android e iOS."
		changed.emit()
		return
	if _consent_info == null:
		_consent_info = UserMessagingPlatform.consent_information
	if not privacy_options_required():
		privacy_message = "Non sono richieste opzioni privacy aggiuntive per questo dispositivo."
		changed.emit()
		return
	privacy_message = "Apertura preferenze privacy..."
	changed.emit()
	UserMessagingPlatform.show_privacy_options_form(func(error: FormError):
		if error != null:
			privacy_message = "Impossibile aprire le preferenze privacy: " + str(error.message)
		else:
			privacy_message = ""
		_finish_consent_state()
		changed.emit()
	)

func _start_consent_flow() -> void:
	_ump_log("_start_consent_flow()")
	if _consent_started:
		_ump_log("flow already started; skip")
		return
	if not privacy_supported():
		_ump_log("privacy_supported=false; skip")
		return
	_consent_started = true
	_consent_info = UserMessagingPlatform.consent_information
	consent_ready = false
	privacy_message = ""
	changed.emit()

	var params := ConsentRequestParameters.new()
	if UMP_DEBUG_FORCE_EEA:
		_ump_log("DEBUG ON | forcing EEA | test_device=" + UMP_TEST_DEVICE_ID)
		# Simula una prima installazione in area SEE/EEA.
		# reset() è SOLO per test: con questa costante a true il popup può
		# ricomparire a ogni avvio.
		_consent_info.reset()
		_ump_dump_state("after reset")
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = DebugGeography.Values.EEA
		debug_settings.test_device_hashed_ids.append(UMP_TEST_DEVICE_ID)
		params.consent_debug_settings = debug_settings

	_ump_log("calling consent_information.update()")
	_consent_info.update(
		params,
		func():
			_ump_log("update SUCCESS")
			_ump_dump_state("after update success")
			_handle_consent_info_updated(),
		func(error: FormError):
			_ump_log("update FAILURE | " + ("null error" if error == null else str(error.message)))
			# Se esiste già una decisione valida salvata, possiamo continuare.
			# Con stato UNKNOWN/REQUIRED non richiediamo annunci.
			privacy_message = "Impossibile aggiornare il consenso privacy."
			if error != null and not str(error.message).is_empty():
				privacy_message += " " + str(error.message)
			_finish_consent_state()
			changed.emit()
	)

func _handle_consent_info_updated() -> void:
	_ump_dump_state("_handle_consent_info_updated")

	if _consent_is_required():
		_ump_log("consent status REQUIRED (platform-aware)")
		if not _consent_info.get_is_consent_form_available():
			_ump_log("form_available=false from bridge; trying load anyway on REQUIRED state")

		_ump_log("loading consent form...")
		UserMessagingPlatform.load_consent_form(
			func(form: ConsentForm):
				_ump_log("consent form LOADED; showing...")
				form.show(func(error: FormError):
					_ump_log("consent form DISMISSED | " + ("no error" if error == null else str(error.message)))
					_ump_dump_state("after form dismissed")
					if error != null:
						privacy_message = "Errore nel modulo privacy: " + str(error.message)
					else:
						privacy_message = ""
					_finish_consent_state()
					changed.emit()
				),
			func(error: FormError):
				_ump_log("consent form LOAD FAILURE | " + ("null error" if error == null else str(error.message)))
				privacy_message = "Impossibile caricare il modulo privacy."
				if error != null and not str(error.message).is_empty():
					privacy_message += " " + str(error.message)
				# Se il consenso è REQUIRED non inizializziamo AdMob.
				consent_ready = false
				changed.emit()
		)
		return

	if _consent_is_not_required():
		_ump_log("consent status NOT_REQUIRED (platform-aware)")
	elif _consent_is_obtained():
		_ump_log("consent status OBTAINED")
	else:
		_ump_log("consent status UNKNOWN/unexpected; ads remain blocked")

	privacy_message = ""
	_finish_consent_state()
	changed.emit()

func _can_request_ads_from_consent() -> bool:
	return _consent_is_not_required() or _consent_is_obtained()

func _finish_consent_state() -> void:
	_ump_dump_state("_finish_consent_state")
	consent_ready = _can_request_ads_from_consent()
	_ump_log("consent_ready=" + str(consent_ready) + " | mobile_ads_initialized=" + str(_initialized))
	if consent_ready and not _initialized:
		MobileAds.initialize()
		_initialized = true

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
	if not _initialized:
		if not _consent_started:
			_start_consent_flow()
		_set_message("Completa le preferenze privacy prima di vedere il video.")
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
