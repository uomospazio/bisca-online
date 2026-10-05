extends Node

signal selected(avatar: String)
const AvatarData = preload("res://scenes/balatro/scripts/avatar_data.gd")
var bridge: JavaScriptObject
var dialog: ConfirmationDialog
var preview: TextureButton
var file_dialog: FileDialog
var chosen := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.has_feature("web"):
		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://scenes/balatro/scripts/profile_picker.js"), true)
		bridge = JavaScriptBridge.get_interface("BiscaProfile")

func open(display_name: String) -> void:
	chosen = ""
	if bridge:
		bridge.open(display_name)
		return
	# Native desktop import; browser builds also offer camera capture.
	if dialog == null:
		dialog = ConfirmationDialog.new()
		add_child(dialog)
		dialog.title = "IL TUO PROFILO"
		dialog.ok_button_text = "CONFERMA"
		dialog.cancel_button_text = "SALTA"
		var column := VBoxContainer.new()
		column.name = "ProfileContent"
		column.add_theme_constant_override("separation", 24)
		dialog.add_child(column)
		var name_label := Label.new()
		name_label.name = "ProfileName"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_label.add_theme_font_size_override("font_size", 38)
		column.add_child(name_label)
		preview = TextureButton.new()
		preview.custom_minimum_size = Vector2(256, 256)
		preview.ignore_texture_size = true
		preview.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(preview)
		var hint := Label.new()
		hint.text = "Tocca la foto per scegliere un'immagine.\nLa foto sara' condivisa con la lobby."
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint.add_theme_font_size_override("font_size", 30)
		column.add_child(hint)
		file_dialog = FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.use_native_dialog = true
		file_dialog.title = "SCEGLI UNA FOTO"
		file_dialog.ok_button_text = "SCEGLI"
		file_dialog.cancel_button_text = "ANNULLA"
		file_dialog.filters = PackedStringArray(["*.jpg,*.jpeg,*.png,*.webp ; Immagini"])
		add_child(file_dialog)
		preview.pressed.connect(_open_files)
		file_dialog.file_selected.connect(_import_file)
		dialog.confirmed.connect(func(): selected.emit(chosen))
		dialog.canceled.connect(func(): selected.emit(""))
	dialog.get_node("ProfileContent/ProfileName").text = display_name
	var blank := Image.create(192, 192, false, Image.FORMAT_RGB8)
	blank.fill(Color("efecfa"))
	preview.texture_normal = AvatarData.circular_texture(Marshalls.raw_to_base64(blank.save_jpg_to_buffer()))
	for button in [dialog.get_ok_button(), dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(240, 80)
		button.add_theme_font_size_override("font_size", 32)
	var available := get_viewport().get_visible_rect().size
	dialog.popup_centered(Vector2i(minf(900, available.x * 0.9), minf(660, available.y * 0.9)))

func _open_files() -> void:
	# Native dialogs ignore the fallback theme and dimensions. On platforms
	# without a native picker, keep the file browser large enough for touch.
	var fallback_theme := Theme.new()
	fallback_theme.default_font_size = 30
	file_dialog.theme = fallback_theme
	for button in [file_dialog.get_ok_button(), file_dialog.get_cancel_button()]:
		button.custom_minimum_size = Vector2(240, 80)
	file_dialog.popup_centered_ratio(0.92)

func _import_file(path: String) -> void:
	var image := Image.load_from_file(path)
	if image == null or image.is_empty():
		return
	var side := mini(image.get_width(), image.get_height())
	image = image.get_region(Rect2i((image.get_width() - side) / 2, (image.get_height() - side) / 2, side, side))
	image.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	image.convert(Image.FORMAT_RGB8)
	for quality in [0.8, 0.65, 0.5, 0.35, 0.2]:
		chosen = Marshalls.raw_to_base64(image.save_jpg_to_buffer(quality))
		if chosen.length() <= AvatarData.MAX_ENCODED:
			break
	if chosen.length() > AvatarData.MAX_ENCODED:
		chosen = ""
		return
	preview.texture_normal = AvatarData.circular_texture(chosen)

func close() -> void:
	if bridge:
		bridge.close()
	if is_instance_valid(dialog):
		dialog.hide()
		file_dialog.hide()

func _process(_delta: float) -> void:
	if bridge:
		var value := str(bridge.drain())
		if not value.is_empty():
			var data = JSON.parse_string(value)
			if data is Dictionary:
				selected.emit(str(data.get("avatar", "")))

func _exit_tree() -> void:
	close()
