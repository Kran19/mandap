import 'dart:math' as math;
import '../entities/mandap_edge.dart';
import '../entities/mandap_layout.dart';
import '../entities/mandap_node.dart';
import '../entities/node_id.dart';
import '../entities/edge_id.dart';
import '../entities/truss_bay.dart';

/// Service to detect and derive rectangular [TrussBay] modules from an authoritative [MandapLayout].
class TrussBayDetector {
  const TrussBayDetector();

  /// Detects all valid rectangular bays in the given layout.
  List<TrussBay> detectBays(MandapLayout layout) {
    if (layout.nodes.isEmpty || layout.edges.isEmpty) return const [];

    const tol = 0.35;

    // 1. Extract all elevated horizontal (along X) and vertical (along Z) edge segments
    final hSegments = <({EdgeId id, double z, double minX, double maxX})>[];
    final vSegments = <({EdgeId id, double x, double minZ, double maxZ})>[];

    for (final edge in layout.edges.values) {
      if (edge.role == TrussMemberRole.tower) continue;
      final n1 = layout.getNode(edge.startNodeId);
      final n2 = layout.getNode(edge.endNodeId);
      if (n1 == null || n2 == null) continue;
      if (n1.elevation < 0.1 || n2.elevation < 0.1) continue;

      final dx = (n1.x - n2.x).abs();
      final dz = (n1.z - n2.z).abs();

      if (dz <= tol && dx > tol) {
        final minX = math.min(n1.x, n2.x);
        final maxX = math.max(n1.x, n2.x);
        final z = (n1.z + n2.z) / 2.0;
        hSegments.add((id: edge.id, z: z, minX: minX, maxX: maxX));
      } else if (dx <= tol && dz > tol) {
        final minZ = math.min(n1.z, n2.z);
        final maxZ = math.max(n1.z, n2.z);
        final x = (n1.x + n2.x) / 2.0;
        vSegments.add((id: edge.id, x: x, minZ: minZ, maxZ: maxZ));
      }
    }

    if (hSegments.length < 2 || vSegments.length < 2) return const [];

    // Helper to check horizontal coverage along a given Z
    bool isHorizontalCovered(
      double lineZ,
      double targetMin,
      double targetMax,
      Set<EdgeId> outEdgeIds,
    ) {
      final intervals = <({double start, double end, EdgeId id})>[];
      for (final s in hSegments) {
        if ((s.z - lineZ).abs() <= tol) {
          final sMin = math.max(targetMin, s.minX);
          final sMax = math.min(targetMax, s.maxX);
          if (sMax > sMin + 0.01) {
            intervals.add((start: sMin, end: sMax, id: s.id));
          }
        }
      }
      if (intervals.isEmpty) return false;

      intervals.sort((a, b) => a.start.compareTo(b.start));

      double currentCoverage = targetMin;
      for (final iv in intervals) {
        if (iv.start <= currentCoverage + tol) {
          if (iv.end > currentCoverage) {
            currentCoverage = iv.end;
            outEdgeIds.add(iv.id);
          }
        } else {
          break;
        }
      }
      return currentCoverage >= targetMax - tol;
    }

    // Helper to check vertical coverage along a given X
    bool isVerticalCovered(
      double lineX,
      double targetMin,
      double targetMax,
      Set<EdgeId> outEdgeIds,
    ) {
      final intervals = <({double start, double end, EdgeId id})>[];
      for (final s in vSegments) {
        if ((s.x - lineX).abs() <= tol) {
          final sMin = math.max(targetMin, s.minZ);
          final sMax = math.min(targetMax, s.maxZ);
          if (sMax > sMin + 0.01) {
            intervals.add((start: sMin, end: sMax, id: s.id));
          }
        }
      }
      if (intervals.isEmpty) return false;

      intervals.sort((a, b) => a.start.compareTo(b.start));

      double currentCoverage = targetMin;
      for (final iv in intervals) {
        if (iv.start <= currentCoverage + tol) {
          if (iv.end > currentCoverage) {
            currentCoverage = iv.end;
            outEdgeIds.add(iv.id);
          }
        } else {
          break;
        }
      }
      return currentCoverage >= targetMax - tol;
    }

    // 2. Collect unique structural dividing coordinates
    final rawX = <double>[];
    for (final s in vSegments) {
      rawX.add(s.x);
    }
    for (final s in hSegments) {
      rawX.add(s.minX);
      rawX.add(s.maxX);
    }

    final rawZ = <double>[];
    for (final s in hSegments) {
      rawZ.add(s.z);
    }
    for (final s in vSegments) {
      rawZ.add(s.minZ);
      rawZ.add(s.maxZ);
    }

    final uniqueX = _clusterCoords(rawX, tol);
    final uniqueZ = _clusterCoords(rawZ, tol);

    if (uniqueX.length < 2 || uniqueZ.length < 2) return const [];

    final rawBays = <TrussBay>[];

    // 3. Test all potential rectangular partitions [x0, x1] x [z0, z1]
    for (int i = 0; i < uniqueX.length - 1; i++) {
      for (int k = i + 1; k < uniqueX.length; k++) {
        final x0 = uniqueX[i];
        final x1 = uniqueX[k];

        for (int j = 0; j < uniqueZ.length - 1; j++) {
          for (int l = j + 1; l < uniqueZ.length; l++) {
            final z0 = uniqueZ[j];
            final z1 = uniqueZ[l];

            final sideEdges = <EdgeId>{};

            // Check 4 boundaries
            if (!isHorizontalCovered(z0, x0, x1, sideEdges)) continue;
            if (!isHorizontalCovered(z1, x0, x1, sideEdges)) continue;
            if (!isVerticalCovered(x0, z0, z1, sideEdges)) continue;
            if (!isVerticalCovered(x1, z0, z1, sideEdges)) continue;

            // Check no internal dividing horizontal edge cuts through
            bool isSubdivided = false;
            for (final h in hSegments) {
              if (h.z > z0 + tol &&
                  h.z < z1 - tol &&
                  h.maxX > x0 + tol &&
                  h.minX < x1 - tol) {
                isSubdivided = true;
                break;
              }
            }
            if (isSubdivided) continue;

            // Check no internal dividing vertical edge cuts through
            for (final v in vSegments) {
              if (v.x > x0 + tol &&
                  v.x < x1 - tol &&
                  v.maxZ > z0 + tol &&
                  v.minZ < z1 - tol) {
                isSubdivided = true;
                break;
              }
            }
            if (isSubdivided) continue;

            // Find corner nodes
            final nTL = _findNodeNear(layout, x0, z0);
            final nTR = _findNodeNear(layout, x1, z0);
            final nBR = _findNodeNear(layout, x1, z1);
            final nBL = _findNodeNear(layout, x0, z1);

            final cornerIds = <NodeId>[
              nTL?.id ?? NodeId('c_${x0.toInt()}_${z0.toInt()}'),
              nTR?.id ?? NodeId('c_${x1.toInt()}_${z0.toInt()}'),
              nBR?.id ?? NodeId('c_${x1.toInt()}_${z1.toInt()}'),
              nBL?.id ?? NodeId('c_${x0.toInt()}_${z1.toInt()}'),
            ];

            final hasInternal = _checkInternalMembers(
              layout,
              x0,
              x1,
              z0,
              z1,
              sideEdges,
            );

            rawBays.add(TrussBay(
              id: '',
              columnIndex: 0,
              rowIndex: 0,
              minX: x0,
              maxX: x1,
              minZ: z0,
              maxZ: z1,
              centerX: (x0 + x1) / 2.0,
              centerZ: (z0 + z1) / 2.0,
              cornerNodeIds: cornerIds,
              boundaryEdgeIds: sideEdges.toList(),
              hasInternalMembers: hasInternal,
            ));
          }
        }
      }
    }

    if (rawBays.isEmpty) return const [];

    // 4. Cluster unique row (Z) and col (X) coordinates among detected bays
    final bayZ = _clusterCoords(rawBays.map((b) => b.minZ).toList(), tol);
    final bayX = _clusterCoords(rawBays.map((b) => b.minX).toList(), tol);

    final List<TrussBay> structuredBays = [];

    for (final bay in rawBays) {
      final r = bayZ.indexWhere((z) => (z - bay.minZ).abs() <= tol);
      final c = bayX.indexWhere((x) => (x - bay.minX).abs() <= tol);

      structuredBays.add(TrussBay(
        id: 'bay_c${c}_r$r',
        columnIndex: c >= 0 ? c : 0,
        rowIndex: r >= 0 ? r : 0,
        minX: bay.minX,
        maxX: bay.maxX,
        minZ: bay.minZ,
        maxZ: bay.maxZ,
        centerX: bay.centerX,
        centerZ: bay.centerZ,
        cornerNodeIds: bay.cornerNodeIds,
        boundaryEdgeIds: bay.boundaryEdgeIds,
        hasInternalMembers: bay.hasInternalMembers,
      ));
    }

    // Sort by row, then column
    structuredBays.sort((a, b) {
      final cmpRow = a.rowIndex.compareTo(b.rowIndex);
      if (cmpRow != 0) return cmpRow;
      return a.columnIndex.compareTo(b.columnIndex);
    });

    return structuredBays;
  }

  static List<double> _clusterCoords(List<double> values, double tolerance) {
    if (values.isEmpty) return const [];
    final sorted = List<double>.from(values)..sort();
    final List<double> clusters = [sorted.first];

    for (int i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      if ((current - clusters.last).abs() > tolerance) {
        clusters.add(current);
      }
    }
    return clusters;
  }

  static MandapNode? _findNodeNear(
    MandapLayout layout,
    double x,
    double z, [
    double tolerance = 0.5,
  ]) {
    MandapNode? best;
    double bestDist = double.infinity;

    for (final node in layout.nodes.values) {
      if (node.elevation > 0.1) {
        final dist = math.sqrt(math.pow(node.x - x, 2) + math.pow(node.z - z, 2));
        if (dist <= tolerance && dist < bestDist) {
          bestDist = dist;
          best = node;
        }
      }
    }
    return best;
  }

  static bool _checkInternalMembers(
    MandapLayout layout,
    double minX,
    double maxX,
    double minZ,
    double maxZ,
    Set<EdgeId> boundaryEdges,
  ) {
    const margin = 0.2;
    for (final edge in layout.edges.values) {
      if (boundaryEdges.contains(edge.id)) continue;

      final start = layout.getNode(edge.startNodeId);
      final end = layout.getNode(edge.endNodeId);
      if (start == null || end == null) continue;

      final midX = (start.x + end.x) / 2.0;
      final midZ = (start.z + end.z) / 2.0;

      if ((start.x > (minX + margin) &&
              start.x < (maxX - margin) &&
              start.z > (minZ + margin) &&
              start.z < (maxZ - margin)) ||
          (end.x > (minX + margin) &&
              end.x < (maxX - margin) &&
              end.z > (minZ + margin) &&
              end.z < (maxZ - margin)) ||
          (midX > (minX + margin) &&
              midX < (maxX - margin) &&
              midZ > (minZ + margin) &&
              midZ < (maxZ - margin))) {
        return true;
      }
    }
    return false;
  }
}
