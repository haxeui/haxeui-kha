#version 450

in vec2 oTex;
in vec4 oColor;
in vec2 oDim;
in float oSmth;

out vec4 FragColor;


float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}


void main() {
    vec4 bg = vec4(0.0);

	float d = sdRoundBox(oTex - oDim, oDim + oSmth / 2.0, oDim.y);

	float a = 1.0 - smoothstep(0.0, oSmth, clamp(-d, 0.0, 1.0));

    FragColor = mix(oColor, bg, a);
}
