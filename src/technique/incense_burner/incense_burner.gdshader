shader_type canvas_item;

// Uniforms for customization in the Inspector
uniform vec4 smoke_color : source_color = vec4(0.8, 0.8, 0.8, 0.5); // Base color and alpha
uniform float radius : hint_range(0.0, 1.0) = 0.5; // Inner radius of the effect (0.0 to 0.5)
uniform float softness : hint_range(0.0, 0.5) = 0.1; // How soft the edge is
uniform sampler2D noise_texture : hint_default_white; // Noise texture for smoke pattern
uniform float noise_scale : hint_range(0.1, 20.0) = 5.0; // How large the noise pattern appears
uniform float scroll_speed : hint_range(0.0, 1.0) = 0.1; // How fast the smoke scrolls
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.05; // How fast the smoke rotates

// Function to create rotation matrix
mat2 rotate(float angle) {
    return mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
}

void fragment() {
    // Center UV coordinates (0,0 is center, range is roughly -0.5 to 0.5)
    vec2 centered_uv = UV - vec2(0.5);

    // Calculate distance from center
    float dist = length(centered_uv);

    // Create a circular mask with soft edges
    float circle_mask = 1.0 - smoothstep(radius - softness, radius + softness, dist);

    // Early exit if outside the circle
    if (circle_mask <= 0.0) {
        discard; // Or set COLOR.a = 0.0;
    }

    // Calculate rotated and scrolled UVs for noise sampling
    float time_scroll = TIME * scroll_speed;
    float time_rotate = TIME * rotation_speed * TAU; // TAU is 2*PI

    vec2 rotated_uv = rotate(time_rotate) * centered_uv;
    vec2 noise_uv = (rotated_uv + vec2(0.5)) * noise_scale + vec2(time_scroll, 0.0); // Add scrolling offset

    // Sample the noise texture
    float noise_value = texture(noise_texture, noise_uv).r; // Use red channel of noise

    // Combine circle mask and noise, modulate final alpha
    float final_alpha = circle_mask * noise_value * smoke_color.a;

    // Set final color
    COLOR = vec4(smoke_color.rgb, final_alpha);
}