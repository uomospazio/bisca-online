extends Control
## Local Q&A browser. No chat, recognition engine or conversation memory.
const DATA := "res://scenes/balatro/data/assistant_knowledge.json"
const GenericSkin = preload("res://scenes/balatro/scripts/generic_ui_skin.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const GROUPS := [
	["rules", "Regole e carte", "Rules and cards"],
	["modes", "Partite e multiplayer", "Matches and multiplayer"],
	["account", "Account e profilo", "Account and profile"],
	["customization", "Personalizzazione e Shop", "Customization and Shop"],
	["settings", "Impostazioni e chat vocale", "Settings and voice chat"]
]
var topics: Array = []
var language := "it"
var panel: PanelContainer
var content: VBoxContainer
var scroll: ScrollContainer
var back_button: Button
var title: Label
var selected_topic := ""
var question_buttons: Array[Button] = []
var home_scroll := 0

static func open(host: Node) -> Control:
	var existing := host.get_node_or_null("BiscaAssistant")
	if existing:
		existing._show_home()
		existing.show()
		existing._fit()
		return existing
	var page = load("res://scenes/balatro/scripts/assistant_chat.gd").new()
	page.name = "BiscaAssistant"
	host.add_child(page)
	return page

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	z_index = 200
	mouse_filter = MOUSE_FILTER_STOP
	set_meta("cartoon_style_children_excluded", true)
	var data = JSON.parse_string(FileAccess.get_file_as_string(DATA))
	if data is Dictionary and data.get("topics") is Array: topics = data.topics
	panel = PanelContainer.new()
	add_child(panel)
	GenericSkin.apply(panel, false, 28)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 24)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	title = _label("", 36)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(title)
	var close := _button("Chiudi", _close)
	close.name = "Close"
	header.add_child(close)
	scroll = preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 160
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = SIZE_EXPAND_FILL
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	scroll.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 24)
	margin.add_child(content)
	back_button = _button("Indietro", _show_home)
	back_button.size_flags_horizontal = SIZE_SHRINK_BEGIN
	column.add_child(back_button)
	_show_home()
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()

func _clear_content() -> void:
	question_buttons.clear()
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _show_home() -> void:
	var settings := get_node_or_null("/root/GameSettings")
	if settings: language = "en" if settings.values.language == "en" else "it"
	title.text = "Domande e risposte" if language == "it" else "Questions and answers"
	title.get_parent().get_node("Close").text = "Chiudi" if language == "it" else "Close"
	back_button.text = "Indietro" if language == "it" else "Back"
	selected_topic = ""
	back_button.hide()
	_clear_content()
	for group in GROUPS:
		var entries: Array = []
		for topic in topics:
			var category: String = str(topic.get("category", ""))
			if category in ["shop", "custom"]: category = "customization"
			if category == group[0]: entries.append(topic)
		if entries.is_empty(): continue
		var heading := _label(group[1] if language == "it" else group[2], 30)
		heading.add_theme_color_override("font_color", Color("bca5ff"))
		content.add_child(heading)
		var grid := GridContainer.new()
		grid.columns = 3
		grid.add_theme_constant_override("h_separation", 24)
		grid.add_theme_constant_override("v_separation", 24)
		content.add_child(grid)
		for topic in entries:
			var card := _button(topic[language].examples[0], _show_answer.bind(str(topic.id)))
			card.size_flags_horizontal = SIZE_EXPAND_FILL
			card.custom_minimum_size = Vector2(0, 104)
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			card.add_theme_font_size_override("font_size", 25)
			var material: ShaderMaterial = card.get_meta("generic_ui_material")
			material.set_shader_parameter("fill_top", Color("1D1A48"))
			material.set_shader_parameter("fill_bottom", Color("1D1A48"))
			material.set_shader_parameter("pill_highlight", false)
			# Run after the generic skin's resize callback, which sets a pill radius.
			var fit_card := func(): material.set_shader_parameter("corner_radius", 10.0)
			card.resized.connect(fit_card)
			fit_card.call()
			grid.add_child(card)
			question_buttons.append(card)
	_restore_scroll.call_deferred()

func _restore_scroll() -> void:
	await get_tree().process_frame
	if selected_topic.is_empty(): scroll.scroll_vertical = home_scroll

func _show_answer(id: String) -> void:
	var selected: Dictionary = {}
	for topic in topics:
		if topic.id == id:
			selected = topic
			break
	if selected.is_empty(): return
	home_scroll = scroll.scroll_vertical
	selected_topic = id
	_clear_content()
	var question := _label(selected[language].examples[0], 36)
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	question.add_theme_color_override("font_color", Color("bca5ff"))
	content.add_child(question)
	var answer := _label(selected[language].answer, 32)
	answer.name = "Answer"
	answer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	answer.add_theme_constant_override("line_spacing", 8)
	content.add_child(answer)
	back_button.show()
	scroll.scroll_vertical = 0
	back_button.grab_focus()

static func display_text(text: String) -> String:
	for pair in [["à", "a'"], ["è", "e'"], ["é", "e'"], ["ì", "i'"], ["ò", "o'"], ["ù", "u'"], ["À", "A'"], ["È", "E'"], ["É", "E'"], ["Ì", "I'"], ["Ò", "O'"], ["Ù", "U'"]]:
		text = text.replace(pair[0], pair[1])
	return text.replace("’", "'").replace("‘", "'").replace("\u0300", "'").replace("\u0301", "'")

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = display_text(text)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f8f5ff"))
	return label

func _button(text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = display_text(text)
	button.custom_minimum_size = Vector2(170, 64)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.pressed.connect(action)
	GenericSkin.apply(button, true)
	return button

func _close() -> void:
	hide()

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel"):
		if selected_topic.is_empty(): _close()
		else: _show_home()
		get_viewport().set_input_as_handled()

func _fit() -> void:
	if not is_instance_valid(panel): return
	var bounds := get_viewport_rect()
	var window := get_window()
	if OS.has_feature("mobile") and window.size.x > 0 and window.size.y > 0:
		var ratio := bounds.size / Vector2(window.size)
		var physical := Rect2(DisplayServer.get_display_safe_area()).intersection(Rect2(Vector2(window.position), Vector2(window.size)))
		if physical.has_area(): bounds = Rect2((physical.position - Vector2(window.position)) * ratio, physical.size * ratio)
	bounds = get_global_transform_with_canvas().affine_inverse() * bounds
	layout_in(bounds)

func layout_in(bounds: Rect2) -> void:
	bounds = bounds.grow(-12)
	var factor := minf(1, minf(bounds.size.x / 1380.0, bounds.size.y / 480.0))
	panel.scale = Vector2.ONE * maxf(0.01, factor)
	panel.size = Vector2(1380, clampf(bounds.size.y / maxf(factor, 0.01), 480, 820))
	panel.position = bounds.get_center() - panel.size * panel.scale / 2
