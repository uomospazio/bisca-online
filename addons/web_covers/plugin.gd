@tool
extends EditorPlugin

var exporter: EditorExportPlugin

class CoverExport extends EditorExportPlugin:
	var web_output := ""

	func _get_name() -> String:
		return "BiscaWebCovers"

	func _export_begin(features: PackedStringArray, _debug: bool, path: String, _flags: int) -> void:
		web_output = path if features.has("web") else ""

	func _export_end() -> void:
		if web_output.is_empty():
			return
		# Browser covers must be available before Godot loads the PCK.
		var directory := ProjectSettings.globalize_path(web_output).get_base_dir()
		for filename in ["cover_verticale.png", "cover_orizzontale.png"]:
			var source := ProjectSettings.globalize_path("res://scenes/balatro/trick_asset/" + filename)
			var error := DirAccess.copy_absolute(source, directory.path_join(filename))
			if error != OK:
				push_error("Cover %s: %s" % [filename, error_string(error)])
		web_output = ""

func _enter_tree() -> void:
	exporter = CoverExport.new()
	add_export_plugin(exporter)

func _exit_tree() -> void:
	remove_export_plugin(exporter)
