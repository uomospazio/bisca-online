extends SceneTree

class Controller extends "res://scenes/balatro/scripts/match_controller.gd":
	var restarted_count := 0
	func _start_solo_offline(count: int) -> void:
		restarted_count = count
		rules.start(count, 123)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var controller := Controller.new()
	controller.menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(controller.menu)
	controller._restart_saved_match({
		"name":"TEST", "count":4, "joker":false,
		"options":{"lives":7,"starting_cards":1,"bot_count":3},
	})
	assert(controller.restarted_count == 4)
	assert(controller.rules.hand_size == 1)
	assert(controller.rules.initial_lives == 7)
	for player in controller.rules.players:
		assert(player.hand.size() == 1 and player.lives == 7)
	assert(controller.menu.match_options.values().starting_cards == 1)
	assert(controller.menu.match_options.values().bot_count == 3)
	controller.menu.free()
	controller.free()
	print("PASS: restarting preserves starting cards, lives and player count")
	quit()
