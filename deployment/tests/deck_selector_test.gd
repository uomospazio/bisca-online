extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var settings = root.get_node("GameSettings")
	settings.save_path = "/private/tmp/bisca-deck-test.cfg"
	settings.values.deck_back = 1
	var selector = load("res://scenes/balatro/scripts/deck_selector.gd").new()
	root.add_child(selector)
	assert(selector.selected == 1)
	for button in [selector.edit_button, selector.editing_controls[0], selector.editing_controls[1]]:
		assert(button.expand_icon)
		assert(button.get_theme_constant("icon_max_width") == 28)
		assert(button.size == Vector2(64, 64))
	selector._edit(true)
	selector._cycle(-1)
	assert(selector.selected == 12 and settings.values.deck_back == 1)
	selector._confirm()
	assert(settings.values.deck_back == 12 and selector.edit_button.visible)
	for control in selector.editing_controls:
		assert(not control.visible)
	settings.load_preferences()
	assert(settings.values.deck_back == 12)
	selector._cycle(1)
	assert(selector.selected == 1)
	for i in range(1, 13):
		assert(settings.back_texture(i) != null)
	var menu = load("res://scenes/balatro/scripts/main_menu.gd").new()
	root.add_child(menu)
	assert(menu.deck_selector.visible)
	assert(menu.name_input.get_parent() == menu.home_page)
	assert(menu.name_input.get_theme_color("font_placeholder_color") == menu.BUTTON_PURPLE)
	assert(menu.profile_button.get_node("CameraIcon").visible)
	var camera = menu.profile_button.get_node("CameraIcon")
	assert(camera.size == Vector2(96, 96))
	assert(camera.position + camera.size / 2 == menu.profile_button.size / 2)
	assert(menu.name_input.position.y < menu.profile_button.position.y + menu.profile_button.size.y)
	assert(menu.name_input.position.y > menu.profile_button.position.y + menu.profile_button.size.y / 2)
	menu.name_input.text = "Test"
	assert(menu.chosen_name() == "TEST")
	menu.show_setup()
	assert(not menu.deck_selector.visible)
	menu._show_network()
	assert(menu.name_input.get_parent() == menu.home_page)
	assert(menu.network_page.profile_picker == menu.profile_picker)
	var lobby = menu.network_page
	lobby.profile_room = "TEST12"
	var people: Array = []
	for i in range(8):
		people.append({"name": "PLAYER%d" % i, "connected": true, "bot": false, "voice_id": "voice%d" % i})
	var state := {"stage": "lobby", "code": "TEST12", "you": 1, "people": people, "options": {"lives": 6, "starting_cards": 4}, "bots": true, "bot_count": 3}
	lobby._update(state)
	assert(lobby.players_box.get_child_count() == 8)
	for row in lobby.players_box.get_children():
		assert(row.get_theme_stylebox("panel").bg_color == menu.BUTTON_PURPLE)
		for item in row.get_child(0).get_children():
			assert(not item is HSlider)
	var voice = root.get_node("VoiceChat")
	var self_speaker = lobby.players_box.get_child(1).get_meta("voice_button")
	assert(self_speaker.pressed.is_connected(voice.toggle_audio))
	voice.enabled = false
	lobby._update_voice_buttons()
	assert(self_speaker.icon.resource_path.ends_with("volume-cross.svg"))
	voice.enabled = true
	voice.changed.emit()
	assert(self_speaker.icon.resource_path.ends_with("volume-high.svg"))
	voice.enabled = false
	assert(lobby.lobby_options.lives.value == 6)
	assert(not lobby.lobby_options.lives.editable)
	assert(lobby.lobby_options.fill_bots.disabled)
	assert(lobby.start_button.disabled)
	state.you = 0
	lobby._update(state)
	assert(lobby.lobby_options.lives.editable and not lobby.start_button.disabled)
	assert(lobby.players_box.get_child_count() == 8)
	print("PASS: 12 backs, wraparound, confirmation, persistence and home-only selector")
	state.people = people.slice(0, 1)
	lobby._update(state)
	assert(lobby.players_box.get_child_count() == 8)
	for index in range(1, 8):
		var empty_row = lobby.players_box.get_child(index)
		assert(empty_row.get_child(0).text == "EMPTY")
		assert(empty_row.get_theme_stylebox("panel").bg_color == menu.LexispellStyle.DISABLED)
		assert(empty_row.get_child(0).get_theme_color("font_color") == menu.LexispellStyle.DISABLED_TEXT)
		assert(empty_row.get_child(0).horizontal_alignment == HORIZONTAL_ALIGNMENT_CENTER)
		assert(not empty_row.has_meta("voice_button"))
	state.people = people.slice(0, 2)
	lobby._update(state)
	assert(lobby.players_box.get_child_count() == 8)
	var joined_name = lobby.players_box.get_child(1).get_child(0).get_child(1)
	assert(joined_name.text == "PLAYER1")
	assert(joined_name.alignment == HORIZONTAL_ALIGNMENT_LEFT)
	assert(lobby.players_box.get_child(2).get_child(0).text == "EMPTY")
	print("PASS: eight lobby slots, centered empty slots and left-aligned joining player")
	var stepper = load("res://scenes/balatro/scripts/option_stepper.gd").new()
	root.add_child(stepper)
	stepper.min_value = 1
	stepper.max_value = 5
	stepper.value = 3
	stepper.setup(menu.KIDS_FONT)
	stepper.next_button.pressed.emit()
	assert(stepper.value == 4 and stepper.caption.text == "4")
	stepper.previous.pressed.emit()
	assert(stepper.value == 3)
	stepper.value = 5
	assert(stepper.next_button.disabled)
	stepper.value = 1
	assert(stepper.previous.disabled)
	stepper.editable = false
	assert(stepper.previous.disabled and stepper.next_button.disabled)
	stepper.next_button.pressed.emit()
	assert(stepper.value == 1)
	stepper.queue_free()
	var hand = load("res://scenes/balatro/scripts/hand.gd").new()
	hand.size = Vector2(1046, 210)
	root.add_child(hand)
	hand.scale = Vector2.ONE * 1.7
	assert(is_equal_approx(hand.pivot_offset.x, hand.size.x / 2.0))
	var visual_center: Vector2 = hand.get_transform() * (hand.size / 2.0)
	assert(is_equal_approx(visual_center.x, hand.position.x + hand.size.x / 2.0))
	hand.queue_free()
	print("PASS: arrow selectors, limits, read-only mode and scaled hand centering")
	quit()
