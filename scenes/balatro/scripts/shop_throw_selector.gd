extends Control

const Catalog = preload("res://scenes/balatro/scripts/throw_catalog.gd")
const Throws = preload("res://scenes/balatro/scripts/throw_objects.gd")
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const ButtonStyle = preload("res://scenes/balatro/scripts/rounded_square_button.gd")
var menu: Control
var badge: Control
var buttons: Array[Button] = []

func setup(owner_menu: Control) -> void:
	menu = owner_menu
	mouse_filter = MOUSE_FILTER_PASS
	size = Vector2(450, 370)
	badge = preload("res://scenes/balatro/scripts/player_badge.gd").new()
	badge.position = Vector2(0, 0)
	badge.scale = Vector2.ONE * 1.5
	add_child(badge)
	badge.mouse_filter = MOUSE_FILTER_IGNORE
	for index in range(3):
		var button := ButtonStyle.new()
		button.size = Vector2(76, 76)
		button.position = Vector2(182, 92) + Vector2.RIGHT.rotated(deg_to_rad(Throws.SLOT_ANGLES[index])) * Throws.SLOT_RADIUS - Vector2(38, 38)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 60)
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := Style.button_style(Style.NORMAL)
			style.set_corner_radius_all(38)
			button.add_theme_stylebox_override(state, style)
		add_child(button)
		button.pressed.connect(func(): _cycle(index))
		buttons.append(button)
	refresh()

func refresh() -> void:
	badge.profile_texture = menu.profile_texture
	badge.configure(menu.chosen_name(), 3, -1, 0, false, false)
	var selection: Array = get_node("/root/GameSettings").values.throw_slots
	for index in buttons.size():
		var id: int = selection[index]
		buttons[index].icon = load("res://scenes/balatro/resources/" + Catalog.FILES[id]) if Catalog.enabled(id) else null
		buttons[index].text = "" if Catalog.enabled(id) else "+"
		buttons[index].tooltip_text = "Cambia oggetto (o lascia vuoto)"

func _cycle(slot: int) -> void:
	var settings := get_node("/root/GameSettings")
	var selection: Array = settings.values.throw_slots.duplicate()
	var choices: Array = [-1]
	for id in Catalog.FILES.size():
		if Catalog.enabled(id): choices.append(id)
	selection[slot] = choices[(choices.find(selection[slot]) + 1) % choices.size()]
	settings.set_value("throw_slots", selection)
	settings.save_preferences()
	refresh()
