#version 450
#define _Irr
#define _EnvTex
#define _Rad
#define _SSAO
#define _SMAA
#include "../../Shaders/compiled.glsl"
#include "../../Shaders/std/gbuffer.glsl"
in vec2 texCoord;
in vec3 wnormal;
out vec4[2] fragColor;
uniform sampler2D ImageTexture;
void main() {
vec3 n = normalize(wnormal);
	vec3 basecol;
	float roughness;
	float metallic;
	float occlusion;
	vec4 ImageTexture_store = texture(ImageTexture, texCoord.xy);
	ImageTexture_store.rgb = pow(ImageTexture_store.rgb, vec3(2.2));
	vec3 ImageTexture_Color_res = ImageTexture_store.rgb;
	basecol = ImageTexture_Color_res;
	roughness = 0.0;
	metallic = 0.0;
	occlusion = 1.0;
	n /= (abs(n.x) + abs(n.y) + abs(n.z));
	n.xy = n.z >= 0.0 ? n.xy : octahedronWrap(n.xy);
	fragColor[0] = vec4(n.xy, packFloat(metallic, roughness), 1.0 - gl_FragCoord.z);
	fragColor[1] = vec4(basecol.rgb, occlusion);
}
