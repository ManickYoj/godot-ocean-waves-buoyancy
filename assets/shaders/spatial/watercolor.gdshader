shader_type spatial;
group_uniforms Light;
/**
 * A noise texture to warp the lighting. 
 * SCREEN_UVs are used to apply this, adjust your scale as needed.
 */
uniform sampler2D light_noise;
/**
 * The scale of SCREEN_UV to apply. (this is already aspect-ratio corrected)
 */
uniform vec2 light_noise_scale = vec2(1.0);
/**
 * The strength of the noise's warping effect on the light.
 */
uniform float light_noise_strength;
/**
 * Amopunt of light bands you want to have.
 */
uniform int light_steps:hint_range(1, 100, 1) = 5;
/**
 * Higher values makes the bands more visible, can be good for cel shading.
 */
uniform float light_step_power = 2.;
/**
 * Offset of light value. You may want to adjust this before the light multiplier.
 * Usually, you'd adjust this so that the black is removed from your model with a single light source
 * Then, you can adjust the light multiplier to adjust the amount of light hitting your model.
 */
uniform float light_offset:hint_range(-2,2) = 0;
/**
 * Multiplies the post-offset light value by this amount. 
 * See: light_offset
 */
uniform float light_multiplier = 1;

group_uniforms Color;
/**
 * The input color texture. 
 * To get the best result, use a limited palette of very saturated colors.
 */
uniform sampler2D albedo;
/**
 * A noise texture to slightly warp the input texture. 
 * Optional.
 */
uniform sampler2D albedo_noise_texture;
/**
 * The strength of the offset applied to the texture from the noise.
 * Optional.
 */
uniform vec2 albedo_noise_strength;
/**
 * The scale of the UV to apply to the noise texture.
 * Optional.
 */
uniform vec2 albedo_noise_scale = vec2(1.0);
/**
 * The amount to multiply the saturation of the albedo by (before light shading)
 * This is handy if you find your inpute texture is getting washed way.
 */
uniform float saturation_multiplier = 1.;
/**
 * The power applied to desaturation effect in bright lights.
 */
uniform float desaturation_power = 10;

group_uniforms Other;
/**
 * scales the light noise by the depth value.
 * This can be great for perspective cameras, so that objects at a distance don't look too noisy.
 * However, with a perspective camera, it makes things hard to tune.
 */
uniform bool enable_depth_scaling = true;
/**
 * The amount depth scaling will be strengthened.
 */
uniform float depth_strength = 2;
/**
 * Multiply edge detection by this amount, higher values leads to more defined edges.
 */
uniform float edge_strength = 1;

void fragment() {
	ALBEDO = vec3(0);
}

vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float stepped(int steps_int, float edge_length, float value) {
	float steps = float(steps_int);
	float stepped = smoothstep(floor(value*steps),ceil(value*steps), value*steps);
	stepped = pow(stepped, light_step_power);
	return (floor(value*steps)+stepped)/steps;
}
// returns 0-1, strength of the light.
float get_light_strength(vec3 normal, vec3 light, vec2 uv, float attenuation, float aspect_ratio, float depth) {
	// Basic 0-1 for light strength
	float light_strength = dot(normal, light) /2. + .5;
	light_strength = light_strength * attenuation;
	// apply a noise for that watercolor-look
	vec2 lns = light_noise_scale;
	if (enable_depth_scaling) {
		lns *= (1.0-depth) * depth_strength;
	}
	float noise = texture(light_noise, uv * lns * vec2(aspect_ratio,1.)).r - .5;
	light_strength += noise * light_noise_strength;
	light_strength *= light_multiplier;
	light_strength += light_offset;
	light_strength = stepped(light_steps, .1, light_strength);
	return clamp(light_strength, 0, 1);
}
float get_edge(vec2 uv) {
	vec3 pixels[9];
	vec2 pixel_size = vec2(1./1024.);
	for (int row = 0; row < 3; row++) {
		for (int col = 0; col < 3; col++) {
			vec2 _uv = uv + vec2(float(col - 1), float(row - 1)) * pixel_size;
			pixels[row * 3 + col] = texture(albedo, _uv).rgb;
		}
	}
	vec3 gx = (
		pixels[0] * -1.0 + pixels[3] * -2.0 + pixels[6] * -1.0
		+ pixels[2] * 1.0 + pixels[5] * 2.0 + pixels[8] * 1.0
	);
	vec3 gy = (
		pixels[0] * -1.0 + pixels[1] * -2.0 + pixels[2] * -1.0
		+ pixels[6] * 1.0 + pixels[7] * 2.0 + pixels[8] * 1.0
	);
	vec3 sobel = sqrt(gx * gx + gy * gy);
	float is_edge = (sobel.r + sobel.g + sobel.b ) / 3.;
	is_edge *= edge_strength;
	return clamp(is_edge, 0, 1);
}

vec3 get_color(vec2 uv, float is_edge, float light_strength, vec3 light_color) {
	vec3 color = texture(albedo, uv).rgb;
	light_color = light_color/PI*light_strength;
	vec3 light_color_hsv = rgb2hsv(light_color);
	color = mix(color, light_color, light_color_hsv.y);
	color = rgb2hsv(color);
	color.y *= saturation_multiplier;
	vec3 desaturated_color = vec3(
		color.x,
		min(color.y, color.y*(1.0-pow(light_color_hsv.z, desaturation_power))),
		max(color.z * light_color_hsv.z, light_color_hsv.z*2. * (light_color_hsv.z ))
	);
	vec3 edge_color = vec3(
		color.x,
		color.y,
		max(color.z * light_color_hsv.z, light_color_hsv.z*2. * (light_color_hsv.z ))
	);
	color = mix(desaturated_color, edge_color, is_edge);
	return hsv2rgb(color);
}

void light() {
	// Get light strength from 0-1
	float light_strength = get_light_strength(NORMAL, LIGHT, SCREEN_UV, ATTENUATION, VIEWPORT_SIZE.x/VIEWPORT_SIZE.y, FRAGCOORD.z);
	
	// used to wobble the texture
	vec2 noise = texture(albedo_noise_texture, SCREEN_UV * albedo_noise_scale).rg - vec2(.5);
	noise *= albedo_noise_strength;
	
	vec2 uv = UV + noise;
	float is_edge = get_edge(uv);
	vec3 color = get_color(uv, is_edge, light_strength, LIGHT_COLOR);
	
    SPECULAR_LIGHT += color;
}