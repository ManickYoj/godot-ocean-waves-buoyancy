shader_type canvas_item;

// hatch parameters (tweak as desired)
uniform float spacing       = 0.08;
uniform float thickness     = 0.02;
uniform float freq          = 18.0;
uniform float amp           = 0.008;
uniform float hatch_angle   = 135.0;
uniform float progress      = 0.5;
uniform float bound_width_a = 0.02;
uniform float corner_a      = 0.025;
uniform vec2  uv_scale      = vec2(1.0, 1.0);

//–– 2D hash → vec2
vec2 hash22(vec2 p)
{
    float h1 = sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123;
    float h2 = sin(dot(p, vec2(269.5, 183.3))) * 43758.5453123;
    return fract(vec2(h1, h2));
}

//–– 2D value noise → vec2
vec2 noise2d(vec2 x)
{
    vec2 i = floor(x);
    vec2 f = fract(x);
    vec2 u = f*f*(3.0 - 2.0*f);
    vec2 a = hash22(i + vec2(0.0));
    vec2 b = hash22(i + vec2(1.0, 0.0));
    vec2 c = hash22(i + vec2(0.0, 1.0));
    vec2 d = hash22(i + vec2(1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

//–– Generic SDF for axis-aligned box in UV [0,1]
float sdBox(vec2 p, vec2 center, vec2 halfSize)
{
    vec2 d = abs(p - center) - halfSize;
    vec2 md = max(d, vec2(0.0));
    return length(md) + min(max(d.x, d.y), 0.0);
}

//–– SDF for rounded box: p in UV, center, halfSize, corner radius
float sdRoundBox(vec2 p, vec2 center, vec2 halfSize, float r)
{
    vec2 d = abs(p - center) - halfSize + vec2(r);
    vec2 md = max(d, vec2(0.0));
    float outside = length(md) - r;
    float inside = min(max(d.x, d.y), 0.0);
    return outside + inside;
}

//–– Rotate vector by -angle
vec2 rotate(vec2 p, float angle)
{
    float c = cos(angle);
    float s = sin(angle);
    // rotation by -angle: [c  s; -s  c]
    return vec2(c*p.x + s*p.y, -s*p.x + c*p.y);
}

//–– Generic hand-drawn hatch for any SDF
// d: SDF value (<0 inside)
// p: point (e.g. UV coords)
// angle: hatch orientation in radians
float shadeHatchSDF(float d, vec2 p, float angle)
{
    // rotate space so stripes align horizontally
    vec2 pr = rotate(p, angle);

    // stripe index
    float idx    = floor(pr.y / spacing);
    float localY = pr.y - (idx + 0.5) * spacing;

    // jitter along stripe
    float j = (noise2d(vec2(pr.x * freq, idx)).x - 0.5) * amp;

    // distance to jittered centerline
    float dist = abs(localY + j) - thickness;

    // anti-aliased stripe mask
    float wAA = fwidth(dist);
    float stripeMask = smoothstep(0.0, wAA, -dist);

    // anti-aliased shape mask
    float shapeMask = smoothstep(0.0, fwidth(d), -d);

    return stripeMask * shapeMask;
}

//–– Contour mask for an SDF: thin outline where |d|≈0
float contourMask(float d)
{
    float w = fwidth(d) + bound_width_a;
    return 1.0 - smoothstep(0.0, w, abs(d));
}

bool is_progressed(vec2 uv)
{
    float theta = radians(hatch_angle);
    float d1 = abs(sin(theta) - cos(theta));
    float duv = abs(uv.x * sin(theta) - uv.y * cos(theta));
    return duv <= d1 * progress; 
}

void fragment()
{
    vec2 uv = UV / uv_scale;

    // first box: center & half-size in UV
    vec2 c1 = vec2(0.5, 0.5);
    vec2 h1 = vec2(0.5 - bound_width_a);
    float d1 = sdRoundBox(uv, c1, h1, corner_a);
    float m1 = shadeHatchSDF(d1, uv, radians(hatch_angle));

    // combine hatches & contours
    float hatch = m1;
    float cont  = contourMask(d1);
    float alpha = max(hatch, cont);

    vec3 bg = vec3(1.0);
    vec3 fg = vec3(0.0);
    
    if (is_progressed(uv))
    {
        COLOR = vec4(mix(bg, fg, alpha), 1.0);
    }
    else
    {
        COLOR = vec4(mix(bg, fg, cont), 1.0);
    }
}