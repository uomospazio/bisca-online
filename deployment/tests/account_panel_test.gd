extends SceneTree

class UnconfirmedSession extends "res://scenes/balatro/scripts/account_session.gd":
	var reply: Dictionary = {}
	func _auth_action(_path: String, _method: int, _body: Dictionary, _authorized := true) -> Dictionary:
		return reply

class Host extends Control:
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
	host.queue_free()
	await process_frame
	print("PASS: pannelli account, conferma cambio, email, protezione ospite")
	quit()
