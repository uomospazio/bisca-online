shader_type canvas_item;
render_mode unshaded;

uniform vec2 body_size = vec2(160.0, 46.0);
uniform float corner_radius = 30.0;
uniform float inner_border = 3.0;
uniform float outer_border = 2.0;
uniform vec4 fill_top : source_color = vec4(0.223529, 0.172549, 0.533333, 1.0);
uniform vec4 fill_bottom : source_color = vec4(0.152941, 0.121569, 0.364706, 1.0);
uniform vec4 border_top : source_color = vec4(0.537255, 0.407843, 0.913725, 1.0);
uniform vec4 border_bottom : source_color = vec4(0.262745, 0.192157, 0.584314, 1.0);
uniform float brightness = 1.0;
uniform bool pill_highlight = false;

float rounded_distance(vec2 p, vec2 half_size, float radius) {
	vec2 q = abs(p) - half_size + vec2(radius);
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius;
}

void fragment() {
	vec2 p = UV * (body_size + vec2(2.0 * outer_border)) - outer_border;
	float radius = min(corner_radius, min(body_size.x, body_size.y) * 0.5);
	float d = rounded_distance(p - body_size * 0.5, body_size * 0.5, radius);
	float aa = max(fwidth(d), 0.001);
	float t = clamp(p.y / max(body_size.y, 1.0), 0.0, 1.0);
	vec4 fill = mix(fill_top, fill_bottom, t);
	vec4 border = mix(border_top, border_bottom, t);
	float body_mask = 1.0 - smoothstep(-aa * 0.5, aa * 0.5, d);
	float fill_mask = 1.0 - smoothstep(-inner_border - aa * 0.5, -inner_border + aa * 0.5, d);
	vec3 rgb = mix(vec3(0.0), border.rgb, body_mask);
	rgb = mix(rgb, fill.rgb, fill_mask);
	if (pill_highlight) {
		float s = body_size.y / 46.0;
		vec2 a = vec2(11.0, 12.0) * s;
		vec2 b = vec2(15.0, 9.0) * s;
		vec2 pa = p - a;
		vec2 ba = b - a;
		float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
		float shine = length(pa - ba * h) - 1.3 * s;
		float mask = (1.0 - smoothstep(-aa * 0.5, aa * 0.5, shine)) * fill_mask;
		rgb = mix(rgb, vec3(0.94, 0.92, 1.0), mask);
	}
	float alpha = 1.0 - smoothstep(outer_border - aa, outer_border, d);
	COLOR = vec4(rgb * brightness, alpha) * COLOR;
}
