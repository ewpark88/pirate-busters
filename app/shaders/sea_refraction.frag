// 바다 측면 굴절 셰이더 (설계서 §10.2, ADR-030). 저사양 모드에서는 쓰지 않는다.
// 옆에서 본 물: 깊이에 따라 짙어지고, 물결에 굴절된 빛 띠가 일렁인다.
#version 460 core
#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform float uSeaY;     // 해수면의 화면 y (px)
uniform float uWorldX0;  // 화면 x = 0 의 월드 x
uniform float uZoom;     // 월드 px 당 화면 px
uniform vec3 uTop;       // 해역 물색: 수면 · 중간 · 깊은 곳 (설계서 §10.2)
uniform vec3 uMid;
uniform vec3 uDeep;
uniform vec3 uLight;     // 굴절 빛 띠 색

out vec4 fragColor;

void main() {
  vec2 p = FlutterFragCoord().xy;
  float d = (p.y - uSeaY) / uZoom;
  if (d < 0.0) {
    fragColor = vec4(0.0);
    return;
  }
  float wx = uWorldX0 + p.x / uZoom;
  float bend = sin(d * 0.08 + uTime * 1.7) * 2.2;
  float band = sin(wx * 0.045 + bend + uTime * 0.9);
  float light = smoothstep(0.72, 1.0, band) * exp(-d / 90.0);
  float t = clamp(d / 300.0, 0.0, 1.0);
  vec3 col = mix(mix(uTop, uMid, clamp(t * 2.0, 0.0, 1.0)), uDeep,
                 clamp(t * 2.0 - 1.0, 0.0, 1.0));
  col += uLight * light * 0.28;
  float a = mix(0.58, 0.9, t);
  fragColor = vec4(col * a, a);
}
