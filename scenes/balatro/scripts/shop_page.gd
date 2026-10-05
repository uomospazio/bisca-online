extends Control

## Vetrina fissa: tre articoli grandi, senza scorrimento.
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const MARKET_TEXTURE = preload("res://scenes/balatro/trick_asset/ui_bisca/fullMarket.png")
const COIN_TEXTURE = preload("res://scenes/balatro/trick_asset/ui_bisca/coin.png")
const PRICE_COLOR := Color("#0c0918")

# Banco, insegna e articoli si spostano insieme.
const MARKET_OFFSET := Vector2.ZERO
const MARKET_POSITION := Vector2(400, 50)
const MARKET_SIZE := Vector2(1700, 1050)
# Coordinate relative alla grafica del banco.
const ITEM_RECTS := [
	Rect2(85, 450, 240, 280),
	Rect2(435, 450, 240, 280),
	Rect2(785, 450, 240, 280),
]
const TAG_RECTS := [
	Rect2(120, 755, 205, 102.5),
	Rect2(480, 755, 205, 102.5),
	Rect2(840, 755, 205, 102.5),
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
var item_previews: Dictionary = {}
var touch_item_id := ""
var touch_start_position := Vector2.ZERO
var touch_dragged := false
var rendered_items: Array = []
var purchase_dialog: Control
var purchase_text: Label
var purchase_amount: Label
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

	var background := ColorRect.new()
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(background)
	var art := TextureRect.new()
	art.texture = MARKET_TEXTURE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.add_child(art)
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fit := func():
		var screen := get_viewport_rect().size
		background.position = -(screen - Vector2(1920, 1080)) * 0.5
		background.size = screen
	get_viewport().size_changed.connect(fit)
	fit.call()
	var market := Control.new()
	market.name = "Market"
	market.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	market.mouse_filter = Control.MOUSE_FILTER_IGNORE
	market.position = MARKET_POSITION + MARKET_OFFSET
	market.size = MARKET_SIZE
	content.add_child(market)

	grid = Control.new()
	grid.name = "Offers"
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	grid.size = MARKET_SIZE
	market.add_child(grid)

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
	counter.scale = Vector2.ONE
	var back: Button = menu._button(self, "INDIETRO", menu._leave_shop)
	menu.match_singleplayer_back(back)
	back.set_meta("safe_bottom", false)
	back.position = Vector2(40, 40)
	fixed_controls = [back, counter]

	_build_purchase_dialog()
	get_viewport().size_changed.connect(_fit_offer_scale, CONNECT_DEFERRED)
	result_dialog = AcceptDialog.new()
	add_child(result_dialog)
	manager.changed.connect(_update)
	visibility_changed.connect(_update)

func _build_purchase_dialog() -> void:
	purchase_dialog = Control.new()
	purchase_dialog.z_index = 100
	add_child(purchase_dialog)
	var shade := ColorRect.new()
	shade.color = Color(0.04, 0.03, 0.08, 0.78)
	purchase_dialog.add_child(shade)
	var panel := Panel.new()
	purchase_dialog.add_child(panel)
	panel.size = Vector2(560, 420)
	var skin := Style.button_style(Style.PANEL, Style.HOVER, 4)
	for edge in ["left", "right", "top", "bottom"]:
		skin.set("content_margin_" + edge, 36.0)
	panel.add_theme_stylebox_override("panel", skin)
	var rows := Control.new()
	panel.add_child(rows)
	rows.position = Vector2(32, 32)
	rows.size = Vector2(496, 356)
	purchase_text = _label("", 32)
	purchase_text.size = Vector2(496, 160)
	purchase_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	purchase_text.max_lines_visible = 5
	purchase_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	purchase_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	purchase_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rows.add_child(purchase_text)
	var cost := HBoxContainer.new()
	cost.alignment = BoxContainer.ALIGNMENT_CENTER
	cost.add_theme_constant_override("separation", 16)
	rows.add_child(cost)
	cost.position = Vector2(0, 180)
	cost.size = Vector2(496, 64)
	purchase_amount = _label("", 44)
	cost.add_child(purchase_amount)
	var coin := TextureRect.new()
	coin.texture = COIN_TEXTURE
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.custom_minimum_size = Vector2(64, 64)
	cost.add_child(coin)
	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 20)
	rows.add_child(buttons)
	buttons.position = Vector2(0, 280)
	buttons.size = Vector2(496, 76)
	for spec in [["ANNULLA", purchase_dialog.hide], ["ACQUISTA", _purchase_confirmed]]:
		var button: Button = menu_owner._button(buttons, spec[0], spec[1])
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(238, 76)
		button.add_theme_font_size_override("font_size", 28)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var button_skin := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
			button_skin.set_corner_radius_all(38)
			for edge in ["left", "right", "top", "bottom"]:
				button_skin.set("content_margin_" + edge, 6.0)
			button.add_theme_stylebox_override(state, button_skin)
	var fit := func():
		var screen := get_viewport_rect().size
		shade.position = -(screen - Vector2(1920, 1080)) * 0.5
		shade.size = screen
		panel.position = (Vector2(1920, 1080) - panel.size) * 0.5
	get_viewport().size_changed.connect(fit)
	panel.resized.connect(fit)
	fit.call()
	purchase_dialog.hide()

func _fit_offer_scale() -> void:
	# Keep design sizes as the maximum, even on larger physical displays.
	var display_scale := get_viewport().get_stretch_transform().get_scale().abs()
	var factor := 1.0 / maxf(1.0, maxf(display_scale.x, display_scale.y))
	for offer in grid.get_children():
		for child in offer.get_children():
			if child is Control:
				child.pivot_offset = child.size * 0.5
				child.scale = Vector2.ONE * factor

func open() -> void:
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

	purchase_text.text = 'Vuoi acquistare "%s" per' % item.name
	purchase_amount.text = str(pending_price)
	purchase_dialog.show()


func _purchase_confirmed() -> void:
	if manager.purchasing:
		return
	purchase_dialog.hide()
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
	for index in mini(items.size(), ITEM_RECTS.size()):
		_build_offer(items[index], index)
	_fit_offer_scale()

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

	var tag := Control.new()
	tag.name = "PriceTag"
	tag.texture_filter = TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tag.position = TAG_RECTS[index].position + Vector2([-15, -25, -35][index], -12)
	tag.size = TAG_RECTS[index].size
	offer.add_child(tag)
	var owned: bool = manager.owns_item(item.id)
	var price := _label("POSSEDUTO" if owned else str(item.price), 34)
	price.name = "Price"
	price.add_theme_color_override("font_color", PRICE_COLOR)
	price.position = Vector2.ZERO
	price.size = tag.size
	price.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var font_size := 34
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
