import 'dart:math' as math;
import '../entities/edge_id.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/node_id.dart';
import '../value_objects/structural_analysis_report.dart';

/// Pure, read-only structural intelligence service.
/// Analyzes a [MandapLayout] graph and produces a [StructuralAnalysisReport]
/// containing support relationships, connectivity diagnostics, and soft warnings.
///
/// CRITICAL: This service NEVER mutates the layout, deletes nodes,
/// adds poles, or repairs user geometry.
class StructuralGraphAnalyzer {
  const StructuralGraphAnalyzer();

  /// Evaluates [layout] against preferred spacing (default 30.0 ft).
  static StructuralAnalysisReport analyze(
    MandapLayout layout, {
    double preferredSpacingFeet = 30.0,
  }) {
    if (layout.nodes.isEmpty) {
      return const StructuralAnalysisReport(
        componentCount: 0,
        warnings: ['Layout has no structural entities'],
      );
    }

    final warnings = <String>[];
    final isolatedNodes = <NodeId>[];
    final unsupportedEndpoints = <NodeId>[];
    final longSpans = <EdgeId>[];

    // 1. Build adjacency and node member degree
    final nodeDegree = <NodeId, int>{};
    final adjacency = <NodeId, Set<NodeId>>{};
    for (final nodeId in layout.nodes.keys) {
      nodeDegree[nodeId] = 0;
      adjacency[nodeId] = {};
    }

    for (final edge in layout.edges.values) {
      if (layout.nodes.containsKey(edge.startNodeId) &&
          layout.nodes.containsKey(edge.endNodeId)) {
        nodeDegree[edge.startNodeId] = (nodeDegree[edge.startNodeId] ?? 0) + 1;
        nodeDegree[edge.endNodeId] = (nodeDegree[edge.endNodeId] ?? 0) + 1;
        adjacency[edge.startNodeId]?.add(edge.endNodeId);
        adjacency[edge.endNodeId]?.add(edge.startNodeId);
      }
    }

    // Intersecting junction nodes that lie along member segments connect into that component
    for (final node in layout.nodes.values) {
      if (node.role == NodeType.junction) {
        for (final edge in layout.edges.values) {
          if (edge.startNodeId == node.id || edge.endNodeId == node.id) continue;
          final p1 = layout.nodes[edge.startNodeId];
          final p2 = layout.nodes[edge.endNodeId];
          if (p1 == null || p2 == null) continue;

          // Check if point lies on line segment between p1 and p2
          final cross = (node.z - p1.z) * (p2.x - p1.x) - (node.x - p1.x) * (p2.z - p1.z);
          if (cross.abs() < 0.05) {
            final dot = (node.x - p1.x) * (p2.x - p1.x) + (node.z - p1.z) * (p2.z - p1.z);
            final lenSq = (p2.x - p1.x) * (p2.x - p1.x) + (p2.z - p1.z) * (p2.z - p1.z);
            if (dot >= -0.05 && dot <= lenSq + 0.05) {
              adjacency[node.id]?.add(edge.startNodeId);
              adjacency[node.id]?.add(edge.endNodeId);
              adjacency[edge.startNodeId]?.add(node.id);
              adjacency[edge.endNodeId]?.add(node.id);
            }
          }
        }
      }
    }

    // 2. Node Analysis: isolated poles & unsupported nodes
    for (final node in layout.nodes.values) {
      // Exclude area zones (stage/carpet) from structural pole analysis
      if (node.type == NodeType.stage || node.type == NodeType.carpet) {
        continue;
      }

      final degree = nodeDegree[node.id] ?? 0;

      if (degree == 0) {
        isolatedNodes.add(node.id);
        if (node.hasPole) {
          warnings.add(
            '⚠️ Isolated pole: Node ${node.id.value} has pole support but no connected members',
          );
        } else {
          warnings.add(
            '⚠️ Isolated node: Node ${node.id.value} is not connected to any structural member',
          );
        }
      } else {
        // Connected node: check physical support.
        // Junction nodes connecting into the perimeter structure receive physical
        // support directly from the perimeter members.
        final isSupportedJunction = node.role == NodeType.junction;
        if (!node.hasPhysicalSupport && !isSupportedJunction) {
          unsupportedEndpoints.add(node.id);
          warnings.add(
            '⚠️ Unsupported structural endpoint: Node ${node.id.value} currently has no vertical support',
          );
        }
      }
    }

    // 3. Member Analysis: spans & support integrity
    for (final edge in layout.edges.values) {
      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);

      if (startNode == null || endNode == null) continue;

      // Internal cross members connecting to a control point span to the center
      // and are structurally valid up to double preferred spacing (e.g. 65 ft).
      // Perimeter members up to 40 ft receive auto intermediate poles from the engine.
      final isControlEdge = (startNode.type == NodeType.controlPoint || endNode.type == NodeType.controlPoint);
      final threshold = isControlEdge ? (preferredSpacingFeet * 2.2) : 40.05;

      final dist = edge.calculateGeometricDistanceFeet(startNode, endNode);
      if (dist > threshold + 0.05) {
        longSpans.add(edge.id);
        warnings.add(
          '⚠️ Span exceeds preferred pole spacing (${preferredSpacingFeet.toInt()} ft): Member ${edge.id.value} (${dist.toStringAsFixed(1)} ft)',
        );
      }
    }

    // 4. Graph Connected Components Analysis
    var componentCount = 0;
    final visited = <NodeId>{};

    for (final nodeId in layout.nodes.keys) {
      final node = layout.getNode(nodeId);
      if (node?.type == NodeType.stage || node?.type == NodeType.carpet) {
        continue;
      }

      if (!visited.contains(nodeId)) {
        componentCount++;
        final componentNodes = <NodeId>{};
        final queue = <NodeId>[nodeId];
        visited.add(nodeId);
        componentNodes.add(nodeId);

        while (queue.isNotEmpty) {
          final curr = queue.removeAt(0);
          for (final neighbor in adjacency[curr] ?? <NodeId>{}) {
            if (visited.add(neighbor)) {
              componentNodes.add(neighbor);
              queue.add(neighbor);
            }
          }
        }

        // Check if this component has at least one physically supported node
        final hasSupportInComponent = componentNodes.any((id) {
          final n = layout.getNode(id);
          return n != null && n.hasPhysicalSupport;
        });

        if (!hasSupportInComponent && componentNodes.isNotEmpty) {
          warnings.add(
            'Structural component $componentCount has no supporting poles',
          );
        }
      }
    }

    return StructuralAnalysisReport(
      componentCount: componentCount,
      isolatedNodes: List.unmodifiable(isolatedNodes),
      unsupportedEndpoints: List.unmodifiable(unsupportedEndpoints),
      longSpans: List.unmodifiable(longSpans),
      warnings: List.unmodifiable(warnings),
    );
  }
}
