shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform float contrast : hint_range(0.8, 1.3) = 1.06;
uniform float saturation : hint_range(0.0, 1.5) = 1.08;
uniform float vignette_strength : hint_range(0.0, 0.5) = 0.18;
uniform float highlight_glow : hint_range(0.0, 0.2) = 0.055;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec3 color = texture(screen_texture, uv).rgb;

	float luminance = dot(color, vec3(0.299, 0.587, 0.114));
	color = mix(vec3(luminance), color, saturation);
	color = (color - vec3(0.5)) * contrast + vec3(0.5);

	float vertical_mix = smoothstep(0.12, 0.92, uv.y);
	vec3 cinematic_tint = mix(
		vec3(0.96, 1.01, 1.06),
		vec3(1.045, 1.005, 0.955),
		vertical_mix
	);
	color *= cinematic_tint;

	float pulse = 0.82 + 0.18 * sin(TIME * 0.38);
	float highlights = max(luminance - 0.58, 0.0) * highlight_glow * pulse;
	color += vec3(1.0, 0.82, 0.52) * highlights;

	vec2 edge = uv * (vec2(1.0) - uv);
	float vignette = pow(clamp(16.0 * edge.x * edge.y, 0.0, 1.0), 0.16);
	color *= mix(1.0 - vignette_strength, 1.0, vignette);

	COLOR = vec4(clamp(color, vec3(0.0), vec3(1.0)), 1.0);
}
