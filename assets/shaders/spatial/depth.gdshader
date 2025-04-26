// Godot 4.3, Forward+ or Mobile
shader_type spatial;
render_mode unshaded, fog_disabled;
#include "res://assets/shaders/helpers/lab_mix.gdshaderinc"

uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable;

uniform sampler2D normal_rough_texture : hint_normal_roughness_texture;
uniform float sensitivity: hint_range(0.0, 3.0, 0.01);
uniform float outline_thickness: hint_range(0.0, 3.0, 0.01);
uniform float step_threshold: hint_range(0.0, 1.0, 0.01);
uniform vec3 outline_color: source_color;
//uniform vec3 gradiant_start: source_color;
//uniform vec3 gradiant_end: source_color;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}
//
float DepthVS(vec2 uv, mat4 inv_projection_mat) {
	float depth = texture(depth_texture, uv).r;
	return 1. / (depth * inv_projection_mat[2].w + inv_projection_mat[3].w);
}

void fragment() {
	// -- Outline shader
	float thickness = outline_thickness * 0.001;
	float depth = DepthVS(SCREEN_UV, INV_PROJECTION_MATRIX);
	//float sensitivity = 1.;

	// Check the depth in the four cardinal and four diagonal directions to determine whether the
	// current pixel is on an edge
	float border_r = DepthVS(SCREEN_UV + vec2(thickness, 0), INV_PROJECTION_MATRIX) - depth;
	float border_l = DepthVS(SCREEN_UV + vec2(-thickness, 0), INV_PROJECTION_MATRIX) - depth;
	float border_t = DepthVS(SCREEN_UV + vec2(0, thickness), INV_PROJECTION_MATRIX) - depth;
	float border_b = DepthVS(SCREEN_UV + vec2(0, -thickness), INV_PROJECTION_MATRIX) - depth;
	float border_rt = DepthVS(SCREEN_UV + vec2(thickness, thickness), INV_PROJECTION_MATRIX) - depth;
	float border_rb = DepthVS(SCREEN_UV + vec2(thickness, -thickness), INV_PROJECTION_MATRIX) - depth;
	float border_lt = DepthVS(SCREEN_UV + vec2(-thickness, thickness), INV_PROJECTION_MATRIX) - depth;
	float border_lb = DepthVS(SCREEN_UV + vec2(-thickness, thickness), INV_PROJECTION_MATRIX) - depth;

	float outline = clamp(((border_r + border_l + border_t + border_b + border_rt + border_rb + border_lt + border_lb) * sensitivity) / 8. , 0., 1.);
	outline = smoothstep(0, step_threshold, outline);

	ALBEDO = outline * outline_color;
	ALPHA = outline;

	//
	//vec4 screen = texture(screen_texture, SCREEN_UV);
	//
	//float depth_raw = texture(depth_texture, SCREEN_UV).x;
	//vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_raw);
	//vec4 position_view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//position_view.xyz /= position_view.w;
	////float linear_depth = -position_view.z;
	//
	//vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	//vec3 position_world = world.xyz / world.w;
	//
	//vec4 normal_rough = texture(normal_rough_texture, SCREEN_UV);
	//vec3 normals_view_raw = normal_rough.xyz; // Normals in view space, in [0.0, 1.0] range
	//vec3 normals_view_remapped = normals_view_raw.xyz * 2.0 - 1.0;  // Normals in view space, in [-1.0, 1.0] range
	//vec3 normals_world = (INV_VIEW_MATRIX * vec4(normals_view_remapped, 0.0)).xyz;
	//float roughness = normal_rough.w;
	////float depth = texture(depth_texture, SCREEN_UV).x;
	//float linear_depth = mix(-10, 10, depth_raw);

	// Visualize the outputs
	// Screen texture
	//ALBEDO.rgb = screen.rgb;
	//Raw depth
	//ALBEDO.rgb = vec3(depth_raw);
	//ALBEDO.rgb = lab_mix(gradiant_start, gradiant_end, depth_raw);
	// Linear depth
	//ALBEDO.rgb = vec3(fract(linear_depth));
	// World position
	//ALBEDO.rgb = fract(position_world);
	// Normals from the normal buffer, in view space
	//ALBEDO.rgb = normals_view_raw;
	// Normals in world space, [-1.0,1.0] range
	//ALBEDO.rgb = normals_world;
	// Roughness
	//ALBEDO.rgb = vec3(roughness);
}