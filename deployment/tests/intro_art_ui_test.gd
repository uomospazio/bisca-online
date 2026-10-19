extends SceneTree

class WelcomeStub extends Control:
	const FONT = preload("res://scenes/balatro/fonts/Comic Lemon.otf")
	var selected := ""
	func _social_choices(provider: String) -> void: selected = provider
	func _email_choices() -> void: selected = "email"
	func _continue_guest() -> void: selected = "guest"

func _initialize() -> void: run.call_deferred()

func run() -> void:
	var settings := root.get_node("GameSettings")
	var original_language: String = settings.values.language
	if "--english" in OS.get_cmdline_user_args():
		settings.values.language = "en"
		settings.changed.emit()
	var host := WelcomeStub.new()
	root.add_child(host)
	var intro = preload("res://scenes/balatro/scripts/intro_art_ui.gd").new()
	root.add_child(intro)
	intro.setup_intro(host)
	assert(intro.language_selector.position == Vector2(40, 30))
	assert(intro.language_selector.selected == (1 if settings.values.language == "en" else 0))
	assert(intro.find_child("WelcomeLogo",true,false).stretch_mode==TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	for child in intro.get_children():
		assert(not child is ColorRect,"No opaque rectangle over the app background")
	for index in 4:
		intro.buttons[index].pressed.emit()
		assert(host.selected == ["apple", "google", "email", "guest"][index])
	for bounds in [Rect2(40, 40, 1840, 800), Rect2(90, 40, 1500, 900)]:
		intro._layout(bounds)
		assert((intro.composition.position + intro.DESIGN * intro.composition.scale / 2).is_equal_approx(bounds.get_center()))
	intro._fit()
	await process_frame
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-intro-art.png")
	print("PASS: intro provider buttons, guest and responsive layout")
	settings.values.language = original_language
	settings.changed.emit()
	quit()
