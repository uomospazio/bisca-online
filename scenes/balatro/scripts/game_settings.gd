extends Node

signal changed
const DEFAULTS := {"main": 100.0, "effects": 100.0, "camera": true, "tooltips": true, "fullscreen": false, "deck_back": 1}

func back_texture(index: int = -1) -> Texture2D:
	var chosen := int(values.deck_back) if index < 0 else index
	return load("res://scenes/balatro/trick_asset/mazzo_2/briscola/back/back%d.png" % clampi(chosen, 1, 12))
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
		var value: Variant = config.get_value("settings", key, DEFAULTS[key])
		if key == "deck_back" and (value is int or value is float):
			values[key] = clampi(int(value), 1, 12)
		elif key in ["main", "effects"]:
			if value is float or value is int:
				values[key] = clampf(float(value), 0.0, 100.0)
		elif value is bool:
			values[key] = value

func set_value(key: String, value: Variant) -> void:
	if not DEFAULTS.has(key):
		return
	values[key] = clampf(float(value), 0.0, 100.0) if key in ["main", "effects"] else bool(value)
	if key == "deck_back":
		values[key] = clampi(int(value), 1, 12)
	apply()
	changed.emit()
	if save_timer:
		save_timer.start()

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
