extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var Rules = load("res://scenes/balatro/scripts/match_rules.gd")
	for cards in range(1, 6):
		var rules = Rules.new()
		rules.configure({"lives": 7, "starting_cards": cards})
		assert(rules.start(8, 123))
		for player in rules.players:
			assert(player.lives == 7 and player.hand.size() == cards)
		for round_index in range(cards * 2):
			assert(rules.hand_size == cards - (round_index % cards))
			rules.phase = "round_complete"
			assert(rules.begin_round())
	var controller = load("res://scenes/balatro/scripts/match_controller.gd").new()
	controller.turn_clock = Label.new()
	controller.add_child(controller.turn_clock)
	controller.game_ui = Control.new()
	controller.add_child(controller.game_ui)
	controller.busy = false
	controller.rules.start(8, 123)
	controller.rules.current = 0
	var before: Dictionary = controller.rules.view_for(0).duplicate(true)
	controller._process(120.0)
	assert(controller.rules.view_for(0) == before)
	assert(not controller.turn_clock.visible)
	controller.online = true
	controller.turn_clock.show()
	controller._process(120.0)
	assert(controller.turn_clock.visible)
	controller.free()
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	menu.show_setup()
	assert(menu.match_options.values().lives == 3)
	assert(menu.match_options.values().starting_cards == 5)
	assert(menu.bot_slider.min_value == 1 and menu.bot_slider.max_value == 7)
	assert(menu.bot_slider.value == 7)
	menu.match_options.lives.value = 9
	menu.match_options.rounds.value = 2
	menu.bot_slider.value = 1
	menu.show_home()
	menu.show_setup()
	assert(menu.match_options.values() == {"lives": 3, "starting_cards": 5, "bots": true, "bot_count": 7})
	var lobby = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	root.add_child(lobby)
	lobby.setup(menu)
	assert(not lobby.match_options.values().bots)
	assert(lobby.match_options.values().bot_count == 2)
	lobby.match_options.fill_bots.button_pressed = true
	assert(lobby.match_options.bot_count.get_parent().visible)
	lobby.match_options.bot_count.value = 4
	assert(lobby.match_options.values().bot_count == 4)
	assert(lobby.match_options.values().turn_seconds == 30)
	for index in 4:
		lobby.match_options.turn_timer.value = index
		assert(lobby.match_options.values().turn_seconds == [15, 30, 60, 0][index])
	lobby.match_options.update_bot_limit(1, true)
	assert(lobby.match_options.bot_count.max_value == 1 and lobby.match_options.bot_count.value == 1)
	lobby.match_options.update_bot_limit(0, true)
	assert(lobby.match_options.bot_count.value == 0 and not lobby.match_options.bot_count.editable)
	assert(lobby.match_options.fill_bots.disabled)
	lobby.match_options.reset_multiplayer()
	assert(lobby.match_options.values().turn_seconds == 30 and not lobby.match_options.values().bots)
	lobby.is_host = false
	lobby._sync_options({"people": [{}, {}, {}, {}, {}, {}, {}], "bots": true, "bot_count": 7, "options": {"lives": 4, "starting_cards": 2, "turn_seconds": 0}})
	assert(lobby.lobby_options.bot_count.value == 1)
	assert(not lobby.lobby_options.bot_count.editable and not lobby.lobby_options.lives.editable)
	assert(not lobby.lobby_options.turn_timer.editable)
	assert(lobby.lobby_options.values().turn_seconds == 0)
	for _i in range(5):
		await process_frame
	assert(menu.setup_page.get_combined_minimum_size().y < 500)
	var hand = load("res://scenes/balatro/scripts/hand.gd").new()
	for i in range(5):
		var card := Control.new()
		card.size = Vector2(115, 174)
		hand.cards.append(card)
		assert(hand._slot_position(i).y == 0 and hand._slot_rotation(i) == 0)
	for card in hand.cards:
		card.free()
	hand.free()
	lobby.address.free()
	print("PASS: round cycles 1..5, initial lives, menu defaults, bot toggle/count, straight hand")
	quit()
