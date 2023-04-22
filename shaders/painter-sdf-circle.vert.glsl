#version 450

in vec3 pos;
in vec2 tex;
in vec4 rCol;
in vec3 bCol;
in float border;
in float smth;
out vec2 texcoord;
out vec4 rectColor;
out vec3 borderColor;
out float bd;
out float sm;

uniform mat4x4 projectionMatrix;

void main() {
	gl_Position = projectionMatrix * vec4(pos, 1.0);
	texcoord = tex;
	rectColor = rCol;
	borderColor = bCol;
	bd = border;
	sm = smth;
}
