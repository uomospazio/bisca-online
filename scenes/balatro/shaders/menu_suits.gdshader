shader_type canvas_item;
render_mode unshaded;

uniform sampler2D denari : filter_linear_mipmap;
uniform sampler2D coppe : filter_linear_mipmap;
uniform sampler2D spade : filter_linear_mipmap;
uniform sampler2D bastoni : filter_linear_mipmap;
uniform vec2 surface_size = vec2(1920.0, 1080.0);
uniform vec4 paper : source_color = vec4(0.992157, 0.992157, 0.984314, 1.0); // Dub Together PAPER: #FDFDFB.
uniform float ink_opacity = 0.075;

float random_value(vec2 cell) {
	return fract(sin(dot(cell, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 grid = (UV * surface_size - TIME * vec2(11.0, 8.0)) / 128.0;
	grid.x += mod(floor(grid.y), 2.0) * 0.5;
	vec2 cell = floor(grid);
	float seed = random_value(cell);
	vec2 point = (fract(grid) - 0.5) * 128.0;
	point -= vec2(seed - 0.5, random_value(cell + 3.7) - 0.5) * 24.0;
	float angle = (random_value(cell + 7.3) - 0.5) * 0.7;
	point = mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle))) * point;
	vec2 sample_uv = point / mix(48.0, 66.0, seed) + 0.5;
	float kind = floor(random_value(cell + 12.8) * 4.0);
	vec4 symbol;
	if (kind < 1.0) { symbol = texture(denari, sample_uv); }
	else if (kind < 2.0) { symbol = texture(coppe, sample_uv); }
	else if (kind < 3.0) { symbol = texture(spade, sample_uv); }
	else { symbol = texture(bastoni, sample_uv); }
	float mask = step(0.0, sample_uv.x) * step(sample_uv.x, 1.0) * step(0.0, sample_uv.y) * step(sample_uv.y, 1.0);
	COLOR = vec4(mix(paper.rgb, vec3(0.133, 0.122, 0.169), symbol.a * mask * ink_opacity), 1.0);
}
