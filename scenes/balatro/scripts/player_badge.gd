@tool
extends Control

signal life_animation_finished

const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const COUNTER_FONT = KIDS_FONT
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")
const HEART_TEXTURE = preload("res://scenes/balatro/trick_asset/mazzo_2/briscola/cuore.png")
const NAME_TEXT_COLOR := Color("fff0cc")
const NAME_OUTLINE_COLOR := Color("347667")
const NAME_SHADOW_COLOR := Color("214f50")

# Posizione nel riquadro del giocatore e scala di cuore e numero.
const HEART_POSITION := Vector2(39, 89)
const HEART_SIZE := 1.5

var heart_scale := Vector2.ONE:
	set(value):
		heart_scale = value
		queue_redraw()
var heart_rotation := 0.1:
	set(value):
		heart_rotation = value
		queue_redraw()

func animate_heart() -> Tween:
	var tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	# Stesso pop/rotazione dei pulsanti Lexispell durante l'interazione.
	tween.tween_property(self, "heart_scale:x", 1.2, 0.2)
	tween.tween_property(self, "heart_scale:y", 1.2, 0.35)
	tween.tween_property(self, "heart_rotation", deg_to_rad(5.0 * [-1, 1].pick_random()), 0.1)
	tween.tween_property(self, "heart_rotation", 0.0, 0.1).set_delay(0.1)
	tween.chain().tween_property(self, "heart_scale:x", 1.0, 0.25)
	tween.parallel().tween_property(self, "heart_scale:y", 1.0, 0.35)
	return tween

var life_animating := false
var defer_elimination_tint := false

func _update_elimination_tint() -> void:
	modulate = Color(0.45, 0.45, 0.45, 0.65) if eliminated and not defer_elimination_tint else Color.WHITE

func finish_damage_return() -> void:
	defer_elimination_tint = false
	_update_elimination_tint()
	queue_redraw()

func animate_life_change(previous: int, damage: int, final_lives: int, dim_after_return: bool = false) -> void:
	life_animating = true
	defer_elimination_tint = dim_after_return
	lives = previous
	eliminated = previous <= 0
	_update_elimination_tint()
	queue_redraw()
	if damage > 0:
		var bounce := animate_heart()
		# Il contatore cambia quando il cuore è già nel suo pop, non all'inizio.
		await get_tree().create_timer(0.2, false).timeout
		lives = final_lives
		GameAudio.play(self, GameAudio.LIFE)
		eliminated = final_lives <= 0
		_update_elimination_tint()
		queue_redraw()
		await bounce.finished
	# A simultaneous-elimination tie can restore one life after reaching zero.
	if lives != final_lives:
		await get_tree().create_timer(0.5, false).timeout
		lives = final_lives
		eliminated = final_lives <= 0
		_update_elimination_tint()
	queue_redraw()
	life_animating = false
	life_animation_finished.emit()

# Drawn separately from the player data so a profile texture can be added later.
var player_name := "ANDREA"
var lives := 3
var prediction := -1
var taken := 0
var show_taken := false
var highlighted := false
var eliminated := false
var profile_texture: Texture2D
var font: Font = KIDS_FONT
var configured := false
var counter_tween: Tween
var name_idle_time := 0.0
var counter_scale := Vector2.ONE:
	set(value):
		counter_scale = value
		queue_redraw()
var counter_rotation := 0.0:
	set(value):
		counter_rotation = value
		queue_redraw()

func animate_counter() -> void:
	GameAudio.play(self, GameAudio.COUNTER, -14.0)
	if counter_tween and counter_tween.is_valid():
		counter_tween.kill()
	counter_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	counter_tween.set_parallel(true)
	counter_tween.tween_property(self, "counter_scale:x", 1.2, 0.2)
	counter_tween.tween_property(self, "counter_scale:y", 1.2, 0.35)
	counter_tween.tween_property(self, "counter_rotation", deg_to_rad(5.0 * [-1, 1].pick_random()), 0.1)
	counter_tween.tween_property(self, "counter_rotation", 0.0, 0.1).set_delay(0.1)
	counter_tween.chain().tween_property(self, "counter_scale:x", 1.0, 0.25)
	counter_tween.parallel().tween_property(self, "counter_scale:y", 1.0, 0.35)

func _init() -> void:
	custom_minimum_size = Vector2(160, 224)
	mouse_filter = Control.MOUSE_FILTER_PASS
	set_process(true)

func _process(delta: float) -> void:
	name_idle_time += delta
	queue_redraw()

func configure(display_name: String, remaining_lives: int, bid: int, tricks: int, current: bool, out: bool, display_tricks: bool = false) -> void:
	var counter_changed := configured and ((bid >= 0 and bid != prediction) or tricks > taken)
	player_name = display_name.to_upper()
	if not life_animating:
		lives = remaining_lives
	prediction = bid
	taken = tricks
	show_taken = display_tricks
	highlighted = current and not out
	if not life_animating:
		eliminated = out
	_update_elimination_tint()
	configured = true
	if counter_changed:
		animate_counter()
	tooltip_text = "%s · %d vite · %s previste · %d fatte" % [display_name, lives, "" if bid < 0 else str(bid), taken]
	queue_redraw()

func _text(center: Vector2, value: String, font_size: int, color: Color = Color.BLACK, custom_font: Font = null, outlined: bool = true) -> void:
	var draw_font: Font = custom_font if custom_font else font
	var width := draw_font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var position_value := Vector2(center.x - width / 2.0, center.y + font_size * 0.33)
	if custom_font:
		position_value.y = center.y + (draw_font.get_ascent(font_size) - draw_font.get_descent(font_size)) / 2.0
	if outlined:
		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("fff0cc"))
		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 1, color)
	draw_string(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

func _draw() -> void:
	if highlighted:
		# Glowing frame behind the avatar, leaving the name outside the panel.
		var frame := StyleBoxFlat.new()
		frame.bg_color = Color(0.964706, 0.784314, 0.372549, 0.48)
		frame.border_color = Color("fff0cc00")
		frame.set_border_width_all(5)
		frame.set_corner_radius_all(68)
		frame.shadow_color = Color(0.964706, 0.784314, 0.372549, 0.827)
		frame.shadow_size = 5
		frame.shadow_offset = Vector2.ZERO
		draw_style_box(frame, Rect2(12, 60, 136, 136))
	var avatar := Vector2(80, 128)
	draw_circle(avatar, 59, Color.BLACK, true, -1, true)
	draw_circle(avatar, 56, Color("e5e8d8"), true, -1, true)
	if profile_texture:
		draw_texture_rect(profile_texture, Rect2(avatar - Vector2(56, 56), Vector2(112, 112)), false)
	var heart_transform := Transform2D(heart_rotation, heart_scale * HEART_SIZE, 0.0, HEART_POSITION)
	draw_set_transform_matrix(heart_transform)
	# Keep the image proportions; its bottom-right padding contains the shadow.
	var texture_size := HEART_TEXTURE.get_size()
	var image_scale := 44.0 / texture_size.x
	var image_size := texture_size * image_scale
	var heart_center := Vector2(-2, 0)
	draw_texture_rect(HEART_TEXTURE, Rect2(-image_size / 2.0, image_size), false)
	var number_text := str(lives)
	var number_size := 20
	var number_width := COUNTER_FONT.get_string_size(number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size).x
	var baseline := heart_center + Vector2(-number_width / 2.0, (COUNTER_FONT.get_ascent(number_size) - COUNTER_FONT.get_descent(number_size)) / 2.0)
	draw_string(COUNTER_FONT, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("fff0cc"))
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var prediction_box := StyleBoxFlat.new()
	prediction_box.bg_color = Color("214f50")
	prediction_box.set_corner_radius_all(10)
	var prediction_shadow := StyleBoxFlat.new()
	prediction_shadow.bg_color = Color("153536")
	prediction_shadow.set_corner_radius_all(10)
	var counter_center := Vector2(125, 169)
	var counter_transform := Transform2D(counter_rotation, counter_scale, 0.0, Vector2.ZERO)
	draw_set_transform_matrix(Transform2D(0.0, counter_center) * counter_transform * Transform2D(0.0, -counter_center))
	draw_style_box(prediction_shadow, Rect2(94, 151, 68, 42))
	draw_style_box(prediction_box, Rect2(91, 148, 68, 42))
	if prediction >= 0:
		_text(Vector2(125, 169), "/", 16, Color("fff0cc"), COUNTER_FONT, false)
		_text(Vector2(143, 169), str(prediction), 24, Color("fff0cc"), KIDS_FONT, false)
		if show_taken or taken > 0:
			_text(Vector2(107, 169), str(taken), 24, Color("fff0cc"), KIDS_FONT, false)
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var name_size := 27
	while font.get_string_size(player_name, HORIZONTAL_ALIGNMENT_LEFT, -1, name_size).x > 152 and name_size > 14:
		name_size -= 1
	_draw_idle_name(player_name, name_size)

func _draw_idle_name(value: String, font_size: int) -> void:
	var total_width := font.get_string_size(value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var cursor_x := 80.0 - total_width / 2.0
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	for index in value.length():
		var character := value.substr(index, 1)
		var character_width := font.get_string_size(character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var phase := name_idle_time * 4.0 + float(index) * 0.55
		var bob := sin(phase) * 2.5
		var tilt := deg_to_rad(sin(phase + 0.7) * 1.4)
		var center := Vector2(cursor_x + character_width / 2.0, 38.0 + bob)
		var baseline := Vector2(-character_width / 2.0, (ascent - descent) / 2.0)
		draw_set_transform(center, tilt, Vector2.ONE)
		draw_string_outline(font, baseline + Vector2(2.0, 4.0), character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, NAME_SHADOW_COLOR)
		draw_string_outline(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 10, NAME_OUTLINE_COLOR)
		draw_string(font, baseline, character, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, NAME_TEXT_COLOR)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		cursor_x += character_width
