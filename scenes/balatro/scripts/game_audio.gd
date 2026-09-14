extends RefCounted

const SWIPE = preload("res://scenes/balatro/audio/swipe.wav")
const CARD = preload("res://scenes/balatro/audio/card.mp3")
const COUNTER = preload("res://scenes/balatro/audio/counter.wav")
const LIFE = preload("res://scenes/balatro/audio/pop_ui.mp3")
const VICTORY = preload("res://scenes/balatro/audio/victory.wav")
const NOTICE = preload("res://scenes/balatro/audio/button_hover.wav")

static func play(owner: Node, sound: AudioStream, volume := -10.0) -> void:
	if Engine.is_editor_hint() or not owner.is_inside_tree():
		return
	var root := owner.get_tree().root
	# Simultaneous counter/heart updates should sound once, not eight times.
	var key := "sfx_" + sound.resource_path.md5_text()
	var now := Time.get_ticks_msec()
	if now - int(root.get_meta(key, -1000)) < 65:
		return
	root.set_meta(key, now)
	var player := AudioStreamPlayer.new()
	if owner.get_tree().paused and owner.can_process():
		player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = sound
	player.volume_db = volume
	if AudioServer.get_bus_index("SFX") >= 0:
		player.bus = "SFX"
	root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()
