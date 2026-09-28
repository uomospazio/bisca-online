extends Node
## Sincronizza esclusivamente il mazzo. Nome/foto lobby restano locali.
## Il cloud prevale al primo caricamento; modifiche locali non inviate prevalgono
## dopo un periodo offline. Le richieste sono seriali, senza lavoro per frame.

signal preferences_loaded
signal changed

const QUEUE_FILE := "user://bisca_profile_pending.cfg"

var profile: Dictionary = {}
var last_error := ""
var _pending := false
var _applying := false
var _busy := false
var _loaded := false
var _revision := 0
var _last_deck: Dictionary = {}
var _http: HTTPRequest
var _timer: Timer
var _account: Node
var _settings: Node
var _owner := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if DisplayServer.get_name() == "headless" or "--server" in OS.get_cmdline_user_args():
		return

	_account = get_node("/root/AccountSession")
	_settings = get_node("/root/GameSettings")

	_last_deck = _deck()
	_owner = str(_account.user_id)

	var queue := ConfigFile.new()

	# Migrazione una tantum della vecchia coda non separata per account.
	if not _owner.is_empty() and not FileAccess.file_exists(_queue_path()):
		var legacy := ConfigFile.new()

		if legacy.load(QUEUE_FILE) == OK and not legacy.has_section_key("sync", "migrated_to"):
			if legacy.save(_queue_path()) == OK:
				legacy.set_value("sync", "migrated_to", _owner)
				legacy.save(QUEUE_FILE)

	if queue.load(_queue_path()) == OK:
		_pending = bool(queue.get_value("sync", "pending", false))

		if _pending:
			_settings.set_value(
				"deck_back",
				queue.get_value("sync", "deck_back", 1)
			)

			_settings.set_value(
				"deck_front",
				queue.get_value("sync", "deck_front", 0)
			)

			_last_deck = _deck()

	_http = HTTPRequest.new()
	_http.timeout = 15.0
	add_child(_http)

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)

	_timer.timeout.connect(sync)
	_settings.changed.connect(_settings_changed)
	_account.changed.connect(_account_changed)

	sync()

func _queue_path() -> String:
	return (
		"user://bisca_profile_%s.cfg" % _owner
		if not _owner.is_empty()
		else QUEUE_FILE
	)

func _account_changed() -> void:
	var next_owner := str(_account.user_id)

	if next_owner != _owner:
		# Ogni identita' ha la propria coda.
		# Mai inviare il mazzo dell'ospite sopra quello di
		# un account esistente appena recuperato.
		_save_queue()

		_owner = next_owner
		_loaded = false
		_pending = false
		profile = {}
		_revision += 1

		var queue := ConfigFile.new()
		queue.load(_queue_path())

		_pending = bool(
			queue.get_value("sync", "pending", false)
		)

		_applying = true

		_settings.set_value(
			"deck_back",
			queue.get_value("sync", "deck_back", 1)
			if _pending
			else 1
		)

		_settings.set_value(
			"deck_front",
			queue.get_value("sync", "deck_front", 0)
			if _pending
			else 0
		)

		_settings.save_preferences()

		_last_deck = _deck()
		_applying = false

		preferences_loaded.emit()

	sync()

func _deck() -> Dictionary:
	return {
		"deck_back": int(_settings.values.deck_back),
		"deck_front": int(_settings.values.deck_front)
	}

func _settings_changed() -> void:
	var current := _deck()

	if _applying or current == _last_deck:
		return

	_last_deck = current
	_pending = true
	_revision += 1

	_save_queue()
	_timer.start(0.75)

func _save_queue() -> void:
	var queue := ConfigFile.new()

	queue.set_value(
		"sync",
		"pending",
		_pending
	)

	for key in _last_deck:
		queue.set_value(
			"sync",
			key,
			_last_deck[key]
		)

	if queue.save(_queue_path()) != OK:
		push_warning(
			"BISCA: salvataggio coda preferenze non riuscito."
		)

func _send(
	method: int,
	path: String,
	body: Dictionary = {}
) -> Dictionary:

	var request_owner := _owner
	var headers: PackedStringArray = _account.database_headers()

	if method == HTTPClient.METHOD_POST:
		headers.append(
			"Prefer: resolution=ignore-duplicates,return=representation"
		)

	var err := _http.request(
		_account.PROJECT_URL + "/rest/v1/bisca_profiles" + path,
		headers,
		method,
		"" if method == HTTPClient.METHOD_GET else JSON.stringify(body)
	)

	if err != OK:
		return {
			"ok": false,
			"code": 0
		}

	var response: Array = await _http.request_completed

	if request_owner != _owner:
		return {
			"ok": false,
			"code": 0,
			"data": null
		}

	return {
		"ok":
			response[0] == HTTPRequest.RESULT_SUCCESS
			and response[1] >= 200
			and response[1] < 300,

		"code": response[1],

		"data":
			JSON.parse_string(
				response[3].get_string_from_utf8()
			)
	}

func sync() -> void:
	if _busy or not _account.is_authenticated():
		return

	_busy = true

	var path := "?id=eq." + str(_account.user_id)

	if not _loaded:

		# MODIFICA:
		# Recuperiamo anche il public_id dell'account.
		var result := await _send(
			HTTPClient.METHOD_GET,
			path + "&select=id,username,public_id,deck_back,deck_front"
		)

		if not result.ok or not result.data is Array:
			_failed(int(result.code))
			return

		if result.data.is_empty():

			var initial := _deck()
			initial.id = _account.user_id

			result = await _send(
				HTTPClient.METHOD_POST,
				"?on_conflict=id",
				initial
			)

			if not result.ok:
				_failed(int(result.code))
				return

			# Rileggi anche quando un altro client ha creato
			# la riga nel frattempo.
			#
			# MODIFICA:
			# Recuperiamo anche public_id.
			result = await _send(
				HTTPClient.METHOD_GET,
				path + "&select=id,username,public_id,deck_back,deck_front"
			)

		if (
			not result.ok
			or not result.data is Array
			or result.data.is_empty()
		):
			_failed(int(result.code))
			return

		profile = result.data[0]

		if not _pending:
			_applying = true

			_settings.set_value(
				"deck_back",
				profile.deck_back
			)

			_settings.set_value(
				"deck_front",
				profile.deck_front
			)

			_settings.save_preferences()

			_last_deck = _deck()
			_applying = false

			preferences_loaded.emit()

		_loaded = true

	if _pending:
		var sent_revision := _revision
		var sent := _deck()

		var result := await _send(
			HTTPClient.METHOD_PATCH,
			path,
			sent
		)

		if not result.ok:
			_failed(int(result.code))
			return

		profile.merge(sent, true)

		if sent_revision == _revision:
			_pending = false
			_save_queue()

	_busy = false
	last_error = ""

	changed.emit()

	if _pending:
		_timer.start(0.75)

func _failed(code: int) -> void:
	_busy = false

	last_error = (
		"Profilo cloud non disponibile (HTTP %d). "
		+ "Preferenze locali conservate."
	) % code

	push_warning(last_error)

	changed.emit()

	# Ritenta lentamente, senza bloccare menu o partita.
	_timer.start(60.0)
