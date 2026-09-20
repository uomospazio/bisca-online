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
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	menu.show_setup()
	assert(menu.match_options.values().lives == 3)
	assert(menu.match_options.values().starting_cards == 5)
	assert(menu.bot_slider.min_value == 1 and menu.bot_slider.max_value == 7)
	var lobby = load("res://scenes/balatro/scripts/network_lobby.gd").new()
	root.add_child(lobby)
	lobby.setup(menu)
	assert(not lobby.match_options.values().bots)
	lobby.match_options.fill_bots.button_pressed = true
	assert(lobby.match_options.bot_count.get_parent().visible)
	lobby.match_options.bot_count.value = 4
	assert(lobby.match_options.values().bot_count == 4)
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
