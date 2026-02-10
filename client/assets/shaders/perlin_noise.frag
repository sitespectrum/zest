precision highp float;

uniform float u_time;
uniform vec2 u_resolution;

uniform vec3 u_foreground;

uniform float u_scale;
uniform float u_speed;

out vec4 fragColor;

// Simple hash-based noise
float hash(vec2 p) {
  return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
  vec2 i = floor(p);
  vec2 f = fract(p);

  float a = hash(i);
  float b = hash(i + vec2(1.0, 0.0));
  float c = hash(i + vec2(0.0, 1.0));
  float d = hash(i + vec2(1.0, 1.0));

  vec2 u = f * f * (3 - 2.0 * f);

  return mix(a, b, u.x) +
         (c - a) * u.y * (1.0 - u.x) +
         (d - b) * u.x * u.y;
}

void main() {

  vec2 p = (gl_FragCoord.xy - 0.5 * u_resolution.xy)
         / min(u_resolution.x, u_resolution.y);
  
  p *= u_scale;

  float h =
      noise(p + u_time * 0.08 * u_speed) +
      0.5 * noise(p * 2.0 - u_time * 0.12 * u_speed);

  // Topographic isolines
  float lines = abs(fract(h * 8.0) - 0.5);
  float contour = smoothstep(0.12, 0.04, lines);

  // Dark green background + light lines
  vec3 bg = vec3(0);
  // vec3 fg = vec3(1);

  vec3 color = mix(bg, u_foreground, contour);

  fragColor = vec4(color, 0);
}