class_name MixedLabel
extends RichTextLabel

const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")

func _init() -> void:
	custom_minimum_size = Vector2(0, 40)
	add_theme_font_override("normal_font", KIDS_FONT)
	add_theme_color_override("default_color", Color("214f50"))
	bbcode_enabled = true
	fit_content = false
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _ready() -> void:
	add_theme_color_override("default_color", Color("214f50"))
	add_theme_font_override("normal_font", KIDS_FONT)
	bbcode_enabled = true
	fit_content = false
	scroll_active = false
	autowrap_mode = TextServer.AUTOWRAP_OFF
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func set_mixed_text(value: String) -> void:
	text = "[center]" + value.to_upper() + "[/center]"
