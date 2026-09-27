extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var card = load("res://scenes/balatro/card.tscn").instantiate()
	root.add_child(card)
	assert(not card.is_processing(), "Una carta ferma non richiede _process")
	card.following_mouse = true
	assert(card.is_processing() and card.shadow.visible)
	card.following_mouse = false
	assert(not card.is_processing() and not card.shadow.visible)
	var badge = load("res://scenes/balatro/scripts/player_badge.gd").new()
	root.add_child(badge)
	for display_name in ["LUCA", "NOME MOLTO LUNGO", "", "SOFIA"]:
		badge.player_name = display_name
		badge._update_name_metrics()
		var expected_size := 27
		while badge.font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, expected_size).x > 152 and expected_size > 14:
			expected_size -= 1
		assert(badge.cached_name_size == expected_size)
		assert(badge.cached_character_widths.size() == display_name.length())
		assert(is_equal_approx(badge.cached_name_width, badge.font.get_string_size(display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, expected_size).x))
		var widths: PackedFloat32Array = badge.cached_character_widths.duplicate()
		badge._update_name_metrics()
		assert(widths == badge.cached_character_widths)
	card.queue_free()
	badge.queue_free()
	await process_frame
	print("PASS: idle cards, drag shadow, cached name metrics preserve layout")
	quit()
