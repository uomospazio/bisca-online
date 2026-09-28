extends SceneTree

class FakeAccount extends Node:
	var user_id := "test-user"
	func is_authenticated() -> bool: return true

class FakeSettings extends Node:
	var values := {"deck_back": 2, "deck_front": 0}
	func set_value(key: String, value: Variant) -> void: values[key] = value
	func save_preferences() -> void: pass

class FakeProfile extends "res://scenes/balatro/scripts/account_profile.gd":
	var replies: Array = []
	var calls: Array = []
	func _send(method: int, path: String, body: Dictionary = {}) -> Dictionary:
		calls.append([method, path, body.duplicate()])
		return replies.pop_front()
	func _save_queue() -> void: pass

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var syncer := FakeProfile.new()
	root.add_child(syncer)
	syncer._account = FakeAccount.new()
	syncer._settings = FakeSettings.new()
	syncer._timer = Timer.new()
	syncer.add_child(syncer._account)
	syncer.add_child(syncer._settings)
	syncer.add_child(syncer._timer)
	var remote := {"id": "test-user", "username": null, "deck_back": 8, "deck_front": 2}
	syncer.replies = [{"ok": true, "code": 200, "data": [remote]}]
	await syncer.sync()
	assert(syncer._settings.values.deck_back == 8)
	assert(syncer._settings.values.deck_front == 2)
	assert(syncer.calls.size() == 1) # Il caricamento non riscrive il cloud.
	syncer._loaded = false
	syncer._pending = true
	syncer._settings.values.deck_back = 4
	syncer.replies = [{"ok": true, "code": 200, "data": [remote]}, {"ok": true, "code": 204}]
	await syncer.sync()
	assert(syncer._settings.values.deck_back == 4) # Modifica offline conservata.
	assert(syncer.calls[-1][2] == {"deck_back": 4, "deck_front": 2})
	assert(not syncer._pending)
	syncer._pending = true
	syncer.replies = [{"ok": false, "code": 503}]
	await syncer.sync()
	assert(syncer._pending and not syncer.last_error.is_empty())
	syncer._owner = "old-user"
	syncer._account.user_id = "new-user"
	var other := {"id": "new-user", "username": null, "deck_back": 11, "deck_front": 1}
	syncer.replies = [{"ok": true, "code": 200, "data": [other]}]
	var count_before := syncer.calls.size()
	syncer._account_changed()
	assert(syncer._settings.values.deck_back == 11)
	assert(syncer.profile.id == "new-user")
	assert(syncer.calls.size() == count_before + 1) # Nessun PATCH dei dati del vecchio utente.
	assert(not syncer._pending)
	syncer.free()
	print("PASS: cloud load, pending preferences, retry after failure")
	quit()
