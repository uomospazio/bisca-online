extends SceneTree

class Account extends Node:
	signal changed
	var user_id := "A"
	var authenticated := true
	func is_authenticated() -> bool: return authenticated

class Shop extends "res://scenes/balatro/scripts/shop_manager.gd":
	signal release
	var replies: Array = []
	var requests: Array = []
	var hold_next := false
	func _get_page(path: String) -> Dictionary:
		requests.append(path)
		var result: Dictionary = replies.pop_front()
		if hold_next:
			hold_next = false
			await release
		return result

var shop: Shop
var account: Account

func _initialize() -> void:
	call_deferred("run")

func item(id: String, asset: int, available := true) -> Dictionary:
	return {"id": id, "name": id, "item_type": "deck_back", "price": 0 if asset == 1 else 100,
		"rarity": "common", "is_available": available, "is_default": asset == 1, "asset_id": asset}

func inv(owner: String, id: String) -> Dictionary:
	return {"user_id": owner, "item_id": id, "item_type": "deck_back"}

func response(rows: Array) -> Dictionary:
	return {"ok": true, "rows": rows}

func snapshot(owner: String, extra := "") -> Array:
	var owned := [inv(owner, "deck_back_1")]
	if not extra.is_empty(): owned.append(inv(owner, extra))
	return [response([item("deck_back_1", 1), item("deck_back_2", 2, false)]), response([]), response(owned), response([])]

func settle() -> void:
	for i in range(5): await process_frame
	assert(not shop.loading)

func run() -> void:
	var original_settings: Dictionary = root.get_node("GameSettings").values.duplicate(true)
	account = Account.new()
	root.add_child(account)
	shop = Shop.new()
	root.add_child(shop)
	shop._account = account
	account.changed.connect(shop._account_changed)
	assert(not shop.owns_item("deck_back_1")) # Non inventa il default offline.
	shop.replies = snapshot("A", "deck_back_2")
	shop._account_changed()
	await settle()
	assert(shop.catalog_ready and shop.inventory_ready)
	assert(shop.owns_item("deck_back_1") and shop.owns_item("deck_back_2"))
	assert(not shop.get_item("deck_back_2").is_available) # Possesso != disponibilita'.
	assert(shop.get_owned_items_by_type("deck_back").size() == 2)
	assert(shop.get_items_by_type("missing").is_empty())
	assert(shop.get_item("unknown").is_empty())
	var copy := shop.get_item("deck_back_2")
	copy.price = 0
	assert(shop.get_item("deck_back_2").price == 100)
	var inventory_copy := shop.get_inventory()
	inventory_copy.clear()
	assert(shop.owns_item("deck_back_2"))
	var count := shop.requests.size()
	account.changed.emit() # Refresh JWT / guest -> permanent, stesso UID.
	await settle()
	assert(shop.requests.size() == count)
	# Offline stesso account: snapshot esplicitamente obsoleto, nessuna richiesta.
	account.authenticated = false
	account.changed.emit()
	assert(shop.stale and shop.owns_item("deck_back_2"))
	account.user_id = "B"
	account.changed.emit()
	assert(not shop.inventory_ready and shop.get_inventory().is_empty())
	assert(not shop.owns_item("deck_back_2"))
	account.authenticated = true
	shop.replies = snapshot("B")
	account.changed.emit()
	await settle()
	assert(shop.owns_item("deck_back_1") and not shop.owns_item("deck_back_2"))
	# Risposta sospesa di B; cambio B -> A -> B. La generazione la invalida.
	shop.hold_next = true
	shop.replies = [response([item("deck_back_1", 1)])]
	shop.refresh()
	assert(shop.loading)
	account.user_id = "A"
	account.changed.emit()
	assert(shop.get_inventory().is_empty())
	account.user_id = "B"
	account.changed.emit()
	shop.replies = snapshot("B")
	shop.release.emit()
	await settle()
	assert(shop.inventory_ready and not shop.owns_item("deck_back_2"))
	# RLS difettosa / risposta sbagliata: non applicare righe di un altro utente.
	shop.replies = [response([item("deck_back_1", 1)]), response([]), response([inv("A", "deck_back_2")]), response([])]
	await shop.refresh()
	assert(shop.stale and not shop.last_error.is_empty())
	assert(not shop.owns_item("deck_back_2"))
	# Errore di rete conserva solo lo snapshot della stessa identita'.
	shop.replies = [{"ok": false, "error": "HTTP 503"}]
	await shop.refresh()
	assert(shop.last_error == "HTTP 503" and shop.stale)
	# Pagine corte: continua fino alla pagina vuota, non assume il limite server.
	shop.replies = [response([item("deck_back_1", 1)]), response([item("deck_back_2", 2)]), response([]), response([inv("B", "deck_back_1")]), response([])]
	await shop.refresh()
	assert(shop.get_items().size() == 2 and not shop.stale)
	assert(shop.requests[-4].contains("offset=1"))
	assert(not shop._parse_catalog([item("deck_back_2", 2)]).ok)
	assert(not shop._parse_catalog([{"id": "broken"}]).ok)
	assert(not shop._integer(1.5))
	assert(not shop._integer(INF))
	# Default mancante: avviso, non grant locale.
	shop.replies = [response([item("deck_back_1", 1)]), response([]), response([])]
	await shop.refresh()
	assert(not shop.owns_item("deck_back_1") and not shop.last_error.is_empty())
	assert(root.get_node("GameSettings").values == original_settings)
	shop.free()
	account.free()
	print("PASS Shop: API, copie, default DB, paginazione, offline, errori, guest, isolamento e race A-B-A")
	quit()
