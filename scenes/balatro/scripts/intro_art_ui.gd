extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"

const INTRO_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/IntroUI/"
const SETTINGS_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/settingsUI/"
const DESIGN := Vector2(2048, 943)

var notice: Label
var buttons: Array[Button] = []

var language_button: Button
var language_open: TextureRect
var language_choice: Button


func setup_intro(welcome: Control) -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	set_meta("cartoon_style_children_excluded", true)

	font = welcome.FONT.duplicate() as FontFile
	font.multichannel_signed_distance_field = true

	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN

	language_button = Button.new()
	composition.add_child(language_button)
	language_button.position = Vector2(40, 30)
	language_button.size = Vector2(348, 76)
	language_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	language_button.pressed.connect(
	func(): language_open.visible = not language_open.visible)
	RoundedSquareButton.ButtonAudio.attach(language_button)
	
	language_button.name = "LanguageSelector"
	language_button.tooltip_text = "Lingua / Language"

	# Rimuove l'eventuale animazione hover dal pulsante lingua
	# e mantiene la grafica identica alle impostazioni.
	language_open = _image(
		composition,
		SETTINGS_ART + "italianoOpen.png",
		Rect2(40, 30, 348, 170)
	)

	language_open.z_index = 5

	# Area cliccabile per chiudere il menu
	var language_close := _language_hotspot(
		language_open,
		Rect2(0, 0, 348, 76),
		func(): language_open.hide()
	)

	# Area cliccabile per cambiare lingua
	language_choice = _language_hotspot(
		language_open,
		Rect2(10, 88, 328, 72),
		func():
			var settings = get_node("/root/GameSettings")
			settings.set_value(
				"language",
				"it" if settings.values.language == "en" else "en"
			)
			language_open.hide()
	)

	language_open.hide()

	get_node("/root/GameSettings").changed.connect(_refresh_language_selector)
	_refresh_language_selector()

	# Logo
	var logo := _image(
		composition,
		"res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/titoloHome.png",
		Rect2(450, 10, 1148, 550)
	)

	logo.name = "WelcomeLogo"
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Separatore
	var separator := _label(
		composition,
		"OPPURE",
		Rect2(850, 725, 348, 44),
		32
	)

	separator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for x in [490, 1210]:
		var line := ColorRect.new()
		composition.add_child(line)
		line.position = Vector2(x, 747)
		line.size = Vector2(348, 3)
		line.color = Color("b7a4e8")
		line.mouse_filter = MOUSE_FILTER_IGNORE

	# Pulsanti accesso
	buttons.append(
		_button(
			composition,
			INTRO_ART + "introApple.png",
			Rect2(356, 611, 428, 99),
			welcome._social_choices.bind("apple")
		)
	)

	buttons.append(
		_button(
			composition,
			INTRO_ART + "introGoogle.png",
			Rect2(810, 611, 428, 99),
			welcome._social_choices.bind("google")
		)
	)

	buttons.append(
		_button(
			composition,
			INTRO_ART + "introEmail.png",
			Rect2(1264, 611, 428, 99),
			welcome._email_choices
		)
	)

	buttons.append(
		_button(
			composition,
			INTRO_ART + "introOspite.png",
			Rect2(810, 785, 428, 99),
			welcome._continue_guest
		)
	)

	# Messaggio informativo
	notice = _label(
		composition,
		"",
		Rect2(350, 891, 1348, 44),
		24
	)

	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	get_viewport().size_changed.connect(_fit)
	_fit()


func _language_hotspot(
	parent: Node,
	rect: Rect2,
	action: Callable
) -> Button:
	var button := Button.new()
	parent.add_child(button)

	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(
			state,
			StyleBoxEmpty.new()
		)

	button.position = rect.position
	button.size = rect.size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.pressed.connect(action)
	RoundedSquareButton.ButtonAudio.attach(button)

	return button


func _refresh_language_selector() -> void:
	if not is_instance_valid(language_button):
		return

	var settings = get_node("/root/GameSettings")
	var english: bool = settings.values.language == "en"

	var texture_path := SETTINGS_ART + (
		"english.png" if english else "italiano.png"
	)

	# Aggiorna il pulsante principale
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := StyleBoxTexture.new()
		style.texture = UiLocale.resource(texture_path)

		if state == "pressed":
			style.modulate_color = Color(0.8, 0.8, 0.8)

		language_button.add_theme_stylebox_override(state, style)

	# Aggiorna il menu aperto
	language_open.texture = UiLocale.resource(
		SETTINGS_ART + (
			"englishOpen.png" if english else "italianoOpen.png"
		)
	)


func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(composition):
		return

	var factor := minf(
		bounds.size.x / DESIGN.x,
		bounds.size.y / DESIGN.y
	)

	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - DESIGN * factor / 2
