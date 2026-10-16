extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
const SHOP := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/shopUI/"
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1920,884)
var host: Control
var countdown: Label
var video: Button
var reroll: Button
var wheel: Button
var reward_caption: Label
var last_daily_attempt := -30000

func setup_shop(owner_page: Control) -> void:
	host = owner_page
	font = host.FONT
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
	var counter := _image(composition,HOME+"contatoreMonete.png",Rect2(1570,40,300,110))
	host.coins_amount = _label(counter,host.menu_owner.coins_label.text,Rect2(112,18,180,72),40)
	host.coins_amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	back = _button(composition,UI+"pngUI/InLobbyUI/tastoIndietro.png",Rect2(40,45,104,96),host.menu_owner._leave_shop)
	var support := _button(composition,UI+"coffee.png",Rect2(130,570,200,190),host.menu_owner._show_support_creator)
	support.tooltip_text = "Supporta il creatore"
	video = _button(composition,SHOP+"guadagnaMonete.png",Rect2(140,260,180,180),func(): _request("shop"))
	video.tooltip_text = "Guarda un annuncio: +50 monete"
	reward_caption = _label(composition,"+50",Rect2(145,442,115,48),34)
	reward_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_image(composition,UI+"coin.png",Rect2(270,448,36,36))
	reroll = _button(composition,SHOP+"rerollShop.png",Rect2(1580,260,185,180),func(): _request("refresh"))
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
	reroll.disabled = ads.busy or (not pending and (not ads.supported() or not host.manager.daily_refresh_available))
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
	var factor := minf(bounds.size.x/DESIGN.x,bounds.size.y/DESIGN.y)
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center()-DESIGN*factor/2
