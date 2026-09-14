class_name RoundedSquareButton
extends Button

# Adapted from Lexispell's RoundedSquareBtn for BISCA's procedural UI.
# Uses the same focus and disabled states as the Lexispell button scene.
const LexispellStyle = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const ButtonAudio = preload("res://scenes/balatro/scripts/button_audio.gd")
var click_sound_enabled := true
@export var hover_animate := true
@export var scale_with_width := true
@export var width_full_rotation := 128.0

var hover_tween: Tween
var silent := false

func _ready() -> void:
	add_theme_stylebox_override("focus", LexispellStyle.button_style(LexispellStyle.HOVER, LexispellStyle.TEXT, 4))
	add_theme_stylebox_override("disabled", LexispellStyle.button_style(LexispellStyle.DISABLED))
	add_theme_stylebox_override("hover_pressed", LexispellStyle.button_style(LexispellStyle.NORMAL, Color.TRANSPARENT, 2))
	add_theme_color_override("font_focus_color", LexispellStyle.TEXT)
	add_theme_color_override("font_hover_pressed_color", LexispellStyle.TEXT)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_resync_pivot()
	resized.connect(_resync_pivot)
	focus_entered.connect(_hover)
	focus_exited.connect(_unhover)
	mouse_entered.connect(_grab_focus)
	mouse_exited.connect(_release_focus)
	focus_entered.connect(func():
		if not disabled and not silent:
			ButtonAudio.play(self, ButtonAudio.HOVER, -4.0)
	)
	pressed.connect(func():
		if click_sound_enabled:
			ButtonAudio.play(self, ButtonAudio.CLICK)
	)

func grab_focus_silent() -> void:
	silent = true
	grab_focus()
	set_deferred("silent", false)

func _resync_pivot() -> void:
	pivot_offset = size / 2.0

func _grab_focus() -> void:
	if not disabled:
		grab_focus()

func _release_focus() -> void:
	if has_focus():
		release_focus()

func _hover() -> void:
	if disabled or not hover_animate:
		return
	_resync_pivot()
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	var ratio := clampf(width_full_rotation / maxf(size.x, 1.0), 0.5, 1.0)
	var target := 1.0 + 0.2 * ratio
	if not scale_with_width:
		ratio = 1.0
		target = 1.2
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	hover_tween.tween_property(self, "scale:x", target, 0.2)
	hover_tween.parallel().tween_property(self, "scale:y", target, 0.35)
	hover_tween.parallel().tween_property(self, "rotation_degrees", 5.0 * ratio * [-1.0, 1.0].pick_random(), 0.1)
	hover_tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.1).set_delay(0.1)

func _unhover() -> void:
	if disabled or not hover_animate:
		return
	_resync_pivot()
	if hover_tween and hover_tween.is_running():
		hover_tween.kill()
	hover_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	hover_tween.tween_property(self, "scale:x", 1.0, 0.25)
	hover_tween.parallel().tween_property(self, "scale:y", 1.0, 0.35)
	hover_tween.parallel().tween_property(self, "rotation_degrees", 0.0, 0.1)
