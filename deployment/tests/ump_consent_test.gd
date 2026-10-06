extends SceneTree

class FakeConsent extends ConsentInformation:
	var status := 0
	var options := 0
	func get_consent_status() -> int: return status
	func get_privacy_options_requirement_status() -> int: return options
	func get_is_consent_form_available() -> bool: return false

func _initialize() -> void:
	var ads := preload("res://scenes/balatro/scripts/rewarded_ads.gd").new()
	var info := FakeConsent.new()
	ads._consent_info = info
	for state in range(4):
		info.status = state
		assert(ads._consent_is_required() == (state == 2))
		assert(ads._consent_is_not_required() == (state == 1))
		assert(ads._consent_is_obtained() == (state == 3))
		assert(ads._can_request_ads_from_consent() == (state in [1, 3]))
	for state in range(3):
		info.options = state
		assert(ads._privacy_options_are_required() == (state == 2))
	info.status = 2
	ads._consent_started = true
	ads._handle_consent_info_updated()
	assert(not ads.consent_ready)
	assert(not ads._consent_started, "Unavailable forms must permit retry")
	ads.free()
	print("PASS: Poing normalized enums, unavailable form blocked and retry enabled")
	quit()
