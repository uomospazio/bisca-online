extends Control

# Due carte sempre visibili:
# - a sinistra il FRONT
# - a destra il BACK
#
# Toccando una carta si passa direttamente alla variante successiva.

const CARD_SIZE := Vector2(180, 272)

# POSIZIONI DELLE DUE CARTE DEL DECK SELECTOR
const FRONT_CARD_POSITION := Vector2(0, 0)
const BACK_CARD_POSITION := Vector2(250, 0)

const FRONT_CARD_ROTATION := -5.0
const BACK_CARD_ROTATION := 5.0

# Carta usata solo come anteprima grafica del fronte.
const FRONT_PREVIEW_SUIT := 3
const FRONT_PREVIEW_VALUE := 5

const PRESS_SCALE := 0.92
const PRESS_IN_DURATION := 0.08
const PRESS_OUT_DURATION := 0.16

var front_preview: TextureButton
var back_preview: TextureButton

var selected_front := 0
var selected_back := 1

var front_tween: Tween
var back_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	front_preview = _create_card_button(
		FRONT_CARD_POSITION,
		FRONT_CARD_ROTATION,
		_cycle_front
	)

	back_preview = _create_card_button(
		BACK_CARD_POSITION,
		BACK_CARD_ROTATION,
		_cycle_back
	)

	var shop := get_node_or_null("/root/ShopManager")
	if shop:
		shop.changed.connect(_refresh_owned_backs)

	var cloud := get_node_or_null("/root/AccountProfile")
	if cloud:
		cloud.preferences_loaded.connect(reset_preview)

	reset_preview()


func _create_card_button(
	at: Vector2,
	rotation: float,
	callback: Callable
) -> TextureButton:
	var button := TextureButton.new()
	button.position = at
	button.size = CARD_SIZE
	button.custom_minimum_size = CARD_SIZE
	button.pivot_offset = CARD_SIZE / 2.0
	button.rotation_degrees = rotation

	button.ignore_texture_size = true
	button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	button.pressed.connect(callback)
	add_child(button)

	return button


func reset_preview() -> void:
	var settings := get_node("/root/GameSettings")

	selected_front = int(settings.values.deck_front)
	selected_back = int(settings.values.deck_back)

	_refresh_owned_backs()
	_update_textures()


## La proprietà resta quella dell'inventario;
## back1 viene usato soltanto come fallback visivo se non c'è nessun dorso disponibile.
func _owned_backs() -> Array[int]:
	var backs: Array[int] = []
	var shop := get_node_or_null("/root/ShopManager")

	if shop:
		for item in shop.get_owned_items():
			var asset := int(item.asset_id)

			if (
				str(item.id).begins_with("deck_back_")
				and asset >= 1
				and asset <= 12
				and not backs.has(asset)
			):
				backs.append(asset)

	backs.sort()
	return backs


func _refresh_owned_backs() -> void:
	var backs := _owned_backs()

	if backs.has(selected_back):
		_update_textures()
		return

	var saved := int(get_node("/root/GameSettings").values.deck_back)

	if backs.has(saved):
		selected_back = saved
	elif not backs.is_empty():
		selected_back = backs[0]
	else:
		selected_back = 0

	_update_textures()


func _cycle_front() -> void:
	var settings := get_node("/root/GameSettings")
	var count: int = int(settings.FRONT_FOLDERS.size())

	if count <= 0:
		return

	selected_front = wrapi(selected_front + 1, 0, count)

	settings.set_value("deck_front", selected_front)
	settings.save_preferences()

	_update_front_texture()
	_animate_card(front_preview, true)


func _cycle_back() -> void:
	var backs := _owned_backs()

	if backs.is_empty():
		return

	var current_index := backs.find(selected_back)

	if current_index == -1:
		current_index = 0
	else:
		current_index = wrapi(current_index + 1, 0, backs.size())

	selected_back = backs[current_index]

	var settings := get_node("/root/GameSettings")
	settings.set_value("deck_back", selected_back)
	settings.save_preferences()

	_update_back_texture()
	_animate_card(back_preview, false)


func _update_textures() -> void:
	_update_front_texture()
	_update_back_texture()


func _update_front_texture() -> void:
	if not is_instance_valid(front_preview):
		return

	var settings := get_node("/root/GameSettings")
	front_preview.texture_normal = settings.front_texture(
		FRONT_PREVIEW_SUIT,
		FRONT_PREVIEW_VALUE,
		selected_front
	)


func _update_back_texture() -> void:
	if not is_instance_valid(back_preview):
		return

	var settings := get_node("/root/GameSettings")
	back_preview.texture_normal = settings.back_texture(
		selected_back if selected_back > 0 else 1
	)


func _animate_card(card: Control, is_front: bool) -> void:
	if not is_instance_valid(card):
		return

	if is_front:
		if front_tween and front_tween.is_valid():
			front_tween.kill()

		front_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		front_tween.tween_property(
			card,
			"scale",
			Vector2.ONE * PRESS_SCALE,
			PRESS_IN_DURATION
		)
		front_tween.tween_property(
			card,
			"scale",
			Vector2.ONE,
			PRESS_OUT_DURATION
		)
	else:
		if back_tween and back_tween.is_valid():
			back_tween.kill()

		back_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		back_tween.tween_property(
			card,
			"scale",
			Vector2.ONE * PRESS_SCALE,
			PRESS_IN_DURATION
		)
		back_tween.tween_property(
			card,
			"scale",
			Vector2.ONE,
			PRESS_OUT_DURATION
		)
