extends Control
signal refreshed(snapshot: Dictionary)
const UI := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/AmiciUI/"
var page: Control
var rows: VBoxContainer
var heading: Label
var countdown: Label
var mine: Label
var snapshot: Dictionary = {}
var busy := false
var deadline := 0
var timer: Timer
var last_refresh := -30000

func setup(friends: Control) -> void:
	page = friends
	size = Vector2(652,800)
	mouse_filter = MOUSE_FILTER_IGNORE
	heading = _label("CLASSIFICA STAGIONALE", Rect2(100,187,510,42), 26)
	countdown = _label("Caricamento...", Rect2(60,229,540,36), 24)
	var info := Button.new()
	add_child(info)
	info.position = Vector2(50,190)
	info.size = Vector2(44,44)
	for state in ["normal","hover","pressed","disabled","focus"]:
		var skin := StyleBoxTexture.new()
		skin.texture = load(UI + "infoClassifica.png")
		info.add_theme_stylebox_override(state,skin)
	info.pressed.connect(_info)
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(info)
	var scroll := preload("res://scenes/balatro/scripts/touch_scroll.gd").new()
	add_child(scroll)
	scroll.position = Vector2(50,284)
	scroll.size = Vector2(550,430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows = VBoxContainer.new()
	rows.size_flags_horizontal = SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",12)
	scroll.add_child(rows)
	mine = _label("",Rect2(50,731,550,40),23)
	timer = Timer.new()
	add_child(timer)
	timer.wait_time = 1
	timer.timeout.connect(_tick)
	timer.start()
	visibility_changed.connect(func():
		if is_visible_in_tree():
			_tick()
			refresh())

func _label(text: String, rect: Rect2, font_size: int, parent: Node = null) -> Label:
	var value: Label = page.label(text, self if parent == null else parent)
	value.position = rect.position
	value.size = rect.size
	value.add_theme_font_size_override("font_size",font_size)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return value

func refresh() -> void:
	if busy: return
	busy = true
	last_refresh = Time.get_ticks_msec()
	var identity := str(get_node("/root/AccountSession").user_id)
	var result: Dictionary = await page.manager.call_api("bisca_season_board")
	busy = false
	if identity != str(get_node("/root/AccountSession").user_id): return
	if not result.get("ok", false) or not result.get("data") is Dictionary:
		reset()
		countdown.text = "Classifica non disponibile"
		return
	apply_snapshot(result.data)

func reset() -> void:
	snapshot = {}
	deadline = 0
	heading.text = "CLASSIFICA STAGIONALE"
	countdown.text = "Caricamento..."
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	mine.text = ""
	refreshed.emit(snapshot)

func apply_snapshot(value: Dictionary) -> void:
	reset()
	snapshot = value
	var season = snapshot.get("season")
	if not season is Dictionary:
		countdown.text = "Nessuna stagione disponibile"
		refreshed.emit(snapshot)
		return
	heading.text = "CLASSIFICA " + str(season.get("name", ""))
	deadline = Time.get_ticks_msec() + int(float(season.get("remaining",0)) * 1000)
	# The server returns our unique rank in this same snapshot, even without a username.
	var own = snapshot.get("own")
	var own_rank := int(own.get("rank",0)) if own is Dictionary else 0
	for entry in snapshot.get("entries",[]):
		var rank := int(entry.get("rank",0))
		var is_self := own_rank > 0 and rank == own_rank
		var row := Panel.new()
		row.custom_minimum_size = Vector2(0,76)
		rows.add_child(row)
		var style := StyleBoxFlat.new()
		style.bg_color = Color("30265D") if is_self else Color("1D1A48")
		style.border_color = Color("FFE66A") if is_self else Color("8968E9")
		style.set_border_width_all(4 if is_self else 2)
		style.set_corner_radius_all(15)
		row.add_theme_stylebox_override("panel",style)
		if rank == 1: _image(row,UI+"Crown.png",Rect2(12,16,50,44))
		else: _label(str(rank),Rect2(12,16,50,44),28,row)
		var avatar := TextureRect.new()
		row.add_child(avatar)
		avatar.position = Vector2(76,17)
		avatar.size = Vector2(42,42)
		avatar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		avatar.texture = preload("res://scenes/balatro/scripts/avatar_data.gd").circular_texture(str(entry.get("avatar","")))
		if avatar.texture == null:
			avatar.texture = preload("res://scenes/balatro/scripts/avatar_data.gd").circular_texture(preload("res://scenes/balatro/scripts/avatar_catalog.gd").encoded(0))
		var username = entry.get("username")
		var name_text := str(username) if username != null and not str(username).is_empty() else "#"+str(entry.get("public_id",""))
		var name_label := _label(name_text,Rect2(125,17,230,42),23,row)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		if is_self:
			name_label.add_theme_color_override("font_color",Color("FFE66A"))
		_image(row,UI+"contatorePunti.png",Rect2(365,16,165,46))
		_label(str(entry.get("points",0)),Rect2(417,18,106,42),24,row)
	mine.text = "TU: #%s · %s PUNTI" % [own.get("rank",0),own.get("points",0)] if own is Dictionary else "Non ancora in classifica"
	if rows.get_child_count() == 0:
		var empty := Label.new()
		empty.text = "Nessun punteggio registrato"
		empty.add_theme_font_size_override("font_size",24)
		rows.add_child(empty)
	_tick()
	refreshed.emit(snapshot)

func _image(parent: Node,path: String,rect: Rect2) -> void:
	var image := TextureRect.new()
	parent.add_child(image)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.texture = load(path)
	image.position = rect.position
	image.size = rect.size
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = MOUSE_FILTER_IGNORE

func _tick() -> void:
	if not is_visible_in_tree() or deadline == 0: return
	var seconds := maxi(0,(deadline-Time.get_ticks_msec())/1000)
	countdown.text = "%dg %02d:%02d:%02d" % [seconds/86400,(seconds/3600)%24,(seconds/60)%60,seconds%60] if seconds>0 else "Stagione terminata"
	if Time.get_ticks_msec() - last_refresh >= 30000: refresh()

func _info() -> void:
	var dialog := preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	dialog.title = "PREMI CLASSIFICA"
	var season = snapshot.get("season",{})
	var prizes: Array = season.get("rewards",[5000,2000,1000,900,800,700,600,500,400,300]) if season is Dictionary else [5000,2000,1000,900,800,700,600,500,400,300]
	var text := ""
	for i in prizes.size(): text += "%d: %d monete%s" % [i+1,prizes[i],"\n\n" if i%2==1 else "     "]
	dialog.dialog_text = text
	dialog.ok_button_text = "OK"
	page.add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.popup_centered(Vector2i(1000,560))
	# This is an informational notice, not a confirmation with two choices.
	dialog.get_cancel_button().hide()
