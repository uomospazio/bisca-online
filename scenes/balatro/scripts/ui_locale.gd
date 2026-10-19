class_name UiLocale
extends Node

# Text is translated at render time by Godot; original Italian strings remain
# intact, including strings used as identifiers by existing gameplay code.
const Catalog = preload("res://scenes/balatro/scripts/ui_translation.gd")
var current_language := ""
var translations: Array[Translation] = []
static var asset_paths: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var translation := Catalog.new()
	translation.locale = "en"
	TranslationServer.add_translation(translation)
	var italian := Catalog.new()
	italian.locale = "it"
	TranslationServer.add_translation(italian)
	translations = [translation, italian]
	get_node("/root/GameSettings").changed.connect(_language_changed)
	get_tree().node_added.connect(_node_added)
	_language_changed()

func _exit_tree() -> void:
	# Remove scripted callbacks before the scripting runtime is shut down.
	for translation in translations:
		TranslationServer.remove_translation(translation)

func _language_changed() -> void:
	var language: String = get_node("/root/GameSettings").values.get("language", "it")
	if language == current_language: return
	current_language = language
	TranslationServer.set_locale(language)
	_refresh_tree(get_tree().root)

static func text(value: String) -> String:
	return str(TranslationServer.translate(value))

static func asset_path(path: String) -> String:
	if not path.contains("/pngUI/"): return path
	var original := path
	if original.get_basename().ends_with("_en"):
		original = original.get_basename().trim_suffix("_en") + "." + original.get_extension()
	if not TranslationServer.get_locale().begins_with("en"): return original
	if not asset_paths.has(original):
		var variant := original.get_basename() + "_en." + original.get_extension()
		asset_paths[original] = variant if ResourceLoader.exists(variant) else original
	return asset_paths[original]

static func resource(path: String) -> Resource:
	return load(asset_path(path))

func _node_added(node: Node) -> void:
	if node is Control or node is Sprite2D:
		_refresh_instance.call_deferred(node.get_instance_id())

func _refresh_instance(id: int) -> void:
	if is_instance_id_valid(id):
		_refresh_node(instance_from_id(id))

func _refresh_tree(node: Node) -> void:
	_refresh_node(node)
	for child in node.get_children(): _refresh_tree(child)

func _localized(texture: Texture2D) -> Texture2D:
	if texture is AtlasTexture:
		var atlas := _localized(texture.atlas)
		if atlas != texture.atlas:
			var copy := texture.duplicate() as AtlasTexture
			copy.atlas = atlas
			return copy
	if texture == null or texture.resource_path.is_empty(): return texture
	var path := asset_path(texture.resource_path)
	return texture if path == texture.resource_path else load(path)

func _refresh_node(node: Node) -> void:
	if not is_instance_valid(node): return
	if node is TextureRect or node is Sprite2D:
		node.texture = _localized(node.texture)
	if node is TextureButton:
		for property in ["texture_normal", "texture_pressed", "texture_hover", "texture_disabled", "texture_focused"]:
			node.set(property, _localized(node.get(property)))
	if node is Button:
		node.icon = _localized(node.icon)
	if node is Button or node is Panel or node is PanelContainer:
		for state in ["normal", "hover", "pressed", "disabled", "hover_pressed", "focus", "panel"]:
			if not node.has_theme_stylebox_override(state): continue
			var style: StyleBox = node.get_theme_stylebox(state)
			if style is StyleBoxTexture:
				var texture := _localized(style.texture)
				if texture != style.texture:
					var localized := style.duplicate() as StyleBoxTexture
					localized.texture = texture
					node.add_theme_stylebox_override(state, localized)
