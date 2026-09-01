# MANDAP System Architecture Documentation

## Architectural Principles

1. **Calculation/Data Model is Source of Truth**: The domain geometry graph (`MandapLayout`) and calculation services (`MandapCalculationEngine`) represent the sole business ground truth. 3D/2D views are visual rendering and editing surfaces. No separate 3D layouts exist.
2. **Pure Dart Core**: The domain core inside `lib/features/mandap/domain/` has zero dependencies on Flutter UI, Material, 3D engines, or external persistence frameworks.
3. **Exact Quantized Precision (`Length`)**: All physical lengths are computed using integer ticks (`1 tick = 0.5 ft`) to guarantee complete immunity against binary floating-point rounding errors.

## Layer Boundaries

```
lib/
├── core/
│   └── geometry/
│       └── length.dart            // Quantized 0.5 ft tick value object
│
└── features/
    └── mandap/
        ├── domain/
        │   ├── entities/          // MandapNode, MandapEdge, MandapLayout, TrussCatalog, TrussInventory
        │   ├── value_objects/     // EdgeSolution, PolePlacement, InventoryShortage, MandapCalculationResult
        │   └── services/          // TrussOptimizer (DP), PolePlacementEngine, InventoryValidator, MandapCalculationEngine
        │
        ├── application/
        │   ├── commands/          // Command pattern history (ResizeEdgeCommand, MoveNodeCommand, AddNodeCommand, etc)
        │   ├── mandap_editor_controller.dart // Application workflow and undo/redo logic
        │   └── editor_mode.dart   // Editor State Machine (view, select, move, addNode, addEdge, delete)
        │
        └── presentation/
            ├── debug_shell_screen.dart   // Engineering debug UI shell
            ├── top_view_2d/
            │   └── mandap_2d_painter.dart // SDK-native 2D top view renderer
            └── widgets/
                └── 3d/
                    ├── mandap_3d_view.dart  // Interactive 3D editor view
                    ├── mandap_3d_controller.dart // Orbit camera and projection manager
                    ├── mandap_3d_painter.dart // 3D Canvas rendering engine
                    └── math/              // Projection, unprojection, and entity mapping utilities
```

## 3D Renderer Integration

Phase 5 productionized the 3D editor under a clean architectural boundary. `Mandap3DController` maps layout parameters to render entities (`RenderEntityRegistry`). Interactive clicks are unprojected to rays and intersected with the interaction plane. The resulting drag positions snap to `0.5 ft` increments, executing standard command objects (`ResizeEdgeCommand`, `MoveNodeCommand`) back onto the `MandapEditorController` source of truth.
