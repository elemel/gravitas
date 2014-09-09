uniform float seed = 0;
uniform float radius = 1;
uniform float scale = 0.01;

vec4 effect(vec4 color, Image image, vec2 local, vec2 screen) {
    float distance = length(2.0 * local - 1.0);
    float sphereDensity = 1.0 - smoothstep(1.0 - 10.0 / radius, 1.0 + 10.0 / radius, distance);

    // Generate tunnel density.
    float tunnelDensity = 2.0 * abs(snoise(scale * radius * local + seed));

    float density = sphereDensity * tunnelDensity;

    // Anti-aliasing.
    float r = fwidth(density);
    float a = gl_Color.a * smoothstep(0.5 - r, 0.5 + r, density);

    return vec4(color.rgb, color.a * a);
}
