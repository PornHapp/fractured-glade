shader_type canvas_item;

render_mode blend_mix;

//////////////////////////////////////////////////////////
// SCREEN
//////////////////////////////////////////////////////////

uniform sampler2D screen_tex :
hint_screen_texture,
filter_linear_mipmap;

//////////////////////////////////////////////////////////
// MAIN
//////////////////////////////////////////////////////////

uniform float break_progress :
hint_range(0.0, 1.0) = 0.0;

uniform vec2 impact_point =
vec2(0.5, 0.5);

//////////////////////////////////////////////////////////
// GLASS MASK SHAPE
//////////////////////////////////////////////////////////

uniform bool use_glass_mask = true;

uniform bool glass_mask_circle = true;

uniform vec2 glass_mask_scale =
vec2(0.35, 0.35);

uniform vec2 glass_mask_position =
vec2(0.5, 0.5);

uniform float glass_mask_rotation :
hint_range(-180.0, 180.0) = 0.0;

uniform float glass_mask_softness :
hint_range(0.0, 0.5) = 0.02;

//////////////////////////////////////////////////////////
// IMPACT SHAPE
//////////////////////////////////////////////////////////

uniform bool use_circle_impact = true;

uniform vec2 impact_shape_scale =
vec2(1.0, 1.0);

uniform float impact_rotation :
hint_range(-180.0, 180.0) = 0.0;

//////////////////////////////////////////////////////////
// SHARDS
//////////////////////////////////////////////////////////

uniform int pieces_x = 12;
uniform int pieces_y = 8;

uniform float point_jitter :
hint_range(0.0, 0.48) = 0.34;

uniform float shard_scatter :
hint_range(0.0, 2.0) = 0.35;

uniform float gravity :
hint_range(0.0, 6.0) = 2.4;

uniform float rotation_amount :
hint_range(0.0, 8.0) = 2.0;

uniform float delay_variation :
hint_range(0.0, 1.0) = 0.35;

//////////////////////////////////////////////////////////
// CRACKS
//////////////////////////////////////////////////////////

uniform float crack_width :
hint_range(0.0001, 0.03) = 0.002;

uniform float crack_brightness :
hint_range(0.0, 5.0) = 1.5;

uniform float crack_density :
hint_range(0.0, 3.0) = 1.0;

uniform vec4 crack_color :
source_color =
vec4(1.0,1.0,1.0,1.0);

//////////////////////////////////////////////////////////
// GLASS
//////////////////////////////////////////////////////////

uniform vec4 glass_tint :
source_color =
vec4(0.75,0.9,1.0,0.15);

uniform float transparency :
hint_range(0.0,1.0) = 0.15;

//////////////////////////////////////////////////////////
// HOLES
//////////////////////////////////////////////////////////

uniform float center_hole_size :
hint_range(0.0,0.5) = 0.08;

uniform float hole_irregularity :
hint_range(0.0,1.0) = 0.4;

//////////////////////////////////////////////////////////
// FX
//////////////////////////////////////////////////////////

uniform float refraction :
hint_range(0.0,0.1) = 0.015;

uniform float chromatic :
hint_range(0.0,0.05) = 0.003;

uniform float shake :
hint_range(0.0,0.1) = 0.008;

uniform bool pixelated = false;

uniform float pixel_size :
hint_range(1.0,256.0) = 4.0;

//////////////////////////////////////////////////////////

const int SEARCH_RADIUS = 1;

//////////////////////////////////////////////////////////
// HASH
//////////////////////////////////////////////////////////

float hash12(vec2 p) {

	vec3 p3 =
	fract(vec3(p.xyx) * 0.1031);

	p3 += dot(p3, p3.yzx + 33.33);

	return fract(
		(p3.x + p3.y)
		* p3.z
	);
}

vec2 hash22(vec2 p) {

	return vec2(
		hash12(p + vec2(1.23,4.56)),
		hash12(p + vec2(7.89,0.12))
	);
}

//////////////////////////////////////////////////////////
// ROT
//////////////////////////////////////////////////////////

mat2 rot(float a) {

	float s = sin(a);
	float c = cos(a);

	return mat2(
		vec2(c,-s),
		vec2(s,c)
	);
}

//////////////////////////////////////////////////////////
// NOISE
//////////////////////////////////////////////////////////

float noise(vec2 p){

	vec2 i = floor(p);
	vec2 f = fract(p);

	float a = hash12(i);
	float b = hash12(i + vec2(1.0,0.0));
	float c = hash12(i + vec2(0.0,1.0));
	float d = hash12(i + vec2(1.0,1.0));

	vec2 u =
	f*f*(3.0-2.0*f);

	return mix(a,b,u.x)
	+ (c-a)*u.y*(1.0-u.x)
	+ (d-b)*u.x*u.y;
}

//////////////////////////////////////////////////////////
// CELL POINT
//////////////////////////////////////////////////////////

vec2 cell_point(vec2 cell_id) {

	vec2 h = hash22(cell_id);

	return cell_id
	+ 0.5
	+ (h - 0.5)
	* (point_jitter * 2.0);
}

//////////////////////////////////////////////////////////
// VORONOI
//////////////////////////////////////////////////////////

void voronoi_info(
	vec2 p,
	out vec2 owner_cell,
	out vec2 owner_point,
	out float edge_dist
){

	vec2 base = floor(p);

	float best_d = 1e20;
	float second_d = 1e20;

	vec2 best_cell = vec2(0.0);
	vec2 best_point = vec2(0.0);

	for(int j=-SEARCH_RADIUS;j<=SEARCH_RADIUS;j++){

		for(int i=-SEARCH_RADIUS;i<=SEARCH_RADIUS;i++){

			vec2 c =
			base + vec2(float(i),float(j));

			vec2 pt =
			cell_point(c);

			float d =
			distance(p,pt);

			if(d < best_d){

				second_d = best_d;
				best_d = d;

				best_cell = c;
				best_point = pt;

			}else if(d < second_d){

				second_d = d;
			}
		}
	}

	owner_cell = best_cell;
	owner_point = best_point;

	edge_dist =
	second_d - best_d;
}

//////////////////////////////////////////////////////////
// GLASS MASK
//////////////////////////////////////////////////////////

float glass_mask(vec2 uv){

	vec2 local_uv =
	uv - glass_mask_position;

	float rot_rad =
	radians(glass_mask_rotation);

	local_uv =
	rot(rot_rad) * local_uv;

	local_uv /= glass_mask_scale;

	float dist;

	if(glass_mask_circle){

		dist = length(local_uv);

	}else{

		vec2 d = abs(local_uv);

		dist = max(d.x, d.y);
	}

	return 1.0 - smoothstep(
		1.0 - glass_mask_softness,
		1.0,
		dist
	);
}

//////////////////////////////////////////////////////////
// SHARD TRANSFORM
//////////////////////////////////////////////////////////

void piece_transform(

	vec2 piece_cell,

	out float t,
	out vec2 piece_offset_uv,
	out float piece_angle

){

	float rnd =
	hash12(piece_cell);

	float rnd2 =
	hash12(piece_cell + 17.37);

	float rnd3 =
	hash12(piece_cell + 91.11);

	vec2 grid =
	vec2(
		float(pieces_x),
		float(pieces_y)
	);

	vec2 piece_uv =
	(piece_cell + 0.5) / grid;

	float impact_dist =
	distance(
		piece_uv,
		impact_point
	);

	float radial_delay =
	impact_dist * delay_variation;

	float delay =
	rnd * 0.2
	+ radial_delay;

	t = clamp(
		(break_progress - delay)
		/ max(0.0001,1.0-delay),
		0.0,
		1.0
	);

	vec2 explode_dir =
	normalize(
		piece_uv
		- impact_point
	);

	float explode_force =
	(1.0 - impact_dist);

	explode_force =
	max(explode_force,0.0);

	float drift_x =
	explode_dir.x
	* shard_scatter
	* t
	* explode_force;

	float drift_y =
	explode_dir.y
	* shard_scatter
	* 0.35
	* t
	* explode_force;

	float fall_y =
	gravity
	* t
	* t
	* (0.3 + rnd2);

	piece_offset_uv =
	vec2(
		drift_x,
		drift_y + fall_y
	);

	piece_angle =
	(rnd - 0.5)
	* rotation_amount
	* t
	* explode_force;
}

//////////////////////////////////////////////////////////
// MAIN
//////////////////////////////////////////////////////////

void fragment() {

	vec2 uv = UV;

	//////////////////////////////////////////////////////
	// PIXEL
	//////////////////////////////////////////////////////

	if(pixelated){

		uv =
		floor(uv * pixel_size)
		/ pixel_size;
	}

	//////////////////////////////////////////////////////
	// SHAKE
	//////////////////////////////////////////////////////

	uv += vec2(
		sin(TIME*120.0 + uv.y*40.0),
		cos(TIME*90.0 + uv.x*50.0)
	) * shake * break_progress;

	//////////////////////////////////////////////////////
	// FRACTURE SPACE
	//////////////////////////////////////////////////////

	vec2 grid =
	vec2(
		float(pieces_x),
		float(pieces_y)
	);

	vec2 p_now =
	uv * grid;

	//////////////////////////////////////////////////////
	// CURRENT SHARD
	//////////////////////////////////////////////////////

	vec2 now_cell;
	vec2 now_point;

	float now_edge;

	voronoi_info(
		p_now,
		now_cell,
		now_point,
		now_edge
	);

	//////////////////////////////////////////////////////
	// TRANSFORM
	//////////////////////////////////////////////////////

	float t;

	vec2 piece_offset_uv;

	float piece_angle;

	piece_transform(
		now_cell,
		t,
		piece_offset_uv,
		piece_angle
	);

	//////////////////////////////////////////////////////
	// SHARD CENTER
	//////////////////////////////////////////////////////

	vec2 piece_center_uv =
	now_point / grid;

	//////////////////////////////////////////////////////
	// REVERSE TRANSFORM
	//////////////////////////////////////////////////////

	vec2 rel_now =
	uv - piece_center_uv;

	vec2 uv_from =
	piece_center_uv
	+ rot(-piece_angle)
	* (rel_now - piece_offset_uv);

	//////////////////////////////////////////////////////
	// SCREEN MASK
	//////////////////////////////////////////////////////

	float inside_screen =

	step(0.0, uv_from.x)
	*
	step(0.0, uv_from.y)
	*
	step(uv_from.x,1.0)
	*
	step(uv_from.y,1.0);

	vec2 safe_uv =
	clamp(
		uv_from,
		vec2(0.0),
		vec2(1.0)
	);

	//////////////////////////////////////////////////////
	// ORIGINAL SHARD
	//////////////////////////////////////////////////////

	vec2 p_from =
	safe_uv * grid;

	vec2 from_cell;
	vec2 from_point;

	float from_edge;

	voronoi_info(
		p_from,
		from_cell,
		from_point,
		from_edge
	);

	float same_piece =
	1.0
	- step(
		0.001,
		distance(
			from_cell,
			now_cell
		)
	);

	//////////////////////////////////////////////////////
	// IMPACT SHAPE
	//////////////////////////////////////////////////////

	vec2 local_uv =
	uv - impact_point;

	float rot_rad =
	radians(impact_rotation);

	local_uv =
	rot(rot_rad) * local_uv;

	local_uv /= impact_shape_scale;

	float impact_dist;

	if(use_circle_impact){

		impact_dist =
		length(local_uv);

	}else{

		vec2 d = abs(local_uv);

		impact_dist =
		max(d.x, d.y);
	}

	//////////////////////////////////////////////////////
	// REFRACTION
	//////////////////////////////////////////////////////

	vec2 refract_dir =
	(normalize(
		uv - impact_point
	) * refraction);

	vec2 refract_uv =
	SCREEN_UV
	+ refract_dir
	* t;

	//////////////////////////////////////////////////////
	// CHROMATIC
	//////////////////////////////////////////////////////

	float r =
	texture(
		screen_tex,
		refract_uv
		+ vec2(chromatic,0.0)
	).r;

	float g =
	texture(
		screen_tex,
		refract_uv
	).g;

	float b =
	texture(
		screen_tex,
		refract_uv
		- vec2(chromatic,0.0)
	).b;

	vec4 col =
	texture(
		screen_tex,
		SCREEN_UV
	);

	col.rgb = vec3(r,g,b);

	//////////////////////////////////////////////////////
	// GLASS TINT
	//////////////////////////////////////////////////////

	col.rgb =
	mix(
		col.rgb,
		glass_tint.rgb,
		transparency
	);

	//////////////////////////////////////////////////////
	// CRACK EDGES
	//////////////////////////////////////////////////////

	float edge =
	1.0
	- smoothstep(
		0.0,
		crack_width,
		now_edge
	);

	//////////////////////////////////////////////////////
	// RADIAL CRACKS
	//////////////////////////////////////////////////////

	float radial =
	abs(
		sin(
			atan(
				uv.y - impact_point.y,
				uv.x - impact_point.x
			)
			* 30.0
		)
	);

	radial =
	pow(radial, 24.0);

	float radial_fade =
	smoothstep(
		1.0,
		0.0,
		impact_dist
	);

	float crack_mask =
	radial
	* radial_fade
	* break_progress
	* crack_density;

	//////////////////////////////////////////////////////
	// COMBINE CRACKS
	//////////////////////////////////////////////////////

	float cracks =
	max(edge, crack_mask);

	col.rgb +=
	crack_color.rgb
	* cracks
	* crack_brightness;

	//////////////////////////////////////////////////////
	// CENTER HOLE
	//////////////////////////////////////////////////////

	float hole_noise =
	noise(uv * 40.0);

	float hole =
	smoothstep(
		center_hole_size
		+ hole_noise
		* hole_irregularity
		* 0.05,

		0.0,

		impact_dist
	);

	hole *=
	smoothstep(
		0.3,
		0.8,
		break_progress
	);

	//////////////////////////////////////////////////////
	// ALPHA
	//////////////////////////////////////////////////////

	col.a *= inside_screen;
	col.a *= same_piece;
	col.a *= (1.0 - hole);

	//////////////////////////////////////////////////////
	// GLASS MASK
	//////////////////////////////////////////////////////

	if(use_glass_mask){

		float mask =
		glass_mask(uv);

		col.a *= mask;
	}

	//////////////////////////////////////////////////////
	// FINAL
	//////////////////////////////////////////////////////

	COLOR = col;
}