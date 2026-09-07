# Mandap Geometry Model Architectural Decision

## Architectural Decision: Ground-Plane Coordinates as Source of Length

To prevent conflicting dual sources of truth (e.g. node coordinates vs manually entered `requestedLength`), the physical geometric length of an edge in `MandapLayout` is **always derived from the spatial coordinates of its endpoint nodes**.

### Data Structures

```dart
class MandapNode {
  final NodeId id;
  final double x; // Ground X in feet
  final double z; // Ground Z in feet
  final NodeType type;
}

class MandapEdge {
  final EdgeId id;
  final NodeId startNodeId;
  final NodeId endNodeId;
  final Length? requestedLength; // Used only in unplaced draft workflows
}
```

### Derivation Equation
For an edge connecting $S(x_1, z_1)$ and $E(x_2, z_2)$:

$$\text{distance} = \sqrt{(x_2 - x_1)^2 + (z_2 - z_1)^2}$$

$$\text{physicalLength} = \text{Length.fromFeet}(\text{distance})$$

This design guarantees that 2D layout edits, 3D handle manipulation, and calculation engine queries operate on the exact same geometric truth.
