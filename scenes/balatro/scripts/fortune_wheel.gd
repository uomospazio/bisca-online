extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
const WHEEL := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/ruotaUI/"
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1920,884)
# Clockwise sectors from the pointer; graphics do NOT determine probabilities.
const SECTORS := {"crown":[7],"coins_5000":[1],"coins_1000":[3,9],"coins_50":[5,11],"tomato":[4,10],"poop":[2,8],"tissues":[0,6]}
var host: Control
var counter: TextureRect
var back_anchor: Control
var disc: TextureRect
var spin: Button
var coins: Label
var spin_sound: AudioStreamPlayer
var last_tick := -1000
var spinning := false
var spin_duration := 5.5

func setup_wheel(owner_page: Control) -> void:
	host = owner_page
	font = host.ui_font
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	set_meta("cartoon_style_children_excluded",true)
	add_to_group("bisca_wheel_page")
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	_image(composition,WHEEL+"retroRuota.png",Rect2(620,0,680,880))
	disc = TextureRect.new()
	composition.add_child(disc)
	var crop := AtlasTexture.new()
	crop.atlas = load(WHEEL+"ruotaGirevole.png")
	crop.region = Rect2(515,184,1533,1533)
	disc.texture = crop
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.position = Vector2(550,45)
	disc.size = Vector2(820,820)
	disc.pivot_offset = disc.size/2
	disc.mouse_filter = MOUSE_FILTER_IGNORE
	_image(composition,WHEEL+"indicatoreRuota.png",Rect2(860,-4,200,183))
	_image(composition,WHEEL+"premiSX.png",Rect2(100,270,345,364))
	_image(composition,WHEEL+"premiDX.png",Rect2(1490,200,345,496))
	spin = _button(composition,WHEEL+"prezzoRuota.png",Rect2(910,418,100,74),_request_spin)
	spin.tooltip_text = "Guarda un video per girare. Nessun limite giornaliero."
	back_anchor = Control.new()
	add_child(back_anchor)
	back_anchor.mouse_filter = MOUSE_FILTER_IGNORE
	back = _button(back_anchor,UI+"pngUI/InLobbyUI/tastoIndietro.png",Rect2(0,0,108,98),_back_to_shop)
	counter = _image(self,HOME+"contatoreMonete.png",Rect2(0,0,300,110))
	counter.add_to_group("visible_coin_counter")
	coins = _label(counter,"",Rect2(112,18,180,72),40)
	coins.name = "CoinsAmount"
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	spin_sound = AudioStreamPlayer.new()
	add_child(spin_sound)
	spin_sound.stream = preload("res://scenes/balatro/audio/button_click.wav")
	get_node("/root/GameSettings").configure_sfx(spin_sound,-14.0)
	get_node("/root/RewardedAds").changed.connect(_update)
	get_node("/root/AccountProfile").changed.connect(_update)
	get_viewport().size_changed.connect(_fit)
	_fit.call_deferred()
	hide()

func open() -> void:
	host.art_ui.hide()
	show()
	_fit()
	_update()

func _back_to_shop() -> void:
	if spinning or get_node("/root/RewardedAds").busy: return
	hide()
	host.art_ui.show()
	host.art_ui._fit()

func _request_spin() -> void:
	if not spinning:
		get_node("/root/RewardedAds").request_reward("wheel","")

func _update() -> void:
	var ads := get_node("/root/RewardedAds")
	spin.disabled = spinning or ads.busy or (not ads.supported() and not ads.pending_for_account())
	back.disabled = spinning or ads.busy
	coins.text = str(int(get_node("/root/AccountProfile").profile.get("credits",0)))

static func result_text(receipt: Dictionary) -> String:
	if receipt.get("outcome","") == "crown":
		return "MAZZO ORO GIA' POSSEDUTO: +5000 MONETE!" if receipt.get("duplicate",false) else "HAI VINTO IL MAZZO ORO!"
	if int(receipt.get("amount",0)) > 0: return "+%d MONETE!" % int(receipt.amount)
	return "NESSUN PREMIO. RITENTA LA FORTUNA!"

static func play_result(owner: Node, receipt: Dictionary) -> void:
	var outcome := str(receipt.get("outcome",""))
	var index: int = {"tomato":8,"poop":0,"tissues":2}.get(outcome,-1)
	var sound: AudioStream = preload("res://scenes/balatro/scripts/throw_catalog.gd").impact_sound(index) if index>=0 else preload("res://scenes/balatro/audio/winner.mp3")
	preload("res://scenes/balatro/scripts/game_audio.gd").play(owner,sound,0.0)

func present_result(receipt: Dictionary) -> void:
	var outcome := str(receipt.get("outcome",""))
	if not SECTORS.has(outcome): return
	spinning = true
	_update()
	var sector: int = SECTORS[outcome].pick_random()
	disc.rotation_degrees = fposmod(disc.rotation_degrees,360.0)
	var landing := fposmod(-float(sector)*30.0,360.0)
	var delta := fposmod(landing-disc.rotation_degrees,360.0)
	var tween := create_tween()
	tween.tween_method(_rotate_with_sound,disc.rotation_degrees,disc.rotation_degrees+1800.0+delta,spin_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await tween.finished
	spin_sound.stop()
	play_result(self,receipt)
	await get_tree().create_timer(0.6).timeout
	spinning = false
	_update()

func _rotate_with_sound(angle: float) -> void:
	var previous_sector := floori((disc.rotation_degrees+15.0)/30.0)
	disc.rotation_degrees = angle
	var now := Time.get_ticks_msec()
	# Pointer clicks follow sector crossings, slowing down with the wheel.
	if floori((angle+15.0)/30.0) != previous_sector and now-last_tick>=55:
		last_tick = now
		spin_sound.play()

func _layout(bounds: Rect2) -> void:
	var home_size := preload("res://scenes/balatro/scripts/home_art_ui.gd").DESIGN
	var home_factor := minf(bounds.size.x/home_size.x,bounds.size.y/home_size.y)
	counter.position = bounds.get_center()-home_size*home_factor/2+preload("res://scenes/balatro/scripts/home_art_ui.gd").COUNTER_RECT.position*home_factor
	counter.scale = Vector2.ONE*home_factor
	back_anchor.position = bounds.position
	back_anchor.scale = Vector2.ONE*maxf(0.01,minf(bounds.size.x/preload("res://scenes/balatro/scripts/solitaria_ui.gd").SOLO_SIZE.x,bounds.size.y/preload("res://scenes/balatro/scripts/solitaria_ui.gd").SOLO_SIZE.y))
	var factor := minf(bounds.size.x/DESIGN.x,bounds.size.y/DESIGN.y)
	composition.scale = Vector2.ONE*factor
	composition.position = bounds.get_center()-DESIGN*factor/2

