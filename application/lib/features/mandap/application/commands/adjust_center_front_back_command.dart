import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/node_id.dart';
import 'adjust_center_position_command.dart';
import 'mandap_command.dart';

/// Command to adjust the internal truss front/back position along the world Z-axis,
/// preserving backwards compatibility while utilizing AdjustCenterPositionCommand.
class AdjustCenterFrontBackCommand implements MandapCommand {
  final NodeId centerNodeId;
  final double fixedX;
  final double oldZ;
  final double newZ;
  final NodeId? westMidNodeId;
  final NodeId? eastMidNodeId;

  const AdjustCenterFrontBackCommand({
    required this.centerNodeId,
    required this.fixedX,
    required this.oldZ,
    required this.newZ,
    this.westMidNodeId,
    this.eastMidNodeId,
  });

  AdjustCenterPositionCommand get _delegate => AdjustCenterPositionCommand(
        centerNodeId: centerNodeId,
        oldX: fixedX,
        oldZ: oldZ,
        newX: fixedX,
        newZ: newZ,
        westMidNodeId: westMidNodeId,
        eastMidNodeId: eastMidNodeId,
      );

  @override
  MandapLayout execute(MandapLayout currentLayout) => _delegate.execute(currentLayout);

  @override
  MandapLayout undo(MandapLayout currentLayout) => _delegate.undo(currentLayout);

  @override
  String get description =>
      'Adjust center front/back from ${oldZ.toStringAsFixed(1)} ft to ${newZ.toStringAsFixed(1)} ft (Fixed X: ${fixedX.toStringAsFixed(1)} ft)';
}

