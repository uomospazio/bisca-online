extends SceneTree

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var settings := root.get_node("GameSettings")
	var saved: String = settings.values.language
	var art := preload("res://scenes/balatro/scripts/shop_art_ui.gd").new()
	root.add_child(art)
	art.slots_background = art._image(art,art.SHOP+"slotShop.png",Rect2(80,200,1760,636))
	art.slots_captions = art._image(art,art.SHOP+"slotShop.png",Rect2(80,750,1760,86))
	for image in [art.slots_background,art.slots_captions]:
		image.set_meta("locale_texture_locked",true)
	for language in ["it","en","it","en"]:
		settings.values.language = language
		settings.changed.emit()
		art._sync_shop_background()
		await process_frame
		await process_frame
		if language == "it":
			assert(art.slots_background.texture.resource_path == art.SHOP+"slotShop.png")
			assert(art.slots_background.size == Vector2(1760,636))
			assert(not art.slots_captions.visible)
		else:
			assert(art.slots_background.texture is AtlasTexture)
			assert(art.slots_background.texture.atlas.resource_path == art.SHOP+"slotShop.png", "Auto-localization must not restore baked-in icons")
			assert(art.slots_background.texture.region == Rect2(0,0,3520,1100))
			assert(art.slots_captions.texture.atlas.resource_path == art.SHOP+"slotShop_en.png")
			assert(art.slots_captions.texture.region == Rect2(0,1100,3520,172))
			assert(art.slots_background.position.y+art.slots_background.size.y == art.slots_captions.position.y)
			assert(art.slots_captions.visible)
	settings.values.language = saved
	settings.changed.emit()
	art.queue_free()
	await process_frame
	print("PASS: English uses clean icon backgrounds and English captions; Italian unchanged; repeated language switches")
	quit()
