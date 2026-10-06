extends SceneTree

class Host extends Control:
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
	page.account = root.get_node("AccountSession")
	page.cloud = root.get_node("AccountProfile")
	page.column = VBoxContainer.new()
	page.add_child(page.column)
	page._choices()
	assert(page.controls.size() == 3)
	page.controls[0].pressed.emit()
	assert(page.controls[0].text == "CONTINUA")
	page._choices()
	page.controls[1].pressed.emit()
	assert(page.controls[0].text == "CONTINUA")
	page._email_choices()
	assert(page.controls.size() == 3)
	page._name_page()
	assert(page.username.max_length == 24)
	page.username.text = "!"
	await page._finish()
	assert(page.notice.text.contains("valido"))
	assert(not page.working)
	host.queue_free()
	print("PASS: welcome choices, social menus, email menu and username validation")
	quit()
