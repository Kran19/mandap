import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import 'mandap_command.dart';

/// Changes the physical support state of a node (e.g. from pole to none, or vice versa)
/// without modifying its world coordinates or connected structural members.
class SetNodeSupportCommand implements MandapCommand {
  final NodeId nodeId;
  final NodeSupport newSupport;
  late final NodeSupport _oldSupport;

  SetNodeSupportCommand({
    required this.nodeId,
    required this.newSupport,
  });

  @override
  MandapLayout execute(MandapLayout layout) {
    final node = layout.getNode(nodeId);
    if (node == null) return layout;
    _oldSupport = node.support;
    return layout.withNode(node.copyWith(support: newSupport));
  }

  @override
  MandapLayout undo(MandapLayout layout) {
    final node = layout.getNode(nodeId);
    if (node == null) return layout;
    return layout.withNode(node.copyWith(support: _oldSupport));
  }

  @override
  String get description =>
      'Set support of node ${nodeId.value} to ${newSupport.name}';
}
