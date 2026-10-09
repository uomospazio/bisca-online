extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const INTRO_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/IntroUI/"
const DESIGN := Vector2(2048, 943)
var notice: Label
var buttons: Array[Button] = []

func setup_intro(welcome: Control) -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	set_meta("cartoon_style_children_excluded", true)
	font = welcome.FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	var backdrop := ColorRect.new()
	backdrop.color = Color("171038")
	add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	backdrop.mouse_filter = MOUSE_FILTER_IGNORE
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	_image(composition, INTRO_ART + "introSfondo.png", Rect2(Vector2.ZERO, DESIGN))
	buttons.append(_button(composition, INTRO_ART + "introApple.png", Rect2(356, 611, 428, 99), welcome._social_choices.bind("apple")))
	buttons.append(_button(composition, INTRO_ART + "introGoogle.png", Rect2(810, 611, 428, 99), welcome._social_choices.bind("google")))
	buttons.append(_button(composition, INTRO_ART + "introEmail.png", Rect2(1264, 611, 428, 99), welcome._email_choices))
	buttons.append(_button(composition, INTRO_ART + "introOspite.png", Rect2(810, 785, 428, 99), welcome._continue_guest))
	notice = _label(composition, "", Rect2(350, 891, 1348, 44), 24)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	get_viewport().size_changed.connect(_fit)
	_fit()

func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(composition): return
	var factor := minf(bounds.size.x / DESIGN.x, bounds.size.y / DESIGN.y)
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - DESIGN * factor / 2
