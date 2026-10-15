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
var confirmation: Control

func setup(controller: Control) -> void:
	host = controller
	layer = 105
	process_mode = Node.PROCESS_MODE_ALWAYS
	var surface := Control.new()
	add_child(surface)
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	surface.add_child(shade)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.08, 0.06, 0.16, 0.6)
	screen = Control.new()
	surface.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	actions = preload("res://scenes/balatro/scripts/in_game_settings_ui.gd").new()
	screen.add_child(actions)
	actions.setup_pause(self)
	restart_button = actions.restart_button
	continue_button = actions.continue_button
	notice = actions.status
	hide()

func open() -> void:
	if visible or host.menu.visible or host.loading_screen.busy:
		return
	paused_singleplayer = not host.online
	for card in host.hand.cards:
		if card.following_mouse:
			card._finish_drag(true)
	if paused_singleplayer:
		get_tree().paused = true
	if is_instance_valid(settings_page):
		settings_page.hide()
	actions.show()
	show()
	actions.open(not paused_singleplayer)
	restart_button = actions.restart_button
	continue_button = actions.continue_button
	notice = actions.status
	continue_button.grab_focus()

func close() -> void:
	var questions := screen.get_node_or_null("BiscaAssistant")
	if questions: questions.hide()
	_cancel_confirmation()
	if screen.has_meta("page_transition_cleanup"):
		screen.get_meta("page_transition_cleanup").call()
	hide()
	if paused_singleplayer:
		get_tree().paused = false
	paused_singleplayer = false

func _show_settings() -> void:
	actions.show()

func _show_actions() -> void:
	actions.show()

func _cancel_confirmation() -> void:
	if is_instance_valid(confirmation):
		confirmation.hide()
		confirmation.queue_free()
	confirmation = null
	if is_instance_valid(actions):
		actions.show()
		continue_button.grab_focus()

func _confirm_leave(restart: bool) -> void:
	if is_instance_valid(confirmation):
		return
	actions.hide()
	confirmation = preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	confirmation.title = "RIAVVIARE LA PARTITA?" if restart else "ABBANDONARE LA PARTITA?"
	confirmation.ok_button_text = "RIAVVIA" if restart else "ABBANDONA"
	confirmation.cancel_button_text = "ANNULLA"
	screen.add_child(confirmation)
	confirmation.canceled.connect(_cancel_confirmation)
	confirmation.confirmed.connect(_leave.bind(restart))
	confirmation.popup_centered(Vector2i(900, 360))
	confirmation.get_cancel_button().grab_focus()

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
		var questions := screen.get_node_or_null("BiscaAssistant")
		if visible and questions and questions.is_visible_in_tree():
			questions._unhandled_key_input(event)
			return
		if visible:
			if is_instance_valid(confirmation):
				_cancel_confirmation()
			elif is_instance_valid(settings_page) and settings_page.visible:
				_show_actions()
			else:
				close()
		else:
			open()
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if paused_singleplayer:
		get_tree().paused = false
