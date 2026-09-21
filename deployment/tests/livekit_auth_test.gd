extends SceneTree

func _initialize() -> void:
	var auth = load("res://scenes/balatro/scripts/livekit_auth.gd")
	# Fixed dummy credentials only; no real account or network calls.
	OS.set_environment("LIVEKIT_URL", "wss://test.invalid")
	OS.set_environment("LIVEKIT_API_KEY", "test-key")
	OS.set_environment("LIVEKIT_API_SECRET", "test-secret-not-a-real-livekit-key")
	var network = load("res://scenes/balatro/scripts/network_session.gd").new()
	network.dedicated = true
	network.rooms = {"ABC": {"people": [{"peer": 7, "bot": false, "voice_id": "public123"}]}}
	network.members = {7: {"code": "ABC", "slot": 0}}
	assert(network._livekit_credentials(8).has("error"))
	var credentials: Dictionary = network._livekit_credentials(7)
	assert(credentials.url == "wss://test.invalid")
	var token: String = credentials.token
	var payload = JSON.parse_string(Marshalls.base64_to_utf8(token.split(".")[1].replace("-", "+").replace("_", "/")))
	assert(payload.sub.begins_with("public123."))
	assert(payload.video.room != "ABC" and payload.video.room.begins_with("bisca-"))
	assert(payload.video.canPublishSources == ["microphone"])
	assert(payload.video.canPublishData == false)
	assert(not payload.video.has("roomAdmin"))
	assert(payload.exp - payload.iat == 60)
	assert(not token.contains("test-secret"))
	var first_room: String = payload.video.room
	network.rooms["ABC"].people[0].bot = true
	assert(network._livekit_credentials(7).has("error"))
	network.rooms["ABC"].people[0].bot = false
	network.rooms["ABC"].people[0].peer = 9
	assert(network._livekit_credentials(7).has("error"))
	network.rooms["ABC"].people[0].peer = 7
	OS.set_environment("LIVEKIT_API_SECRET", "")
	assert(network._livekit_credentials(7).has("error"))
	assert(not auth.configured())
	# Revocation rotates the identity even when the service is unavailable.
	network._revoke_voice(network.rooms["ABC"], network.rooms["ABC"].people[0])
	assert(not network.rooms["ABC"].people[0].has("livekit_identity"))
	OS.set_environment("LIVEKIT_API_SECRET", "test-secret-not-a-real-livekit-key")
	network.rooms["ABC"] = {"people": [{"peer": 7, "bot": false, "voice_id": "public123"}]}
	network._livekit_credentials(7)
	assert(network.rooms["ABC"].livekit_room != first_room)
	FileAccess.open("/private/tmp/bisca-livekit-test.jwt", FileAccess.WRITE).store_string(token)
	network.free()
	print("PASS: LiveKit membership, bot rejection, credentials, scoped grants, expiry, unique rooms, identity rotation")
	quit()
