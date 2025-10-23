shader_type canvas_item;

uniform float wind_strength : hint_range(0.0, 0.2) = 0.05;
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;
uniform vec2 rotation_pivot = vec2(0.5, 1.0);

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 0.0, 1.0);
uniform float outline_width : hint_range(0.0, 10.0) = 3.0;
uniform float glow_strength : hint_range(0.0, 2.0) = 0.8;
uniform bool highlight_enabled = false;

void fragment() {
	float time = TIME * wind_speed;
	float angle = sin(time + UV.y * 3.0) * wind_strength;
	
	vec2 rotated_uv = UV - rotation_pivot;
	rotated_uv = vec2(
		rotated_uv.x * cos(angle) - rotated_uv.y * sin(angle),
		rotated_uv.x * sin(angle) + rotated_uv.y * cos(angle)
	);
	rotated_uv += rotation_pivot;
	
	vec4 tex = texture(TEXTURE, rotated_uv);
	
	if (highlight_enabled) {
		vec2 pixel_size = TEXTURE_PIXEL_SIZE * outline_width;
		
		// Échantillonner 8 directions pour l'outline
		float outline = 0.0;
		outline += texture(TEXTURE, rotated_uv + vec2(pixel_size.x, 0.0)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(-pixel_size.x, 0.0)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(0.0, pixel_size.y)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(0.0, -pixel_size.y)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(pixel_size.x, pixel_size.y)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(-pixel_size.x, -pixel_size.y)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(pixel_size.x, -pixel_size.y)).a;
		outline += texture(TEXTURE, rotated_uv + vec2(-pixel_size.x, pixel_size.y)).a;
		outline = clamp(outline, 0.0, 1.0);
		
		float pulse = sin(TIME * 4.0) * 0.5 + 0.5;
		
		if (tex.a < 0.1 && outline > 0.1) {
			COLOR = vec4(outline_color.rgb, outline_color.a * pulse);
		} 
		else if (tex.a > 0.1) {
			vec3 glow = outline_color.rgb * glow_strength * pulse;
			COLOR = vec4(tex.rgb + glow, tex.a);
		}
		else {
			COLOR = tex;
		}
	} else {
		COLOR = tex;
	}
}