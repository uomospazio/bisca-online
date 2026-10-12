extends "res://scenes/balatro/scripts/multiplayer_entry_ui.gd"
signal finished(completed: bool)
const SIZE := Vector2(956, 440)
const TUTORIAL_ART := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/"
const PORTRAITS := [
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_28-1.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_29-2.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_30-3.png",
	"res://scenes/balatro/trick_asset/ui_bisca/pngUI/tutorialUI/Immagine ChatGPT 10 ott 2026, 13_42_31-4.png"]

# Copy, progress and example cards are already included in the numbered artwork.
const PORTRAIT_ORDER := [0, 2, 1, 0, 3, 2, 0, 1, 0, 3]
const COMPACT_STEPS := [3, 4, 7, 9]
var step := 0
var completed := false
var portrait: TextureRect
var slide: TextureRect
var next_button: Button
var table_background: TextureRect

func _ready() -> void:
	set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	mouse_filter = MOUSE_FILTER_STOP
	clip_contents = true
	set_meta("cartoon_style_children_excluded", true)
	table_background = _image(self, "res://scenes/balatro/trick_asset/table.png", Rect2())
	table_background.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	table_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	composition = Control.new()
	add_child(composition)
	composition.size = SIZE
	# Let the portrait reach the viewport edge instead of cutting it at the
	# safe-area composition border on wider/taller screens.
	composition.clip_contents = false
	slide = _image(composition, TUTORIAL_ART + "tutorial1.png", Rect2())
	portrait = _image(composition, PORTRAITS[0], Rect2())
	next_button = Button.new()
	composition.add_child(next_button)
	next_button.name = "TutorialNext"
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		next_button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
	# Flip just the image so the existing hover tween stays unchanged.
	var arrow := _image(next_button, "res://scenes/balatro/trick_asset/ui_bisca/pngUI/InLobbyUI/tastoIndietro.png", Rect2())
	arrow.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	arrow.flip_h = true
	next_button.pressed.connect(advance)
	RoundedSquareButton.ButtonAudio.attach(next_button)
	preload("res://scenes/balatro/scripts/menu_button_hover.gd").attach(next_button)
	get_viewport().size_changed.connect(_fit)
	_render()
	_fit.call_deferred()

func _layout(bounds: Rect2) -> void:
	if not is_instance_valid(composition): return
	var factor := maxf(0.01, minf(bounds.size.x / SIZE.x, bounds.size.y / SIZE.y))
	composition.scale = Vector2.ONE * factor
	composition.position = bounds.get_center() - SIZE * factor / 2

func _render() -> void:
	slide.texture = load(TUTORIAL_ART + "tutorial%d.png" % (step + 1))
	var compact := step in COMPACT_STEPS
	var rect := Rect2(92, 26, 774, 388)
	if step == 3:
		rect = Rect2(228, 80, 519, 338)
	elif step == 4:
		rect = Rect2(241, 124, 505, 292)
	elif compact:
		rect = Rect2(241, 283, 505, 134.25)
	slide.position = rect.position
	slide.size = rect.size
	portrait.texture = load(PORTRAITS[PORTRAIT_ORDER[step]])
	portrait.position = Vector2(112 if compact else -8, 220)
	portrait.size = Vector2(204, 306)
	next_button.position = Vector2(696, 369) if compact else Vector2(798, 354)
	next_button.size = Vector2(40, 37) if compact else Vector2(54, 49)
	next_button.pivot_offset = next_button.size / 2
	next_button.tooltip_text = "Completa tutorial" if step == 9 else "Avanti"
	next_button.scale = Vector2.ONE

func advance() -> void:
	if completed: return
	if step == 9:
		completed = true
		next_button.disabled = true
		finished.emit(true)
		return
	step += 1
	_render()
