#version 450
#define _Irr
#define _EnvTex
#define _Rad
#define _SSAO
#define _SMAA

#ifdef GL_ES
precision highp float;
#endif

uniform mat4 LVWVP;

in vec3 pos;

out vec4 wvpposition;

void main() {
	wvpposition = LVWVP * vec4(pos, 1.0);
	gl_Position = wvpposition;
}
