extends SceneTree

class MatchProbe extends "res://scenes/balatro/scripts/match_controller.gd":
	func _ready() -> void: pass

func _initialize() -> void: run.call_deferred()

func run() -> void:
	root.size = Vector2i(1920, 1080)
	var host := MatchProbe.new()
	var parallax := Node.new()
	parallax.name = "Parallax"
	host.add_child(parallax)
	var hand := Node.new()
	hand.name = "Hand"
	parallax.add_child(hand)
	var hand_box := HBoxContainer.new()
	hand_box.name = "HBoxContainer"
	hand.add_child(hand_box)
	for node_name in ["PlayArea", "DeckPile"]:
		var placeholder := Control.new()
		placeholder.name = node_name
		parallax.add_child(placeholder)
	root.add_child(host)
	host.size = Vector2(1920, 1080)
	var table := TextureRect.new()
	table.texture = preload("res://scenes/balatro/trick_asset/table.png")
	table.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	table.size = host.size
	table.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(table)
	var heading := Label.new()
	heading.text = "QUANTE PRESE FAI?"
	heading.position = Vector2(320, 295)
	heading.size = Vector2(1280, 140)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_override("font", host.KIDS_FONT)
	heading.add_theme_font_size_override("font_size", 104)
	host.add_child(heading)
	host.actions = host._box(host, Vector2(160, 480), Vector2(1600, 108))
	var predictions: Array[Button] = []
	for bid in range(6):
		var button := host._button(str(bid), func(): pass, bid != 3)
		button.custom_minimum_size = host.PREDICTION_BUTTON_SIZE
		host._style_match_choice(button, 52)
		host._style_button_deferred(weakref(button))
		predictions.append(button)
	var row := HBoxContainer.new()
	row.position = Vector2(160, 720)
	row.size = Vector2(1600, 116)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 96)
	host.add_child(row)
	var completed := [0]
	var low := host._hold_button_in("LA PIU' BASSA", func(): completed[0] += 1, row)
	var high := host._hold_button_in("LA PIU' ALTA", func(): completed[0] += 1, row)
	await process_frame
	await process_frame
	for button in predictions:
		assert(button.has_meta("generic_ui_skin"))
		assert(not button.has_meta("cartoon_style"))
		assert(button.size.y >= 108 and button.get_theme_font_size("font_size") == 52)
		assert(button.position.x >= 0 and button.position.x + button.size.x <= host.actions.size.x)
	assert(predictions[3].disabled)
	for button in [low, high]:
		assert(button.has_meta("generic_ui_skin"))
		assert(button.size == host.JOKER_CHOICE_SIZE)
		assert(button.get_node("Caption").get_theme_font_size("font_size") == 36)
		assert(button.progress.offset_left > 0 and button.progress.offset_right < 0)
		var caption := button.get_node("Caption") as Label
		assert(caption.get_minimum_size().x < button.size.x)
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/private/tmp/bisca-match-choices.png")
	low._start_hold()
	low._process(0.1)
	low._cancel_hold()
	assert(completed[0] == 0 and not low.holding)
	high._start_hold()
	high._process(0.76)
	assert(completed[0] == 1 and high.confirming)
	await create_timer(0.8).timeout
	host.queue_free()
	await process_frame
	print("PASS: prediction/joker skin, larger layout, disabled bid and hold/cancel behavior")
	quit()
