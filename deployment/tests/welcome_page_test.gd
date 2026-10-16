extends SceneTree

class Account extends Node:
	var user_id := "test"

class Social extends Node:
	signal completed(result: Dictionary)
	var provider := ""
	var linking := true
	func start(value: String, link: bool) -> void:
		provider = value
		linking = link

class Host extends Control:
	var tutorial_offered := false
	func offer_tutorial() -> void: tutorial_offered = true
	func _button(parent: Node, text: String, action: Callable) -> Button:
		var button := Button.new()
		button.text = text
		parent.add_child(button)
		button.pressed.connect(action)
		return button
	func _style_input(_input: LineEdit, _size: int) -> void:
		pass

func _initialize() -> void:
	call_deferred("_test")

func _test() -> void:
	var host := Host.new()
	root.add_child(host)
	var page = load("res://scenes/balatro/scripts/welcome_page.gd").new()
	host.add_child(page)
	page.menu = host
	var account := Account.new()
	host.add_child(account)
	var social := Social.new()
	social.name = "SocialAuth"
	account.add_child(social)
	page.account = account
	page.cloud = root.get_node("AccountProfile")
	page.column = VBoxContainer.new()
	page.add_child(page.column)
	page._choices()
	assert(page.controls.size() == 4) # Apple, Google, Email, Ospite.
	page.controls[0].pressed.emit()
	assert(social.provider=="apple" and not social.linking and page.working)
	assert(page.controls.size()==4 and page.controls[0].disabled)
	social.completed.emit({"ok":false,"message":"Annullato"})
	assert(not page.working and not page.controls[0].disabled)
	page._choices()
	page.controls[1].pressed.emit()
	assert(social.provider=="google" and not social.linking)
	social.completed.emit({"ok":true})
	assert(is_instance_valid(page.username))
	page._email_choices()
	assert(page.controls.size() == 3)
	page._name_page()
	assert(page.username.max_length == 24)
	page.username.text = "!"
	await page._finish()
	assert(page.notice.text.contains("valido"))
	assert(not page.working)
	page._offer_tutorial()
	assert(host.tutorial_offered)
	host.queue_free()
	print("PASS: direct Apple/Google sign-in, cancellation, username step and email menu")
	quit()
