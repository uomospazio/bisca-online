extends Node

signal selected(avatar: String)
const AvatarData = preload("res://scenes/balatro/scripts/avatar_data.gd")
const Avatars = preload("res://scenes/balatro/scripts/avatar_catalog.gd")
var avatar_index := -1
var bridge: JavaScriptObject
var dialog: Control
var status: Label
var confirm: Button
var overlay: CanvasLayer
var preview: TextureRect
var file_dialog: FileDialog
var chosen := ""
var photo_bridge: Object
var photo_pending := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if OS.get_name() in ["iOS", "Android"] and Engine.has_singleton("BiscaVoice"):
		var native := Engine.get_singleton("BiscaVoice")
		if native.has_method("drain_photo"):
			photo_bridge = native
	if OS.has_feature("web"):
		JavaScriptBridge.eval(FileAccess.get_file_as_string("res://scenes/balatro/scripts/profile_picker.js"), true)
		bridge = JavaScriptBridge.get_interface("BiscaProfile")

func open(display_name: String) -> void:
	var current = get_parent().get("profile_avatar")
	chosen = str(current) if current != null else ""
	if chosen.is_empty():
		chosen = Avatars.encoded(0)
	avatar_index = -1
	for index in range(Avatars.TEXTURES.size()):
		if chosen == Avatars.encoded(index):
			avatar_index = index
			break
	if bridge:
		var presets: Array[String] = []
		for index in range(Avatars.TEXTURES.size()):
			presets.append(Avatars.encoded(index))
		bridge.open(display_name, chosen, JSON.stringify(presets))
		return
	# Native desktop import; browser builds also offer camera capture.
	if dialog == null:
		overlay = CanvasLayer.new()
		overlay.layer = 110
		add_child(overlay)
		dialog = Control.new()
		overlay.add_child(dialog)
		dialog.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var shade := ColorRect.new()
		shade.color = Color(0.05, 0.03, 0.1, 0.8)
		dialog.add_child(shade)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var center := CenterContainer.new()
		dialog.add_child(center)
		center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		var layout := VBoxContainer.new()
		layout.add_theme_constant_override("separation", 24)
		center.add_child(layout)
		var panel := PanelContainer.new()
		layout.add_child(panel)
		var skin := preload("res://scenes/balatro/scripts/lexispell_style.gd").button_style(Color("2c2647"), Color("7a68b8"), 4)
		for edge in ["left", "right", "top", "bottom"]:
			skin.set("content_margin_" + edge, 32)
		panel.add_theme_stylebox_override("panel", skin)
		var column := VBoxContainer.new()
		column.name = "ProfileContent"
		column.add_theme_constant_override("separation", 24)
		panel.add_child(column)
		var carousel := HBoxContainer.new()
		carousel.alignment = BoxContainer.ALIGNMENT_CENTER
		carousel.add_theme_constant_override("separation", 32)
		column.add_child(carousel)
		_avatar_arrow(carousel, "arrow-left.svg", -1)
		preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(256, 256)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		carousel.add_child(preview)
		_avatar_arrow(carousel, "arrow-right.svg", 1)
		var sources := HBoxContainer.new()
		sources.alignment = BoxContainer.ALIGNMENT_CENTER
		sources.add_theme_constant_override("separation", 24)
		column.add_child(sources)
		var camera := _button(sources, "SCATTA", _open_camera)
		camera.disabled = photo_bridge == null or not photo_bridge.has_method("open_camera")
		_button(sources, "IMPORTA", _open_files)
		status = Label.new()
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		status.add_theme_font_size_override("font_size", 26)
		status.visible = false
		column.add_child(status)
		var footer := HBoxContainer.new()
		layout.add_child(footer)
		_button(footer, "INDIETRO", close)
		var spacer := Control.new()
		spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		footer.add_child(spacer)
		confirm = _button(footer, "CONFERMA", func():
			selected.emit(chosen)
			close()
		)
		file_dialog = FileDialog.new()
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		file_dialog.use_native_dialog = true
		file_dialog.title = "SCEGLI UNA FOTO"
		file_dialog.ok_button_text = "SCEGLI"
		file_dialog.cancel_button_text = "ANNULLA"
		file_dialog.filters = PackedStringArray(["*.jpg,*.jpeg,*.png,*.webp ; Immagini"])
		add_child(file_dialog)
		file_dialog.file_selected.connect(_import_file)
	status.text = ""
	var blank := Image.create(192, 192, false, Image.FORMAT_RGB8)
	blank.fill(Color("efecfa"))
	preview.texture = AvatarData.circular_texture(chosen if not chosen.is_empty() else Marshalls.raw_to_base64(blank.save_jpg_to_buffer()))
	confirm.disabled = chosen.is_empty()
	dialog.show()

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = get_parent()._button(parent, text, action)
	button.custom_minimum_size = Vector2(300, 80)
	button.add_theme_font_size_override("font_size", 32)
	return button

func _avatar_arrow(parent: Control, icon_file: String, step: int) -> void:
	var arrow := _button(parent, "", func():
		avatar_index = posmod(avatar_index + step, Avatars.TEXTURES.size()) if avatar_index >= 0 else (0 if step > 0 else Avatars.TEXTURES.size() - 1)
		chosen = Avatars.encoded(avatar_index)
		preview.texture = AvatarData.circular_texture(chosen)
		confirm.disabled = chosen.is_empty()
		_set_status("")
	)
	arrow.custom_minimum_size = Vector2(80, 80)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	arrow.icon = load("res://scenes/balatro/trick_asset/ui_bisca/" + icon_file)
	arrow.expand_icon = true
	arrow.add_theme_constant_override("icon_max_width", 36)

func _open_camera() -> void:
	if photo_bridge != null and photo_bridge.has_method("open_camera"):
		photo_pending = true
		photo_bridge.open_camera()

func _open_files() -> void:
	if OS.get_name() == "iOS":
		if photo_bridge != null:
			photo_pending = true
			photo_bridge.open_photo()
		else:
			_set_status("Aggiorna la build iOS per scegliere una foto.")
		return
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
	preview.texture = AvatarData.circular_texture(chosen)
	avatar_index = -1
	confirm.disabled = false
	_set_status("")

func _set_status(message: String) -> void:
	status.text = message
	status.visible = not message.is_empty()

func close() -> void:
	photo_pending = false
	if bridge:
		bridge.close()
	if is_instance_valid(dialog):
		dialog.hide()
		file_dialog.hide()

func _process(_delta: float) -> void:
	if photo_bridge != null:
		var photo: String = photo_bridge.drain_photo()
		if not photo.is_empty() and photo_pending:
			photo_pending = false
			if photo != "cancel":
				if photo == "error" or photo.length() > AvatarData.MAX_ENCODED:
					_set_status("Foto non disponibile. Controlla i permessi e riprova.")
				else:
					chosen = photo
					avatar_index = -1
					preview.texture = AvatarData.circular_texture(chosen)
					confirm.disabled = false
					_set_status("")
	if bridge:
		var value := str(bridge.drain())
		if not value.is_empty():
			var data = JSON.parse_string(value)
			if data is Dictionary:
				selected.emit(str(data.get("avatar", "")))

func _exit_tree() -> void:
	close()
