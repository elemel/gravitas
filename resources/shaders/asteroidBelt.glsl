uniform float scale = 1;
uniform float innerRadius = 1;
uniform float outerRadius = 1;
uniform float noiseScale = 0.005;
uniform float innerStepRadius = 50.0;
uniform float outerStepRadius = 50.0;

vec4 effect(vec4 color, Image image, vec2 texturePosition, vec2 screenPosition) {
    vec2 localPosition = scale * (2.0 * texturePosition - 1.0);
    float centerDistance = length(localPosition);

    float torusDensity = smoothstep(innerRadius - innerStepRadius, innerRadius + innerStepRadius, centerDistance) -
        smoothstep(outerRadius - outerStepRadius, outerRadius + outerStepRadius, centerDistance);

    // Generate tunnel density.
    float tunnelDensity = 2.0 * abs(snoise(noiseScale * localPosition));

    float density = torusDensity * tunnelDensity;

    // Anti-aliasing.
    float r = fwidth(density);
    float a = smoothstep(0.5 - r, 0.5 + r, density);

    return vec4(color.rgb, color.a * a);
}
