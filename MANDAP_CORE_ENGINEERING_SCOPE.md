# Mandap Core --- Flutter Truss Calculator & Interactive 3D Layout

## Engineering Scope / Architecture Research Brief --- v0.1

**Project:** Mandap & Stage Builder\
**Core focus:** Module 4 (Mandap Truss Calculator) + Module 5
(Interactive 3D Layout / Editor)\
**Primary client:** Android Flutter application\
**Working unit:** feet; 0.5 ft increments\
**Status:** architecture/research specification before implementation

------------------------------------------------------------------------

## 1. Why this document exists

This document defines the technical scope for the core feature before UI
implementation begins. The calculator and geometry model must be correct
independently of the 3D renderer. The 3D editor is a visualization and
geometry-editing surface over the same domain model; it must never
become the source of truth for calculations.

The wider product scope supplied by the client includes OTP login,
subscription, inventory, jobs/history, sharing, admin, Gujarati/English
and offline use. The current engineering milestone deliberately isolates
the hardest and most valuable part: **turning an arbitrary mandap layout
into deterministic geometry, truss requirements, poles, stock shortages,
and an editable 3D representation.**

------------------------------------------------------------------------

## 2. Source business rules

### 2.1 Truss inventory

-   Standard truss pieces exist in fixed lengths from **1 ft to 20 ft**.
-   Inventory stores quantity per length.
-   Half-foot input is allowed by the app. The actual available
    stock-size configuration must remain data-driven rather than
    hard-coded.
-   Pieces connect directly with bolts; there is no separately
    inventoried connector/corner component.

### 2.2 Mandap representation

Do **not** model a mandap as "a rectangle with length and width."

Represent it as a graph/geometry model: - `Node`: a geometric
joint/corner/pole location. - `Edge`: a horizontal truss run between two
nodes. - `Segment`: one stock truss piece assigned to an edge. - `Pole`:
a vertical support at a node or generated support point. - A layout can
therefore be rectangular, L-shaped, U-shaped, irregular, open, or
eventually freehand.

This representation is the key architectural decision.

### 2.3 Edge decomposition

For every edge: 1. Read its required length. 2. Select stock truss
lengths that cover the edge using the **minimum number of pieces**. 3.
Exact construction is preferred. 4. If exact construction is impossible
with the configured stock lengths, return: - invalid/exact-fit
warning, - closest feasible lower length, - closest feasible higher
length, - difference from requested length. 5. Aggregate selected pieces
across the entire job. 6. Compare aggregate demand against inventory.

This is a bounded/unbounded integer optimization problem depending on
mode: - **Design mode:** optimize using allowed sizes, independent of
current stock. - **Loading mode:** validate the designed bill of
materials against stock. - A future optional "stock-aware optimizer" may
choose a different valid combination based on available quantities, but
it should not silently alter the design calculation.

### 2.4 Pole rule

-   A support exists at required structural/corner nodes.
-   No unsupported run may exceed **30 ft**.
-   For a long straight edge, insert intermediate pole/support positions
    so every resulting span is `<= 30 ft`.
-   The target spacing may later prefer 25--30 ft, but **30 ft is the
    hard calculation rule**.
-   Pole placement must be deterministic.

Important: pole calculation and stock-piece decomposition are related
visually but are separate calculations. A truss joint does not
automatically mean a pole unless the business rule says it does.

### 2.5 Bolt points

Bolt/join count is optional output only. A useful initial rule is to
count piece-to-piece joints along edges, while corner/node joints can be
reported separately if the client later wants them. Do not invent
physical connector inventory.

------------------------------------------------------------------------

## 3. Critical domain-model proposal

``` text
MandapJob
 ├── id
 ├── name
 ├── presetType
 ├── unit
 ├── layout: MandapLayout
 ├── inventorySnapshot
 └── calculationResult

MandapLayout
 ├── nodes: List<MandapNode>
 └── edges: List<MandapEdge>

MandapNode
 ├── id
 ├── position: Vec3/Vec2 ground-plane coordinate
 ├── nodeType: corner | generatedSupport | openEnd | junction
 └── locked

MandapEdge
 ├── id
 ├── startNodeId
 ├── endNodeId
 ├── requestedLength
 ├── geometryLength
 └── metadata

TrussPieceType
 ├── id
 ├── length
 └── stockQty

EdgeSolution
 ├── edgeId
 ├── exact
 ├── pieces
 ├── pieceCount
 ├── joints
 ├── suggestedLower
 └── suggestedHigher

PolePlacement
 ├── edgeId/nodeId
 ├── position
 └── reason

MandapCalculationResult
 ├── edgeSolutions
 ├── requiredTrussBySize
 ├── poles
 ├── boltPoints
 ├── shortages
 └── validationIssues
```

Use integer IDs and immutable domain objects where practical. Use
integer "half-foot ticks" internally (1 tick = 0.5 ft) instead of binary
floating-point for business calculations. Rendering can convert ticks to
`double`.

Example: - 10 ft = 20 ticks - 10.5 ft = 21 ticks - 30 ft hard pole span
= 60 ticks

This prevents `10.5 + 5.5` style floating-point equality problems.

------------------------------------------------------------------------

## 4. Calculation engine requirements

The engine should be a **pure Dart package/module** with no Flutter
widgets and no 3D dependency.

Recommended layers:

``` text
core/domain/
core/calculation/
  truss_optimizer.dart
  pole_placement.dart
  inventory_validator.dart
  layout_validator.dart
  calculation_engine.dart
core/geometry/
  vectors
  edge geometry
  snapping
  polygon/graph helpers
```

### Required deterministic functions

-   `solveEdge(length, availablePieceSizes)`
-   `solveAllEdges(layout, pieceCatalog)`
-   `placePoles(layout, maxSpan)`
-   `aggregateBillOfMaterials(edgeSolutions)`
-   `checkStock(required, inventory)`
-   `validateLayout(layout)`
-   `recalculate(layout, inventory, rules)`

### Optimization strategy

Because lengths are small and quantized, use dynamic programming rather
than a greedy algorithm.

Why: - Greedy "take the largest first" is not guaranteed to produce the
correct minimum-piece exact combination for arbitrary configured
sizes. - Dynamic programming can minimize: 1. number of pieces, 2. then
apply deterministic tie-breakers such as larger pieces first / fewer
distinct sizes. - The search space is tiny when lengths are measured in
0.5-ft ticks.

Add unit tests for every rule before 3D work begins.

------------------------------------------------------------------------

## 5. Geometry/editing model

### Ground-plane convention

Use a clear world coordinate convention: - X = horizontal ground axis -
Y = vertical height - Z = second ground axis - poles extend in +Y - top
beams exist at `Y = mandapHeight`

Keep business dimensions in feet/ticks. Apply a render scale only inside
the renderer.

### Editing principle

The screenshot resembles CAD/truss software, but the product does not
need full CAD.

The editor needs: - orbit camera, - pan, - pinch zoom, - object/edge
selection, - edit-mode toggle, - draggable edge/node handles, -
dimension label, - snap to 0.5 ft, - live recalculation, - generated
pole preview, - undo/redo, - save/complete.

### Important ambiguity in the current scope

"Drag one horizontal bar and only that bar moves" is geometrically
ambiguous.

An edge has two endpoints. Changing only its length must define **which
endpoint moves and along which axis/direction**. For production
behavior, define explicit edit operations rather than arbitrary mesh
deformation:

1.  **Resize edge from endpoint A** --- B remains fixed.
2.  **Resize edge from endpoint B** --- A remains fixed.
3.  **Move node** --- all edges connected to that node update.
4.  Later: **translate edge** --- moves both endpoints and affects
    connected geometry according to constraints.

The UI may make this feel like "dragging a bar," but the underlying
command must be mathematically explicit.

For Phase 1, support a controlled single-edge resize. For Phase 2,
introduce node/edge manipulation for arbitrary layouts.

------------------------------------------------------------------------

## 6. 3D technology research (August 2026)

### Candidate A --- `three_js` for Flutter

Current package information indicates that `three_js` is a Dart/Flutter
3D engine derived from three.js/three_dart and is intended to view, edit
and manipulate 3D objects. Its documented control ecosystem includes
**OrbitControls, DragControls, ArcballControls and TransformControls on
mobile**, which maps unusually well to this product's editor
requirements.

**Why it is the strongest prototype candidate** - Scene graph and
procedural geometry are natural for poles/beams. - Raycasting/selection
and manipulation concepts are already part of the three.js
architecture. - Orbit/drag/transform controls are much closer to a
CAD-like editor than a GLB-only viewer. - We need to generate geometry
dynamically from calculation data, not merely display a prebuilt model.

**Risks** - It is a community package, not an official Flutter 3D
stack. - Renderer/backend evolution must be tested against the exact
Flutter stable version and target Android devices. - Build a technical
spike before committing the product.

### Candidate B --- Thermion

Thermion is a cross-platform Dart/Flutter 3D toolkit with Flutter
embedding, entity/camera manipulation and native-oriented rendering. It
is actively published and is a serious alternative if native rendering
stability/performance proves stronger.

**Why evaluate it** - Cross-platform engine architecture. -
Camera/entity manipulation. - Native 3D orientation and active
development.

**Concern for this exact editor** The public feature surface is less
obviously aligned with ready-made CAD-style transform/drag controls than
`three_js`; therefore we must prove picking, gizmos, runtime primitive
creation/update and touch manipulation in a spike.

### Candidate C --- `interactive_3d`

This plugin uses Google Filament on Android and SceneKit on iOS and
supports selection of parts of GLB/glTF models.

**Good for:** native interactive model viewers/configurators.\
**Not first choice for Mandap:** our scene is procedural and
continuously regenerated/resized. We need an editor, not mainly a GLB
viewer.

### Candidate D --- Flutter GPU / Flutter Scene

Flutter's first-party GPU/3D direction is strategically interesting, but
Flutter Scene has been described as early preview and historically
required tracking Flutter's main channel/breaking GPU APIs.

**Recommendation:** monitor it; do not make Phase 1 production delivery
depend on an experimental first-party 3D stack unless a current spike
proves it stable enough.

### Reject for the core editor

-   `flutter_gl` + old `three_dart`: older foundation and Dart
    compatibility/maintenance concerns.
-   WebView/model-viewer solutions: useful for model viewing, poor fit
    for a low-latency procedural CAD-like editor.
-   Flame/Forge2D: excellent for games/2D physics, but this requirement
    is a 3D geometry editor, not a 2D physics simulation.
-   Unity embedded in Flutter: technically possible but introduces a
    second runtime/toolchain, larger app, bridge/state synchronization
    complexity, and is excessive for simple truss primitives unless
    Flutter-native approaches fail.

### Initial decision

**Prototype with `three_js` first. Keep Thermion as the mandatory
fallback benchmark. Do not finalize the renderer until both are tested
on a real mid-range Android device.**

------------------------------------------------------------------------

## 7. Required 3D technical spike

Build a throwaway prototype before the production screen.

The spike must demonstrate all of these on Android: 1. Render 100+
beam/pole primitives. 2. Orbit with one/two-finger gesture design that
does not fight editing. 3. Pinch zoom. 4. Tap/raycast one beam reliably.
5. Highlight selected beam. 6. Show endpoint handles. 7. Drag one
endpoint constrained to the edge axis/ground plane. 8. Snap length to
0.5 ft. 9. Display live dimension text. 10. Update beam transform
without rebuilding the whole Flutter screen. 11. Re-run calculation
engine during drag at a controlled rate. 12. Add/remove generated pole
when crossing 30 ft. 13. Undo/redo the edit. 14. Maintain smooth
interaction on a target mid-range Android phone. 15. Dispose/reopen
scene repeatedly without memory/resource leaks.

Benchmark `three_js` and Thermion against the same spike.

### Go/no-go criteria

Choose the renderer only after recording: - FPS/frame-time during orbit
and drag, - input latency, - memory after repeated scene open/close, -
implementation complexity, - picking reliability, - primitive update
complexity, - Android build stability.

------------------------------------------------------------------------

## 8. Rendering architecture

Never recreate complex truss lattice geometry for every frame unless
necessary.

Use two visual quality modes:

### Editing representation

-   beam = simple rectangular/cylindrical prism or lightweight reusable
    truss asset,
-   pole = same,
-   selected beam = highlighted material,
-   handles = simple spheres/cubes,
-   grid = lightweight plane/line grid,
-   dimensions = Flutter overlay or 3D label strategy.

### Presentation representation

Optionally swap a simple beam for a reusable truss-looking mesh/GLB
after geometry is stable.

This keeps interaction fast while allowing the final result to resemble
the Global Truss reference screenshot.

Use object pooling/reuse where the chosen renderer permits it.

------------------------------------------------------------------------

## 9. Flutter application architecture for this module

Recommended: - Flutter UI shell - pure Dart domain/calculation engine -
repository layer - local database for offline jobs/inventory - remote
API sync later - renderer adapter behind an interface

``` text
features/mandap/
  domain/
  data/
  application/
  presentation/
  renderer/
    mandap_renderer.dart
    three_js_renderer.dart   // prototype/implementation
    thermion_renderer.dart   // spike/fallback
```

### Renderer abstraction

The calculation layer must never import `three_js`, Thermion, or Flutter
rendering types.

Example conceptual interface:

``` text
MandapRenderer
  setLayout(RenderLayout)
  setSelection(EntityId?)
  updateNode(...)
  updateEdge(...)
  setCameraMode(...)
  dispose()
```

This makes the 3D engine replaceable.

### State management

Riverpod or BLoC are both acceptable. For this project, choose one
team-wide and keep high-frequency drag state out of broad application
rebuilds.

A good split: - persistent/domain state: Riverpod/BLoC, - transient
pointer/drag/render state: renderer/controller/local notifier, -
calculation result: pure engine invoked from controlled edit events.

Do not trigger a full widget-tree rebuild for every pointer pixel.

------------------------------------------------------------------------

## 10. Offline-first direction

Jobs and inventory snapshots should work without network.

Use: - local database as immediate source for job/layout data, -
repository as the single access point, - sync metadata (`dirty`,
`updatedAt`, server revision), - remote sync when connectivity returns.

A saved job should retain the rules/inventory snapshot or version used
for its calculation so reopening an old job does not silently change
historical results after admin inventory/rules change.

------------------------------------------------------------------------

## 11. Phase 1 UX

1.  New Job
2.  Choose preset: Chori / Jamanvar / Custom
3.  Enter/edit edges
4.  Immediate 2D/top preview
5.  Calculate
6.  Result sheet:
    -   poles,
    -   truss pieces by size,
    -   shortage warnings,
    -   per-edge decomposition
7.  Open 3D
8.  Orbit/zoom
9.  Enable Edit
10. Select one edge
11. Resize via handle/dimension
12. Snap and live recalculate
13. Undo or Done
14. Save job

Strong recommendation: build a **2D top-view editor before full freehand
3D editing**. It is easier to input precise geometry on a phone and uses
the same node/edge domain model. The 3D view then becomes a powerful
verification/editor surface rather than the only way to define geometry.

------------------------------------------------------------------------

## 12. Validation cases that must exist

-   zero/negative edge
-   non-0.5-ft input
-   exact stock fit
-   multiple exact combinations
-   impossible exact fit
-   very long edge
-   exactly 30 ft
-   30.5 ft
-   multiple generated supports
-   open shape
-   closed polygon
-   L-shape
-   repeated/overlapping nodes
-   zero-length edge after drag
-   disconnected graph
-   inventory shortage for one size
-   shortage for multiple sizes
-   sufficient total truss footage but wrong sizes
-   undo after generated pole appears
-   edit causing exact-fit → impossible-fit and reverse
-   app killed/reopened offline with saved job

------------------------------------------------------------------------

## 13. Testing strategy

### Pure Dart unit tests

Highest priority. Hundreds of fast cases for: - optimizer, -
tie-breaking, - pole placement, - validation, - inventory aggregation.

### Property-based/fuzz tests

Generate many edge lengths/layouts and assert invariants: - no selected
piece length is invalid, - exact solutions sum exactly, - no pole span
exceeds max, - BOM equals sum of edge solutions, - calculations are
deterministic.

### Golden/widget tests

For input/result UI, not for core math.

### Integration tests

-   create job → calculate → 3D edit → recalc → save → reopen.
-   offline save/sync scenarios.

### Device performance tests

Use at least one lower/mid-range Android device representative of the
client.

------------------------------------------------------------------------

## 14. Questions that must be confirmed with the client before finalizing algorithms

1.  Are actual stock lengths every integer 1--20 ft, or only selected
    sizes?
2.  Does inventory contain any half-foot physical truss pieces, or is
    half-foot only an input tolerance?
3.  If an edge is 35 ft, is the intermediate pole exactly at a truss
    joint, at a preferred 25--30 ft location, or anywhere as long as
    spans are \<=30?
4.  Does every corner always require a pole, including concave corners
    and open ends?
5.  Are T-junctions/cross-junctions valid layouts? If yes, does each
    junction require a pole?
6.  When several minimum-piece combinations exist, which combination
    should be preferred?
7.  Should the optimizer ignore current stock and only warn afterward,
    or may it choose another combination to fit available stock?
8.  For "drag one bar," which endpoint is anchored? Can connected edges
    change?
9.  Are beams only on the outer perimeter, or can the mandap contain
    internal cross-bars/grid beams as shown in some sketches/reference
    structures?
10. Does the 30-ft support rule apply to internal bars too?
11. Is mandap height fixed per job (10/12 ft), or configurable?
12. Does a vertical pole consume the same 1--20 ft truss inventory or is
    pole stock tracked separately? The supplied scope says same
    inventory, but this needs operational confirmation.
13. For Chori/Jamanvar presets, provide exact dimensions and
    internal-bar topology.
14. Should bolt points include corner/node joins or only joins between
    stock pieces on a run?

These answers are more important than choosing a UI library.

------------------------------------------------------------------------

## 15. Recommended execution order

**Milestone 0 --- domain validation** - confirm the 14 business
questions with client.

**Milestone 1 --- calculation engine** - domain model, - optimizer, -
pole algorithm, - inventory validation, - tests.

**Milestone 2 --- 2D geometry editor** - nodes/edges, - dimensions, -
snapping, - presets, - arbitrary outline groundwork.

**Milestone 3 --- 3D spike** - benchmark `three_js` vs Thermion.

**Milestone 4 --- production 3D viewer** - generated scene, - camera, -
selection, - dimension overlays.

**Milestone 5 --- controlled 3D editing** - endpoint/edge resize, - live
recalculation, - pole appearance, - undo/redo.

**Milestone 6 --- freehand/irregular editor** - advanced constraints, -
junctions/internal bars, - polished phone gestures.

Do not start by building a beautiful 3D truss screen. First prove the
domain model and calculator, because every renderer/editor operation
depends on them.

------------------------------------------------------------------------

## 16. Current technical recommendation

**Flutter is viable for the product**, provided the 3D editor is treated
as a specialized renderer/editor subsystem rather than ordinary Flutter
widget layout.

Recommended starting stack for this core: - Flutter stable - Dart pure
calculation package - `vector_math` for geometry math - `three_js` as
first 3D editor spike - Thermion as fallback/native-rendering
benchmark - Riverpod or BLoC for app/domain state - local SQL
database/repository for offline-first jobs - immutable command-based
undo/redo - renderer-independent node/edge IDs - 0.5-ft integer ticks
for calculation precision

The hardest problem is **not rendering a truss**. It is maintaining a
correct, editable geometry graph while touch gestures change dimensions
and the calculation/stock engine updates deterministically. Architecture
should optimize for that fact.
