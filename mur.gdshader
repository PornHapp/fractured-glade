shader_type canvas_item;

uniform bool EnableShader = true;
// Wether the gradient distance is calculated towards to bottom edge of the pixel
// if disabled, uses a corner of the pixel
uniform bool LinearGradient = false;
uniform bool ClampDist = true;
// "Offsets the point" where the distance is measured from, effectively moving the gradient
uniform float DistOffset: hint_range(-1.0, 1.0, 0.01) = -0.1;
// Just a constant value to add to the gradient to control the strength
uniform float DistAdd: hint_range(-1.0, 1.0, 0.01) = -0.13;
// If you are using upscaled pixel art, you can use this value to scale the grid up
uniform int GridScale: hint_range(1,100000, 1) = 1;
// Color of the gradient
uniform vec4 ModulateColor: source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float GradientOpacity: hint_range(0.0, 1.0, 0.01) = 0.5;

vec2 grid(vec2 uv, vec2 tex_size){
	return fract(uv * tex_size / vec2(float(GridScale)));
}


void fragment() {
	if (EnableShader) {
		vec4 orig_color = texture(TEXTURE, UV);
		vec2 tex_size = vec2(textureSize(TEXTURE, 0));

		vec2 grid_uv = grid(UV, tex_size);
		float dist = 0.0;
		if (LinearGradient) {
			dist = 1.0 - (grid_uv.y + DistOffset);
		} else {
			dist = sqrt(pow(1.0 - (grid_uv.x + DistOffset), 2.0) + pow(1.0 - (grid_uv.y + DistOffset), 2.0));
		}
		dist += DistAdd;
		if (ClampDist) dist = clamp(dist, 0.0, 1.0);
		COLOR = mix(orig_color, ModulateColor, (1.0 - dist) * GradientOpacity);
	}
}
