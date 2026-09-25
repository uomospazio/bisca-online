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
		dialog.add_child(column)
		var name_label := Label.new()
		name_label.name = "ProfileName"
		column.add_child(name_label)
		preview = TextureButton.new()
		preview.custom_minimum_size = Vector2(192, 192)
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(preview)
		var hint := Label.new()
		hint.text = "Premi il cerchio per importare una foto.\nPer scattarla usa la versione browser.\nLa foto sara' condivisa con la lobby."
		column.add_child(hint)
		file_dialog = FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.filters = PackedStringArray(["*.jpg,*.jpeg,*.png,*.webp ; Immagini"])
		add_child(file_dialog)
		preview.pressed.connect(func(): file_dialog.popup_centered(Vector2i(800, 500)))
		file_dialog.file_selected.connect(_import_file)
		dialog.confirmed.connect(func(): selected.emit(chosen))
		dialog.canceled.connect(func(): selected.emit(""))
	dialog.get_node("ProfileContent/ProfileName").text = display_name
	var blank := Image.create(192, 192, false, Image.FORMAT_RGB8)
	blank.fill(Color("efecfa"))
	preview.texture_normal = AvatarData.circular_texture(Marshalls.raw_to_base64(blank.save_jpg_to_buffer()))
	dialog.popup_centered(Vector2i(460, 400))

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
