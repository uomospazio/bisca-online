extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
const SHOP := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/shopUI/"
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1920,884)
var host: Control
var counter: TextureRect
var back_anchor: Control
var countdown: Label
var video: Button
var reroll: Button
var wheel: Button
var reward_caption: Label
var last_daily_attempt := -30000
var entrance := preload("res://scenes/balatro/scripts/page_pop.gd").new()

func pop_in() -> void:
	entrance.play(self,_fit)

func setup_shop(owner_page: Control) -> void:
	host = owner_page
	font = host.ui_font
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_IGNORE
	set_meta("cartoon_style_children_excluded",true)
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	host.content = composition
	_image(composition,SHOP+"slotShop.png",Rect2(80,200,1760,636))
	host.grid = Control.new()
	composition.add_child(host.grid)
	host.grid.position = Vector2(80,200)
	host.grid.size = Vector2(1760,636)
	host.grid.mouse_filter = MOUSE_FILTER_IGNORE
	var clock_art := _image(composition,SHOP+"tempoRimanente.png",Rect2(746,42,426,129))
	countdown = _label(clock_art,"--:--:--",Rect2(120,65,290,42),34)
	countdown.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	counter = _image(self,HOME+"contatoreMonete.png",Rect2(0,0,300,110))
	counter.add_to_group("visible_coin_counter")
	host.coins_amount = _label(counter,host.menu_owner.coins_label.text,Rect2(112,18,180,72),40)
	host.coins_amount.name = "CoinsAmount"
	host.coins_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back_anchor = Control.new()
	add_child(back_anchor)
	back_anchor.mouse_filter = MOUSE_FILTER_IGNORE
	back = _button(back_anchor,UI+"pngUI/InLobbyUI/tastoIndietro.png",Rect2(0,0,108,98),host.menu_owner._leave_shop)
	var support := _button(composition,UI+"coffee.png",Rect2(130,570,200,190),host.menu_owner._show_support_creator)
	support.tooltip_text = "Supporta il creatore"
	video = _button(composition,SHOP+"guadagnaMonete.png",Rect2(140,260,180,180),func(): _request("shop"),false)
	video.tooltip_text = "Guarda un annuncio: +50 monete"
	var reward_width := ceilf(font.get_string_size("+50",HORIZONTAL_ALIGNMENT_LEFT,-1,34).x)
	var reward_left := 230.0-(reward_width+6.0+36.0)/2.0
	reward_caption = _label(composition,"+50",Rect2(reward_left,442,reward_width,48),34)
	reward_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_image(composition,UI+"coin.png",Rect2(reward_left+reward_width+6.0,448,36,36))
	reroll = _button(composition,SHOP+"rerollShop.png",Rect2(1580,260,185,180),func(): _request("refresh"),false)
	for button in [video,reroll]:
		button.set_meta("hover_when_disabled",true)
		button.set_meta("touch_hover",true)
		preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(button)
	reroll.tooltip_text = "Cambia le sei offerte con un annuncio"
	wheel = _button(composition,SHOP+"ruotaFortuna.png",Rect2(1570,552,210,210),host.open_wheel)
	wheel.tooltip_text = "Ruota della fortuna"
	host.fixed_controls.assign([back,counter,support,video,reroll,wheel])
	host.status = _label(composition,"",Rect2(380,842,1160,40),18)
	host.status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	host.status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	get_node("/root/RewardedAds").changed.connect(update_ads)
	get_node("/root/ShopManager").changed.connect(update_ads)
	var timer := Timer.new()
	add_child(timer)
	timer.wait_time = 1
	timer.timeout.connect(_tick)
	timer.start()
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()
	update_ads()

func _request(placement: String) -> void:
	get_node("/root/RewardedAds").request_reward(placement,"")

func update_ads() -> void:
	var ads := get_node("/root/RewardedAds")
	var pending: bool = ads.pending_for_account()
	back.disabled = ads.busy
	wheel.disabled = ads.busy
	video.disabled = ads.busy or (not ads.supported() and not pending)
	var reroll_used: bool = not host.manager.daily_refresh_available
	reroll.disabled = ads.busy or reroll_used or (not pending and not ads.supported())
	reroll.modulate = Color(0.45,0.45,0.45,0.65) if reroll_used else Color.WHITE
	reroll.set_meta("hover_when_disabled",not reroll_used)
	if reroll_used: reroll.mouse_exited.emit()
	reroll.tooltip_text = "Refresh gia' usato oggi" if reroll_used else "Cambia le sei offerte con un annuncio"
	video.tooltip_text = "Recupera premio in sospeso" if pending else "Guarda un annuncio: +50 monete"
	host._update()

func _tick() -> void:
	if not is_visible_in_tree(): return
	var remaining: int = host.manager.daily_seconds_remaining()
	countdown.text = "%02d:%02d:%02d" % [remaining/3600,(remaining/60)%60,remaining%60] if remaining>0 else "--:--:--"
	if remaining == 0 and Time.get_ticks_msec()-last_daily_attempt>=30000:
		last_daily_attempt = Time.get_ticks_msec()
		host.manager.refresh_daily()

func _layout(bounds: Rect2) -> void:
	var home_size := preload("res://scenes/balatro/scripts/home_art_ui.gd").DESIGN
	var home_factor := minf(bounds.size.x/home_size.x,bounds.size.y/home_size.y)
	counter.position = bounds.get_center()-home_size*home_factor/2+preload("res://scenes/balatro/scripts/home_art_ui.gd").COUNTER_RECT.position*home_factor
	counter.scale = Vector2.ONE*home_factor
	back_anchor.position = bounds.position
	back_anchor.scale = Vector2.ONE*maxf(0.01,minf(bounds.size.x/preload("res://scenes/balatro/scripts/solitaria_ui.gd").SOLO_SIZE.x,bounds.size.y/preload("res://scenes/balatro/scripts/solitaria_ui.gd").SOLO_SIZE.y))
	var factor := minf(bounds.size.x/DESIGN.x,bounds.size.y/DESIGN.y)
	factor *= entrance.amount
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center()-DESIGN*factor/2
