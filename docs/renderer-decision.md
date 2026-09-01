# 3D Renderer Decision Matrix — Mandap Core

| Decision Criteria | `three_js` (Primary Candidate) | Thermion (Fallback Candidate) |
|---|---|---|
| **Rendering Backend** | WebGL / Custom Flutter Texture | Filament Native C++ FFI |
| **Android Support** | Tested & Compatible | Native Android Surface |
| **Flutter 3.44.8 Stable** | Supported | Supported |
| **Dart 3.12.2 Compatibility** | Fully Compatible | Fully Compatible |
| **Procedural Primitives** | High (`BoxGeometry`, `CylinderGeometry`) | Medium (Custom Filament Meshes) |
| **Scene Graph & Stable IDs** | High (`Object3D.userData['id']`) | High (Filament Entity IDs) |
| **Raycasting / Picking** | High (`Raycaster`) | High (Entity Raycast) |
| **Orbit & Zoom Controls** | High (`OrbitControls`) | High (`ThermionViewer`) |
| **Drag & Transform Gizmos** | High (`TransformControls`) | Low (Custom Math Required) |
| **Runtime Transform Updates** | Real-time (`position`, `scale`, `rotation`) | Real-time (Entity Transforms) |
| **Dimension Overlay** | High (`WorldToScreen` projection) | Medium |
| **Resource Disposal** | Clean (`dispose()`) | Clean (Native Context) |
| **CAD / Editor Suitability** | **EXCELLENT** | MEDIUM |
| **Production Risk** | LOW | MEDIUM-HIGH |
| **VERDICT** | **PRIMARY SPIKE CANDIDATE** | **FALLBACK BENCHMARK** |
