#version 450

in vec3 pos;
in vec2 tex;
in vec4 color;
in vec2 dim;
in float smth;
out vec2 oTex;
out vec4 oColor;
out vec2 oDim;
out float oSmth;

uniform mat4x4 projectionMatrix;


void main() {
	gl_Position = projectionMatrix * vec4(pos, 1.0);
	oTex = tex;
	oColor = color;
	oDim = dim;
	oSmth = smth;
}
