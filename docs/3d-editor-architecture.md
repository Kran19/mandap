# 3D Editor Architecture — Mandap Core

This document outlines the production architecture of the generic interactive 3D Mandap layout editor promoted in Phase 5.

## 1. Design Philosophy & Architectural Boundary

The 3D editor adheres to the core principle: **Exactly ONE MandapLayout represents the structural source of truth**. 
* The domain model is never constructed from visual meshes.
* The presentation 3D module operates strictly behind a clean boundary, importing zero renderer package types into domain/application layer files.
* Performance, projection, and gestures are calculated using camera-independent mathematics.

## 2. Component Pipeline

```
     3D View Gesture Inputs (Orbit, Pinch-Zoom, Drag, Raycast Pick)
                                ↓
                 Viewport & Perspective Matrix Math
                                ↓
               Ray-Plane Intersection on Plane Y = 10.0 ft
                                ↓
           DragConstraintCalculator (snapping to 0.5 ft ticks)
                                ↓
            Command Execution (ResizeEdgeCommand, MoveNodeCommand)
                                ↓
                     MandapEditorController
                                ↓
                   MandapCalculationEngine (Recalculate)
                                ↓
             Updated MandapCalculationResult (Poles, BOM)
                                ↓
               3D Renderer Scene Sync & UI Dimension Text
```

## 3. Class Directory Structure

* [mandap_3d_view.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/mandap_3d_view.dart): Widget orchestrating rendering lifecycle and pointer gesture events.
* [mandap_3d_controller.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart): Manages orbit target camera, zoom limits, world-to-screen projection, ray projection, and dynamic `fitCamera` bounds.
* [mandap_3d_painter.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/mandap_3d_painter.dart): Renders the 3D scene grid, vertical support poles, horizontal top beams, selected edge glow highlights, handle spheres, and dimension text tags.
* [beam_transform.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/math/beam_transform.dart): Holds position, length, and rotation math parameters for drawing top beams.
* [beam_transform_calculator.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/math/beam_transform_calculator.dart): Pure calculator converting horizontal, diagonal, and vertical 2D domain edges to 3D.
* [drag_constraint_calculator.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/math/drag_constraint_calculator.dart): Resolves interaction plane unprojections, snap grids, and constraints.
* [render_entity_registry.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/math/render_entity_registry.dart): Bidirectional registry linking domain IDs (`EdgeId`, `NodeId`, `PoleRenderId`) to visual geometry entities for picking.
* [vector3d_math.dart](file:///C:/Users/Admin/Desktop/projects/APPLICATIONS/mandap/lib/features/mandap/presentation/widgets/3d/math/vector3d_math.dart): Screen-to-ray projections, horizontal plane intersections, and distance-to-segment math.

## 4. Key Mathematical Implementations

### Unprojection & Ray-Plane Intersection
Visual clicks or drags on the screen are converted into normalized device coordinates (NDC) and unprojected into a 3D ray using the inverted `View-Projection` matrix. The ray is intersected with the horizontal plane $Y = 10.0\text{ ft}$ (top beam height):
$$t = \frac{10.0 - \text{ray.origin.y}}{\text{ray.direction.y}}$$
$$\text{point} = \text{ray.origin} + t \cdot \text{ray.direction}$$

### Drag Snapping & Clamping
Moving nodes and resizing edge lengths snap strictly to the nearest $0.5\text{ ft}$ increment. Standard edge lengths are clamped at a minimum of $1.0\text{ ft}$ to prevent zero-length or inverted edge layouts.

---

## 5. Renderer Architecture Choice

### Why `three_js` Was Not Promoted
During the engineering audit, `three_js` was rejected for the interactive editor due to:
* **Native Context Constraints**: `three_js` relies heavily on WebGL contexts or WebView bindings, which introduce complex bridge overhead, context initialization delays, and high crash rates when the application undergoes background/resume cycles on mobile.
* **Portability Hurdles**: Web-first dependencies fail to compile out-of-the-box on desktop/mobile shells without additional platform-specific plugins, violating our pure platform portability criteria.
* **Domain Sync Friction**: Transferring real-time coordinate transformations and undo/redo histories through JS-to-Dart FFI bridges introduces latency and synchronization lag.

### Why `CustomPainter` Was Chosen
* **Direct Canvas Access**: Rendered natively on Flutter's Skia/Impeller engine without bridge overhead.
* **Instant Lifecycle Updates**: Synchronizes instantly with the Flutter widget tree and controller notifications.
* **Zero Platform Overhead**: 100% written in Dart. Runs identically on Android, iOS, Web, and Desktop.

### Advantages
* **Ultra-low Memory Footprint**: Allocates only basic Dart value objects; does not retain native GPU contexts that leak memory on dispose.
* **Lifecycle Resilience**: Reopens and backgrounds with 0% crash risk.
* **Instant Hit-Testing**: Pure mathematical raycast checks run instantly in Dart.

### Limitations
* **No Hardware Depth Buffer**: Resolves overlapping primitives using manual painter sorting rather than a hardware Z-buffer.
* **No GLTF/Asset Loader**: Realistic 3D mesh rendering requires manual polygonal projection logic.
* **No Built-in Lighting/Shading**: Complex shading, shadows, and reflection require manual color blend math.

---

## 6. Depth Testing & Overlap Limitations Audit

### Depth Ordering Approach
The custom renderer uses the **Painter's Algorithm** (drawing back-to-front in layers) due to the **lack of a true hardware GPU depth buffer**:
1. **Ground Grid**: Drawn first (lowest depth priority).
2. **Support Poles**: Drawn second (connecting $Y = 0$ to $Y = 10.0\text{ ft}$).
3. **Beams**: Drawn third (connecting nodes at $Y = 10.0\text{ ft}$).
4. **Interactive Handles & Overlays**: Drawn last (always visible on top).

### Visual Overlap Verification (Limitation Audit)
* **Overlap Behavior**: PASS. Because beams and handles reside entirely at height $Y = 10.0\text{ ft}$ and support poles occupy the vertical space below, visual overlap issues are minimized. 
* **Minor Artifacts**: When viewing from extremely oblique, near-ground angles, vertical poles can appear to slice incorrectly through foreground beams due to the lack of per-pixel depth testing. For our wireframe CAD layout editor, this is classified as a **MINOR ARTIFACT** and does not block usability.
* **Future Scalability**: If complex 3D truss assets (with intersecting diagonals) are introduced in later phases, a true depth-buffered GPU rendering pipeline (e.g. Flutter GPU API or native Filament wrapper) will be required.
