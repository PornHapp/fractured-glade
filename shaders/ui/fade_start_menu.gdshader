shader_type canvas_item;

uniform sampler2D dark_texture; 
uniform float transition_progress : hint_range(0.0, 1.0) = 0.0; 

float random(vec2 uv) {
    return fract(sin(dot(uv.xy, vec2(12.9898,78.233))) * 43758.5453123);
}

void fragment() {
    vec2 uv = UV;

    // Глитч искажает картинку только в середине перехода
    float glitch_intensity = sin(transition_progress * 3.1415); 

    if (glitch_intensity > 0.0) {
        float block = floor(uv.y * 20.0);
        float offset = (random(vec2(block, TIME)) - 0.5) * glitch_intensity * 0.5;
        uv.x += offset;
    }

    vec4 light_color = texture(TEXTURE, uv);
    vec4 dark_color = texture(dark_texture, uv);

    // Генерируем цифровой шум
    float noise = random(uv * 100.0);
    
    // ИДЕАЛЬНАЯ МАТЕМАТИКА: 
    // Если progress 0.0, mix_factor = 0 (светлый мир)
    // Если progress 1.0, mix_factor = 1 (темный мир)
    // А посередине будет красивое пиксельное растворение
    float mix_factor = smoothstep(noise - 0.05, noise + 0.05, transition_progress);

    COLOR = mix(light_color, dark_color, mix_factor);
}