extends SceneTree

func _initialize() -> void:
	var path: String = ProjectSettings.get_setting("application/boot_splash/image")
	var image := Image.new()
	assert(image.load(path) == OK)
	assert(ProjectSettings.get_setting("application/boot_splash/stretch_mode") == 4)
	var presets := ConfigFile.new()
	assert(presets.load("res://export_presets.cfg") == OK)
	var found_ios := false
	for section in presets.get_sections():
		if presets.get_value(section, "platform", "") == "iOS":
			found_ios = true
			assert(presets.get_value(section + ".options", "storyboard/image_scale_mode") == 3)
			assert(presets.get_value(section + ".options", "storyboard/custom_image@2x") == path)
			assert(presets.get_value(section + ".options", "storyboard/custom_image@3x") == path)
	assert(found_ios)
	# The full title texture (including glow) remains visible on landscape phones/tablets.
	var source := Vector2(image.get_size())
	var title_size := Vector2(source.x * 0.5, source.x * 0.5 * 1095.0 / 2069.0)
	for screen in [Vector2(2532,1170), Vector2(1920,1080), Vector2(2360,1640), Vector2(2048,1536)]:
		var cover: float = maxf(screen.x / source.x, screen.y / source.y)
		assert(source.x * cover >= screen.x - 0.01)
		assert(source.y * cover >= screen.y - 0.01)
		assert(title_size.x * cover <= screen.x)
		assert(title_size.y * cover <= screen.y)
	print("PASS: boot splash assets, iOS cover settings, phone/tablet title bounds")
	quit()
