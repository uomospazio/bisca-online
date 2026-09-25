extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var settings = root.get_node("GameSettings")
	settings.save_path = "/private/tmp/bisca-front-selector-test.cfg"
	settings.values.deck_front = 0
	for front in range(2):
		for suit in range(4):
			for number in range(1, 11):
				assert(settings.front_texture(suit, number, front) != null)
	var selector = preload("res://scenes/balatro/scripts/deck_selector.gd").new()
	root.add_child(selector)
	selector._edit(true, false)
	selector._flip()
	await selector.flip_tween.finished
	assert(selector.showing_front and selector.flip_button.text == "BACK")
	selector._cycle(1)
	assert(selector.preview.texture == settings.front_texture(3, 5, 1))
	await selector._confirm()
	await selector.controls_tween.finished
	assert(not selector.showing_front and selector.edit_button.visible)
	settings.load_preferences()
	assert(settings.values.deck_front == 1)
	var card = preload("res://scenes/balatro/card.tscn").instantiate()
	root.add_child(card)
	var data = preload("res://scenes/balatro/scripts/card_data.gd").new()
	data.colour = 3
	data.number = 5
	card.set_card_data(data)
	assert(card.card_texture.texture == settings.front_texture(3, 5, 1))
	card.set_face_down(true)
	assert(card.card_texture.texture == settings.back_texture())
	selector._edit(true, false)
	selector._flip()
	selector.reset_preview()
	await create_timer(0.4).timeout
	assert(not selector.showing_front and selector.preview.scale == Vector2.ONE)
	print("PASS: 80 fronts, flip, selection, persistence, in-game textures and interrupted reset")
	quit()
