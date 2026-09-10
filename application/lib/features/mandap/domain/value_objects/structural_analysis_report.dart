import 'package:meta/meta.dart';
import '../entities/edge_id.dart';
import '../entities/node_id.dart';

/// Pure read-only diagnostics report produced by [StructuralGraphAnalyzer].
/// Contains independent connectivity diagnostics, support analysis, and soft warnings.
@immutable
class StructuralAnalysisReport {
  /// Total number of independent connected graph components / structures.
  final int componentCount;

  /// Nodes that have 0 connected members.
  final List<NodeId> isolatedNodes;

  /// Member endpoint nodes that have no physical support (`support == NodeSupport.none`).
  final List<NodeId> unsupportedEndpoints;

  /// Members whose physical span exceeds the preferred pole spacing threshold (e.g. 30 ft).
  final List<EdgeId> longSpans;

  /// Human-readable, non-blocking diagnostic and structural warnings.
  final List<String> warnings;

  const StructuralAnalysisReport({
    required this.componentCount,
    this.isolatedNodes = const [],
    this.unsupportedEndpoints = const [],
    this.longSpans = const [],
    this.warnings = const [],
  });

  /// True if there are any soft structural warnings.
  bool get hasWarnings => warnings.isNotEmpty;

  /// True if all members are supported with no isolated poles or long spans.
  bool get isClean =>
      unsupportedEndpoints.isEmpty &&
      isolatedNodes.isEmpty &&
      longSpans.isEmpty;

  @override
  String toString() =>
      'StructuralAnalysisReport(components: $componentCount, '
      'unsupported: ${unsupportedEndpoints.length}, '
      'isolated: ${isolatedNodes.length}, '
      'longSpans: ${longSpans.length}, '
      'warnings: ${warnings.length})';
}
