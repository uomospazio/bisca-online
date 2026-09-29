extends CanvasLayer
## Mostra solo ricevute confermate dal server, mai accrediti calcolati in locale.
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
const COIN = preload("res://scenes/balatro/trick_asset/ui_bisca/coin.svg")
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
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-350, -220)
	panel.size = Vector2(700, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("2e2748")
	style.border_color = Color("8976c5")
	style.set_border_width_all(4)
	style.set_corner_radius_all(32)
	panel.add_theme_stylebox_override("panel", style)
	shade.add_child(panel)
	var title := _label("VITTORIA!" if receipt.outcome == "victory" else "PARTITA CONCLUSA", 38)
	title.position = Vector2(20, 35)
	title.size = Vector2(660, 60)
	panel.add_child(title)
	var coin := TextureRect.new()
	coin.texture = COIN
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin.position = Vector2(165, 140)
	coin.size = Vector2(110, 110)
	panel.add_child(coin)
	var number := _label("+0", 76)
	number.position = Vector2(280, 140)
	number.size = Vector2(240, 110)
	panel.add_child(number)
	var subtitle := _label("MONETE ACCREDITATE", 25)
	subtitle.position = Vector2(20, 265)
	subtitle.size = Vector2(660, 45)
	panel.add_child(subtitle)
	var close := Button.new()
	close.text = "CONTINUA"
	close.add_theme_font_override("font", FONT)
	close.add_theme_font_size_override("font_size", 30)
	close.position = Vector2(190, 335)
	close.size = Vector2(320, 70)
	var button_style := style.duplicate() as StyleBoxFlat
	button_style.bg_color = Color("493b72")
	button_style.set_corner_radius_all(35)
	close.add_theme_stylebox_override("normal", button_style)
	close.pressed.connect(func():
		hide()
		if not balance_loading:
			queue_free())
	panel.add_child(close)
	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2.ONE * 0.7
	panel.modulate.a = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_method(func(value: float): number.text = "+%d" % roundi(value), 0.0, float(receipt.amount), 0.9).set_delay(0.2)

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
