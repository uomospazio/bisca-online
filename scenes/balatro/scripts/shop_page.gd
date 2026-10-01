extends Control

## Vetrina fissa: due articoli grandi e due piccoli, senza scorrimento.
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const MARKET_TEXTURE = preload("res://scenes/balatro/trick_asset/ui_bisca/market_four.png")
const PRICE_TAG_TEXTURE = preload("res://scenes/balatro/trick_asset/ui_bisca/market_price_tag.png")
const PRICE_COLOR := Color("#340602")

# Banco, insegna e articoli si spostano insieme.
const MARKET_OFFSET := Vector2.ZERO
const MARKET_POSITION := Vector2(400, 50)
const MARKET_SIZE := Vector2(1700, 1050)
const DECK_POSITION := Vector2(60, 300)
const DECK_SCALE := 1.25
const OBJECTS_POSITION := Vector2(40, 650)
const OBJECTS_SCALE := 1.25
# Coordinate relative alla grafica del banco.
const ITEM_RECTS := [
	Rect2(475, 460, 260, 300),
	Rect2(835, 460, 260, 300),
	Rect2(1185, 452, 145, 112),
	Rect2(1185, 682, 145, 112),
]
const TAG_RECTS := [
	Rect2(500, 755, 205, 102.5),
	Rect2(860, 755, 205, 102.5),
	Rect2(1190, 538, 140, 70),
	Rect2(1190, 777, 140, 70),
]
const TAP_MOVE_THRESHOLD := 18.0
const ITEM_SHADOW_COLOR := Color(0.10, 0.055, 0.025, 0.48)
const ITEM_SHADOW_OFFSET := Vector2(5, 10)
const ITEM_SHADOW_SOFTNESS := 14

var manager: Node
var status: Label
var grid: Control
var menu_owner: Control
var coins_amount: Label
var fixed_controls: Array[Control] = []
var content: Control
var throw_selector: Control
var item_previews: Dictionary = {}
var touch_item_id := ""
var touch_start_position := Vector2.ZERO
var touch_dragged := false
var rendered_items: Array = []
var purchase_dialog: ConfirmationDialog
var result_dialog: AcceptDialog
var pending_item := ""
var pending_price := 0
var pending_user := ""

func setup(menu: Control) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_owner = menu
	manager = get_node("/root/ShopManager")
	content = Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(content)

	var market := TextureRect.new()
	market.name = "Market"
	market.texture = MARKET_TEXTURE
	market.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	market.stretch_mode = TextureRect.STRETCH_SCALE
	market.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	market.mouse_filter = Control.MOUSE_FILTER_IGNORE
	market.position = MARKET_POSITION + MARKET_OFFSET
	market.size = MARKET_SIZE
	content.add_child(market)
	var title := _label("SHOP", 60)
	title.position = Vector2(670, 142)
	title.size = Vector2(475, 83)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	market.add_child(title)

	grid = Control.new()
	grid.name = "Offers"
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.size = MARKET_SIZE
	market.add_child(grid)

	throw_selector = preload("res://scenes/balatro/scripts/shop_throw_selector.gd").new()
	content.add_child(throw_selector)
	throw_selector.position = OBJECTS_POSITION
	throw_selector.scale = Vector2.ONE * OBJECTS_SCALE
	throw_selector.setup(menu)

	status = _label("", 20)
	status.position = Vector2(70, 910)
	status.size = Vector2(410, 145)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(status)

	# Conserva geometria, scala e safe area del precedente HUD.
	var counter: Control = menu.home_persistent_ui.get_node("CoinsCounter").duplicate()
	add_child(counter)
	if counter.has_meta("safe_edge"):
		counter.position -= Vector2(counter.get_meta("safe_edge"))
		counter.remove_meta("safe_edge")
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(counter, true)
	coins_amount = counter.get_node("CoinBar/CoinsAmount")
	counter.pivot_offset = Vector2(counter.size.x, 0)
	counter.scale = Vector2.ONE * 1.12
	var back: Button = menu._button(self, "INDIETRO", menu.show_home)
	back.position = Vector2(40, 40)
	back.custom_minimum_size = Vector2(296, 108)
	back.size = Vector2(296, 108)
	for state in ["normal", "hover", "pressed", "hover_pressed", "focus", "disabled"]:
		var pill := back.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if pill:
			pill.set_corner_radius_all(54)
			back.add_theme_stylebox_override(state, pill)
	fixed_controls = [back, counter]

	purchase_dialog = ConfirmationDialog.new()
	purchase_dialog.title = "CONFERMA ACQUISTO"
	purchase_dialog.ok_button_text = "ACQUISTA"
	purchase_dialog.cancel_button_text = "ANNULLA"
	add_child(purchase_dialog)
	purchase_dialog.confirmed.connect(_purchase_confirmed)
	result_dialog = AcceptDialog.new()
	add_child(result_dialog)
	manager.changed.connect(_update)
	visibility_changed.connect(_update)

func open() -> void:
	var deck: Control = menu_owner.deck_selector
	deck.reparent(content, false)
	deck.position = DECK_POSITION
	deck.scale = Vector2.ONE * DECK_SCALE
	deck.show()
	deck.reset_preview()
	throw_selector.refresh()
	coins_amount.text = menu_owner.coins_label.text
	_update()
	manager.refresh_daily()
	if not manager.inventory_ready or manager.stale or not manager.last_error.is_empty():
		manager.refresh()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		touch_item_id = ""
		return
	if event is InputEventScreenTouch or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT):
		if event is InputEventMouseButton and DisplayServer.is_touchscreen_available():
			return
		if event.pressed:
			touch_item_id = _item_at_position(event.position)
			touch_start_position = event.position
			touch_dragged = false
		else:
			if not touch_dragged and not touch_item_id.is_empty() and touch_item_id == _item_at_position(event.position):
				_ask_purchase(touch_item_id)
			touch_item_id = ""
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if event.position.distance_to(touch_start_position) > TAP_MOVE_THRESHOLD:
			touch_dragged = true

func _item_at_position(viewport_position: Vector2) -> String:
	if not is_visible_in_tree() or purchase_dialog.visible or result_dialog.visible:
		return ""
	for control in fixed_controls:
		if control.is_visible_in_tree() and Rect2(Vector2.ZERO, control.size).has_point(control.get_global_transform_with_canvas().affine_inverse() * viewport_position):
			return ""
	for item_id in item_previews:
		for target in item_previews[item_id]:
			if is_instance_valid(target) and target.is_visible_in_tree() and Rect2(Vector2.ZERO, target.size).has_point(target.get_global_transform_with_canvas().affine_inverse() * viewport_position):
				return str(item_id)
	return ""

func _ask_purchase(item_id: String) -> void:
	if manager.purchasing:
		return

	if manager.owns_item(item_id):
		return

	var item: Dictionary = manager.get_item(item_id)

	if item.is_empty():
		return

	if not item.is_available:
		return

	pending_item = item_id
	pending_price = int(item.price)
	pending_user = str(
		get_node("/root/AccountSession").user_id
	)

	purchase_dialog.dialog_text = (
		"Acquistare %s per %d monete?"
		% [
			item.name,
			pending_price
		]
	)

	purchase_dialog.popup_centered(
		Vector2i(560, 200)
	)


func _purchase_confirmed() -> void:
	# Se nel frattempo è cambiato account,
	# l'acquisto viene annullato.
	if pending_user != str(
		get_node("/root/AccountSession").user_id
	):
		return

	var result: Dictionary = await manager.purchase_item(
		pending_item,
		pending_price
	)

	if not is_inside_tree():
		return

	result_dialog.dialog_text = result.message

	result_dialog.popup_centered(
		Vector2i(560, 200)
	)



func _label(text: String, font_size := 22) -> Label:
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Style.TEXT)
	return label

func _update() -> void:
	if grid == null or not is_visible_in_tree():
		return
	status.text = ""
	if manager.loading:
		status.text = "CARICAMENTO..."
	elif not manager.last_error.is_empty():
		status.text = manager.last_error
	elif manager.stale:
		status.text = "OFFLINE: DATI NON AGGIORNATI."
	elif not manager.inventory_ready:
		status.text = "IN ATTESA DELL'ACCOUNT."
	if not manager.daily_error.is_empty():
		status.text += "\n" + manager.daily_error
	status.visible = not status.text.is_empty()
	var items: Array = manager.get_daily_items()
	var snapshot: Array = []
	for item in items:
		snapshot.append([item, manager.owns_item(item.id)])
	if rendered_items == snapshot:
		return
	rendered_items = snapshot.duplicate(true)
	item_previews.clear()
	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()
	for index in mini(items.size(), 4):
		_build_offer(items[index], index)

func _build_offer(item: Dictionary, index: int) -> void:
	var offer := Control.new()
	offer.name = "Offer%d" % index
	offer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.add_child(offer)
	var bounds: Rect2 = ITEM_RECTS[index]
	var preview := TextureRect.new()
	preview.name = "Preview"
	preview.position = bounds.position
	preview.size = bounds.size
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if str(item.id).begins_with("deck_back_") and item.asset_id >= 1 and item.asset_id <= 12:
		preview.texture = get_node("/root/GameSettings").back_texture(item.asset_id)
	offer.add_child(preview)
	if preview.texture:
		_add_item_shadow(preview)
	else:
		var caption := _label(str(item.name), 22)
		caption.position = bounds.position
		caption.size = bounds.size
		caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		offer.add_child(caption)

	var tag := TextureRect.new()
	tag.name = "PriceTag"
	tag.texture = PRICE_TAG_TEXTURE
	tag.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tag.stretch_mode = TextureRect.STRETCH_SCALE
	tag.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.position = TAG_RECTS[index].position
	tag.size = TAG_RECTS[index].size
	offer.add_child(tag)
	var owned: bool = manager.owns_item(item.id)
	var price := _label("POSSEDUTO" if owned else str(item.price), 34 if index < 2 else 23)
	price.name = "Price"
	price.add_theme_color_override("font_color", PRICE_COLOR)
	# Solo testo: la moneta fa gia' parte della grafica dell'etichetta.
	price.position = tag.size * Vector2(0.28, 0.40)
	price.size = tag.size * Vector2(0.56, 0.38)
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size := 34 if index < 2 else 23
	while FONT.get_string_size(price.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > price.size.x and font_size > 10:
		font_size -= 1
	price.add_theme_font_size_override("font_size", font_size)
	tag.add_child(price)
	if not owned and item.is_available:
		item_previews[str(item.id)] = [preview, tag]

func _add_item_shadow(preview: TextureRect) -> void:
	var shadow := Control.new()
	shadow.name = "ItemShadow"
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shadow.show_behind_parent = true
	preview.add_child(shadow)
	shadow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color.TRANSPARENT
	style.shadow_color = ITEM_SHADOW_COLOR
	style.shadow_size = ITEM_SHADOW_SOFTNESS
	style.shadow_offset = ITEM_SHADOW_OFFSET
	style.set_corner_radius_all(10)
	shadow.draw.connect(func():
		if preview.texture == null or preview.size.x <= 0 or preview.size.y <= 0:
			return
		# Segue la carta effettiva (KEEP_ASPECT), non tutta la cella della griglia.
		var texture_size := preview.texture.get_size()
		var fitted := texture_size * minf(preview.size.x / texture_size.x, preview.size.y / texture_size.y)
		shadow.draw_style_box(style, Rect2((preview.size - fitted) / 2.0, fitted))
	)
	preview.resized.connect(shadow.queue_redraw)
