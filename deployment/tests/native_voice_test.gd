extends SceneTree

class NativeBridge extends RefCounted:
	var calls: Array = []
	var events: Array = []
	func invoke(method: String, arguments: String) -> void:
		calls.append([method, JSON.parse_string(arguments)])
	func drain() -> String:
		var result := JSON.stringify(events)
		events.clear()
		return result

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var voice = root.get_node("VoiceChat")
	voice.set_process(false)
	var native := NativeBridge.new()
	voice.native_bridge = native
	assert(voice.available())
	voice._on_network_updated({"code": "TEST", "you": 0, "people": [
		{"voice_id": "self", "name": "ME", "bot": false, "connected": true},
		{"voice_id": "other", "name": "OTHER", "bot": false, "connected": true}]})
	assert(native.calls.back()[0] == "update")
	voice.activate()
	assert(voice.pending and native.calls.back()[0] == "start")
	native.events.append({"op": "token", "id": 7})
	voice._process(0.0)
	# No RPC-to-self when the phone loses the game connection before requesting a token.
	assert(native.calls.back()[0] == "credentials")
	assert(native.calls.back()[1][0] == 7 and native.calls.back()[1][1].has("error"))
	native.events.append({"op": "status", "text": "Connected", "enabled": true, "muted": false, "pending": false})
	voice._process(0.0)
	assert(voice.enabled and not voice.pending)
	voice.set_muted(true)
	assert(native.calls.back() == ["setMuted", [true]])
	voice.set_player_volume("other", 25.0)
	assert(native.calls.back() == ["setVolume", ["other", 0.25]])
	voice._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	assert(not voice.enabled and not voice.pending)
	assert(native.calls.back()[0] == "stop")
	voice.leave()
	assert(voice.people.is_empty() and voice.volumes.is_empty())
	assert(native.calls.back() == ["update", ["", "", []]])
	voice.native_bridge = null
	print("PASS: native voice routing, offline token, status, mute, volume, background stop, cleanup")
	quit()
