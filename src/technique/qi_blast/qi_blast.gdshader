shader_type canvas_item;

uniform vec4 aura_color : source_color = vec4(0.832, 1.0, 0.996, 0.5); // Aura color (RGB) and translucency (A)
uniform float aura_width : hint_range(0.0, 16.0) = 2.0; // Width in pixels

void fragment() {
    vec2 tex_size = vec2(textureSize(TEXTURE, 0));
    vec4 original_color = texture(TEXTURE, UV);
    float outline_alpha = 0.0;

    // --- Outline Detection ---
    // Find the maximum alpha value in the neighbourhood within aura_width
    for (float x = -aura_width; x <= aura_width; x += 1.0) {
        for (float y = -aura_width; y <= aura_width; y += 1.0) {
            // Optional: Use length check for a rounder aura
            // if (length(vec2(x, y)) > aura_width) continue;

            vec2 offset = vec2(x, y) / tex_size;
            outline_alpha = max(outline_alpha, texture(TEXTURE, UV + offset).a);
        }
    }

    // Modulate outline alpha by the desired aura translucency
    // Only apply outline where the original texture is transparent
    outline_alpha = step(original_color.a, 0.001) * outline_alpha * aura_color.a;

    // --- Color Calculation ---
    // Calculate the base color by mixing the original sprite color with the aura color
    // The mix factor is the aura's alpha, applied only where the original sprite is visible
    vec3 mixed_rgb = mix(original_color.rgb, aura_color.rgb, aura_color.a * step(0.001, original_color.a));

    // If this pixel is part of the outline (original was transparent), use the pure aura color instead
    vec3 final_rgb = mix(mixed_rgb, aura_color.rgb, step(original_color.a, 0.001) * step(0.001, outline_alpha));

    // Final alpha is the max of original alpha and the calculated outline alpha
    float final_alpha = max(original_color.a, outline_alpha);

    COLOR = vec4(final_rgb, final_alpha);
}