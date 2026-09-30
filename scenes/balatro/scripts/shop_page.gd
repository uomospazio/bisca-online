extends Control

## UI Shop.
## Il tap su un oggetto apre l'acquisto.
## Su mobile lo ScrollContainer gestisce automaticamente tap vs trascinamento.

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")

# Area visibile degli oggetti.
const ITEMS_POSITION := Vector2(220, 180)
const ITEMS_SIZE := Vector2(1560, 900)

# Distanza che il dito deve percorrere prima che il gesto
# venga considerato uno scroll.
const TAP_MOVE_THRESHOLD := 18.0

var manager: Node
var status: Label
var grid: GridContainer
var reload_button: Button
var menu_owner: Control
var coins_amount: Label
var shop_scroll: ScrollContainer

# Aree cliccabili degli articoli. Gestite globalmente così lo ScrollContainer
# resta libero di ricevere e gestire gli swipe su mobile.
var item_previews: Dictionary = {}
var touch_item_id := ""
var touch_start_position := Vector2.ZERO
var touch_start_scroll := 0
var touch_dragged := false

var intro_controls: Array[Control] = []
var intro_tween: Tween
var rendered_items: Array = []

var purchase_dialog: ConfirmationDialog
var result_dialog: AcceptDialog

var pending_item := ""
var pending_price := 0
var pending_user := ""


func setup(menu: Control) -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	menu_owner = menu

	# Stessa geometria e risorse della home, senza duplicare il saldo.
	var counter: Control = menu.home_persistent_ui.get_node("CoinsCounter").duplicate()
	add_child(counter)

	coins_amount = counter.get_node("CoinBar/CoinsAmount")

	manager = get_node("/root/ShopManager")


	# ---------------------------------------------------------
	# TITOLO
	# ---------------------------------------------------------

	var title := _label("SHOP", 58)

	add_child(title)

	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -160
	title.offset_right = 160
	title.offset_top = 40
	title.offset_bottom = 136

	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	intro_controls.append(title)


	# ---------------------------------------------------------
	# STATUS
	# ---------------------------------------------------------

	status = _label("", 23)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	add_child(status)

	status.position = Vector2(180, 160)
	status.size = Vector2(1540, 100)


	# ---------------------------------------------------------
	# SCROLL SHOP
	# ---------------------------------------------------------

	shop_scroll = ScrollContainer.new()

	add_child(shop_scroll)

	shop_scroll.position = ITEMS_POSITION
	shop_scroll.size = ITEMS_SIZE

	shop_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	shop_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO


	# ---------------------------------------------------------
	# GRIGLIA
	# ---------------------------------------------------------

	grid = GridContainer.new()

	grid.columns = 4

	grid.add_theme_constant_override(
		"h_separation",
		120
	)

	grid.add_theme_constant_override(
		"v_separation",
		30
	)

	shop_scroll.add_child(grid)


	# ---------------------------------------------------------
	# INDIETRO
	# ---------------------------------------------------------

	var back: Button = menu._button(
		self,
		"INDIETRO",
		menu.show_home
	)

	back.position = Vector2(40, 40)

	intro_controls.append(back)


	# ---------------------------------------------------------
	# AGGIORNA
	# ---------------------------------------------------------

	reload_button = menu._button(
		self,
		"AGGIORNA",
		manager.refresh
	)

	reload_button.position = Vector2(320, 40)


	for button in [back, reload_button]:
		button.custom_minimum_size = Vector2(260, 96)
		button.size = Vector2(260, 96)

		for state in [
			"normal",
			"hover",
			"pressed",
			"hover_pressed",
			"focus",
			"disabled"
		]:
			var pill := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat

			if pill:
				pill.set_corner_radius_all(48)

				button.add_theme_stylebox_override(
					state,
					pill
				)


	intro_controls.append(reload_button)


	# ---------------------------------------------------------
	# SIGNAL
	# ---------------------------------------------------------

	manager.changed.connect(_update)
	visibility_changed.connect(_update)


	# ---------------------------------------------------------
	# DIALOG ACQUISTO
	# ---------------------------------------------------------

	purchase_dialog = ConfirmationDialog.new()

	purchase_dialog.title = "CONFERMA ACQUISTO"
	purchase_dialog.ok_button_text = "ACQUISTA"
	purchase_dialog.cancel_button_text = "ANNULLA"

	add_child(purchase_dialog)

	purchase_dialog.confirmed.connect(
		_purchase_confirmed
	)


	# ---------------------------------------------------------
	# DIALOG RISULTATO
	# ---------------------------------------------------------

	result_dialog = AcceptDialog.new()

	add_child(result_dialog)


func _input(event: InputEvent) -> void:
	# TOUCH MOBILE
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_item_id = _item_at_position(event.position)
			touch_start_position = event.position
			touch_start_scroll = shop_scroll.scroll_vertical if shop_scroll else 0
			touch_dragged = false
		else:
			var released_item := _item_at_position(event.position)
			var scroll_changed := false

			if shop_scroll:
				scroll_changed = abs(shop_scroll.scroll_vertical - touch_start_scroll) > 1

			if (
				not touch_item_id.is_empty()
				and released_item == touch_item_id
				and not touch_dragged
				and not scroll_changed
			):
				_ask_purchase(touch_item_id)

			touch_item_id = ""
			touch_dragged = false

	elif event is InputEventScreenDrag:
		if (
			not touch_item_id.is_empty()
			and event.position.distance_to(touch_start_position) > TAP_MOVE_THRESHOLD
		):
			touch_dragged = true

	# MOUSE DESKTOP
	# Su dispositivi touch ignoriamo gli eventi mouse emulati dal dito.
	elif event is InputEventMouseButton:
		if DisplayServer.is_touchscreen_available():
			return

		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var item_id := _item_at_position(event.position)
			if not item_id.is_empty():
				_ask_purchase(item_id)


func _item_at_position(viewport_position: Vector2) -> String:
	for item_id in item_previews:
		var preview: Control = item_previews[item_id]

		if not is_instance_valid(preview):
			continue

		if not preview.is_visible_in_tree():
			continue

		if preview.get_global_rect().has_point(viewport_position):
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


func open() -> void:
	coins_amount.text = menu_owner.coins_label.text

	_update()


	# ---------------------------------------------------------
	# ANIMAZIONE ENTRATA
	# ---------------------------------------------------------

	if intro_tween and intro_tween.is_valid():
		intro_tween.kill()

	intro_tween = create_tween().set_parallel(true)

	var elements: Array[Control] = intro_controls.duplicate()

	# Gli oggetti dello shop sono già presenti senza pop: si animano solo
	# titolo e pulsanti della schermata.

	for index in elements.size():
		var element := elements[index]

		element.pivot_offset = element.size / 2.0

		intro_tween.tween_property(
			element,
			"scale",
			Vector2.ONE,
			0.35
		).from(
			Vector2.ZERO
		).set_delay(
			index * 0.035
		).set_trans(
			Tween.TRANS_BACK
		).set_ease(
			Tween.EASE_OUT
		)


	# ---------------------------------------------------------
	# REFRESH
	# ---------------------------------------------------------

	if (
		not manager.inventory_ready
		or manager.stale
		or not manager.last_error.is_empty()
	):
		manager.refresh()


func _label(
	text: String,
	font_size := 22
) -> Label:

	var label := Label.new()

	label.text = text

	label.add_theme_font_override(
		"font",
		FONT
	)

	label.add_theme_font_size_override(
		"font_size",
		font_size
	)

	label.add_theme_color_override(
		"font_color",
		Style.TEXT
	)

	return label


func _update() -> void:
	if grid == null:
		return

	if not is_visible_in_tree():
		return


	# ---------------------------------------------------------
	# STATO
	# ---------------------------------------------------------

	reload_button.disabled = (
		manager.loading
		or manager.purchasing
	)

	status.text = ""


	if manager.loading:
		status.text += "\nCARICAMENTO..."

	elif not manager.last_error.is_empty():
		status.text += "\n" + manager.last_error

	elif manager.stale:
		status.text += (
			"\nOFFLINE: DATI DELL'ULTIMA LETTURA, "
			+ "NON AGGIORNATI."
		)

	elif not manager.inventory_ready:
		status.text += "\nIN ATTESA DELL'ACCOUNT."


	status.visible = not status.text.is_empty()


	# ---------------------------------------------------------
	# ITEMS
	# ---------------------------------------------------------

	var items: Array = manager.get_items()

	var snapshot: Array = []


	for item in items:
		snapshot.append(
			[
				item,
				manager.owns_item(item.id)
			]
		)


	# Gli aggiornamenti di rete non ricreano
	# gli elementi già visibili se non è cambiato nulla.
	if snapshot == rendered_items:
		return


	rendered_items = snapshot.duplicate(true)


	# ---------------------------------------------------------
	# PULIZIA GRIGLIA
	# ---------------------------------------------------------

	item_previews.clear()

	for child in grid.get_children():
		grid.remove_child(child)
		child.queue_free()


	# ---------------------------------------------------------
	# CREAZIONE CARTE SHOP
	# ---------------------------------------------------------

	for item in items:

		var panel := PanelContainer.new()

		panel.custom_minimum_size = Vector2(
			280,
			365
		)


		var box_style := Style.button_style(
			Style.PANEL,
			Style.HOVER,
			3
		)

		box_style.bg_color.a = 0.0
		box_style.border_color.a = 0.0
		box_style.shadow_color.a = 0.0

		panel.add_theme_stylebox_override(
			"panel",
			box_style
		)

		grid.add_child(panel)


		# -----------------------------------------------------
		# CONTENUTO CARTA
		# -----------------------------------------------------

		var rows := VBoxContainer.new()

		rows.add_theme_constant_override(
			"separation",
			8
		)

		panel.add_child(rows)


		# -----------------------------------------------------
		# PREVIEW DORSO
		# -----------------------------------------------------

		if (
			str(item.id).begins_with("deck_back_")
			and item.asset_id >= 1
			and item.asset_id <= 12
		):

			var preview := TextureRect.new()

			preview.custom_minimum_size = Vector2(
				0,
				240
			)

			preview.size_flags_vertical = (
				Control.SIZE_EXPAND
				| Control.SIZE_SHRINK_CENTER
			)

			preview.expand_mode = (
				TextureRect.EXPAND_IGNORE_SIZE
			)

			preview.stretch_mode = (
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			)

			preview.texture_filter = (
				CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			)

			preview.texture = get_node(
				"/root/GameSettings"
			).back_texture(
				item.asset_id
			)

			rows.add_child(preview)


			# -------------------------------------------------
			# AREA CLICCABILE
			# -------------------------------------------------

			# Nessun Button invisibile sopra la carta: in questo modo
			# lo ScrollContainer riceve sempre il trascinamento.
			preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

			if not manager.owns_item(item.id) and item.is_available:
				item_previews[str(item.id)] = preview


		# -----------------------------------------------------
		# FOOTER
		# -----------------------------------------------------

		var footer := Control.new()

		footer.custom_minimum_size.y = 80

		rows.add_child(footer)


		var center := CenterContainer.new()

		footer.add_child(center)

		center.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT
		)


		# Alza prezzo / posseduto senza cambiare
		# dimensioni e posizione dell'immagine.
		center.offset_top = -20
		center.offset_bottom = -20


		# -----------------------------------------------------
		# POSSEDUTO
		# -----------------------------------------------------

		if manager.owns_item(item.id):

			var owned := Button.new()

			owned.text = "POSSEDUTO"

			owned.custom_minimum_size = Vector2(
				240,
				54
			)

			owned.mouse_filter = (
				Control.MOUSE_FILTER_IGNORE
			)

			owned.focus_mode = (
				Control.FOCUS_NONE
			)


			owned.add_theme_font_override(
				"font",
				FONT
			)


			owned.add_theme_font_size_override(
				"font_size",
				24
			)


			owned.add_theme_color_override(
				"font_color",
				Style.TEXT
			)


			var pill := Style.button_style(
				Style.NORMAL
			)

			pill.set_corner_radius_all(27)


			owned.add_theme_stylebox_override(
				"normal",
				pill
			)


			center.add_child(owned)


		# -----------------------------------------------------
		# PREZZO
		# -----------------------------------------------------

		else:

			var price_row := HBoxContainer.new()

			price_row.add_theme_constant_override(
				"separation",
				10
			)

			center.add_child(price_row)


			var coin := TextureRect.new()

			coin.custom_minimum_size = Vector2(
				42,
				42
			)

			coin.expand_mode = (
				TextureRect.EXPAND_IGNORE_SIZE
			)

			coin.stretch_mode = (
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			)

			coin.texture_filter = (
				CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			)

			coin.texture = load(
				menu_owner.COINS_ICON_PATH
			)


			price_row.add_child(coin)


			price_row.add_child(
				_label(
					str(item.price),
					38
				)
			)


		# -----------------------------------------------------
		# TOOLTIP
		# -----------------------------------------------------

		panel.tooltip_text = "%s · %s" % [
			item.rarity,
			(
				"Disponibile"
				if item.is_available
				else "Non disponibile"
			)
		]
