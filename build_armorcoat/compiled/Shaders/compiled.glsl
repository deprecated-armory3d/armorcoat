#ifndef _COMPILED_GLSL_
#define _COMPILED_GLSL_
const float PI = 3.1415926535;
const float PI2 = PI * 2.0;
const vec2 cameraPlane = vec2(0.1, 200.0);
const vec2 shadowmapSize = vec2(2048, 2048);
const float shadowmapCubePcfSize = 0.001;
const float ssaoSize = 0.12;
const float ssaoStrength = 0.1;
const float ssaoTextureScale = 1.0;
const float bloomThreshold = 5.0;
const float bloomStrength = 1.0;
const float bloomRadius = 1.0;
const float motionBlurIntensity = 1.0;
const float ssrRayStep = 0.04;
const float ssrMinRayStep = 0.05;
const float ssrSearchDist = 5.0;
const float ssrFalloffExp = 5.0;
const float ssrJitter = 0.6;
const float volumAirTurbidity = 1.0;
const vec3 volumAirColor = vec3(1.0, 1.0, 1.0);
const int skinMaxBones = 8;
#endif // _COMPILED_GLSL_
