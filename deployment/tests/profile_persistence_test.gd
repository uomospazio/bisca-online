extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var path := "/tmp/bisca-profile-test-%s.cfg" % Time.get_ticks_usec()
	var script = preload("res://scenes/balatro/scripts/main_menu.gd")
	var avatar := preload("res://scenes/balatro/scripts/avatar_catalog.gd").encoded(0)
	var menu = script.new()
	menu.profile_save_path = path
	root.add_child(menu)
	await process_frame
	menu._set_home_profile(avatar)
	menu.name_input.text = "Nome salvato"
	menu.name_input.text_changed.emit(menu.name_input.text)
	menu.queue_free()
	await process_frame
	menu = script.new()
	menu.profile_save_path = path
	root.add_child(menu)
	await process_frame
	assert(menu.profile_avatar == avatar and menu.profile_texture != null)
	assert(menu.name_input.text == "Nome salvato")
	menu._refresh_default_name()
	assert(menu.name_input.text == "Nome salvato")
	var config := ConfigFile.new()
	assert(config.load(path) == OK)
	assert(config.get_value("profile", "avatar") == avatar)
	assert(config.get_value("profile", "name") == "Nome salvato")
	menu.queue_free()
	await process_frame
	DirAccess.remove_absolute(path)
	print("PASS: avatar and match name survive menu recreation without overwriting each other")
	quit()
