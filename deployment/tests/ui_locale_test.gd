extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings := root.get_node("GameSettings")
	var saved: String = settings.values.language
	var ui := Control.new()
	root.add_child(ui)
	var image := TextureRect.new()
	var path := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/IntroUI/introGoogle.png"
	image.texture = load(path)
	ui.add_child(image)
	var label := Label.new()
	label.text = "CONTINUA"
	ui.add_child(label)
	for language in ["it", "en", "it"]:
		settings.values.language = language
		settings.changed.emit()
		await process_frame
		assert(image.texture.resource_path == path.replace(".png", "_en.png") if language == "en" else image.texture.resource_path == path)
		assert(label.text == "CONTINUA") # Translation must not alter source or logic.
		assert(label.tr(label.text) == ("CONTINUE" if language == "en" else "CONTINUA"))
		assert(UiLocale.text("QUANTE PRESE FAI?") == ("HOW MANY TRICKS WILL YOU WIN?" if language == "en" else "QUANTE PRESE FAI?"))
		assert(UiLocale.text("[center]E' IL TUO TURNO![/center]") == ("[center]IT'S YOUR TURN![/center]" if language == "en" else "[center]E' IL TUO TURNO![/center]"))
		assert(UiLocale.text("Luca vince la presa") == ("Luca wins the trick" if language == "en" else "Luca vince la presa"))
		assert(UiLocale.text("5 carte · Predizione di Luca") == ("5 cards · Luca is predicting" if language == "en" else "5 carte · Predizione di Luca"))
		assert(UiLocale.text("CLASSIFICA STAGIONE 0") == ("LEADERBOARD SEASON 0" if language == "en" else "CLASSIFICA STAGIONE 0"))
		assert(UiLocale.text("77g 00:20:24") == ("77d 00:20:24" if language == "en" else "77g 00:20:24"))
		var unchanged := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/tastoSingleplayer.png"
		assert(UiLocale.asset_path(unchanged) == unchanged)
		_check_assets("res://scenes/balatro/trick_asset/ui_bisca/pngUI", language)
		assert(UiLocale.text("17°") == ("17th" if language == "en" else "17°"))
		assert(UiLocale.text("Asso di denari") == ("Ace of coins" if language == "en" else "Asso di denari"))
		assert(UiLocale.text('Vuoi acquistare "Dorso 2" per') == ('Buy "Card back 2" for' if language == "en" else 'Vuoi acquistare "Dorso 2" per'))
		assert(UiLocale.text("1: 5000 monete     2: 2000 monete\n\n") == ("1: 5000 coins     2: 2000 coins\n\n" if language == "en" else "1: 5000 monete     2: 2000 monete\n\n"))
	if "--snapshot" in OS.get_cmdline_user_args():
		image.hide()
		label.hide()
		settings.values.language = "en"
		settings.changed.emit()
		var overlay = preload("res://scenes/balatro/scripts/game_overlay.gd").new()
		ui.add_child(overlay)
		ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		overlay._set_wide_prediction_banner(true)
		overlay._set_animated_title("QUANTE PRESE FAI?")
		overlay.show()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/bisca-localized-game.png")
		overlay.queue_free()
		await process_frame
	settings.values.language = saved
	settings.changed.emit()
	ui.queue_free()
	print("UI localization: PASS")
	quit()

func _check_assets(directory: String, language: String) -> void:
	for folder in DirAccess.get_directories_at(directory):
		_check_assets(directory.path_join(folder), language)
	for file in DirAccess.get_files_at(directory):
		if not file.ends_with("_en.png"): continue
		var original := directory.path_join(file.trim_suffix("_en.png") + ".png")
		if not ResourceLoader.exists(original): continue
		assert(UiLocale.asset_path(original) == (directory.path_join(file) if language == "en" else original))
