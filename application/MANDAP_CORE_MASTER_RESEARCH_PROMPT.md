# MASTER RESEARCH + IMPLEMENTATION PROMPT --- Mandap Core Flutter Module

You are the principal Flutter architect, computational-geometry
engineer, and real-time 3D mobile engineer for the **Mandap Core**
project.

Your task is NOT to immediately write the full feature.

Your first job is to deeply research, challenge assumptions, produce a
technical decision, and only then design an implementation plan for a
production Android Flutter application.

## Context

Read `MANDAP_CORE_ENGINEERING_SCOPE.md` completely before doing anything
else. Treat it as the current source of truth.

The core product is a mandap/truss calculator plus an interactive 3D
editor: - arbitrary layouts represented by nodes + edges, not only
rectangles; - fixed stock truss lengths; - minimum-piece edge
decomposition; - pole/support generation with max 30-ft unsupported
span; - inventory shortage validation; - 3D visualization; - touch
selection and edge/node manipulation; - 0.5-ft snapping; - live
recalculation; - undo/redo; - offline saved jobs.

Reference visual behavior is similar to lightweight truss/CAD software,
but we are NOT building AutoCAD and we do NOT need structural
engineering simulation.

## Non-negotiable architecture

1.  Business/calculation logic must be pure Dart.
2.  The calculation engine must have zero dependency on Flutter UI or
    the 3D engine.
3.  The layout must use stable IDs and a node/edge graph.
4.  Do not use `double` equality for business lengths. Use integer
    half-foot ticks (or justify a superior exact representation).
5.  The 3D engine is replaceable through an adapter.
6.  Rendering must never become the source of truth.
7.  Do not use greedy truss decomposition unless you mathematically
    prove it is correct for the configured catalog.
8.  High-frequency drag events must not rebuild the whole Flutter
    app/widget tree.
9.  All architecture decisions must target a real mid-range Android
    phone, not only emulator/desktop/web.
10. Do not invent missing client rules. Surface ambiguities explicitly.

## Research task

Research the CURRENT ecosystem, documentation, package health, Android
support, Flutter compatibility, GitHub activity/issues, examples and
practical limitations for at least:

-   `three_js`
-   `three_js_controls`
-   `three_js_transform_controls`
-   Thermion (`thermion_flutter`, `thermion_dart`)
-   `interactive_3d`
-   Flutter GPU / Flutter Scene
-   any genuinely stronger current alternative you discover

Also investigate whether any candidate supports or can cleanly
implement: - procedural boxes/cylinders/lines; - scene graph with stable
entities; - raycasting/object picking; - OrbitControls-like camera; -
constrained dragging; - transform gizmos/handles; - runtime mesh
transform updates; - text/dimension labels; - world-to-screen
projection; - custom materials/highlighting; - instancing/object
reuse; - resource disposal; - Android touch gestures; - Flutter Impeller
compatibility; - Android build requirements; - minSdk/ABI
restrictions; - performance on many simple primitives.

Do not choose a package because its README says "3D." Our requirement is
an **interactive procedural editor**, not a GLB viewer.

## Mandatory comparison

Create a decision matrix with columns:

-   renderer
-   rendering backend
-   Android support
-   Flutter stable compatibility
-   procedural geometry
-   picking/raycast
-   orbit
-   drag
-   transform controls
-   runtime geometry/transform updates
-   text/dimension strategy
-   expected performance
-   maintenance/activity
-   integration complexity
-   editor suitability
-   production risk
-   verdict

Every important claim must have a source/link or be clearly labeled as
your inference.

## Calculation-engine research

Design the exact algorithm for truss decomposition.

Requirements: - catalog is configurable; - lengths are quantized; -
primary objective = minimum number of pieces; - exact fit preferred; -
deterministic tie-breaker; - if impossible, return nearest lower and
higher feasible lengths; - aggregate BOM; - inventory shortage
calculation.

Compare: - greedy, - dynamic programming, - BFS/shortest path, - integer
programming.

Pick the simplest algorithm that is mathematically correct for our scale
and explain time/space complexity.

Then design pole placement: - required corner/node poles; - generated
supports such that no span \>30 ft; - deterministic coordinates; -
behavior at exactly 30 and 30.5; - long edges; - open shapes; -
junctions.

Do NOT assume a truss-piece joint automatically means a pole.

## Geometry/editor research

Challenge this requirement:

> "User grabs one horizontal bar, drags it, only that bar changes."

Explain the geometry consequences. Define precise edit commands such
as: - resize edge from start; - resize edge from end; - move node; -
translate edge; - insert node; - delete edge.

Propose Phase 1 behavior that is easy for a non-technical mandap worker
on a phone but does not corrupt connected geometry.

Research and define: - ray-plane intersection for touch dragging; -
axis-constrained movement; - camera projection/unprojection; - snapping
to 0.5 ft; - hit target sizing for fingers; - conflict between orbit
gesture and edit gesture; - dimension overlays; - selection
highlighting; - generated support visualization; - throttled live
calculation.

## Required prototype/spike

Before production architecture is accepted, specify a runnable spike
that compares the top TWO renderer candidates using the SAME scene and
interactions.

Scene: - rectangular/irregular mandap; - \>=100 simple beam/pole
objects; - grid; - camera orbit/zoom; - tap selection; - selected
highlight; - two endpoint handles; - constrained endpoint drag; - live
length; - 0.5-ft snap; - support added when edge exceeds 30 ft; - undo.

Define measurable acceptance criteria: - frame time/FPS; - drag
latency; - memory; - scene reopen/dispose test; - Android build
stability; - picking accuracy; - code complexity.

Do not proceed to the full editor until the spike passes.

## Flutter architecture output

Propose a production folder structure and dependency boundaries.

At minimum separate: - domain entities; - calculation use
cases/services; - geometry math; - inventory; - repositories; - local
persistence; - sync; - application state; - Flutter screens; - renderer
adapter; - concrete renderer; - editor controller; - command/undo
system.

Explain what state belongs in: - persistent app/domain state; - editor
state; - renderer-only transient state.

Compare Riverpod vs BLoC briefly and choose one for THIS project. Do not
turn this into a generic state-management essay.

Research the current Flutter offline-first guidance and recommend local
persistence. Compare suitable current SQLite/Dart options if needed.

## Testing output

Produce a serious test plan: - unit tests; - optimizer edge cases; -
pole invariants; - property/fuzz tests; - geometry tests; - widget
tests; - integration tests; - Android performance tests.

Include concrete test vectors: - 30 ft; - 30.5 ft; - 60 ft; - impossible
stock combination; - equal-minimum-piece alternatives; - shortage
despite sufficient total footage; - L-shape; - open layout; -
disconnected graph; - zero-length edge; - drag across 30-ft threshold; -
undo/redo.

## Deliverables --- in this exact order

### 1. Executive technical verdict

Maximum 1 page. State whether Flutter is viable and the recommended
renderer path.

### 2. Unknowns/blockers

List every business-rule question that must be answered by the client.

### 3. Current ecosystem research

Source-backed package/library analysis.

### 4. Renderer decision matrix

Top candidates with final ranking.

### 5. Calculation-engine design

Data structures + algorithms + pseudocode.

### 6. Geometry/editor design

Coordinate system, selection, dragging, snapping, commands, constraints.

### 7. Architecture

Layers, folder tree, state boundaries, renderer adapter.

### 8. Spike specification

Exactly what to build before production.

### 9. Testing strategy

Including deterministic and fuzz/property tests.

### 10. Performance strategy

How to avoid rebuilds, allocations and excessive mesh regeneration.

### 11. Implementation roadmap

Small ordered milestones. Each milestone must have a Definition of Done.

### 12. Risk register

Risk, probability, impact, mitigation.

### 13. Recommended dependencies

Only after research. For each dependency give: - exact purpose; - why
needed; - alternative; - risk; - whether it belongs in production or
spike only.

### 14. Final recommendation

Give one primary stack and one fallback stack.

## Rules for your response

-   Think like an engineer who must ship and maintain this for years.
-   Prefer simple deterministic math over visual hacks.
-   Do not blindly agree with the scope.
-   Flag contradictions.
-   Do not write the whole production code yet.
-   Small pseudocode/examples are allowed where they prove the
    architecture.
-   Search current official docs, pub.dev and repositories/issues.
-   Prefer sources from 2026/current versions.
-   Clearly separate FACT, INFERENCE, and RECOMMENDATION.
-   Do not suggest Unity unless the Flutter-native spike fails and you
    can prove why.
-   Do not recommend WebView/model-viewer as the primary editor.
-   Do not let a 3D package dictate the domain model.
-   End with a concrete "build this first tomorrow morning" checklist of
    no more than 10 items.
