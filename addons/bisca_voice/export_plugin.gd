@tool
extends EditorPlugin

var _export_plugin: EditorExportPlugin


func _enter_tree() -> void:
	_export_plugin = _BiscaVoiceExportPlugin.new()
	add_export_plugin(_export_plugin)


func _exit_tree() -> void:
	if _export_plugin != null:
		remove_export_plugin(_export_plugin)
		_export_plugin = null


class _BiscaVoiceExportPlugin extends EditorExportPlugin:
	const PLUGIN_NAME := "BiscaVoice"
	const AAR_PATH := "res://addons/bisca_voice/bin/bisca_voice.aar"
	const LIVEKIT_DEPENDENCY := "io.livekit:livekit-android:2.29.0"
	var _ios_project := ""
	var _ios_debug := true

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid or platform is EditorExportPlatformIOS

	func _export_begin(features: PackedStringArray, is_debug: bool, path: String, _flags: int) -> void:
		_ios_project = ""
		if features.has("ios"):
			_ios_project = path.get_basename() + ".xcodeproj"
			_ios_debug = is_debug

	func _export_end() -> void:
		if _ios_project.is_empty():
			return
		var project := _ios_project
		_ios_project = ""
		if not FileAccess.file_exists(project.path_join("project.pbxproj")):
			push_error("BISCA: progetto Xcode assente; integrazione LiveKit non eseguita.")
			return
		var source := OS.get_environment("BISCA_GODOT_SOURCE")
		if source.is_empty():
			source = ProjectSettings.globalize_path("res://.native-deps/godot")
		var output: Array = []
		var result := OS.execute("/usr/bin/python3", PackedStringArray([
			ProjectSettings.globalize_path("res://deployment/ios/setup.py"),
			project, "--godot-source", source, "--engine-target",
			"template_debug" if _ios_debug else "template_release"
		]), output, true)
		if result != 0:
			push_error("BISCA: integrazione LiveKit iOS fallita. Non compilare questa esportazione prima di correggere l'errore: " + str(output))
		else:
			print("BISCA: LiveKit e bridge nativi aggiunti al progetto Xcode. ", str(output))

	func _get_name() -> String:
		return PLUGIN_NAME

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([AAR_PATH])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([LIVEKIT_DEPENDENCY])

	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://jitpack.io"])
