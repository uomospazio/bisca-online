extends Node
## SOLA LETTURA: proprieta' cosmetici, non equipaggiamento o acquisti.
## AccountProfile resta responsabile di deck_back/front. Nessun dato su disco.
signal catalog_loaded
signal inventory_loaded
signal changed

const DEFAULT_ITEM := "deck_back_1"
const PAGE_SIZE := 100
const MAX_PAGES := 100
var catalog_ready := false
var inventory_ready := false
var loading := false
var last_error := ""
var stale := false
var _catalog: Dictionary = {}
var _inventory: Dictionary = {}
var _owner := ""
var _generation := 0
var _queued := false
var _account: Node
var _http: HTTPRequest
var purchasing := false
var daily_error := ""
var _daily_ids: Array = []
var _daily_loading := false
var _daily_until := 0

func get_daily_items() -> Array:
	var result: Array = []
	for id in _daily_ids:
		var item := get_item(str(id))
		if not item.is_empty() and item.is_available:
			result.append(item)
	return result

func refresh_daily() -> void:
	if DisplayServer.get_name() == "headless" or _daily_loading:
		return
	if Time.get_ticks_msec() < _daily_until:
		return
	_daily_ids.clear()
	if _account == null or not _account.is_authenticated():
		daily_error = "MARKET GIORNALIERO: CONNETTITI A INTERNET."
		changed.emit()
		return
	_daily_loading = true
	daily_error = "CARICAMENTO MARKET..."
	changed.emit()
	var request := HTTPRequest.new()
	request.timeout = 15.0
	request.accept_gzip = not OS.has_feature("web")
	add_child(request)
	var error := request.request(_account.PROJECT_URL + "/rest/v1/rpc/bisca_daily_shop", _account.database_headers(), HTTPClient.METHOD_POST, "{}")
	var response: Array = []
	if error == OK:
		response = await request.request_completed
	request.queue_free()
	_daily_loading = false
	daily_error = "MARKET NON DISPONIBILE. Verifica la migrazione 012_daily_shop.sql."
	if response.size() == 4 and response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200:
		var data = JSON.parse_string(response[3].get_string_from_utf8())
		if data is Dictionary and data.get("items") is Array and _integer(data.get("refresh_after")) and int(data.refresh_after) > 0:
			var valid: bool = data.items.size() <= 6
			var unique: Array = []
			for id in data.items:
				if not id is String or unique.has(id): valid = false
				unique.append(id)
			if valid:
				_daily_ids = unique
				daily_error = ""
				var seconds := clampi(int(data.refresh_after), 1, 86400)
				_daily_until = Time.get_ticks_msec() + seconds * 1000
				get_tree().create_timer(seconds).timeout.connect(refresh_daily)
	changed.emit()

## Il client invia solo ID e prezzo confermato. Saldo e proprieta' decide il server.
func purchase_item(item_id: String, expected_price: int) -> Dictionary:
	if purchasing or _account == null or not _account.is_authenticated():
		return {"ok": false, "message": "Acquisto occupato o account offline."}
	var owner := _owner
	var generation := _generation
	purchasing = true
	changed.emit()
	var request := HTTPRequest.new()
	request.timeout = 20.0
	request.accept_gzip = not OS.has_feature("web")
	add_child(request)
	var error := request.request(_account.PROJECT_URL + "/rest/v1/rpc/bisca_purchase_item",
		_account.database_headers(), HTTPClient.METHOD_POST,
		JSON.stringify({"p_item_id": item_id, "p_expected_price": expected_price}))
	var response: Array = []
	if error == OK:
		response = await request.request_completed
	request.queue_free()
	purchasing = false
	changed.emit()
	if not _current(generation, owner):
		return {"ok": false, "message": "Account cambiato: controlla l'inventario dell'account precedente."}
	if response.is_empty() or response[0] != HTTPRequest.RESULT_SUCCESS:
		refresh()
		return {"ok": false, "message": "Risposta non ricevuta. Aggiorna l'inventario prima di riprovare: l'acquisto potrebbe essere riuscito."}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if response[1] < 200 or response[1] >= 300:
		var messages := {
			"INSUFFICIENT_CREDITS": "Monete insufficienti.",
			"PRICE_CHANGED": "Prezzo cambiato: aggiorna lo shop e riprova.",
			"ITEM_UNAVAILABLE": "Oggetto non disponibile.",
			"PROFILE_NOT_READY": "Profilo non pronto. Riconnetti l'account.",
			"ITEM_NOT_FOUND": "Oggetto non trovato."
		}
		var code := str(data.get("message", "")) if data is Dictionary else ""
		var message: String = messages.get(code, "Acquisto non disponibile. Controlla che 004_shop_purchase.sql sia stato eseguito.")
		return {"ok": false, "message": message}
	if not data is Dictionary or str(data.get("user_id", "")) != owner or not str(data.get("credits", "")).is_valid_int():
		return {"ok": false, "message": "Risposta inattesa. Aggiorna l'inventario prima di riprovare."}
	var cloud := get_node("/root/AccountProfile")
	if str(cloud.profile.get("id", "")) == owner:
		cloud.profile.credits = int(data.credits)
		cloud.changed.emit()
	refresh()
	return {"ok": true, "message": "Gia' posseduto, nessun addebito." if data.get("already_owned", false) else "Acquisto completato!"}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if DisplayServer.get_name() == "headless" or "--server" in OS.get_cmdline_user_args():
		return
	_account = get_node("/root/AccountSession")
	_http = HTTPRequest.new()
	_http.accept_gzip = not OS.has_feature("web")
	_http.timeout = 15.0
	_http.body_size_limit = 2 * 1024 * 1024
	add_child(_http)
	_account.changed.connect(_account_changed)
	_account_changed()

func _account_changed() -> void:
	if str(_account.user_id) != _owner:
		_owner = str(_account.user_id)
		_generation += 1 # Anche A -> B -> A invalida la prima risposta di A.
		_inventory.clear()
		inventory_ready = false
		last_error = ""
		stale = false
		_queued = loading
		changed.emit() # La UI elimina immediatamente il vecchio inventario.
	if not _account.is_authenticated():
		stale = inventory_ready
		changed.emit()
		return
	# Rinnovo JWT o conversione guest: stesso UID, stessi oggetti.
	if not inventory_ready or stale:
		refresh()
	else:
		changed.emit()

## Ricaricamento esplicito per la UI; nessun polling o richiesta per frame.
func refresh() -> void:
	if _account == null:
		return
	if str(_account.user_id) != _owner:
		_account_changed()
		return
	if not _account.is_authenticated() or _owner.is_empty():
		last_error = "Account offline. Riconnetti dai Settings."
		stale = inventory_ready
		changed.emit()
		return
	if loading:
		_queued = true
		return
	loading = true
	_queued = false
	last_error = ""
	changed.emit()
	var generation := _generation
	var owner := _owner
	var result := await _read_all("bisca_items?select=id,name,item_type,price,rarity,is_available,is_default,asset_id&order=id", generation, owner)
	if not _current(generation, owner):
		_finish_obsolete()
		return
	if not result.ok:
		_fail(result.error)
		return
	var parsed := _parse_catalog(result.rows)
	if not parsed.ok:
		_fail(parsed.error)
		return
	var new_catalog: Dictionary = parsed.value
	result = await _read_all("bisca_inventory?select=user_id,item_id,item_type&user_id=eq." + owner.uri_encode() + "&order=item_id", generation, owner)
	if not _current(generation, owner):
		_finish_obsolete()
		return
	if not result.ok:
		_fail(result.error)
		return
	parsed = _parse_inventory(result.rows, owner)
	if not parsed.ok:
		_fail(parsed.error)
		return
	# Pubblica uno snapshot completo; mai un inventario a meta' paginazione.
	_catalog = new_catalog
	_inventory = parsed.value
	catalog_ready = true
	inventory_ready = true
	stale = not _account.is_authenticated()
	loading = false
	if not _inventory.has(DEFAULT_ITEM):
		last_error = "Dorso default assente nel database: esegui la migrazione Shop."
	catalog_loaded.emit()
	inventory_loaded.emit()
	changed.emit()
	refresh_daily()
	_restart_queued()

func _current(generation: int, owner: String) -> bool:
	return generation == _generation and owner == _owner and owner == str(_account.user_id)

func _finish_obsolete() -> void:
	loading = false
	_queued = true
	changed.emit()
	_restart_queued()

func _restart_queued() -> void:
	if _queued and _account.is_authenticated():
		_queued = false
		refresh.call_deferred()

func _fail(message: String) -> void:
	loading = false
	last_error = message
	stale = inventory_ready
	changed.emit()
	_restart_queued()

func _read_all(path: String, generation: int, owner: String) -> Dictionary:
	var rows: Array = []
	for page in range(MAX_PAGES):
		if not _current(generation, owner):
			return {"ok": false, "error": "Account cambiato."}
		var result := await _get_page(path + "&limit=%d&offset=%d" % [PAGE_SIZE, rows.size()])
		if not _current(generation, owner):
			return {"ok": false, "error": "Account cambiato."}
		if not result.ok:
			return result
		if not result.get("rows") is Array:
			return {"ok": false, "error": "Risposta Shop non valida."}
		if result.rows.is_empty():
			return {"ok": true, "rows": rows}
		rows.append_array(result.rows)
		# Prosegue anche su pagine corte: Supabase puo' imporre un limite piu' basso.
	return {"ok": false, "error": "Catalogo/inventario oltre il limite di sicurezza; nessun dato parziale applicato."}

## Unico punto HTTP: solo GET, header presi sempre dalla sessione attuale.
func _get_page(path: String) -> Dictionary:
	var error := _http.request(_account.PROJECT_URL + "/rest/v1/" + path,
		_account.database_headers(), HTTPClient.METHOD_GET)
	if error != OK:
		return {"ok": false, "error": "Impossibile avviare la lettura Shop."}
	var response: Array = await _http.request_completed
	if response[0] != HTTPRequest.RESULT_SUCCESS or response[1] < 200 or response[1] >= 300:
		return {"ok": false, "error": "Shop non disponibile (HTTP %d, trasporto %d)." % [response[1], response[0]]}
	var data = JSON.parse_string(response[3].get_string_from_utf8())
	if not data is Array:
		return {"ok": false, "error": "Risposta Shop non valida: atteso un array JSON."}
	return {"ok": true, "rows": data}

func _parse_catalog(rows: Array) -> Dictionary:
	var value: Dictionary = {}
	for row in rows:
		if not row is Dictionary:
			return {"ok": false, "error": "Oggetto catalogo non valido."}
		for key in ["id", "name", "item_type", "rarity"]:
			if not row.get(key) is String or str(row[key]).is_empty():
				return {"ok": false, "error": "Catalogo: campo %s mancante o non valido." % key}
		for key in ["price", "asset_id"]:
			if not _integer(row.get(key)) or float(row[key]) < 0:
				return {"ok": false, "error": "Catalogo: numero %s non valido." % key}
		if not row.get("is_available") is bool or not row.get("is_default") is bool or value.has(row.id):
			return {"ok": false, "error": "Catalogo: flag non validi o ID duplicato."}
		value[row.id] = row.duplicate(true)
		value[row.id].price = int(row.price)
		value[row.id].asset_id = int(row.asset_id)
	if not value.has(DEFAULT_ITEM) or value[DEFAULT_ITEM].price != 0 or not value[DEFAULT_ITEM].is_default or value[DEFAULT_ITEM].asset_id != 1:
		return {"ok": false, "error": "Configura deck_back_1 come default gratuito, asset_id 1, nel database."}
	return {"ok": true, "value": value}

func _integer(value: Variant) -> bool:
	# JSON numerico: rifiuta interi fuori dalla precisione sicura, anziche' arrotondare prezzi.
	return (value is int or value is float) and is_finite(float(value)) and absf(float(value)) <= 9007199254740991.0 and float(value) == floor(float(value))

func _parse_inventory(rows: Array, owner: String) -> Dictionary:
	var value: Dictionary = {}
	for row in rows:
		if not row is Dictionary or row.get("user_id") != owner or not row.get("item_id") is String or str(row.item_id).is_empty() or not row.get("item_type") is String:
			return {"ok": false, "error": "Inventario non valido o appartenente a un altro account."}
		value[row.item_id] = row.duplicate(true)
	return {"ok": true, "value": value}

## Le API restituiscono copie: la UI non modifica le cache per riferimento.
func get_items() -> Array:
	var items: Array = _catalog.values().duplicate(true)
	items.sort_custom(func(a: Dictionary, b: Dictionary):
		if a.item_type != b.item_type: return str(a.item_type) < str(b.item_type)
		if a.asset_id != b.asset_id: return a.asset_id < b.asset_id
		return str(a.id) < str(b.id))
	return items

func get_items_by_type(type: String) -> Array:
	return get_items().filter(func(item: Dictionary): return item.item_type == type)

func get_item(item_id: String) -> Dictionary:
	return _catalog.get(item_id, {}).duplicate(true)

func owns_item(item_id: String) -> bool:
	return _account != null and _owner == str(_account.user_id) and inventory_ready and _inventory.has(item_id)

func get_owned_items() -> Array:
	return get_items().filter(func(item: Dictionary): return owns_item(item.id))

func get_owned_items_by_type(type: String) -> Array:
	return get_owned_items().filter(func(item: Dictionary): return item.item_type == type)

func get_inventory() -> Dictionary:
	return _inventory.duplicate(true) if _account != null and _owner == str(_account.user_id) and inventory_ready else {}
