shader_type canvas_item;

// Настройки цвета и прозрачности блика (настраивается через альфа-канал цвета)
uniform vec4 shine_color : source_color = vec4(1.0, 1.0, 1.0, 0.25);

// Настройки движения
uniform float angle = 0.6; // Угол наклона блика (0.0 - вертикально, 1.0 - сильный наклон)
uniform float speed = 1.2; // Скорость движения
uniform float wait_time = 3.0; // Пауза в секундах между пролетами блика

// Настройки полос
uniform float stripe1_width = 0.06; // Ширина первой (главной) полосы
uniform float stripe2_width = 0.02; // Ширина второй (тонкой) полосы
uniform float stripe_distance = 0.1; // Расстояние между ними

void fragment() {
    // Берем оригинальный цвет логотипа
    vec4 tex_color = texture(TEXTURE, UV);
    
    // Искажаем координаты, чтобы получить наклон
    float tilted_uv = UV.x + UV.y * angle;
    
    // Зацикливаем время с паузой. 
    // Смещаем на -0.5, чтобы блик выезжал из-за левого края картинки, а не появлялся из ниоткуда.
    float current_time = mod(TIME * speed, wait_time) - 0.5;
    
    // Вычисляем расстояние от пикселя до текущей позиции блика
    float dist = tilted_uv - current_time;
    
    // --- ПЕРВАЯ ПОЛОСА ---
    // Функция step дает жесткие края. Вычитаем один step из другого, чтобы получить четкую полоску.
    float s1 = step(0.0, dist) - step(stripe1_width, dist);
    
    // --- ВТОРАЯ ПОЛОСА ---
    // То же самое, но с отступом stripe_distance
    float s2 = step(stripe_distance, dist) - step(stripe_distance + stripe2_width, dist);
    
    // Складываем обе полосы вместе
    float total_shine = clamp(s1 + s2, 0.0, 1.0);
    
    // --- СМЕШИВАНИЕ ---
    // Добавляем цвет блика поверх логотипа (аддитивное наложение), чтобы не терять текстуру
    vec3 final_color = tex_color.rgb + (shine_color.rgb * shine_color.a * total_shine);
    
    // Применяем финальный цвет, жестко сохраняя прозрачность самого логотипа
    COLOR.rgb = final_color;
    COLOR.a = tex_color.a;
}