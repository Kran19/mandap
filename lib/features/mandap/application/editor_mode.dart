/// State machine for the Mandap 2D editor interaction mode.
///
/// Transitions:
///   view ──► select ──► move      (drag selected node)
///                  └──► resize    (drag edge handle)
///   view ──► addNode              (tap to place node)
///   view ──► addEdge              (tap source → tap target)
///   view ──► delete               (tap node/edge to remove)
enum EditorMode {
  /// Default: pan/zoom gestures only. No selection or editing.
  view,

  /// Tap nodes or edges to select them. Shows context sheet.
  select,

  /// Drag a selected node to a new snapped position.
  move,

  /// Tap canvas to place a new structural node.
  addNode,

  /// Two-tap workflow: tap source node → tap target node → creates edge.
  addEdge,

  /// Tap a node or edge to delete it (with undo support).
  delete,
}

extension EditorModeLabel on EditorMode {
  String get label => switch (this) {
    EditorMode.view => 'View',
    EditorMode.select => 'Select',
    EditorMode.move => 'Move',
    EditorMode.addNode => 'Add Node',
    EditorMode.addEdge => 'Add Edge',
    EditorMode.delete => 'Delete',
  };

  String get shortLabel => switch (this) {
    EditorMode.view => 'View',
    EditorMode.select => 'Select',
    EditorMode.move => 'Move',
    EditorMode.addNode => '+Node',
    EditorMode.addEdge => '+Edge',
    EditorMode.delete => 'Del',
  };
}
