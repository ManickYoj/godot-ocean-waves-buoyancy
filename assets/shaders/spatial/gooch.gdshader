shader_type spatial;
uniform vec3 model_color : source_color;
uniform sampler2D depth : hint_depth_texture;

uniform vec3 warm : source_color;
uniform vec3 cold : source_color;
uniform float cold_strength = 0.0;
uniform float warm_strength = 0.0;
uniform float smoothness = 1.0;

float DotClamped(vec3 a, vec3 b){
	return max(0.0, dot(a, b));
}

void fragment() {
	ALBEDO = model_color;
}

void light() {
	float gooch = (1.0f + dot(LIGHT, NORMAL)) / 2.0;
	gooch *= ATTENUATION;
	
	vec3 kCold = cold.rgb + cold_strength * ALBEDO.rgb;
	vec3 kWarm = warm.rgb + warm_strength * ALBEDO.rgb;
	
	vec3 gooch_diffuse = gooch * kWarm + (1.0 - gooch) * kCold;
	vec3 reflection_dir = reflect(-LIGHT, NORMAL);
	float specular = DotClamped(VIEW, reflection_dir);
	specular = pow(specular, smoothness * 32.0) * 5.0;
	
	DIFFUSE_LIGHT += gooch_diffuse * ATTENUATION;
	SPECULAR_LIGHT += specular * ATTENUATION * LIGHT_COLOR;
}
