extends VBoxContainer
const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const KIDS_FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
var placement := "shop"
var context := ""
var caption := "VIDEO · +20 MONETE"
var button: Button
var status: Label
var ads: Node

func _ready() -> void:
	ads = get_node("/root/RewardedAds")
	add_theme_constant_override("separation", 8)
	button = preload("res://scenes/balatro/scripts/rounded_square_button.gd").new()
	button.custom_minimum_size = Vector2(350, 64)
	button.icon = load("res://scenes/balatro/trick_asset/ui_bisca/ad.svg")
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 34)
	button.add_theme_font_override("font", KIDS_FONT)
	button.add_theme_font_size_override("font_size", 24)
	button.add_theme_color_override("font_color", Style.TEXT)
	button.add_theme_color_override("font_hover_color", Style.TEXT)
	button.add_theme_stylebox_override("normal", Style.button_style(Style.NORMAL, Color.TRANSPARENT, 0, 64))
	button.add_theme_stylebox_override("hover", Style.button_style(Style.HOVER, Style.TEXT, 4, 64))
	button.add_theme_stylebox_override("pressed", Style.button_style(Style.NORMAL, Style.TEXT, 2, 64))
	add_child(button)
	status = Label.new()
	status.add_theme_font_override("font", KIDS_FONT)
	status.add_theme_font_size_override("font_size", 18)
	status.add_theme_color_override("font_color", Style.TEXT)
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(status)
	button.pressed.connect(func(): ads.request_reward(placement, context))
	ads.changed.connect(_update)
	get_node("/root/ShopManager").changed.connect(_update)
	_update()

func _update() -> void:
	var pending: bool = ads.pending_for_account()
	var used: bool = ads.claimed(placement, context)
	if placement == "refresh": used = not get_node("/root/ShopManager").daily_refresh_available
	var clean_caption := caption.replace("VIDEO · ", "")
	button.text = "RECUPERA PREMIO" if pending else ("PREMIO GIÀ RICEVUTO" if used and placement != "refresh" else clean_caption)
	button.disabled = ads.busy or (used and not pending) or (not ads.supported() and not pending)
	status.text = ads.message
	if status.text.is_empty():
		status.text = "Annuncio facoltativo · test" if ads.supported() else "Disponibile su Android e iOS"
	if placement == "refresh" and used and not pending and not ads.busy:
		status.text = "Un refresh al giorno · reset 00:00 UTC"
