extends RefCounted

const HOVER = preload("res://scenes/balatro/audio/button_hover.wav")
const CLICK = preload("res://scenes/balatro/audio/button_click.wav")

static func play(button: BaseButton, stream: AudioStream, volume_db := 0.0) -> void:
	if not button.is_inside_tree():
		return
	var player := AudioStreamPlayer.new()
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	player.stream = stream
	player.volume_db = volume_db
	if AudioServer.get_bus_index("SFX") >= 0:
		player.bus = "SFX"
	# Keep clicks audible when the button's page is removed immediately.
	button.get_tree().root.add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

static func attach(button: BaseButton) -> void:
	button.mouse_entered.connect(func():
		if not button.disabled:
			play(button, HOVER, -4.0)
	)
	button.pressed.connect(func(): play(button, CLICK))
