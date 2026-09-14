extends RefCounted

# Palette and StyleBox geometry from Lexispell/rounded_square_btn.tscn.
const NORMAL := Color("474660")
const HOVER := Color("74ab8e")
const TEXT := Color("fde4b9")
const SHADOW := Color("313145")
const DISABLED := Color(0.38, 0.38, 0.38)
const DISABLED_TEXT := Color(0.65, 0.65, 0.65)

static func button_style(color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(16)
	style.corner_detail = 12
	style.anti_aliasing_size = 0.285
	if border_width == 2:
		# Lexispell's pressed state: inset caption and no shadow.
		style.content_margin_left = 3.0
		style.content_margin_top = 4.0
	else:
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.shadow_color = Color(0.27, 0.27, 0.27) if color == DISABLED else SHADOW
		if color == Color(0.89, 0.3204, 0.3204):
			style.shadow_color = Color(0.69, 0.2484, 0.2484)
		style.shadow_size = 1
		style.shadow_offset = Vector2(3, 4)
		if border_width > 0:
			style.set_border_width_all(4)
			style.border_color = border_color
	return style
