#version 450

in vec2 texcoord;
in vec4 rectColor;
in vec3 borderColor;
in float bd;
in float sm;
out vec4 FragColor;


float sdCircle(vec2 p, float r) {
    return length(p) - r;
}

vec4 framedCircle(vec4 fgCol, vec4 bdCol, vec2 p, float r, float border, float s) {
	vec4 bgColor = vec4(0.0);
	float dA = sdCircle(p, r + s / 2.0);
	float dB = abs(sdCircle(p, r + s / 2.0)) - border;
	dA = 1.0 - smoothstep(0.0, s, clamp(-dA, 0.0, 1.0));
	dB = 1.0 - smoothstep(0.0, s, clamp(-dB, 0.0, 1.0));
	fgCol = mix(bdCol, fgCol, dB);
	return mix(fgCol, bgColor, dA);
}

void main() {
	FragColor = framedCircle(rectColor, vec4(borderColor, rectColor.a), texcoord - 0.5, 0.5, bd, sm);
}
