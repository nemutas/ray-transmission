/*
* The Art of Code
* part1: https://youtu.be/NCpaaLkmXI8?si=HVd3LZQyFankb_a1
* part2: https://youtu.be/0RWaR7zApEo?si=bad-YhmqAYhbvUfv
*/ 

#define m4v3Vec(m4, v3) normalize((m4 * vec4(v3, 0.0)).xyz)
#define m4v3Coord(m4, v3) (m4 * vec4(v3, 1.0)).xyz

uniform samplerCube tEnv;
uniform vec3 uCameraPosition;
uniform mat4 uProjectionMatrixInverse;
uniform mat4 uViewMatrixInverse;

varying vec2 vUv;

const int STEP = 100;
const float MAX_DIST = 100.0;
const float SURF_DIST = 0.001;
const float PI = acos(-1.0);
const float IOR = 1.45;

#include './raymarching/primitives.glsl'
#include './raymarching/combinations.glsl'

float sdf(vec3 p) {
  float c = cos(PI / 5.0);
  float s = sqrt(0.75 - c * c);
  vec3 n = vec3(-0.5, -c, s);
  
  p = abs(p);
  p -= 2.0 * min(0.0, dot(p, n)) * n;

  p.xy = abs(p.xy);
  p -= 2.0 * min(0.0, dot(p, n)) * n;

  p.xy = abs(p.xy);
  p -= 2.0 * min(0.0, dot(p, n)) * n;

  float d = p.z - 1.0;
  return d;
}

#include './raymarching/normal.glsl'

float rayMarch(vec3 ro, vec3 rd, float side) {
  float totalDist = 0.0;

  for (int i = 0; i < STEP; i++) {
    vec3 p = ro + rd * totalDist;
    float dist = sdf(p) * side;
    totalDist += dist;
    if (abs(dist) < SURF_DIST || MAX_DIST < totalDist) break;
  }

  return totalDist;
}

void main() {
  vec2 p = vUv * 2.0 - 1.0;

  vec4 ndcRay = vec4(p, 1.0, 1.0);
  vec3 ray = (uViewMatrixInverse * uProjectionMatrixInverse * ndcRay).xyz;
  ray = normalize(ray);

  vec3 ro = uCameraPosition;

  float d = rayMarch(ro, ray, 1.0);

  vec3 color = textureCube(tEnv, ray).rgb;

  if (d < MAX_DIST) {
    vec3 p = ro + ray * d; // 3d hit position
    vec3 n = calcNormal(p); // normal
    // n = m4v3Vec(uNormalMatrix, n);

    vec3 rdIn = refract(ray, n, 1.0 / IOR);

    vec3 pEnter = p - n * SURF_DIST * 3.0;
    float dIn = rayMarch(pEnter, rdIn, -1.0);
    vec3 pExit = pEnter + rdIn * dIn;
    vec3 nExit = -calcNormal(pExit);

    vec3 reflTex = vec3(0);
    vec3 rdOut = vec3(0);

    // chromatic aberration（色収差）
    float ca = 0.005;

    rdOut = refract(rdIn, nExit, IOR - ca);
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.r = textureCube(tEnv, rdOut).r;

    rdOut = refract(rdIn, nExit, IOR);
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.g = textureCube(tEnv, rdOut).g;

    rdOut = refract(rdIn, nExit, IOR + ca);
    if (dot(rdOut, rdOut) == 0.0) rdOut = reflect(rdIn, nExit);
    reflTex.b = textureCube(tEnv, rdOut).b;

    // density
    float dens = 0.1;
    float optDist = exp(-dIn * dens);
    color = reflTex * optDist;

    // fresnel reflection
    float fresnel = pow(1.0 + dot(ray, n), 3.0);
    vec3 reflOutside = textureCube(tEnv, reflect(ray, n)).rgb;
    color = mix(color, reflOutside, fresnel);
  }
  gl_FragColor = vec4(color, 1.0);
}