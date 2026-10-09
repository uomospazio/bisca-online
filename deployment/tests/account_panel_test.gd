extends SceneTree

class UnconfirmedSession extends "res://scenes/balatro/scripts/account_session.gd":
	var reply: Dictionary = {}
	func _auth_action(_path: String, _method: int, _body: Dictionary, _authorized := true) -> Dictionary:
		return reply

class Host extends Control:
	func _notification_dot(button: Control) -> Panel:
		return preload("res://scenes/balatro/scripts/main_menu.gd")._notification_dot(button)
	func _button(parent: Node, text: String, action: Callable) -> Button:
		var button := Button.new()
		button.text = text
		button.pressed.connect(action)
		parent.add_child(button)
		return button

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var host := Host.new()
	root.add_child(host)
	var panel := preload("res://scenes/balatro/scripts/account_panel.gd").new()
	host.add_child(panel)
	panel.setup(host)
	var cloud = root.get_node("AccountProfile")
	var session = root.get_node("AccountSession")
	var original_profile: Dictionary = cloud.profile
	var original_account: Node = cloud._account
	cloud._account = session
	var original_uid: String = session.user_id
	session.user_id = "notification-test"
	cloud.profile = {"id": session.user_id, "public_id": "ABC123", "username": null}
	assert(cloud.needs_username())
	panel._show("home")
	assert(panel.buttons.size() == 3)
	assert(panel.buttons[0].text == "SALVA\nPROGRESSI")
	assert(panel.buttons[1].text == "ACCEDI")
	panel.buttons[0].pressed.emit()
	assert(panel.mode == "save_providers" and panel.provider_intent == "save")
	assert(panel.buttons[0].text == "APPLE" and panel.buttons[1].text == "GOOGLE" and panel.buttons[2].text == "EMAIL")
	panel.buttons[0].pressed.emit()
	assert(panel.mode == "apple" and panel.provider_intent == "save")
	panel._go_back()
	assert(panel.mode == "save_providers")
	panel._go_back()
	panel.buttons[1].pressed.emit()
	assert(panel.mode == "login_providers" and panel.provider_intent == "login")
	panel.buttons[2].pressed.emit()
	assert(panel.mode == "login")
	panel._go_back()
	assert(panel.mode == "login_providers")
	panel._show("home")
	cloud.profile.username = "Space"
	cloud.changed.emit()
	assert(panel.buttons.size() == 3)
	cloud.profile.username = "  "
	assert(cloud.needs_username())
	cloud.profile.id = "another-account"
	assert(not cloud.needs_username())
	cloud.profile = {}
	assert(not cloud.needs_username())
	cloud.profile = original_profile
	cloud._account = original_account
	session.user_id = original_uid
	for mode in ["home", "link", "verify", "password", "login", "logout"]:
		panel._show(mode)
		await process_frame
		assert(panel.buttons.size() >= 2)
	panel._show("login")
	panel.address.text = "test@example.invalid"
	panel.password.text = "not-a-real-password"
	await panel._run("login")
	assert(panel.notice.text.contains("Conferma"))
	assert(not panel.working)
	panel._show("link")
	panel.address.text = "invalid"
	await panel._run("link")
	assert(panel.notice.text.contains("valido"))
	var account := root.get_node("AccountSession")
	assert(not account._accept_session({"user": {"id": "wrong"}}, false))
	assert(not (await account.sign_out()).ok) # Non si puo' abbandonare l'ospite.
	var probe := UnconfirmedSession.new()
	probe.user_id = "test-guest"
	probe.reply = {"ok": true, "data": {"id": "test-guest", "is_anonymous": true}}
	assert(not (await probe.check_email_confirmation()).ok)
	probe.reply = {"ok": true, "data": {"id": "other-user", "email_confirmed_at": "now"}}
	assert(not (await probe.check_email_confirmation()).ok)
	assert(not probe.email_verified)
	probe.free()
	if "--snapshot" in OS.get_cmdline_user_args():
		var bg := ColorRect.new()
		bg.color = Color("1e1833")
		bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.add_child(bg)
		root.move_child(bg, 0)
		for screen in ["home", "new_guest", "save_providers"]:
			panel._show(screen)
			await create_timer(0.15).timeout
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("/tmp/bisca-account-" + screen + ".png")
	host.queue_free()
	await process_frame
	print("PASS: pannelli account, conferma cambio, email, protezione ospite")
	quit()
