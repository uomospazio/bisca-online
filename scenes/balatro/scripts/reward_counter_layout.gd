extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

var counter: TextureRect
var amount: Label

func setup_counter(target: TextureRect, label: Label) -> void:
	counter = target
	amount = label
	mouse_filter = MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	get_viewport().size_changed.connect(_fit)

func _layout(bounds: Rect2) -> void:
	var design := preload("res://scenes/balatro/scripts/home_art_ui.gd").DESIGN
	var rect := preload("res://scenes/balatro/scripts/home_art_ui.gd").COUNTER_RECT
	var factor := minf(bounds.size.x/design.x,bounds.size.y/design.y)
	counter.size = rect.size*factor
	counter.position = bounds.get_center()-design*factor/2+rect.position*factor
	counter.pivot_offset = counter.size/2
	amount.position = Vector2(112,18)*factor
	amount.size = Vector2(180,72)*factor
	amount.add_theme_font_size_override("font_size",roundi(40*factor))
