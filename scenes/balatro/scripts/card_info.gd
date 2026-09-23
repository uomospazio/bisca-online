extends CanvasLayer

const Style = preload("res://scenes/balatro/scripts/lexispell_style.gd")
const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
var host: Control
var paused_here := false
var close_button: Button

func setup(controller: Control) -> void:
	host = controller
	layer = 106
	process_mode = Node.PROCESS_MODE_ALWAYS
	var screen := Control.new()
	add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	screen.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.082353, 0.207843, 0.211765, 0.75)
	shade.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	var panel := PanelContainer.new()
	screen.add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -650
	panel.offset_top = -340
	panel.offset_right = 650
	panel.offset_bottom = 340
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var style := Style.button_style(Style.NORMAL, Style.HOVER, 4)
	style.content_margin_left = 40
	style.content_margin_right = 40
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	panel.add_child(column)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.custom_minimum_size.y = 490
	text.add_theme_font_override("normal_font", FONT)
	text.add_theme_font_size_override("normal_font_size", 27)
	text.add_theme_color_override("default_color", Style.TEXT)
	text.text = "[center][font_size=42]INFO[/font_size][/center]\n\nSEMI: DAL PIU' FORTE\n\nDENARI > COPPE > SPADE > BASTONI\nSTESSO SEME: VINCE IL NUMERO PIU' ALTO\n\nJOLLY = ASSO DI DENARI\n\nLA PIU' ALTA: batte tutti.\nLA PIU' BASSa: perde contro tutti."
	column.add_child(text)
	close_button = host.menu._button(column, "CHIUDI", close)
	close_button.custom_minimum_size.y = 70
	host.game_ui.visibility_changed.connect(func():
		if not host.game_ui.visible:
			close()
	)
	hide()

func open() -> void:
	if visible or host.menu.visible or host.loading_screen.busy or host.pause_menu.visible:
		return
	for card in host.hand.cards:
		if card.following_mouse:
			card._finish_drag(true)
	paused_here = not host.online and not get_tree().paused
	if paused_here:
		get_tree().paused = true
	show()
	close_button.grab_focus_silent()

func close() -> void:
	hide()
	if paused_here:
		get_tree().paused = false
	paused_here = false

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if paused_here:
		get_tree().paused = false
