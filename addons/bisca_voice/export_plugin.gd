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

	func _supports_platform(platform: EditorExportPlatform) -> bool:
		return platform is EditorExportPlatformAndroid

	func _get_name() -> String:
		return PLUGIN_NAME

	func _get_android_libraries(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([AAR_PATH])

	func _get_android_dependencies(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray([LIVEKIT_DEPENDENCY])

	func _get_android_dependencies_maven_repos(_platform: EditorExportPlatform, _debug: bool) -> PackedStringArray:
		return PackedStringArray(["https://jitpack.io"])
