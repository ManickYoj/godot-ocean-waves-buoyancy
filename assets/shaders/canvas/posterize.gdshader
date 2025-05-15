#define FLT_MAX 3.402823466e+38

shader_type canvas_item;
render_mode unshaded;

// Annoyingly, since this is set at compile, it seems you need to manually
// set this array size to match the number of colors in your array. Otherwise
// it will disregard the 'extra' colors
uniform vec4[256] colors : source_color;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

const vec3 D65_WHITE = vec3(0.95045592705, 1.0, 1.08905775076);
const vec3 WHITE = D65_WHITE;

// RGB to LAB implementation from
// https://github.com/sv3/gift/blob/master/RGB2Lab.glsl
vec3 rgb_to_lab(vec4 rgb){
    float R = rgb.x;
    float G = rgb.y;
    float B = rgb.z;
    // threshold
    float T = 0.008856;

    float X = R * 0.412453 + G * 0.357580 + B * 0.180423;
    float Y = R * 0.212671 + G * 0.715160 + B * 0.072169;
    float Z = R * 0.019334 + G * 0.119193 + B * 0.950227;

    // Normalize for D65 white point
    X = X / 0.950456;
    Y = Y;
    Z = Z / 1.088754;

    bool XT, YT, ZT;
    XT = false; YT=false; ZT=false;
    if(X > T) XT = true;
    if(Y > T) YT = true;
    if(Z > T) ZT = true;

    float Y3 = pow(Y,1.0/3.0);
    float fX, fY, fZ;
    if(XT){ fX = pow(X, 1.0/3.0);} else{ fX = 7.787 * X + 16.0/116.0; }
    if(YT){ fY = Y3; } else{ fY = 7.787 * Y + 16.0/116.0 ; }
    if(ZT){ fZ = pow(Z,1.0/3.0); } else{ fZ = 7.787 * Z + 16.0/116.0; }

    float L; if(YT){ L = (116.0 * Y3) - 16.0; }else { L = 903.3 * Y; }
    float a = 500.0 * ( fX - fY );
    float b = 200.0 * ( fY - fZ );

    return vec3(L,a,b);
}

void fragment() {
	vec4 color = texture(SCREEN_TEXTURE, SCREEN_UV).rgba;
	float min_dist = FLT_MAX;
	for(int i=0;i<colors.length(); i++) {
		float dist = distance(
			rgb_to_lab(color),
			rgb_to_lab(colors[i])
		);
		if (dist < min_dist) {
			min_dist = dist;
			COLOR = colors[i];
		}
	}
}