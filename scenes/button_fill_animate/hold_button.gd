class_name HoldButton
extends "res://scenes/balatro/scripts/rounded_square_button.gd"

# Adapted from Lexispell's RoundedSquareProgressBtn:
# Button -> rounded Progress Panel -> caption, with independent fill/confirm tweens.
signal hold_completed
signal confirmation_finished

const FILL_SHADER = preload("res://scenes/button_fill_animate/lexispell_fill.gdshader")
const HOLD_SOUND = preload("res://scenes/button_fill_animate/lexispell_hold.wav")
const CONFIRM_SOUND = preload("res://scenes/button_fill_animate/lexispell_confirm.wav")

@export var hold_duration := 0.75
@export var base_color := Color("474660")
@export var fill_color := Color("74ab8e")
@export var hover_color := Color("74ab8e")
@export var caption := ""
@export var font: Font
@export var font_size := 26
@export var corner_radius := 16
@export var confirm_progress_color := Color("74ab8e")
@export var hold_target_scale := Vector2(1.30, 1.30)
@export var confirm_target_scale := Vector2(1.4, 1.4)

var progress: Panel
var progress_material: ShaderMaterial
var long_press_sfx: AudioStreamPlayer
var confirm_sfx: AudioStreamPlayer
var hold_progress := 0.0
var hold_time := 0.0
var holding := false
var confirming := false
var locked := false
var reset_tween: Tween
var hold_scale_tween: Tween
var confirm_tween: Tween
var hint_label: Label
var hint_tween: Tween

func _ready() -> void:
	click_sound_enabled = false # The completed hold already plays its confirmation sound.
	scale_with_width = false
	super._ready()
	mouse_filter = Control.MOUSE_FILTER_STOP
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var state_color := hover_color if state in ["hover", "focus"] else base_color
		var border := 4 if state == "focus" else (2 if state in ["pressed", "hover_pressed"] else 0)
		var style := LexispellStyle.button_style(state_color, LexispellStyle.TEXT, border)
		style.set_corner_radius_all(corner_radius)
		add_theme_stylebox_override(state, style)
	progress = Panel.new()
	progress.name = "Progress"
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var silhouette := StyleBoxFlat.new()
	silhouette.bg_color = Color.WHITE
	silhouette.set_corner_radius_all(corner_radius)
	silhouette.corner_detail = 12
	silhouette.anti_aliasing_size = 0.285
	progress.add_theme_stylebox_override("panel", silhouette)
	progress_material = ShaderMaterial.new()
	progress_material.shader = FILL_SHADER
	progress_material.set_shader_parameter("fill_color", fill_color)
	progress.material = progress_material
	add_child(progress)
	progress.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	progress.hide()
	var label := Label.new()
	label.name = "Caption"
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", LexispellStyle.TEXT)
	if font:
		label.add_theme_font_override("font", font)
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	
	# "Tieni premuto" hint
	hint_label = Label.new()
	hint_label.name = "HoldHint"
	hint_label.text = "TIENI PREMUTO"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_label.add_theme_font_size_override("font_size", 18)
	hint_label.add_theme_color_override("font_color", LexispellStyle.TEXT)
	if font:
		hint_label.add_theme_font_override("font", font)

	add_child(hint_label)

	hint_label.anchor_left = 0.0
	hint_label.anchor_right = 1.0
	hint_label.anchor_top = 1.0
	hint_label.anchor_bottom = 1.0

	hint_label.offset_top = 8.0
	hint_label.offset_bottom = 40.0

	hint_label.modulate.a = 0.0
	
	long_press_sfx = AudioStreamPlayer.new()
	long_press_sfx.bus = "SFX"
	long_press_sfx.stream = HOLD_SOUND
	add_child(long_press_sfx)
	confirm_sfx = AudioStreamPlayer.new()
	confirm_sfx.bus = "SFX"
	confirm_sfx.stream = CONFIRM_SOUND
	add_child(confirm_sfx)
	button_down.connect(_start_hold)
	button_up.connect(_cancel_hold)
	mouse_exited.connect(_cancel_hold)
	focus_exited.connect(_cancel_hold)
	visibility_changed.connect(func():
		if not is_visible_in_tree():
			_cancel_hold()
	)
	set_process(false)

func _hover() -> void:
	if locked or confirming or holding:
		return
	super._hover()

func _unhover() -> void:
	if locked or confirming or holding:
		return
	super._unhover()

func _start_hold() -> void:
	if locked or confirming or disabled or holding:
		return
	if reset_tween and reset_tween.is_running():
		reset_tween.kill()
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	if hold_scale_tween and hold_scale_tween.is_running():
		hold_scale_tween.kill()
	holding = true
	hold_time = 0.0
	hold_progress = 0.0
	long_press_sfx.pitch_scale = 0.8
	progress_material.set_shader_parameter("fill_color", fill_color)
	progress_material.set_shader_parameter("progress", 0.0)
	progress.show()
	# Il passaggio dal hover al hold non deve far rimpicciolire il pulsante.
	var current_scale := maxf(scale.x, scale.y)
	var target_scale := maxf(hold_target_scale.x, current_scale)
	hold_scale_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hold_scale_tween.tween_property(self, "scale", Vector2.ONE * target_scale, 0.18)
	set_process(true)

func _process(delta: float) -> void:
	if not holding:
		return
	hold_time += delta
	hold_progress = clampf(hold_time / maxf(hold_duration, 0.01), 0.0, 1.0)
	progress_material.set_shader_parameter("progress", hold_progress)
	if hold_progress >= 1.0:
		holding = false
		set_process(false)
		_confirm_progress()
		hold_completed.emit()
		return
	if not long_press_sfx.playing or long_press_sfx.get_playback_position() >= long_press_sfx.stream.get_length() * 0.75:
		long_press_sfx.play()
		long_press_sfx.pitch_scale += 0.05

func _cancel_hold() -> void:
	if confirming or not holding:
		return
	var was_short_press := hold_time < 0.25
	holding = false
	set_process(false)
	long_press_sfx.stop()
	if reset_tween and reset_tween.is_running():
		reset_tween.kill()
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	if hold_scale_tween and hold_scale_tween.is_running():
		hold_scale_tween.kill()
	reset_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	reset_tween.tween_property(progress_material, "shader_parameter/progress", 0.0, 0.25)
	reset_tween.parallel().tween_property(self, "scale", Vector2.ONE * (1.2 if has_focus() else 1.0), 0.2)
	reset_tween.parallel().tween_property(self, "rotation", 0.0, 0.1)
	reset_tween.tween_callback(progress.hide)
	hold_progress = 0.0
	if was_short_press:
		_show_hold_hint()


func _show_hold_hint() -> void:
	if hint_tween and hint_tween.is_running():
		hint_tween.kill()

	hint_label.modulate.a = 1.0

	hint_tween = create_tween()

	hint_tween.tween_interval(2.0)

	hint_tween.tween_property(
		hint_label,
		"modulate:a",
		0.0,
		0.25
	)

func _confirm_progress() -> void:
	confirming = true
	long_press_sfx.stop()
	confirm_sfx.play()
	confirm_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	confirm_tween.tween_property(progress_material, "shader_parameter/fill_color", confirm_progress_color, 0.1)
	confirm_tween.tween_interval(0.2)
	confirm_tween.tween_property(progress_material, "shader_parameter/progress", 0.0, 0.01)
	confirm_tween.tween_callback(progress.hide)
	hover_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(self, "scale:x", confirm_target_scale.x, 0.15)
	hover_tween.parallel().tween_property(self, "scale:y", confirm_target_scale.y, 0.3)
	hover_tween.parallel().tween_property(self, "rotation_degrees", 5.0 * [-1.0, 1.0].pick_random(), 0.1)
	hover_tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.1).set_delay(0.1)
	hover_tween.tween_property(self, "scale", Vector2.ONE * 1.2, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	hover_tween.tween_callback(func():
		confirming = false
		confirmation_finished.emit()
	)

func lock_interaction() -> void:
	locked = true
	_cancel_hold()

func stop_visual_tweens() -> void:
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	if reset_tween and reset_tween.is_running():
		reset_tween.kill()
