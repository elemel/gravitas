// Adapted from: https://github.com/ashima/webgl-noise

uniform float radius = 1.0;
uniform float stepRadius = 0.0;
uniform float time = 0.0; // Used for texture animation

vec4 effect(vec4 color, Image image, vec2 texturePosition, vec2 screenPosition) {
  float normalizedScale = (radius + stepRadius) / radius;
  float x = (2.0 * texturePosition.x - 1.0) * normalizedScale;
  float y = (2.0 * texturePosition.y - 1.0) * normalizedScale;
  float z = sqrt(max(0.0, 1.0 - x * x - y * y));
  vec3 texturePosition3D = 0.5 + 0.5 * vec3(x, y, z);

  // Perturb the texcoords with three components of noise
  vec3 uvw = texturePosition3D + 0.1*vec3(snoise(texturePosition3D + vec3(0.0, 0.0, time)),
    snoise(texturePosition3D + vec3(43.0, 17.0, time)),
	snoise(texturePosition3D + vec3(-17.0, -43.0, time)));

  // Six components of noise in a fractal sum
  float n = snoise(uvw - vec3(0.0, 0.0, time));
  n += 0.5 * snoise(uvw * 2.0 - vec3(0.0, 0.0, time * 1.4)); 
  n += 0.25 * snoise(uvw * 4.0 - vec3(0.0, 0.0, time * 2.0)); 
  n += 0.125 * snoise(uvw * 8.0 - vec3(0.0, 0.0, time * 2.8)); 
  n += 0.0625 * snoise(uvw * 16.0 - vec3(0.0, 0.0, time * 4.0)); 
  n += 0.03125 * snoise(uvw * 32.0 - vec3(0.0, 0.0, time * 5.6)); 
  n = n * 0.7;

  float distance = length(vec2(x, y));
  float density = 1.0 - smoothstep(1.0 - stepRadius / radius, 1.0 + stepRadius / radius, distance);

  // A "hot" colormap - cheesy but effective 
  return vec4(vec3(1.0, 0.5, 0.0) + vec3(n, n, n), density);
}