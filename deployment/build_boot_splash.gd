extends SceneTree
## Render static launch UI from existing assets; never modifies the source PNGs.
## Run: godot --headless --path . --script deployment/build_boot_splash.gd
const HOME := "res://scenes/balatro/trick_asset/ui_bisca/pngUI/homeUI/"
const OUTPUT := "res://scenes/balatro/trick_asset/ui_bisca/boot_splash.png"
const TITLE_WIDTH_RATIO := 0.50 # Includes the transparent glow; lettering is about 1/3.

func _initialize() -> void:
	var background := Image.load_from_file(HOME + "sfondoViola.png")
	var title := Image.load_from_file(HOME + "titoloHome.png")
	if background == null or title == null:
		push_error("Missing launch UI assets")
		quit(1)
		return
	background.convert(Image.FORMAT_RGBA8)
	title.convert(Image.FORMAT_RGBA8)
	var width := roundi(background.get_width() * TITLE_WIDTH_RATIO)
	var height := roundi(float(width) * title.get_height() / title.get_width())
	title.resize(width, height, Image.INTERPOLATE_LANCZOS)
	var position := (background.get_size() - title.get_size()) / 2
	background.blend_rect(title, Rect2i(Vector2i.ZERO, title.get_size()), position)
	var error := background.save_png(OUTPUT)
	if error != OK:
		push_error("Cannot save launch UI: " + error_string(error))
		quit(1)
		return
	print("PASS: launch UI rendered, centered title, native aspect ratio: ", background.get_size())
	quit()
