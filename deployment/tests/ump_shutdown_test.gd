extends SceneTree

class NativeConsent extends RefCounted:
	signal on_consent_info_updated_success
	signal on_consent_info_updated_failure(error: Dictionary)
	signal on_consent_form_load_success_listener(uid: int)
	signal on_consent_form_load_failure_listener(error: Dictionary)
	signal on_privacy_options_form_dismissed_listener(error: Dictionary)
	signal on_consent_form_dismissed(uid: int, error: Dictionary)
	var scenario := "obtained"
	var completed_form := false
	func update(_params: Dictionary) -> void:
		if scenario == "pending_update": return
		if scenario == "update_error": on_consent_info_updated_failure.emit({"error_code": 1, "message": "Test failure"})
		else: on_consent_info_updated_success.emit()
	func get_consent_status() -> int:
		return 2 if scenario in ["form", "pending_load", "pending_form", "load_error"] and not completed_form else 3
	func get_is_consent_form_available() -> bool: return true
	func get_privacy_options_requirement_status() -> int: return 2
	func load_consent_form() -> void:
		if scenario == "pending_load": return
		if scenario == "load_error": on_consent_form_load_failure_listener.emit({"error_code": 2, "message": "Test load failure"})
		else: on_consent_form_load_success_listener.emit(42)
	func show(uid: int) -> void:
		if scenario == "pending_form": return
		completed_form = true
		on_consent_form_dismissed.emit(uid, {})
	func show_privacy_options_form() -> void:
		if scenario != "pending_privacy": on_privacy_options_form_dismissed_listener.emit({})

class AdsProbe extends "res://scenes/balatro/scripts/rewarded_ads.gd":
	func supported() -> bool: return false
	func privacy_supported() -> bool: return true

func _initialize() -> void: run.call_deferred()

func timed_out() -> void:
	push_error("UMP shutdown regression timed out")
	quit(1)

func run() -> void:
	create_timer(10).timeout.connect(timed_out)
	var native := NativeConsent.new()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--case="): native.scenario = arg.trim_prefix("--case=")
	ConsentInformation._plugin = native
	UserMessagingPlatform._plugin = native
	ConsentForm._plugin = native
	var ads := AdsProbe.new()
	root.add_child(ads)
	ads._start_consent_flow()
	for frame in range(5): await process_frame
	assert(ads.consent_ready == (native.scenario in ["obtained", "update_error", "form", "privacy", "pending_privacy"]))
	if native.scenario in ["privacy", "pending_privacy"]:
		ads.show_privacy_options()
		await process_frame
	if native.scenario == "obtained":
		assert(UserMessagingPlatform.consent_information._on_consent_info_updated_success_callback == null)
		assert(UserMessagingPlatform.consent_information._on_consent_info_updated_failure_callback == null)
	if "--exit-in-flight" in OS.get_cmdline_user_args():
		# Let SceneTree shutdown invoke the owner's _exit_tree, as on iOS.
		print("PASS: exiting with live consent owner: ", native.scenario)
		quit()
		return
	ads.queue_free()
	await process_frame
	assert(UserMessagingPlatform.consent_information._on_consent_info_updated_success_callback == null)
	assert(UserMessagingPlatform.consent_information._on_consent_info_updated_failure_callback == null)
	assert(UserMessagingPlatform._on_consent_form_load_success_listener_callback == null)
	assert(UserMessagingPlatform._on_consent_form_load_failure_listener_callback == null)
	assert(UserMessagingPlatform._on_privacy_options_form_dismissed_callback == null)
	assert(UserMessagingPlatform.active_consent_form == null)
	for event in native.get_signal_list():
		assert(native.get_signal_connection_list(event.name).is_empty())
	# Late native events after owner teardown must not invoke destroyed scripts.
	native.on_consent_info_updated_success.emit()
	native.on_consent_form_load_success_listener.emit(42)
	native.on_consent_form_dismissed.emit(42, {})
	native.on_privacy_options_form_dismissed_listener.emit({})
	await process_frame
	print("PASS: mobile consent shutdown: ", native.scenario)
	quit()
