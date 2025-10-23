shader_type canvas_item;

uniform vec4 outline_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

uniform float outline_width : hint_range(0.0, 10.0) = 8.0;

uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0;

uniform float glow_speed : hint_range(0.0, 5.0) = 0.5;

void fragment() {

    vec4 base_color = texture(TEXTURE, UV);

    vec4 final_color = base_color;

    // Outline detection

    bool is_outline = false;

    for (float x = -outline_width; x <= outline_width; x += 1.0) {

        for (float y = -outline_width; y <= outline_width; y += 1.0) {

            if (x == 0.0 && y == 0.0) continue;

            vec2 offset_uv = UV + vec2(x, y) * TEXTURE_PIXEL_SIZE;

            if (texture(TEXTURE, offset_uv).a < 0.5 && base_color.a > 0.5) {

                is_outline = true;

                break;

            }

        }

        if (is_outline) break;

    }

    if (is_outline) {

        float glow_factor = 1.0 * 0.5 + 0.5; // Pulsating glow

        final_color = mix(final_color, outline_color * glow_intensity * glow_factor, outline_color.a);

    }   

    COLOR = final_color;

}