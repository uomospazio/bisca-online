extends SceneTree

func _initialize() -> void:
	var catalog = preload("res://scenes/balatro/scripts/throw_catalog.gd")
	assert(catalog.impact_sound(catalog.FILES.find("poop.png")).resource_path == "res://scenes/balatro/audio/poop.mp3")
	assert(catalog.impact_sound(-1).resource_path.ends_with("/impact.mp3"))
	assert(catalog.impact_sound(catalog.FILES.size()).resource_path.ends_with("/impact.mp3"))
	for i in catalog.FILES.size():
		assert(catalog.impact_sound(i) != null)
	assert(load("res://scenes/balatro/scripts/throw_objects.gd").can_instantiate())
	print("PASS: matching impact audio, fallback and throw script")
	quit()
