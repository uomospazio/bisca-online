extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
const WHEEL := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/ruotaUI/"
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const DESIGN := Vector2(1920,884)
# Clockwise sectors from the pointer; graphics do NOT determine probabilities.
const SECTORS := {"crown":[7],"coins_5000":[1],"coins_1000":[3,9],"coins_50":[5,11],"tomato":[4,10],"poop":[2,8],"tissues":[0,6]}
var host: Control
var disc: TextureRect
var spin: Button
var coins: Label
var status: Label
var spinning := false
var spin_duration := 5.5

func setup_wheel(owner_page: Control) -> void:
	host = owner_page
	font = host.FONT
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	set_meta("cartoon_style_children_excluded",true)
	add_to_group("bisca_wheel_page")
	composition = Control.new()
	add_child(composition)
	composition.size = DESIGN
	composition.mouse_filter = MOUSE_FILTER_IGNORE
	_image(composition,WHEEL+"retroRuota.png",Rect2(640,40,640,828))
	disc = TextureRect.new()
	composition.add_child(disc)
	var crop := AtlasTexture.new()
	crop.atlas = load(WHEEL+"ruotaGirevole.png")
	crop.region = Rect2(515,184,1533,1533)
	disc.texture = crop
	disc.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	disc.position = Vector2(575,90)
	disc.size = Vector2(770,770)
	disc.pivot_offset = disc.size/2
	disc.mouse_filter = MOUSE_FILTER_IGNORE
	_image(composition,WHEEL+"indicatoreRuota.png",Rect2(865,18,190,174))
	_image(composition,WHEEL+"premiSX.png",Rect2(100,270,345,364))
	_image(composition,WHEEL+"premiDX.png",Rect2(1490,200,345,496))
	spin = _button(composition,WHEEL+"prezzoRuota.png",Rect2(914,441,92,68),_request_spin)
	spin.tooltip_text = "Guarda un video per girare. Nessun limite giornaliero."
	back = _button(composition,UI+"pngUI/InLobbyUI/tastoIndietro.png",Rect2(40,45,104,96),_back_to_shop)
	var counter := _image(composition,HOME+"contatoreMonete.png",Rect2(1570,40,300,110))
	coins = _label(counter,"",Rect2(112,18,180,72),40)
	coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status = _label(composition,"",Rect2(270,865,1380,34),21)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	if not spinning: status.text = ads.message

static func result_text(receipt: Dictionary) -> String:
	if receipt.get("outcome","") == "crown":
		return "MAZZO ORO GIA' POSSEDUTO" if receipt.get("duplicate",false) else "HAI VINTO IL MAZZO ORO!"
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
	status.text = "LA RUOTA GIRA..."
	var sector: int = SECTORS[outcome].pick_random()
	disc.rotation_degrees = fposmod(disc.rotation_degrees,360.0)
	var landing := fposmod(-float(sector)*30.0,360.0)
	var delta := fposmod(landing-disc.rotation_degrees,360.0)
	var tween := create_tween()
	tween.tween_property(disc,"rotation_degrees",disc.rotation_degrees+1800.0+delta,spin_duration).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	await tween.finished
	play_result(self,receipt)
	status.text = result_text(receipt)
	await get_tree().create_timer(0.6).timeout
	spinning = false
	_update()
	status.text = result_text(receipt)

func _layout(bounds: Rect2) -> void:
	var factor := minf(bounds.size.x/DESIGN.x,bounds.size.y/DESIGN.y)
	composition.scale = Vector2.ONE*factor
	composition.position = bounds.get_center()-DESIGN*factor/2

