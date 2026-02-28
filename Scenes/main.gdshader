shader_type canvas_item;

uniform float vignette_strength : hint_range(0.0, 3.0) = 1.2;
uniform float scanline_opacity : hint_range(0.0, 1.0) = 0.15;
uniform float scanline_count : hint_range(50.0, 500.0) = 200.0;
uniform float aberration : hint_range(0.0, 0.01) = 0.002;
uniform float fisheye_strength : hint_range(-1.0, 1.0) = 0.3;  // ← new


uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

void fragment() {
    vec2 uv = SCREEN_UV;
	
	
    vec2 centered = uv - 0.5;        
    float dist = length(centered);    
    float distorted = dist * (1.0 + fisheye_strength * dist * dist);
    uv = centered * (distorted / dist) + 0.5;  

    bool outside = uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0;


    // Chromatic aberration (slight RGB split)
    float r = texture(SCREEN_TEXTURE, uv + vec2(aberration, 0.0)).r;
    float g = texture(SCREEN_TEXTURE, uv).g;
    float b = texture(SCREEN_TEXTURE, uv - vec2(aberration, 0.0)).b;
    vec3 color = vec3(r, g, b);

    // Scanlines
    float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
    color *= 1.0 - scanline * scanline_opacity;

    // Vignette
    vec2 vdist = (uv - 0.5) * vec2(1.3, 1.0);
    float vignette = 1.0 - dot(vdist, vdist) * vignette_strength;
    vignette = clamp(vignette, 0.0, 1.0);
    color *= vignette;

    COLOR = vec4(color, 1.0);
}