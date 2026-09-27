extends Label

const Badge = preload("res://scenes/balatro/scripts/player_badge.gd")
var idle_time := 0.0
var animated := false
var cached_text := ""
var cached_font: Font
var cached_font_size := -1
var character_widths := PackedFloat32Array()
var text_width := 0.0

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
	# Le misure cambiano solo con testo/font, non con l'oscillazione delle lettere.
	if text != cached_text or font != cached_font or font_size != cached_font_size:
		cached_text = text
		cached_font = font
		cached_font_size = font_size
		text_width = 0.0
		character_widths.clear()
		for character in text:
			var measured := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			character_widths.append(measured)
			text_width += measured
	var cursor_x := (size.x - text_width) / 2.0
	var baseline_y := font.get_ascent(font_size)
	for index in text.length():
		var character := text.substr(index, 1)
		var character_width := character_widths[index]
		var phase := idle_time * 4.0 + float(index) * 0.55
		var center := Vector2(cursor_x + character_width / 2.0, baseline_y + sin(phase) * 2.5)
		var baseline := Vector2(-character_width / 2.0, 0)
		draw_set_transform(center, deg_to_rad(sin(phase + 0.7) * 1.4))
		draw_string_outline(font, baseline + Vector2(2, 4), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Badge.NAME_SHADOW_COLOR)
		draw_string_outline(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, Badge.NAME_OUTLINE_COLOR)
		draw_string(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Badge.NAME_TEXT_COLOR)
		draw_set_transform(Vector2.ZERO)
		cursor_x += character_width
