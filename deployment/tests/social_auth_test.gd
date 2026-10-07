extends SceneTree
const Auth = preload("res://scenes/balatro/scripts/social_auth.gd")

class FakeAccount extends Node:
	const PROJECT_URL := "https://example.supabase.co"
	var user_id := "guest-original"
	var _busy := false
	var accepted := false
	var switched := false
	var response := {"ok": true, "data": {"url": "https://example.supabase.co/auth/v1/authorize"}}
	var last_path := ""
	var last_body := {}
	func is_authenticated() -> bool: return true
	func _auth_action(path: String, _method: int, body: Dictionary, _authorized := true) -> Dictionary:
		last_path = path
		last_body = body
		return response
	func _accept_session(_data: Dictionary, allow_switch: bool, password_login := true) -> bool:
		assert(not password_login)
		accepted = true
		switched = allow_switch
		return true

class FakeBridge extends RefCounted:
	var url := ""
	var callback := ""
	func open_auth(value: String) -> void: url = value
	func drain_auth() -> String:
		var value := callback
		callback = ""
		return value
	func cancel_auth() -> void: callback = ""

func _initialize() -> void: call_deferred("_test")

func _test() -> void:
	# RFC 7636 known challenge vector.
	assert(Auth.base64url("dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk".sha256_buffer()) == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
	assert(Auth.callback_params("https://evil.invalid/?code=x").is_empty())
	assert(Auth.callback_params(Auth.REDIRECT + "?flow=a&flow=b").is_empty())
	assert(Auth.callback_params(Auth.REDIRECT + "?flow=a#access_token=x").is_empty())
	var account := FakeAccount.new()
	root.add_child(account)
	var auth := Auth.new()
	account.add_child(auth)
	var bridge := FakeBridge.new()
	auth.bridge = bridge
	await auth.start("google", false)
	assert(auth.pending and auth.verifier.length() == 43)
	assert(bridge.url.contains("code_challenge_method=s256"))
	bridge.callback = Auth.REDIRECT + "?flow=stale&code=x"
	auth._process(0)
	assert(not account.accepted and auth.pending)
	bridge.callback = Auth.REDIRECT + "?flow=" + auth.flow + "&code=test-code"
	auth._process(0)
	assert(account.accepted and account.switched and not auth.pending)
	assert(account.last_body.auth_code == "test-code")
	account.accepted = false
	await auth.start("apple", true)
	assert(account.last_path.begins_with("user/identities/authorize?"))
	bridge.callback = Auth.REDIRECT + "?flow=" + auth.flow + "&code=link-code"
	auth._process(0)
	assert(account.accepted and not account.switched)
	await auth.start("google", false)
	auth.cancel()
	assert(not auth.pending and auth.verifier.is_empty())
	account.accepted = false
	account.response = {"ok": false}
	await auth.start("google", false)
	bridge.callback = Auth.REDIRECT + "?flow=" + auth.flow + "&code=expired"
	auth._process(0)
	assert(not account.accepted and not auth.pending)
	account.response = {"ok": true, "data": {}}
	await auth.start("google", false)
	account.user_id = "another-account"
	bridge.callback = Auth.REDIRECT + "?flow=" + auth.flow + "&code=stale-owner"
	auth._process(0)
	assert(not account.accepted and not auth.pending)
	account.queue_free()
	print("PASS: PKCE vector, strict callbacks, stale callback rejection, login/link distinction, cancellation")
	quit()
