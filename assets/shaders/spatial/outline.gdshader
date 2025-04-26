// Godot 4.4, Forward+ or Mobile
// Based quite closely on shader by Digvijaysinh Gohil
// See https://www.youtube.com/watch?v=-SXJvpbFJ7M&ab_channel=DigvijaysinhGohil
shader_type spatial;
render_mode unshaded, fog_disabled;

uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable;
uniform float sensitivity: hint_range(0.0, 3.0, 0.01);
uniform float outline_thickness: hint_range(0.0, 2.0, 0.01);
uniform float step_threshold: hint_range(0.0, 1.0, 0.01);
uniform vec3 outline_color: source_color;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

float DepthVS(vec2 uv, mat4 inv_projection_mat) {
	float depth = texture(depth_texture, uv).r;
	return 1. / (depth * inv_projection_mat[2].w + inv_projection_mat[3].w);
}

void fragment() {
	float thickness = outline_thickness * 0.001;
	float depth = DepthVS(SCREEN_UV, INV_PROJECTION_MATRIX);
	
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
}