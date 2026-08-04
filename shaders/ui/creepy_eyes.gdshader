shader_type canvas_item;

// Оставляем только прогресс, вторая текстура нам больше не нужна
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

    // Берем оригинальный цвет меню/картинки
    vec4 color = texture(TEXTURE, uv);

    // Генерируем цифровой шум
    float noise = random(uv * 100.0);
    
    // Математика растворения: 
    // Чем выше прогресс, тем больше пикселей становятся прозрачными
    float alpha_mask = smoothstep(transition_progress - 0.05, transition_progress + 0.05, noise);

    // ЖЕЛЕЗНАЯ ЗАЩИТА ОТ ШУМА:
    // Если прогресс на нуле, картинка 100% непрозрачная (без шума)
    // Если прогресс на 100%, картинка полностью исчезает
    if (transition_progress <= 0.01) {
        alpha_mask = 1.0;
    } else if (transition_progress >= 0.99) {
        alpha_mask = 0.0;
    }

    COLOR = color;
    // Умножаем прозрачность картинки на нашу маску растворения
    COLOR.a *= alpha_mask;
}