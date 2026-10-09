extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var dialog = preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	root.add_child(dialog)
	dialog.title = "SUPPORTA IL CREATORE"
	dialog.dialog_text = "Se ti piace Bisca, puoi supportare il progetto offrendo un caffè."
	dialog.get_ok_button().text = "OFFRIMI UN CAFFE'"
	dialog.get_cancel_button().text = "ANNULLA"
	var events := []
	dialog.confirmed.connect(func(): events.append("confirmed"))
	dialog.canceled.connect(func(): events.append("canceled"))
	dialog.popup_centered()
	await create_timer(0.5).timeout
	assert(dialog.visible and dialog.panel.has_meta("generic_ui_skin"))
	assert(dialog.ok.has_meta("generic_ui_skin"))
	assert(dialog.panel.scale.x > 0)
	if "--snapshot" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-menu-dialog.png")
	dialog.cancel.pressed.emit()
	assert(not dialog.visible and events == ["canceled"])
	dialog.popup_centered(Vector2i(760, 540))
	dialog.ok.pressed.emit()
	assert(not dialog.visible and events == ["canceled", "confirmed"])
	dialog.queue_free()
	print("PASS: menu dialog skin, layout, cancel and confirm")
	quit()
