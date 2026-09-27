extends RefCounted

# Palette and StyleBox geometry from Lexispell/rounded_square_btn.tscn.
const NORMAL := Color("38315a")
const HOVER := Color("7a68b8")
const TEXT := Color("f3effe")
const PANEL := Color("2c2647")
const MUTED_TEXT := Color("a79fc4")
const SHADOW := Color("0c0918")
const DISABLED := Color("2a2440")
const DISABLED_TEXT := Color("a79fc4")

static func button_style(color: Color, border_color: Color = Color.TRANSPARENT, border_width: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(22)
	style.corner_detail = 12
	style.anti_aliasing_size = 0.285
	if border_width == 2:
		# Lexispell's pressed state: inset caption and no shadow.
		style.content_margin_left = 3.0
		style.content_margin_top = 4.0
	else:
		style.content_margin_left = 10.0
		style.content_margin_right = 10.0
		style.shadow_color = Color(0.658824, 0.635294, 0.709804) if color == DISABLED else SHADOW
		if color == Color(0.909804, 0.364706, 0.407843):
			style.shadow_color = Color(0.623529, 0.207843, 0.290196)
		style.shadow_size = 1
		style.shadow_offset = Vector2(3, 4)
		if border_width > 0:
			style.set_border_width_all(4)
			style.border_color = border_color
	return style
