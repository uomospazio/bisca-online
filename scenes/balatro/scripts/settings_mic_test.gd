extends Node

var active := false
var level := 0.0
var message_it := "Il test misura il microfono senza trasmettere la voce."
var message_en := "This test measures your microphone without transmitting voice."
var player: AudioStreamPlayer
var capture: AudioEffectCapture
var bus := -1

func start() -> void:
	active = true
	message_it = "Parla nel microfono: controlla la barra del livello."
	message_en = "Speak into your microphone and check the level meter."
	if OS.has_feature("web"):
		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://scenes/balatro/scripts/settings_mic_test.js"), true)
		JavaScriptBridge.eval("window.BiscaMicTest.start()", true)
	else:
		if DisplayServer.get_name() == "headless":
			_failed()
			return
		bus = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(bus, "SettingsMicTest")
		AudioServer.set_bus_mute(bus, true)
		capture = AudioEffectCapture.new()
		AudioServer.add_bus_effect(bus, capture)
		player = AudioStreamPlayer.new()
		player.stream = AudioStreamMicrophone.new()
		player.bus = "SettingsMicTest"
		add_child(player)
		player.play()

func _failed() -> void:
	stop()
	message_it = "Microfono non disponibile: controlla dispositivo e permessi."
	message_en = "Microphone unavailable: check your device and permissions."

func _process(_delta: float) -> void:
	if not active: return
	if OS.has_feature("web"):
		if bool(JavaScriptBridge.eval("window.BiscaMicTest.failed", true)):
			_failed()
			return
		level = float(JavaScriptBridge.eval("window.BiscaMicTest.level", true))
	elif capture != null:
		var frames := capture.get_buffer(capture.get_frames_available())
		level = 0.0
		for frame in frames:
			level = maxf(level, maxf(absf(frame.x), absf(frame.y)))
		level = clampf(level * 4.0, 0.0, 1.0)

func stop() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.BiscaMicTest?.stop()", true)
	if is_instance_valid(player):
		player.stop()
		player.queue_free()
	player = null
	capture = null
	if bus >= 0:
		AudioServer.remove_bus(bus)
		bus = -1
	active = false
	level = 0.0
	message_it = "Il test misura il microfono senza trasmettere la voce."
	message_en = "This test measures your microphone without transmitting voice."

func _exit_tree() -> void:
	stop()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if active: stop()
