shader_type canvas_item;
render_mode unshaded;

uniform float horizontal_wave_amount : hint_range(0.0, 0.01) = 0.0018;
uniform float vertical_wave_amount : hint_range(0.0, 0.005) = 0.0007;
uniform float wave_speed : hint_range(0.0, 4.0) = 1.25;

void fragment() {
	float slow_wave = sin(UV.y * 84.0 + TIME * wave_speed);
	float fine_wave = sin(UV.y * 156.0 - TIME * wave_speed * 1.7);
	vec2 water_uv = UV;
	water_uv.x += (slow_wave * 0.7 + fine_wave * 0.3) * horizontal_wave_amount;
	water_uv.y += sin(UV.x * 42.0 + TIME * wave_speed * 0.8) * vertical_wave_amount;

	vec4 water = texture(TEXTURE, water_uv);
	COLOR = water;
}
