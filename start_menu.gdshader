shader_type canvas_item;

uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    vec2 uv = UV;
    // Глюк по горизонтали на основе времени и интенсивности
    if (glitch_intensity > 0.01) {
        float time = TIME * 10.0;
        float offset = sin(uv.y * 50.0 + time) * 0.05 * glitch_intensity;
        uv.x += offset;
    }
    
    vec4 color = texture(TEXTURE, uv);
    // Добавим легкое искажение цвета при сильном глюке
    if (glitch_intensity > 0.5) {
        color.r += sin(TIME * 20.0) * 0.2 * glitch_intensity;
    }
    
    COLOR = color;
}