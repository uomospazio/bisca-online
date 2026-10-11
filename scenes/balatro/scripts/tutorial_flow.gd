extends CanvasLayer
## Local onboarding only: never changes accounts, wallets or match statistics.
const SAVE := "user://bisca_tutorial.cfg"
var save_path := SAVE
var tutorial: Control

static func was_offered(path: String = SAVE) -> bool:
	var config := ConfigFile.new()
	config.load(path)
	return bool(config.get_value("tutorial", "offered", false))

func _remember(completed := false) -> void:
	var config := ConfigFile.new()
	config.load(save_path)
	config.set_value("tutorial", "offered", true)
	if completed: config.set_value("tutorial", "completed", true)
	config.save(save_path)

func offer() -> void:
	layer = 150
	var shield := ColorRect.new()
	shield.color = Color(0.04, 0.02, 0.12, 0.7)
	add_child(shield)
	shield.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var dialog = preload("res://scenes/balatro/scripts/menu_dialog.gd").new()
	dialog.title = "BENVENUTO SU BISCA!"
	dialog.dialog_text = "Ti va di imparare a giocare?"
	dialog.ok_button_text = "AVVIA TUTORIAL"
	dialog.cancel_button_text = "SALTA"
	add_child(dialog)
	dialog.canceled.connect(func(): _remember(); queue_free())
	dialog.confirmed.connect(func():
		_remember()
		shield.queue_free()
		dialog.queue_free()
		start())
	dialog.popup_centered(Vector2i(1000, 420))

func start() -> void:
	layer = 150
	_remember()
	tutorial = preload("res://scenes/balatro/scripts/tutorial_page.gd").new()
	add_child(tutorial)
	tutorial.finished.connect(func(completed: bool): _remember(completed); queue_free())
