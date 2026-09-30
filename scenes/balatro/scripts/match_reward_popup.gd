extends CanvasLayer
## Mostra solo ricevute confermate dal server, mai accrediti calcolati in locale.
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const COIN = preload("res://scenes/balatro/trick_asset/ui_bisca/coin.svg")
const COIN_SOUND = preload("res://scenes/balatro/audio/coin.mp3")
const GameAudio = preload("res://scenes/balatro/scripts/game_audio.gd")
static var seen: Dictionary = {}
var balance_loading := false

static func present(network: Node, receipt: Dictionary) -> void:
	var account: Node = network.get_node("/root/AccountSession")
	var uid := str(receipt.get("user_id", ""))
	var amount := int(receipt.get("amount", 0))
	if uid != account.user_id or uid.is_empty() or amount not in [30, 50]:
		return
	network.reward_seen.rpc_id(1, str(receipt.get("match_id", "")))
	var key := uid + ":" + str(receipt.get("match_id", ""))
	if seen.has(key):
		return
	seen[key] = true
	var cache := ConfigFile.new()
	cache.load("user://bisca_reward_receipts.cfg")
	if cache.has_section_key(uid, str(receipt.match_id)):
		return
	cache.set_value(uid, str(receipt.match_id), true)
	cache.save("user://bisca_reward_receipts.cfg")
	var popup = load("res://scenes/balatro/scripts/match_reward_popup.gd").new()
	network.add_child(popup)
	popup.show_reward(receipt)

func show_reward(receipt: Dictionary) -> void:
	layer = 120
	var account: Node = get_node("/root/AccountSession")
	var uid: String = receipt.user_id
	account.changed.connect(func():
		if account.user_id != uid:
			queue_free())
	# Rilegge il saldo corrente: una ricevuta ritardata non deve annullare acquisti successivi.
	_refresh_balance(uid)
	await _wait_for_match_presentation()
	if account.user_id != uid:
		return
	var shade := ColorRect.new()
	shade.color = Color(0.133333, 0.121569, 0.168627, 0.0)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := Control.new()
	panel.name = "RewardAmount"
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -65)
	panel.size = Vector2(400, 130)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(panel)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(0, 0)
	coin.size = Vector2(130, 130)
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	panel.add_child(coin)
	var number := _label("+%d" % int(receipt.amount), 88)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	number.position = Vector2(145, 0)
	number.size = Vector2(255, 130)
	panel.add_child(number)
	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2.ONE * 0.7
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(shade, "color:a", 0.55, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	await tween.finished
	await get_tree().create_timer(0.6).timeout
	await _animate_coins_to_balance(shade, coin, number, receipt)
	# Prima scompaiono ricompensa e contatore, poi torna visibile la partita.
	var elements_out := create_tween().set_parallel(true)
	for element in shade.get_children():
		if element is CanvasItem:
			elements_out.tween_property(element, "modulate:a", 0.0, 0.2)
	await elements_out.finished
	var exit_tween := create_tween()
	exit_tween.tween_property(shade, "color:a", 0.0, 0.25)
	await exit_tween.finished
	hide()
	if not balance_loading:
		queue_free()

func _wait_for_match_presentation() -> void:
	# Le ricevute possono arrivare mentre la coda degli snapshot anima ancora
	# la perdita delle vite. Non interrompere quella presentazione.
	var host := get_tree().current_scene
	if host == null or host.get_script() != load("res://scenes/balatro/scripts/match_controller.gd"):
		return
	await get_tree().process_frame
	while host.online and not host.menu.visible:
		var match_view = host.online_match
		var eliminated: bool = not host.rules.players.is_empty() and not host.rules.players[0].active
		var finished: bool = host.rules.phase == "finished"
		if not match_view.processing and (eliminated or finished) and match_view.state.get("stage", "") == "turn":
			if finished:
				# Lascia leggere il vincitore prima di sovrapporre la ricompensa.
				var buttons: Control = host.overlay.buttons
				buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
				for button in buttons.get_children():
					if button is Button:
						button.disabled = true
				await get_tree().create_timer(2.0).timeout
				for button in buttons.get_children():
					if button is Button:
						button.disabled = false
				buttons.mouse_filter = Control.MOUSE_FILTER_PASS
			return
		await get_tree().process_frame

func _animate_coins_to_balance(surface: Control, source: TextureRect, amount_label: Label, receipt: Dictionary) -> void:
	var host := get_tree().current_scene
	var original: Control = host.find_child("CoinsCounter", true, false) if host != null else null
	if original == null:
		return
	# Copia solo l'aspetto del contatore HOME; il saldo resta quello del server.
	var stage := Control.new()
	surface.add_child(stage)
	stage.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	# Gli offset sono relativi all'ancora centrale; position invece è assoluta
	# nel genitore e spostava il contatore sopra lo schermo.
	stage.offset_left = -960
	stage.offset_top = -540
	stage.offset_right = 960
	stage.offset_bottom = 540
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var counter := original.duplicate(0) as Control
	if counter.has_meta("safe_edge"):
		counter.remove_meta("safe_edge")
	stage.add_child(counter)
	# La HOME nascosta può lasciare alpha/trasformazioni di uscita sulla copia.
	# Ricostruisci la posizione di riposo e rendi il contatore indipendente.
	var menu_style = preload("res://scenes/balatro/scripts/main_menu.gd")
	counter.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	counter.size = menu_style.COINS_SIZE
	counter.position = Vector2(1920 - menu_style.COINS_RIGHT_MARGIN - counter.size.x, menu_style.COINS_TOP_MARGIN)
	counter.modulate = Color.WHITE
	counter.self_modulate = Color.WHITE
	counter.rotation = 0.0
	counter.show()
	preload("res://scenes/balatro/scripts/safe_edges.gd").attach(counter, true)
	var label := counter.find_child("CoinsAmount", true, false) as Label
	# La ricevuta contiene il saldo DOPO questo premio: 130 - 30 = 100.
	# Il refresh del profilo può essere già arrivato oppure essere ancora in volo.
	var balance := int(receipt.get("credits", 0))
	var start := maxi(0, balance - int(receipt.amount))
	label.text = str(start)
	counter.pivot_offset = counter.size / 2.0
	counter.scale = Vector2.ZERO
	var pop := create_tween()
	pop.tween_property(counter, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await pop.finished
	await get_tree().create_timer(0.45).timeout
	var destination := counter.get_global_transform_with_canvas() * (counter.size / 2.0)
	var origin := source.get_global_transform_with_canvas() * (source.size / 2.0)
	var flight := create_tween().set_parallel(true)
	for index in range(8):
		var token := TextureRect.new()
		token.texture = COIN
		token.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		token.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		token.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		token.size = Vector2(48, 48)
		token.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surface.add_child(token)
		token.position = surface.get_global_transform_with_canvas().affine_inverse() * origin - token.size / 2.0
		var target := surface.get_global_transform_with_canvas().affine_inverse() * destination - token.size / 2.0
		flight.tween_property(token, "position", target, 0.65).set_delay(index * 0.09).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		flight.tween_property(token, "modulate:a", 0.0, 0.12).set_delay(0.58 + index * 0.09)
		flight.tween_callback(func(): GameAudio.play(self, COIN_SOUND)).set_delay(0.65 + index * 0.09)
	flight.tween_property(source, "modulate:a", 0.0, 0.3)
	flight.tween_callback(_animate_counter_gain.bind(counter)).set_delay(0.6)
	flight.tween_method(func(value: float):
		label.text = str(start + roundi(value))
		amount_label.text = "+%d" % (int(receipt.amount) - roundi(value)),
		0.0, float(receipt.amount), 0.75).set_delay(0.6)
	await flight.finished
	# Lascia leggere il nuovo totale prima di far sparire il pulsante.
	await get_tree().create_timer(1.0).timeout

func _animate_counter_gain(counter: Control) -> void:
	# Tre piccoli impulsi mentre il numero sale, poi torna alla scala originale.
	var bounce := create_tween().set_loops(3)
	bounce.tween_property(counter, "scale", Vector2.ONE * 1.06, 0.10).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	bounce.tween_property(counter, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _refresh_balance(uid: String) -> void:
	balance_loading = true
	var account: Node = get_node("/root/AccountSession")
	var http := HTTPRequest.new()
	http.accept_gzip = not OS.has_feature("web")
	http.timeout = 12
	add_child(http)
	if http.request(account.PROJECT_URL + "/rest/v1/bisca_profiles?id=eq." + uid + "&select=credits", account.database_headers()) == OK:
		var response: Array = await http.request_completed
		if response[0] == HTTPRequest.RESULT_SUCCESS and response[1] == 200 and account.user_id == uid:
			var rows = JSON.parse_string(response[3].get_string_from_utf8())
			var profile: Node = get_node("/root/AccountProfile")
			if rows is Array and rows.size() == 1 and profile.profile.get("id", "") == uid:
				profile.profile.credits = rows[0].credits
				profile.changed.emit()
	http.queue_free()
	balance_loading = false
	if not visible:
		queue_free()

func _label(text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("f3effe"))
	return label
