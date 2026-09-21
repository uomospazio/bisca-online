extends RefCounted
## Server-only credentials. Never write keys to ProjectSettings or snapshots.

static func configured() -> bool:
	return OS.get_environment("LIVEKIT_URL").begins_with("wss://") and not OS.get_environment("LIVEKIT_API_KEY").is_empty() and not OS.get_environment("LIVEKIT_API_SECRET").is_empty()

static func base64url(bytes: PackedByteArray) -> String:
	return Marshalls.raw_to_base64(bytes).replace("+", "-").replace("/", "_").replace("=", "")

static func sign_claims(claims: Dictionary, key: String, secret: String) -> String:
	var now := int(Time.get_unix_time_from_system())
	var payload := claims.duplicate(true)
	payload.merge({"iss": key, "iat": now, "nbf": now - 5, "exp": now + 60}, true)
	var header := base64url(JSON.stringify({"alg": "HS256", "typ": "JWT"}).to_utf8_buffer())
	var body := header + "." + base64url(JSON.stringify(payload).to_utf8_buffer())
	var signature := Crypto.new().hmac_digest(HashingContext.HASH_SHA256, secret.to_utf8_buffer(), body.to_utf8_buffer())
	return body + "." + base64url(signature)

static func token_for(room_name: String, identity: String) -> String:
	return sign_claims({"sub": identity, "video": {"roomJoin": true, "room": room_name, "canPublish": true, "canPublishSources": ["microphone"], "canSubscribe": true, "canPublishData": false, "canUpdateOwnMetadata": false}}, OS.get_environment("LIVEKIT_API_KEY"), OS.get_environment("LIVEKIT_API_SECRET"))

static func remove_participant(parent: Node, room_name: String, identity: String) -> void:
	if not configured() or room_name.is_empty() or identity.is_empty():
		return
	var request := HTTPRequest.new()
	request.timeout = 10
	parent.add_child(request)
	request.request_completed.connect(func(_result, _code, _headers, _body): request.queue_free())
	var token := sign_claims({"video": {"roomAdmin": true, "room": room_name}}, OS.get_environment("LIVEKIT_API_KEY"), OS.get_environment("LIVEKIT_API_SECRET"))
	var url := OS.get_environment("LIVEKIT_URL").replace("wss://", "https://").trim_suffix("/") + "/twirp/livekit.RoomService/RemoveParticipant"
	var error := request.request(url, ["Authorization: Bearer " + token, "Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify({"room": room_name, "identity": identity}))
	if error != OK:
		request.queue_free()
