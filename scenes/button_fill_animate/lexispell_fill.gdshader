shader_type canvas_item;

uniform vec4 fill_color : source_color;
uniform float progress : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Lexispell's left-to-right fill on a rounded Panel. Preserve the Panel's
	// alpha as well, so parent fades and rounded edge antialiasing still work.
	COLOR = vec4(fill_color.rgb, COLOR.a * fill_color.a * step(UV.x, progress));
}
