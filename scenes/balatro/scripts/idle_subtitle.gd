extends Label

const Badge = preload("res://scenes/balatro/scripts/player_badge.gd")
var idle_time := 0.0
var animated := false

func set_animated(value: bool) -> void:
	animated = value
	add_theme_color_override("font_color", Color.TRANSPARENT if animated else Badge.NAME_TEXT_COLOR)
	set_process(animated)
	queue_redraw()

func _process(delta: float) -> void:
	if is_visible_in_tree():
		idle_time += delta
		queue_redraw()

func _draw() -> void:
	if not animated:
		return
	var font := get_theme_font("font")
	var font_size := get_theme_font_size("font_size")
	var width := 0.0
	for character in text:
		width += font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cursor_x := (size.x - width) / 2.0
	var baseline_y := font.get_ascent(font_size)
	for index in text.length():
		var character := text.substr(index, 1)
		var character_width := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var phase := idle_time * 4.0 + float(index) * 0.55
		var center := Vector2(cursor_x + character_width / 2.0, baseline_y + sin(phase) * 2.5)
		var baseline := Vector2(-character_width / 2.0, 0)
		draw_set_transform(center, deg_to_rad(sin(phase + 0.7) * 1.4))
		draw_string_outline(font, baseline + Vector2(2, 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Badge.NAME_SHADOW_COLOR)
		draw_string_outline(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Badge.NAME_OUTLINE_COLOR)
		draw_string(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Badge.NAME_TEXT_COLOR)
		draw_set_transform(Vector2.ZERO)
		cursor_x += character_width
