extends Control

const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const MixedLabel = preload("res://scenes/balatro/scripts/mixed_label.gd")
const ButtonShadow = preload("res://scenes/balatro/scripts/button_shadow.gd")
const RoundedSquareButton = preload("res://scenes/balatro/scripts/rounded_square_button.gd")
const LexispellStyle = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const BUTTON_PURPLE := LexispellStyle.NORMAL
const BUTTON_PURPLE_PRESSED := LexispellStyle.NORMAL
const BUTTON_CYAN := LexispellStyle.HOVER
const BUTTON_TEXT := LexispellStyle.TEXT

signal replay_requested
signal menu_requested
signal prediction_banner_cleared
signal prediction_question_started

var panel: PanelContainer
var overlay_shade: ColorRect
var banner_center: CenterContainer
var title: MixedLabel
var prediction_title: MixedLabel
var subtitle: MixedLabel
var buttons: HBoxContainer
var wide_prediction_banner := false
var panel_style: StyleBoxFlat

func _update_banner_width() -> void:
	panel.custom_minimum_size.x = size.x / 1.5 if wide_prediction_banner else 1280.0 / 1.5
	if is_instance_valid(prediction_title):
		prediction_title.custom_minimum_size.x = maxf(1.0, size.x - 96.0)

func _set_wide_prediction_banner(enabled: bool) -> void:
	wide_prediction_banner = enabled
	_update_banner_width()
	if enabled:
		panel.hide()
		prediction_title.show()
	else:
		prediction_title.hide()
		panel.show()

func _set_animated_title(value: String) -> void:
	var target: MixedLabel = prediction_title if wide_prediction_banner else title
	# Keep BBCode lowercase: MixedLabel uppercases the entire input, including tags.
	target.text = "[center][wave amp=8.0 freq=4.0 connected=1]%s[/wave][/center]" % value.to_upper()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	overlay_shade = ColorRect.new()
	add_child(overlay_shade)
	overlay_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay_shade.color = Color(0.082353, 0.207843, 0.211765, 0.55)
	overlay_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_center = CenterContainer.new()
	add_child(banner_center)
	banner_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel = PanelContainer.new()
	banner_center.add_child(panel)
	panel.custom_minimum_size = Vector2(1280 / 1.5, 300)
	resized.connect(_update_banner_width)
	panel_style = StyleBoxFlat.new()
	panel_style.bg_color = LexispellStyle.TEXT
	panel_style.border_color = LexispellStyle.NORMAL
	panel_style.set_border_width_all(5)
	panel_style.set_corner_radius_all(24)
	panel_style.content_margin_top = 40
	panel_style.content_margin_bottom = 40
	panel_style.content_margin_left = 60
	panel_style.content_margin_right = 60
	panel_style.shadow_color = LexispellStyle.SHADOW
	panel_style.shadow_size = 1
	panel_style.shadow_offset = Vector2(3, 4)
	panel.add_theme_stylebox_override("panel", panel_style)
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	panel.add_child(column)
	title = MixedLabel.new()
	column.add_child(title)
	title.custom_minimum_size.y = 112
	title.add_theme_font_override("normal_font", KIDS_FONT)
	title.add_theme_font_size_override("normal_font_size", 92)
	title.add_theme_color_override("default_color", LexispellStyle.TEXT)
	title.add_theme_color_override("font_color", LexispellStyle.TEXT)
	title.add_theme_color_override("font_outline_color", LexispellStyle.HOVER)
	title.add_theme_color_override("font_shadow_color", LexispellStyle.NORMAL)
	title.add_theme_constant_override("outline_size", 8)
	title.add_theme_constant_override("shadow_outline_size", 6)
	title.add_theme_constant_override("shadow_offset_x", 2)
	title.add_theme_constant_override("shadow_offset_y", 4)
	prediction_title = title.duplicate() as MixedLabel
	prediction_title.name = "PredictionTitle"
	prediction_title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_center.add_child(prediction_title)
	# RichTextLabel does not size itself to its text when fit_content is false.
	prediction_title.custom_minimum_size.y = 144
	prediction_title.add_theme_color_override("default_color", LexispellStyle.TEXT)
	_update_banner_width()
	prediction_title.hide()
	subtitle = MixedLabel.new()
	column.add_child(subtitle)
	subtitle.custom_minimum_size.y = 48
	subtitle.add_theme_font_override("normal_font", KIDS_FONT)
	subtitle.add_theme_font_size_override("normal_font_size", 30)
	subtitle.add_theme_color_override("font_color", LexispellStyle.NORMAL)
	subtitle.add_theme_color_override("default_color", LexispellStyle.NORMAL)
	buttons = HBoxContainer.new()
	column.add_child(buttons)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	for caption in ["Rigioca", "Torna al menu"]:
		var button := RoundedSquareButton.new()
		buttons.add_child(button)
		button.text = caption.to_upper()
		button.custom_minimum_size = Vector2(260, 64)
		button.add_theme_font_size_override("font_size", 20)
		button.add_theme_font_override("font", KIDS_FONT)
		button.add_theme_stylebox_override("normal", _overlay_button_style(BUTTON_PURPLE))
		button.add_theme_stylebox_override("hover", _overlay_button_style(BUTTON_CYAN, BUTTON_TEXT, 6))
		button.add_theme_stylebox_override("pressed", _overlay_button_style(BUTTON_PURPLE_PRESSED, BUTTON_TEXT, 2))
		button.add_theme_color_override("font_color", BUTTON_TEXT)
		button.add_theme_color_override("font_hover_color", BUTTON_TEXT)
		button.add_theme_color_override("font_pressed_color", BUTTON_TEXT)
		button.add_theme_color_override("font_disabled_color", LexispellStyle.DISABLED_TEXT)
		if caption == "Rigioca":
			button.pressed.connect(func(): hide(); replay_requested.emit())
		else:
			button.pressed.connect(func(): hide(); menu_requested.emit())
	hide()

func _overlay_button_style(color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	return LexispellStyle.button_style(color, border_color, border_width)

func announce_turn(prediction: bool, single_card: bool = false) -> void:
	preload("res://scenes/balatro/scripts/game_audio.gd").play(self, preload("res://scenes/balatro/scripts/game_audio.gd").NOTICE)
	_set_wide_prediction_banner(prediction)
	_set_animated_title("E' IL TUO TURNO!")
	buttons.hide()
	if prediction:
		# During predictions the banner stays visible while the choices are shown
		# below it. The overlay must not block those buttons.
		overlay_shade.hide()
		# Keep the banner above the prediction buttons instead of covering them.
		banner_center.offset_top = -50
		banner_center.offset_bottom = -50
		banner_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		modulate.a = 0.0
		show()
		var prediction_in := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		prediction_in.tween_property(self, "modulate:a", 1.0, 0.18)
		await prediction_in.finished
		await get_tree().create_timer(1.5, false).timeout
		if single_card:
			prediction_banner_cleared.emit()
			return
		var prediction_out := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		prediction_out.tween_property(self, "modulate:a", 0.0, 0.18)
		await prediction_out.finished
		_set_animated_title("QUANTE PRESE FAI?")
		prediction_question_started.emit()
		modulate.a = 0.0
		prediction_title.pivot_offset = prediction_title.size / 2.0
		prediction_title.scale = Vector2(0.9, 0.9)
		var title_in := prediction_title.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		title_in.tween_property(prediction_title, "scale", Vector2.ONE, 0.22)
		var prediction_reveal := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		prediction_reveal.tween_property(self, "modulate:a", 1.0, 0.18)
		await prediction_reveal.finished
		prediction_banner_cleared.emit()
		return
	overlay_shade.hide()
	banner_center.offset_top = 0
	banner_center.offset_bottom = 0
	banner_center.mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 0.0
	show()
	var animation := create_tween()
	animation.tween_property(self, "modulate:a", 1.0, 0.15)
	animation.tween_interval(0.8)
	animation.tween_property(self, "modulate:a", 0.0, 0.2)
	await animation.finished
	hide()
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func dismiss_prediction_turn() -> void:
	if not visible:
		return
	var animation := create_tween()
	animation.tween_property(self, "modulate:a", 0.0, 0.16)
	await animation.finished
	hide()
	overlay_shade.show()
	_set_wide_prediction_banner(false)
	banner_center.offset_top = 0
	banner_center.offset_bottom = 0
	banner_center.mouse_filter = Control.MOUSE_FILTER_STOP
	modulate.a = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP

func announce_joker(high: bool) -> void:
	preload("res://scenes/balatro/scripts/game_audio.gd").play(self, preload("res://scenes/balatro/scripts/game_audio.gd").SWIPE)
	_set_wide_prediction_banner(true)
	_set_animated_title("LA PIU' ALTA!" if high else "LA PIU' BASSA!")
	prediction_title.scale = Vector2.ONE
	banner_center.offset_top = 0
	banner_center.offset_bottom = 0
	overlay_shade.hide()
	# This banner has only one line; clear the previous banner subtitle.
	subtitle.set_mixed_text("")
	buttons.hide()
	modulate.a = 0.0
	show()
	var animation := create_tween()
	animation.tween_property(self, "modulate:a", 1.0, 0.15)
	animation.tween_interval(0.65)
	animation.tween_property(self, "modulate:a", 0.0, 0.2)
	await animation.finished
	hide()
	modulate.a = 1.0

func show_victory(player_name: String) -> void:
	preload("res://scenes/balatro/scripts/game_audio.gd").play(self, preload("res://scenes/balatro/scripts/game_audio.gd").VICTORY)
	_set_wide_prediction_banner(false)
	title.add_theme_color_override("default_color", LexispellStyle.NORMAL)
	title.add_theme_color_override("font_color", LexispellStyle.NORMAL)
	title.add_theme_constant_override("outline_size", 0)
	title.add_theme_constant_override("shadow_outline_size", 0)
	title.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
	title.set_mixed_text(player_name.to_upper())
	subtitle.set_mixed_text("HA VINTO LA PARTITA!")
	buttons.show()
	modulate.a = 1.0
	show()
