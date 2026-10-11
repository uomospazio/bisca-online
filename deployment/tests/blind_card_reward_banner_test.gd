extends SceneTree

class MatchHost extends Node:
	var online := true
	var online_match := {"state": {"singleplayer": false}}

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings := root.get_node("GameSettings")
	var previous: int = settings.values.deck_back
	settings.values.deck_back = 7 # In-memory only: do not modify saved preferences.
	var card = load("res://scenes/balatro/card.tscn").instantiate()
	card.set_face_down(true)
	root.add_child(card)
	assert(card.data == null)
	assert(card.card_texture.texture == settings.back_texture())
	settings.values.deck_back = 4
	card.set_face_down(true)
	assert(card.card_texture.texture == settings.back_texture())
	assert(card.tooltip_text.is_empty())
	settings.values.deck_back = previous
	card.queue_free()
	var host := MatchHost.new()
	root.add_child(host)
	current_scene = host
	var popup = load("res://scenes/balatro/scripts/match_reward_popup.gd").new()
	host.add_child(popup)
	var receipt := {"user_id": root.get_node("AccountSession").user_id, "match_id": "banner-test"}
	popup._show_elimination_offer(receipt)
	assert(host.get_child_count() == 2)
	var banner := host.get_child(1)
	var dialog := banner.get_child(0)
	var offer = dialog.body.get_child(1)
	assert(offer.placement == "multi" and offer.context == "banner-test")
	dialog.confirmed.emit()
	await process_frame
	await process_frame
	assert(host.get_child_count() == 1)
	host.online_match.state.singleplayer = true
	popup._show_elimination_offer(receipt)
	assert(host.get_child_count() == 1, "No multiplayer banner in singleplayer")
	host.queue_free()
	await process_frame
	print("PASS: blind card uses selected back before/after ready; multiplayer banner context, dismissal and solo exclusion")
	quit()
