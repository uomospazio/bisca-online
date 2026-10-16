extends Node

signal changed
const BACK_COUNT := 14
const DEFAULTS := {"main": 100.0, "effects": 100.0, "camera": true, "text_animations": false, "tooltips": true, "fullscreen": false, "deck_back": 1, "deck_front": 0, "throw_slots": [8, -1, -1], "show_thrown_objects": true, "language": "it", "microphone_enabled": true, "push_to_talk": false, "push_notifications": false, "push_permission_asked": false}
const FRONT_FOLDERS := ["res://scenes/balatro/trick_asset/mazzo_2/briscola/", "res://scenes/balatro/trick_asset/mazzo_2/briscola_big/Deck/"]
const GOLD_FRONT := 3 # 2 remains the retired front, never reuse its saved ID.
const GOLD_FRAMES := [
	[156,155,147,148,149,150,151,152,153,154],
	[146,145,137,138,139,140,141,142,143,144],
	[136,135,127,128,129,130,131,132,133,134],
	[119,118,117,120,121,122,123,124,125,126],
]

func available_fronts() -> Array[int]:
	var result: Array[int] = [0,1]
	var shop := get_node_or_null("/root/ShopManager")
	if shop and shop.owns_item("deck_back_13"):
		result.append(GOLD_FRONT)
	return result

func _valid_front(value: int) -> int:
	return GOLD_FRONT if value == GOLD_FRONT else clampi(value,0,1)

func front_texture(colour: int = 3, number: int = 5, index: int = -1) -> Texture2D:
	var chosen := int(values.deck_front) if index < 0 else index
	if chosen == GOLD_FRONT and GOLD_FRONT in available_fronts():
		return load("res://scenes/balatro/trick_asset/mazzo_2/briscola/mazzoOro/Frame %d.png" % GOLD_FRAMES[colour][number-1])
	var suits := ["Bastoni", "Spade", "Coppe", "Denari"]
	var ranks := ["Ace", "2", "3", "4", "5", "6", "7", "Jack", "Queen", "King"]
	return load(FRONT_FOLDERS[clampi(chosen, 0, FRONT_FOLDERS.size() - 1)] + "Suit=%s, Rank=%s, Front _=Yes.png" % [suits[colour], ranks[number - 1]])

func back_texture(index: int = -1) -> Texture2D:
	var chosen := int(values.deck_back) if index < 0 else index
	return load("res://scenes/balatro/trick_asset/mazzo_2/briscola/back/back%d.png" % clampi(chosen, 1, BACK_COUNT))
var values: Dictionary = DEFAULTS.duplicate()
var save_path := "user://bisca_settings.cfg"
var save_timer: Timer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if "--server" in OS.get_cmdline_user_args():
		return
	if not OS.has_feature("web") and AudioServer.get_bus_index("SFX") < 0:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, "SFX")
		AudioServer.set_bus_send(AudioServer.bus_count - 1, "Master")
	load_preferences()
	apply()
	save_timer = Timer.new()
	save_timer.one_shot = true
	save_timer.wait_time = 0.25
	add_child(save_timer)
	save_timer.timeout.connect(save_preferences)

func load_preferences() -> void:
	values = DEFAULTS.duplicate()
	var config := ConfigFile.new()
	if config.load(save_path) != OK:
		return
	for key in DEFAULTS:
		# Retired option: never restore the old enabled preference.
		if key == "text_animations": continue
		var value: Variant = config.get_value("settings", key, DEFAULTS[key])
		if key == "language":
			values[key] = value if value in ["it", "en"] else "it"
		elif key == "throw_slots":
			values[key] = _valid_throw_slots(value)
		elif key == "deck_back" and (value is int or value is float):
			values[key] = clampi(int(value), 1, BACK_COUNT)
		elif key == "deck_front" and (value is int or value is float):
			values[key] = _valid_front(int(value))
		elif key in ["main", "effects"]:
			if value is float or value is int:
				values[key] = clampf(float(value), 0.0, 100.0)
		elif value is bool:
			values[key] = value

func set_value(key: String, value: Variant) -> void:
	if key == "text_animations": value = false
	if not DEFAULTS.has(key):
		return
	if key == "language":
		values[key] = value if value in ["it", "en"] else "it"
	elif key == "throw_slots":
		values[key] = _valid_throw_slots(value)
	elif key in ["main", "effects"]:
		values[key] = clampf(float(value), 0.0, 100.0)
	else:
		values[key] = bool(value)
	if key == "deck_back":
		values[key] = clampi(int(value), 1, BACK_COUNT)
	if key == "deck_front":
		values[key] = _valid_front(int(value))
	if key == "throw_slots":
		values[key] = _valid_throw_slots(value)
	apply()
	changed.emit()
	if save_timer:
		save_timer.start()

func _valid_throw_slots(value: Variant) -> Array:
	var result: Array = [preload("res://scenes/balatro/scripts/throw_catalog.gd").DEFAULT_INDEX, -1, -1]
	if value is Array and value.size() == 3:
		for index in 3:
			result[index] = int(value[index]) if value[index] is int and preload("res://scenes/balatro/scripts/throw_catalog.gd").enabled(value[index]) else -1
	return result

func reset_defaults() -> void:
	if save_timer:
		save_timer.stop()
	values = DEFAULTS.duplicate()
	apply()
	changed.emit()
	save_preferences()

func apply() -> void:
	for key in ["main", "effects"]:
		if OS.has_feature("web"):
			continue
		var bus := AudioServer.get_bus_index("Master" if key == "main" else "SFX")
		if bus >= 0:
			var volume := float(values[key]) / 100.0
			AudioServer.set_bus_mute(bus, volume <= 0.0)
			AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	if OS.has_feature("web"):
		for player in get_tree().get_nodes_in_group("bisca_web_sfx"):
			_apply_web_sfx_volume(player)
	if DisplayServer.get_name() != "headless" and OS.get_name() not in ["Android", "iOS", "Web"]:
		var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if values.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)

# Web Sample playback bypasses Godot's single-thread audio mixer. Keep it on
# Master: dynamically inserted buses can leave the browser sample graph silent.
# Apply both sliders to each source, so no browser bus manipulation is needed.
func configure_sfx(player: AudioStreamPlayer, base_db: float = 0.0) -> void:
	player.volume_db = base_db
	if OS.has_feature("web"):
		player.bus = "Master"
		player.playback_type = AudioServer.PLAYBACK_TYPE_SAMPLE
		player.set_meta("bisca_base_db", base_db)
		player.add_to_group("bisca_web_sfx")
		_apply_web_sfx_volume(player)
	elif AudioServer.get_bus_index("SFX") >= 0:
		player.bus = "SFX"

func _apply_web_sfx_volume(player: AudioStreamPlayer) -> void:
	var gain := float(values.main) * float(values.effects) / 10000.0
	player.volume_db = float(player.get_meta("bisca_base_db", 0.0)) + linear_to_db(gain)

func save_preferences() -> void:
	var config := ConfigFile.new()
	for key in values:
		config.set_value("settings", key, values[key])
	var result := config.save(save_path)
	if result != OK:
		push_warning("Impossibile salvare le impostazioni BISCA: %s" % error_string(result))

func _exit_tree() -> void:
	if save_timer and not save_timer.is_stopped():
		save_preferences()
