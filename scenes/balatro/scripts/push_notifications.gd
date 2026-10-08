extends Node
## FCM push bridge. Requires the Godotx Firebase native plugin on iOS/Android.

signal registration_changed(registered: bool, message: String)
signal notification_received(title: String, body: String)

const WEBHOOK_RPC := "bisca_register_push_device"
const IOS_PUSH_ENABLED := true # Requires paid Apple team and APNs configuration in Firebase.

var _account: Node
var _settings: Node
var _core: Object
var _messaging: Object
var _initialized := false
var _token := ""
var _registered_user := ""
var _registering := false
var _unregistering := false
var _enabled_cache := false
var _plugin_requested := false
var last_message := "Notifiche non ancora verificate."
var last_registered := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_account = get_node("/root/AccountSession")
	_settings = get_node("/root/GameSettings")
	if OS.get_name() == "iOS" and not IOS_PUSH_ENABLED:
		_report(false, "Notifiche temporaneamente non disponibili su iOS.")
		return
	_enabled_cache = bool(_settings.values.get("push_notifications", false))
	_account.changed.connect(_on_account_changed)
	_settings.changed.connect(_on_settings_changed)
	_on_account_changed()
	_initialize_plugin()

func _initialize_plugin() -> void:
	if _plugin_requested:
		return
	if OS.has_feature("web") or OS.get_name() not in ["Android", "iOS"]:
		return
	if not Engine.has_singleton("GodotxFirebaseCore") or not Engine.has_singleton("GodotxFirebaseMessaging"):
		_report(false, "Plugin Firebase mobile assente in questa build.")
		return # Keep desktop/Web usable; native plugins are supplied at mobile export time.
	_plugin_requested = true
	_core = Engine.get_singleton("GodotxFirebaseCore")
	_messaging = Engine.get_singleton("GodotxFirebaseMessaging")
	_core.connect("core_initialized", _on_core_initialized)
	_messaging.connect("messaging_permission_granted", _on_permission_granted)
	_messaging.connect("messaging_permission_denied", _on_permission_denied)
	_messaging.connect("messaging_token_received", _on_token_received)
	_messaging.connect("messaging_message_received", _on_message_received)
	_messaging.connect("messaging_error", _on_native_error)
	_core.call("initialize")

func set_enabled(enabled: bool) -> void:
	_settings.set_value("push_notifications", enabled)

func _on_settings_changed() -> void:
	var enabled := bool(_settings.values.get("push_notifications", false))
	if enabled == _enabled_cache:
		return
	_enabled_cache = enabled
	if not enabled:
		_permission_granted = false
		_unregister_current_device()
		_report(false, "Notifiche disattivate.")
		return
	_initialize_plugin()
	if _messaging == null:
		_report(false, "Plugin push mobile non installato.")
	elif not _permission_granted:
		_report(false, "Verifica del permesso notifiche in corso…")
		_request_permission()

var _permission_granted := false

func _request_permission() -> void:
	if _messaging == null or not _initialized:
		return
	_messaging.call("request_permission")

func _on_core_initialized(success: bool) -> void:
	if not success:
		_report(false, "Firebase non inizializzato: controlla la configurazione inclusa nell’APK.")
		return
	_initialized = true
	_messaging.call("initialize")
	var opted_in := bool(_settings.values.get("push_notifications", false))
	var permission_asked := bool(_settings.values.get("push_permission_asked", false))
	if opted_in:
		_request_permission() # Re-check OS permission and refresh the FCM token on startup.
	elif not permission_asked:
		# Record before opening the OS dialog: a restart won't unexpectedly ask again.
		_settings.set_value("push_permission_asked", true)
		_request_permission()
	else:
		_report(false, "Permesso non attivo. Riattiva Notifiche push e consenti la richiesta di Android.")

func _on_permission_granted() -> void:
	_permission_granted = true
	_report(false, "Permesso concesso; richiesta del token FCM…")
	if not bool(_settings.values.get("push_notifications", false)):
		_settings.set_value("push_notifications", true)
	if _messaging != null:
		_messaging.call("get_token")

func _on_permission_denied() -> void:
	_permission_granted = false
	if bool(_settings.values.get("push_notifications", false)):
		_settings.set_value("push_notifications", false)
	_report(false, "Permesso notifiche negato o disattivato nelle impostazioni Android.")

func _on_token_received(token: String) -> void:
	if token.strip_edges().is_empty():
		_report(false, "Firebase ha restituito un token vuoto.")
		return
	if token != _token:
		_registered_user = ""
	_token = token
	_report(false, "Token FCM ricevuto; registrazione dell’account in corso…")
	_register_current_device()

func _on_message_received(title: String, body: String) -> void:
	notification_received.emit(title, body)
	get_node("/root/FriendsManager").refresh()

func _on_native_error(message: String) -> void:
	push_warning("BISCA push: %s" % message)
	_report(false, "Errore Firebase: %s" % message)

func _on_account_changed() -> void:
	if not bool(_settings.values.get("push_notifications", false)):
		_unregister_current_device()
	elif not _token.is_empty():
		_register_current_device()

func _register_current_device() -> void:
	if _registering or _token.is_empty() or not bool(_settings.values.get("push_notifications", false)):
		return
	if not _account.is_authenticated():
		_report(false, "Token ricevuto; attendo la connessione all’account ospite BISCA…")
		return
	var owner := str(_account.user_id)
	if _registered_user == owner:
		return
	_registering = true
	var request := HTTPRequest.new()
	request.timeout = 15.0
	request.accept_gzip = not OS.has_feature("web")
	add_child(request)
	var platform := "ios" if OS.get_name() == "iOS" else "android"
	var err := request.request(
		_account.PROJECT_URL + "/rest/v1/rpc/" + WEBHOOK_RPC,
		_account.database_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify({"device_token": _token, "device_platform": platform})
	)
	var response: Array = []
	if err == OK:
		response = await request.request_completed
	request.queue_free()
	_registering = false
	if owner != str(_account.user_id):
		_register_current_device()
		return
	var success: bool = not response.is_empty() and response[0] == HTTPRequest.RESULT_SUCCESS and response[1] >= 200 and response[1] < 300
	if success:
		_registered_user = owner
		_report(true, "Notifiche attive: dispositivo registrato su BISCA.")
	else:
		var detail := _registration_error_detail(response, err)
		push_warning("BISCA push: registrazione non riuscita (%s)." % detail)
		_report(false, "Registrazione token non riuscita (%s)." % detail)

func _registration_error_detail(response: Array, request_error: int) -> String:
	if request_error != OK:
		return "avvio richiesta HTTP %s" % error_string(request_error)
	if response.is_empty():
		return "nessuna risposta HTTP"
	var detail := "trasporto %s, HTTP %s" % [response[0], response[1]]
	if response.size() < 4 or not response[3] is PackedByteArray:
		return detail
	var parsed = JSON.parse_string(response[3].get_string_from_utf8())
	if not parsed is Dictionary:
		return detail
	# Mostra solo i campi diagnostici standard PostgREST, mai il corpo intero.
	var code := str(parsed.get("code", ""))
	var message := str(parsed.get("message", ""))
	if not _token.is_empty():
		message = message.replace(_token, "[token nascosto]")
	message = message.replace("\n", " ").replace("\r", " ").strip_edges()
	if not code.is_empty():
		detail += ", codice %s" % code
	if not message.is_empty():
		detail += ": %s" % message.left(180)
	return detail

func _report(registered: bool, message: String) -> void:
	last_registered = registered
	last_message = message
	registration_changed.emit(registered, message)

func _unregister_current_device() -> void:
	if _unregistering or _token.is_empty() or _registered_user.is_empty() or not _account.is_authenticated():
		return
	_unregistering = true
	var request := HTTPRequest.new()
	request.timeout = 15.0
	request.accept_gzip = not OS.has_feature("web")
	add_child(request)
	var err := request.request(
		_account.PROJECT_URL + "/rest/v1/rpc/bisca_unregister_push_device",
		_account.database_headers(),
		HTTPClient.METHOD_POST,
		JSON.stringify({"device_token": _token})
	)
	if err == OK:
		var response: Array = await request.request_completed
		if not response.is_empty() and response[0] == HTTPRequest.RESULT_SUCCESS and response[1] >= 200 and response[1] < 300:
			_registered_user = ""
	request.queue_free()
	_unregistering = false
