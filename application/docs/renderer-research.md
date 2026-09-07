# 3D Renderer Research Documentation — Mandap Core

**Date**: August 2026  
**Environment**: Flutter 3.44.8 (stable), Dart 3.12.2, Android-first target.

---

## 1. Candidate A: `three_js` Ecosystem (`three_js`, `three_js_core`, `three_js_controls`, `three_js_transform_controls`)

### Overview
`three_js` is a Flutter-native Dart port of the Three.js ecosystem. It provides scene graph, object picking (`Raycaster`), camera controls (`OrbitControls`), and manipulation gizmos (`TransformControls`) directly within Dart code.

### Analysis & Capabilities Matrix
- **Rendering Backend**: Custom Flutter Texture / Painter over WebGL/OpenGL.
- **Flutter / Dart Compatibility**: Compatible with Flutter 3.44+ and Dart 3.12+.
- **Android Compatibility**: Renders on Android devices via Flutter texture widget. Impeller compatible on modern Flutter engines.
- **Procedural Geometry**: Native support for `BoxGeometry`, `CylinderGeometry`, `SphereGeometry`, `PlaneGeometry`, `Line`.
- **Picking & Raycasting**: Built-in `Raycaster` mapping screen coordinates to scene mesh objects.
- **Camera Controls**: Built-in `OrbitControls` handling touch orbit, pan, and pinch zoom.
- **Transform Controls**: `TransformControls` gizmo support for translating/scaling handles along axes.
- **Text / Dimension Strategy**: Screen-space projection using `Vector3.project(camera)` mapping 3D world coordinates to Flutter `Positioned` widgets.
- **Disposal**: `threeJs.dispose()` cleanly releases textures, WebGL buffers, and event listeners.

### Risk & Maintenance Score
- **Maintenance**: Community-maintained Dart port.
- **Risk**: Low-medium. Excellent fit for procedural CAD-style editing.

---

## 2. Candidate B: `Thermion` (`thermion_flutter`, `thermion_dart`)

### Overview
`Thermion` is a cross-platform 3D rendering engine built on Google's Filament C++ engine via Dart FFI.

### Analysis & Capabilities Matrix
- **Rendering Backend**: Native C++ Google Filament engine.
- **Flutter / Dart Compatibility**: Compatible with Flutter stable and Dart 3+.
- **Android Compatibility**: High-performance native Filament Surface/Texture view.
- **Procedural Geometry**: Low-level mesh API; primarily optimized for glTF asset loading rather than procedural box manipulation.
- **Picking & Raycasting**: Native entity picking available via Filament entity IDs.
- **Camera Controls**: Orbit gesture support available.
- **Transform Controls**: No built-in CAD-style `TransformControls` gizmo equivalent; requires custom mathematical gizmo implementation.
- **Disposal**: Native Filament context destruction.

### Risk & Maintenance Score
- **Maintenance**: Actively developed by thermion.dev.
- **Risk**: High integration complexity for procedural CAD gizmos/handles compared to `three_js`. High rendering performance for glTF assets.

---

## 3. Fact vs Inference vs Recommendation

- **FACT**: `three_js` provides Dart ports of `OrbitControls` and `TransformControls` out of the box.
- **FACT**: `Thermion` wraps Google Filament for high-performance glTF rendering via native C++ FFI.
- **INFERENCE**: `three_js` provides lower integration friction for interactive procedural box handle dragging and axis-constrained editing.
- **RECOMMENDATION**: Primary spike candidate: `three_js`. Fallback benchmark: `Thermion`.
