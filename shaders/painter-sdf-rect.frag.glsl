#version 450

in vec2 texcoord;
in vec2 bx;
in vec4 rectColor;
in vec3 borderColor;
in vec4 cn;
in float bd;
in float sm;
out vec4 FragColor;


float sdRoundBox(vec2 p, vec2 b, vec4 r) {
	r.xy = (p.x>0.0)?r.xy : r.zw;
    r.x  = (p.y>0.0)?r.x  : r.y;
    vec2 q = abs(p)-b+r.x;
    return min(max(q.x,q.y),0.0) + length(max(q,0.0)) - r.x;
}

vec4 framedBox(vec4 fgCol, vec4 bdCol, vec2 p, vec2 b, vec4 r, float border, float s) {
	vec4 bgColor = {0.0, 0.0, 0.0, 0.0};
	float dA = sdRoundBox(p, b + s / 2.0, r);
	float dB = abs(sdRoundBox(p, b + s / 2.0, r)) - border;
	dA = 1.0 - smoothstep(0.0, s, clamp(-dA, 0.0, 1.0));
	dB = 1.0 - smoothstep(0.0, s, clamp(-dB, 0.0, 1.0));
	fgCol = mix(bdCol, fgCol, dB);
	return mix(fgCol, bgColor, dA) * rectColor.a;
}


void main() {
	FragColor = framedBox(rectColor, vec4(borderColor, rectColor.a), texcoord - bx, bx, cn, bd, sm);
}
