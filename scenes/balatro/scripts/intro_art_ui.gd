extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const INTRO_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/IntroUI/"
const DESIGN := Vector2(2048, 943)
var notice: Label
var buttons: Array[Button] = []
var language_selector: OptionButton

func setup_intro(welcome: Control) -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	set_meta("cartoon_style_children_excluded", true)
	font = welcome.FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	language_selector = OptionButton.new()
	language_selector.name = "LanguageSelector"
	composition.add_child(language_selector)
	language_selector.position = Vector2(40, 30)
	language_selector.size = Vector2(270, 74)
	language_selector.add_item("Italiano", 0)
	language_selector.add_item("English", 1)
	language_selector.add_theme_font_override("font", font)
	language_selector.add_theme_font_size_override("font_size", 32)
	preload("res://scenes/balatro/scripts/generic_ui_skin.gd").apply(language_selector, true)
	language_selector.item_selected.connect(func(index: int): get_node("/root/GameSettings").set_value("language", "en" if index == 1 else "it"))
	get_node("/root/GameSettings").changed.connect(_refresh_language_selector)
	_refresh_language_selector()
	var logo := _image(composition, "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/titoloHome.png", Rect2(450, 10, 1148, 550))
	logo.name = "WelcomeLogo"
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var separator := _label(composition,"OPPURE",Rect2(850,725,348,44),32)
	separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for x in [490,1210]:
		var line := ColorRect.new()
		composition.add_child(line)
		line.position = Vector2(x,747)
		line.size = Vector2(348,3)
		line.color = Color("b7a4e8")
		line.mouse_filter = MOUSE_FILTER_IGNORE
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

func _refresh_language_selector() -> void:
	language_selector.select(1 if get_node("/root/GameSettings").values.language == "en" else 0)
