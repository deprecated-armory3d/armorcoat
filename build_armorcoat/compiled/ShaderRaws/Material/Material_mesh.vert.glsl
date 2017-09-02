#version 450
#define _Irr
#define _EnvTex
#define _Rad
#define _SSAO
#define _SMAA
in vec3 pos;
in vec3 nor;
in vec2 tex;
out vec2 texCoord;
out vec3 wnormal;
uniform mat3 N;
uniform mat4 WVP;
void main() {
vec4 spos = vec4(pos, 1.0);
	wnormal = normalize(N * nor);
	gl_Position = WVP * spos;
	texCoord = tex;
}
