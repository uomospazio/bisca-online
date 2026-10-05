extends Node
## FCM push bridge. Requires the Godotx Firebase native plugin on iOS/Android.

signal registration_changed(registered: bool, message: String)
signal notification_received(title: String, body: String)

const WEBHOOK_RPC := "bisca_register_push_device"

var _account: Node
var _settings: Node
var _core: Object
var _messaging: Object
var _initialized := false
var _token := ""
var _registered_user := ""
var _registering := false
var _enabled_cache := false
var _plugin_requested := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_account = get_node("/root/AccountSession")
	_settings = get_node("/root/GameSettings")
	_enabled_cache = bool(_settings.values.get("push_notifications", false))
	_account.changed.connect(_on_account_changed)
	_settings.changed.connect(_on_settings_changed)
	_on_account_changed()
	if _enabled_cache:
		_initialize_plugin()

func _initialize_plugin() -> void:
	if _plugin_requested:
		return
	if OS.has_feature("web") or OS.get_name() not in ["Android", "iOS"]:
		return
	if not Engine.has_singleton("GodotxFirebaseCore") or not Engine.has_singleton("GodotxFirebaseMessaging"):
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
		_unregister_current_device()
		return
	_initialize_plugin()
	if _messaging == null:
		registration_changed.emit(false, "Plugin push mobile non installato.")
	elif _initialized:
		_messaging.call("request_permission")

func _on_core_initialized(success: bool) -> void:
	if not success:
		registration_changed.emit(false, "Firebase non inizializzato.")
		return
	_initialized = true
	_messaging.call("initialize")
	if bool(_settings.values.get("push_notifications", false)):
		_messaging.call("request_permission")

func _on_permission_granted() -> void:
	if _messaging != null:
		_messaging.call("get_token")

func _on_permission_denied() -> void:
	registration_changed.emit(false, "Permesso notifiche non concesso dal dispositivo.")

func _on_token_received(token: String) -> void:
	if token.strip_edges().is_empty():
		return
	_token = token
	_register_current_device()

func _on_message_received(title: String, body: String) -> void:
	notification_received.emit(title, body)
	get_node("/root/FriendsManager").refresh()

func _on_native_error(message: String) -> void:
	push_warning("BISCA push: %s" % message)
	registration_changed.emit(false, message)

func _on_account_changed() -> void:
	if not _token.is_empty():
		_register_current_device()

func _register_current_device() -> void:
	if _registering or _token.is_empty() or not bool(_settings.values.get("push_notifications", false)) or not _account.is_authenticated():
		return
	_registering = true
	var owner := str(_account.user_id)
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
	else:
		push_warning("BISCA push: registrazione dispositivo non riuscita.")
	registration_changed.emit(success, "Notifiche attive." if success else "Registrazione notifiche non riuscita.")

func _unregister_current_device() -> void:
	if _token.is_empty() or not _account.is_authenticated():
		_registered_user = ""
		return
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
		await request.request_completed
	request.queue_free()
	_registered_user = ""
