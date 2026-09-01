import '../../domain/entities/edge_id.dart';
import '../../domain/entities/mandap_edge.dart';
import '../../domain/entities/mandap_layout.dart';
import 'mandap_command.dart';

/// Removes a single [MandapEdge] from the layout. Undo re-inserts it.
class DeleteEdgeCommand implements MandapCommand {
  final EdgeId edgeId;

  /// Snapshot of the edge at deletion time, needed for undo.
  final MandapEdge snapshot;

  DeleteEdgeCommand({required this.edgeId, required this.snapshot});

  @override
  MandapLayout execute(MandapLayout layout) => layout.withoutEdge(edgeId);

  @override
  MandapLayout undo(MandapLayout layout) => layout.withEdge(snapshot);

  @override
  String get description => 'Delete edge $edgeId';
}
