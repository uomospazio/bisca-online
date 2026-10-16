extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
const GAME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/inGameUI/"
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1920,884)
var flow: Node
var coin: TextureRect
var amount: Label
var xp: Label
var ad_button: Button
var continue_button: Button
var message: Label

func setup_result(owner_flow: Node) -> void:
	flow = owner_flow
	set_meta("cartoon_style_children_excluded",true)
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	font = preload("res://scenes/balatro/fonts/Comic Lemon.otf").duplicate() as FontFile
	font.multichannel_signed_distance_field = true
	font.msdf_size = 64
	get_viewport().size_changed.connect(_fit)

func render(_rooms: Array = []) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var bg := TextureRect.new()
	add_child(bg)
	bg.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = MOUSE_FILTER_IGNORE
	if flow.final_screen and (not flow.solo or flow.won):
		bg.texture = load(HOME+"sfondoViola.png")
	else:
		var shade := ColorRect.new()
		add_child(shade)
		shade.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
		shade.color = Color(0,0,0,0.6)
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	var rewards_visible: bool = flow.solo or not flow.base_done()
	if flow.solo:
		if flow.won:
			_image(composition,GAME+"crownVincente.png",Rect2(885,95,150,105)).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var title := _label(composition,"HAI VINTO" if flow.won else "SEI STATO ELIMINATO",Rect2(160,235,1600,120),90)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elif flow.final_screen:
		_draw_podium()
	else:
		var title := _label(composition,"SEI STATO ELIMINATO",Rect2(110,220,1700,140),88)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var reward_y := 510.0 if flow.final_screen and not flow.solo else 395.0
	var reward_row := Control.new()
	composition.add_child(reward_row)
	reward_row.position = Vector2(590,reward_y)
	reward_row.size = Vector2(740,120)
	reward_row.visible = rewards_visible
	xp = _label(reward_row,"+%d" % flow.points(),Rect2(0,12,160,90),65)
	xp.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_image(reward_row,GAME+"xpStagionali.png",Rect2(175,0,110,110))
	amount = _label(reward_row,"+%d" % flow.coins(),Rect2(360,12,160,90),65)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coin = _image(reward_row,UI+"coin.png",Rect2(540,0,110,110))
	if flow.solo:
		ad_button = _button(composition,GAME+"riscatta.png",Rect2(670,565,580,148),flow.watch_ad)
		continue_button = _text_button("CONTINUA SENZA PREMI",Rect2(580,755,760,70),flow.skip)
	elif not flow.final_screen:
		ad_button = _button(composition,GAME+"guardaVideo.png",Rect2(755,560,410,152),flow.watch_ad)
		continue_button = _text_button("NON ORA",Rect2(760,755,400,70),flow.skip)
	else:
		continue_button = _button(composition,GAME+"ok.png",Rect2(840,735,240,94),flow.skip)
		ad_button = _button(composition,HOME.replace("homeUI/","shopUI/")+"guadagnaMonete.png",
			Rect2(1640,655,190,190) if rewards_visible else Rect2(865,535,190,170),flow.watch_ad)
	message = _label(composition,"",Rect2(310,835,1300,46),24)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_fit()
	refresh()

func _text_button(text: String, rect: Rect2, callback: Callable) -> Button:
	var button := Button.new()
	composition.add_child(button)
	button.position = rect.position
	button.size = rect.size
	button.text = text
	button.add_theme_font_override("font",font)
	button.add_theme_font_size_override("font_size",34)
	for state in ["normal","hover","pressed","disabled","focus"]:
		button.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	button.pressed.connect(callback)
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(button)
	return button

func _draw_podium() -> void:
	for i in mini(3,flow.podium.size()):
		var entry: Dictionary = flow.podium[i]
		var x: float = [960,650,1270][i]
		var size: float = 180.0 if i==0 else 112.0
		var y: float = 255.0 if i==0 else 325.0
		var portrait := TextureRect.new()
		composition.add_child(portrait)
		portrait.texture = entry.get("avatar")
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.position = Vector2(x-size/2,y)
		portrait.size = Vector2(size,size)
		if i==0:
			_image(composition,GAME+"crownVincente.png",Rect2(x-75,135,150,105)).stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		else:
			var rank := _label(composition,"%d°" % (i+1),Rect2(x-45,y-65,90,50),30)
			rank.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var name_label := _label(composition,str(entry.get("name","")),Rect2(x-190,445,380,60),40 if i==0 else 29)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		name_label.clip_text = true

func refresh() -> void:
	if not is_instance_valid(ad_button): return
	var ads := get_node("/root/RewardedAds")
	var ready: bool = flow.solo or flow.base_done() or not flow.receipt.is_empty()
	continue_button.disabled = flow.busy or not ready
	ad_button.disabled = flow.busy or ads.busy or not ready or ads.claimed(flow.placement(),flow.match_id) or (not ads.supported() and not ads.pending_for_account())
	ad_button.modulate.a = 0.45 if ad_button.disabled else 1.0
	message.text = "Sincronizzazione premi..." if not ready else flow.error_message

func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(composition): return
	var factor := minf(bounds.size.x/DESIGN.x,bounds.size.y/DESIGN.y)
	composition.scale = Vector2.ONE*factor
	composition.position = bounds.get_center()-DESIGN*factor/2

