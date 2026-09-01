import '../domain/entities/edge_id.dart';
import '../domain/entities/mandap_layout.dart';
import '../domain/entities/node_id.dart';
import '../domain/value_objects/mandap_calculation_result.dart';

/// Listener callbacks emitted by the 3D renderer adapter to the editor application layer.
abstract class MandapRendererEventListener {
  void onEdgeSelected(EdgeId? edgeId);
  void onHandleDragStart(EdgeId edgeId, NodeId handleNodeId);
  void onHandleDragUpdate(
    EdgeId edgeId,
    NodeId handleNodeId,
    double newLengthFeet,
  );
  void onHandleDragEnd(
    EdgeId edgeId,
    NodeId handleNodeId,
    double finalLengthFeet,
  );
}

/// Abstract interface controller decoupling domain logic from concrete 3D renderers.
///
/// Domain models and calculation engines MUST NOT import renderer-specific packages.
abstract class MandapRendererController {
  /// Initializes 3D scene resources and camera settings.
  void initialize();

  /// Updates visual scene objects to reflect current [layout] and [result].
  void updateScene({
    required MandapLayout layout,
    required MandapCalculationResult result,
    EdgeId? selectedEdgeId,
  });

  /// Updates edge selection state.
  void selectEdge(EdgeId? edgeId);

  /// Resets camera to default perspective view.
  void resetCamera();

  /// Registers event listener for touch interaction events.
  void setEventListener(MandapRendererEventListener? listener);

  /// Releases renderer textures, buffers, and event listeners cleanly.
  void dispose();
}
