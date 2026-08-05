shader_type canvas_item;

// Настройки перспективы
uniform float fov : hint_range(1.0, 179.0) = 90.0;
uniform float rotation_y : hint_range(-90.0, 90.0) = 30.0; // Инвертировали базовый угол

// Наклон (курсив)
uniform float italic_skew : hint_range(-2.0, 2.0) = -0.3; 

// Позиционирование
uniform float offset_x : hint_range(-200.0, 200.0) = 0.0;
uniform float offset_y : hint_range(-200.0, 200.0) = 0.0;

void vertex() {
	// 1. Применяем наклон влево/назад
	VERTEX.x += VERTEX.y * italic_skew;

	// 2. Смещение для подгонки по центру
	VERTEX.x += offset_x;
	VERTEX.y += offset_y;

	// 3. Вычисление перспективного разворота
	float rad = radians(rotation_y);
	float sin_r = sin(rad);
	float cos_r = cos(rad);
	
	vec2 pos = VERTEX;
	
	// Отраженная формула Z: теперь чем левее точка (меньше pos.x), тем она БЛИЖЕ к экрану
	float z = -pos.x * sin_r + 300.0;
	
	if (z > 1.0) {
		float scale = 300.0 / z;
		VERTEX.x = pos.x * cos_r * scale;
		VERTEX.y = pos.y * scale;
	}
}