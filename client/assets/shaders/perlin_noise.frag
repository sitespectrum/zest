#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uSize;
uniform vec4 uColor;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}

mat2 rot(float a) {
    float s = sin(a);
    float c = cos(a);
    return mat2(c, -s, s, c);
}

void main() {
    vec2 uv = FlutterFragCoord().xy / uSize;
    
    float distortedY = uv.y;
    vec2 p = vec2(uv.x * 4.5, distortedY * 8.0);
    
    float t = uTime * 0.06;
    float n = 0.0;
    
    vec2 p1 = p * rot(t * 0.2);
    n += noise(p1 + vec2(t, t * 0.5)) * 0.5;
    
    vec2 p2 = p * 2.0 * rot(-t * 0.3);
    n += noise(p2 - vec2(t * 0.7, t * 1.2)) * 0.25;
    
    vec2 p3 = p * 4.0 * rot(t * 0.5);
    n += noise(p3 + vec2(t * 1.5, -t)) * 0.125;

    float line = sin(n * 35.0 + t); 
    line = smoothstep(0.2, 0.5, line) * smoothstep(0.8, 0.5, line);

    float mask = smoothstep(0.3, 0.1, uv.y);

    vec3 finalColor = uColor.rgb * line * mask;
    
    finalColor *= 1.5; 

    fragColor = vec4(finalColor, 1.0);
}   