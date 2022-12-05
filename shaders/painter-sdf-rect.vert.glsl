#version 450

in vec3 pos;
in vec2 tex;
in vec2 box;
in vec4 rCol;
in vec3 bCol;
in vec4 corner;
in float border;
in float smth;
out vec2 texcoord;
out vec2 bx;
out vec4 rectColor;
out vec3 borderColor;
out vec4 cn;
out float bd;
out float sm;

uniform mat4x4 projectionMatrix;

void main() {
	gl_Position = projectionMatrix * vec4(vec3(pos.x, pos.y, -0.5), 1.0);
	texcoord = tex;
	bx = box;
	rectColor = rCol;
	borderColor = bCol;
	cn = corner;
	bd = border;
	sm = smth;
}
