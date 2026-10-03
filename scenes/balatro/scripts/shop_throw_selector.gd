extends Control

const Catalog = preload("res://scenes/balatro/scripts/throw_catalog.gd")
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const ButtonStyle = preload("res://scenes/balatro/scripts/rounded_square_button.gd")

const SLOT_SIZE := 120.0
const SLOT_GAP := 24.0

var menu: Control
var buttons: Array[Button] = []
var vertical_layout := false

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	mouse_filter = Control.MOUSE_FILTER_PASS
	var step := SLOT_SIZE + SLOT_GAP
	size = Vector2(SLOT_SIZE + 8.0, SLOT_SIZE * 3.0 + SLOT_GAP * 2.0) if vertical_layout else Vector2(SLOT_SIZE * 3.0 + SLOT_GAP * 2.0, SLOT_SIZE + 8.0)
	for index in range(3):
		var button := ButtonStyle.new()
		button.size = Vector2.ONE * SLOT_SIZE
		button.position = Vector2(0, index * step) if vertical_layout else Vector2(index * step, 0)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 110)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := Style.button_style(Style.NORMAL)
			style.set_corner_radius_all(SLOT_SIZE * 0.5)
			button.add_theme_stylebox_override(state, style)
		add_child(button)
		button.pressed.connect(func(): _cycle(index))
		buttons.append(button)
	refresh()

func refresh() -> void:
	var selection: Array = get_node("/root/GameSettings").values.throw_slots
	for index in buttons.size():
		var id: int = int(selection[index])
		var enabled := id >= 0 and id < Catalog.FILES.size() and Catalog.enabled(id)
		buttons[index].icon = load("res://scenes/balatro/resources/" + Catalog.FILES[id]) if enabled else null
		buttons[index].text = "" if enabled else "+"
		buttons[index].tooltip_text = "Cambia oggetto (o lascia vuoto)"

func _cycle(slot: int) -> void:
	var settings := get_node("/root/GameSettings")
	var selection: Array = settings.values.throw_slots.duplicate()
	var choices: Array = [-1]
	for id in Catalog.FILES.size():
		if Catalog.enabled(id):
			choices.append(id)
	selection[slot] = choices[(choices.find(selection[slot]) + 1) % choices.size()]
	settings.set_value("throw_slots", selection)
	settings.save_preferences()
	refresh()
