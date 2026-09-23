shader_type canvas_item;
render_mode unshaded;

uniform vec4 base_color : source_color = vec4(0.156863, 0.560784, 0.392157, 1.0);
uniform vec4 edge_color : source_color = vec4(0.117647, 0.376471, 0.286275, 1.0);
uniform vec4 center_color : source_color = vec4(0.329412, 0.729412, 0.474510, 1.0);
uniform vec2 surface_size = vec2(1920.0, 1080.0);

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec2 centered = (UV - vec2(0.5, 0.46)) * 2.0;
	float radius = length(centered * vec2(0.82, 1.0));
	float glow = 1.0 - smoothstep(0.0, 0.92, radius);
	float vignette = smoothstep(0.58, 1.25, radius);
	vec3 felt = mix(base_color.rgb, center_color.rgb, glow * 0.85);
	felt = mix(felt, edge_color.rgb, vignette);
	// Static, subtle fibers: no animated noise or distracting repeating symbols.
	vec2 fibers = floor(UV * surface_size / 2.5);
	float texture_grain = grain(fibers) - 0.5;
	felt += texture_grain * 0.022;
	COLOR = vec4(felt, 1.0);
}
