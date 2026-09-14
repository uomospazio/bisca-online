extends CanvasLayer

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
var host: Control
var screen: Control
var actions: Control
var settings_page: Control
var restart_button: Button
var continue_button: Button
var notice: Label
var paused_singleplayer := false

func setup(controller: Control) -> void:
	host = controller
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen = Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.19, 0.19, 0.27, 0.85)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	actions = Control.new()
	screen.add_child(actions)
	actions.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := RichTextLabel.new()
	actions.add_child(title)
	title.position = Vector2(460, 180)
	title.size = Vector2(1000, 140)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title.bbcode_enabled = true
	title.text = "[wave amp=25.0 freq=5.0 connected=1]PAUSE[/wave]"
	title.scroll_active = false
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("normal_font", FONT)
	title.add_theme_font_size_override("normal_font_size", 62)
	title.add_theme_color_override("default_color", Style.TEXT)
	title.add_theme_color_override("font_outline_color", Style.HOVER)
	title.add_theme_constant_override("outline_size", 12)
	notice = Label.new()
	actions.add_child(notice)
	notice.position = Vector2(360, 305)
	notice.size = Vector2(1200, 65)
	notice.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice.add_theme_font_override("font", FONT)
	notice.add_theme_font_size_override("font_size", 24)
	notice.add_theme_color_override("font_color", Style.TEXT)
	var buttons := VBoxContainer.new()
	actions.add_child(buttons)
	buttons.position = Vector2(710, 410)
	buttons.size.x = 500
	buttons.add_theme_constant_override("separation", 24)
	continue_button = host.menu._button(buttons, "CONTINUE", close)
	host.menu._button(buttons, "SETTINGS", _show_settings)
	restart_button = host.menu._button(buttons, "RESTART", func(): _leave(true))
	var quit_button: Button = host.menu._button(buttons, "QUIT", func(): _leave(false))
	quit_button.add_theme_stylebox_override("normal", Style.button_style(Color(0.89, 0.3204, 0.3204)))
	hide()

func open() -> void:
	if visible or host.menu.visible or host.loading_screen.busy:
		return
	paused_singleplayer = not host.online
	for card in host.hand.cards:
		if card.following_mouse:
			card._finish_drag(true)
	restart_button.visible = paused_singleplayer
	notice.text = "PARTITA IN PAUSA" if paused_singleplayer else "MULTIPLAYER: LA PARTITA E IL TIMER CONTINUANO"
	if paused_singleplayer:
		get_tree().paused = true
	if is_instance_valid(settings_page):
		settings_page.hide()
	actions.show()
	show()
	actions.modulate.a = 0.0
	create_tween().tween_property(actions, "modulate:a", 1.0, 0.2)
	continue_button.grab_focus_silent()

func close() -> void:
	if screen.has_meta("page_transition_cleanup"):
		screen.get_meta("page_transition_cleanup").call()
	hide()
	if paused_singleplayer:
		get_tree().paused = false
	paused_singleplayer = false

func _show_settings() -> void:
	if not is_instance_valid(settings_page):
		settings_page = preload("res://scenes/balatro/scripts/settings_page.gd").new()
		screen.add_child(settings_page)
		settings_page.setup(host.menu, _show_actions, host.online)
	preload("res://scenes/balatro/scripts/page_transition.gd").slide(screen, actions, settings_page)

func _show_actions() -> void:
	preload("res://scenes/balatro/scripts/page_transition.gd").slide(screen, settings_page, actions, true)

func _leave(restart: bool) -> void:
	close()
	if host.online:
		host.get_node("/root/NetworkSession").leave()
	if restart:
		get_tree().set_meta("bisca_restart", {"name": host.local_name, "count": host.player_count, "joker": host.rules.force_local_joker})
	# A fresh scene cancels the old deal/bot/animation coroutines safely.
	get_tree().reload_current_scene()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if visible:
			if is_instance_valid(settings_page) and settings_page.visible:
				_show_actions()
			else:
				close()
		else:
			open()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if paused_singleplayer:
		get_tree().paused = false
