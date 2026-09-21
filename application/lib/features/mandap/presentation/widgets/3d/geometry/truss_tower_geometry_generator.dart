import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/mandap_layout.dart';
import '../../../../domain/entities/mandap_node.dart';
import '../../../../domain/value_objects/pole_placement.dart';
import 'truss_member_geometry.dart';

/// Pure, deterministic geometry generator that transforms a tower/pole placement
/// into a physically believable 4-chord vertical aluminum box truss tower with
/// metal base plate and top connection.
class TrussTowerGeometryGenerator {
  const TrussTowerGeometryGenerator();

  TrussTowerGeometry generate({
    required PolePlacement pole,
    required MandapLayout layout,
    double defaultHeight = 20.0,
  }) {
    final bx = pole.x;
    final bz = pole.z;

    // Determine authoritative full height from connected node or supporting edge
    MandapNode? matchingNode;
    if (pole.sourceNodeId != null) {
      matchingNode = layout.getNode(pole.sourceNodeId!);
    }
    if (matchingNode == null) {
      for (final n in layout.nodes.values) {
        if ((n.x - bx).abs() < 0.5 && (n.z - bz).abs() < 0.5) {
          matchingNode = n;
          break;
        }
      }
    }

    double fullHeight;
    if (matchingNode != null && matchingNode.elevation > 0) {
      fullHeight = matchingNode.elevation;
    } else if (pole.sourceEdgeId != null) {
      final edge = layout.getEdge(pole.sourceEdgeId!);
      if (edge != null) {
        final sNode = layout.getNode(edge.startNodeId);
        final eNode = layout.getNode(edge.endNodeId);
        if (sNode != null && eNode != null) {
          final dx = eNode.x - sNode.x;
          final dz = eNode.z - sNode.z;
          final edgeLenSq = dx * dx + dz * dz;
          if (edgeLenSq > 0.001) {
            final t = (((bx - sNode.x) * dx + (bz - sNode.z) * dz) / edgeLenSq).clamp(0.0, 1.0);
            fullHeight = sNode.elevation + t * (eNode.elevation - sNode.elevation);
          } else {
            fullHeight = sNode.elevation;
          }
        } else {
          fullHeight = defaultHeight;
        }
      } else {
        fullHeight = defaultHeight;
      }
    } else {
      fullHeight = defaultHeight;
    }
    if (fullHeight <= 0) fullHeight = defaultHeight;

    const halfW = boxTrussVisualWidthFeet / 2.0; // 0.50 ft

    // 1. 4 Primary Vertical Chords
    final cornerOffsets = [
      v64.Vector3(-halfW, 0, -halfW), // 0: front-left
      v64.Vector3(halfW, 0, -halfW),  // 1: front-right
      v64.Vector3(halfW, 0, halfW),   // 2: back-right
      v64.Vector3(-halfW, 0, halfW),  // 3: back-left
    ];

    final verticalChords = <TrussTubeSegment>[];
    for (int i = 0; i < 4; i++) {
      final off = cornerOffsets[i];
      verticalChords.add(TrussTubeSegment(
        start: v64.Vector3(bx + off.x, 0.0, bz + off.z),
        end: v64.Vector3(bx + off.x, fullHeight, bz + off.z),
        edgeId: pole.sourceEdgeId,
        isTopChord: i >= 2,
      ));
    }

    // 2. Evenly Distributed 4-Face Warren Lattice Bracing
    final latticeStruts = <TrussTubeSegment>[];
    final transverseTies = <TrussTubeSegment>[];

    final bayCount = math.max(2, (fullHeight / 2.5).round().clamp(2, 20));
    final bayLength = fullHeight / bayCount;

    for (int k = 0; k < bayCount; k++) {
      final yStart = k * bayLength;
      final yEnd = (k + 1) * bayLength;

      for (int i = 0; i < 4; i++) {
        final offA = cornerOffsets[i];
        final offB = cornerOffsets[(i + 1) % 4];

        // Horizontal tower tie rung at level yStart
        final tieStart = v64.Vector3(bx + offA.x, yStart, bz + offA.z);
        final tieEnd = v64.Vector3(bx + offB.x, yStart, bz + offB.z);
        transverseTies.add(TrussTubeSegment(
          start: tieStart,
          end: tieEnd,
          edgeId: pole.sourceEdgeId,
        ));

        // Alternating diagonal Warren strut on each of the 4 faces (/\/\/\/\)
        final v64.Vector3 strutStart;
        final v64.Vector3 strutEnd;
        if (k.isEven) {
          strutStart = v64.Vector3(bx + offA.x, yStart, bz + offA.z);
          strutEnd = v64.Vector3(bx + offB.x, yEnd, bz + offB.z);
        } else {
          strutStart = v64.Vector3(bx + offB.x, yStart, bz + offB.z);
          strutEnd = v64.Vector3(bx + offA.x, yEnd, bz + offA.z);
        }

        latticeStruts.add(TrussTubeSegment(
          start: strutStart,
          end: strutEnd,
          edgeId: pole.sourceEdgeId,
        ));
      }
    }

    // Closing top tie rung on all 4 faces
    for (int i = 0; i < 4; i++) {
      final offA = cornerOffsets[i];
      final offB = cornerOffsets[(i + 1) % 4];
      transverseTies.add(TrussTubeSegment(
        start: v64.Vector3(bx + offA.x, fullHeight, bz + offA.z),
        end: v64.Vector3(bx + offB.x, fullHeight, bz + offB.z),
        edgeId: pole.sourceEdgeId,
      ));
    }

    // 3. Realistic Metal Base Plate (Metal mounting plate + 4 corner bolts)
    const plateHalfW = 1.00;
    final cornerBolts = [
      v64.Vector3(bx - plateHalfW * 0.8, 0.05, bz - plateHalfW * 0.8),
      v64.Vector3(bx + plateHalfW * 0.8, 0.05, bz - plateHalfW * 0.8),
      v64.Vector3(bx + plateHalfW * 0.8, 0.05, bz + plateHalfW * 0.8),
      v64.Vector3(bx - plateHalfW * 0.8, 0.05, bz + plateHalfW * 0.8),
    ];

    final basePlate = TrussBasePlate(
      nodeId: pole.sourceNodeId,
      center: v64.Vector3(bx, 0.0, bz),
      halfW: plateHalfW,
      collarHalfW: 0.65,
      cornerBolts: cornerBolts,
    );

    // 4. Top Connection Junction Cube (Locks tower into upper truss with ZERO GAP)
    TrussConnectorCube? topConnector;
    if (matchingNode != null) {
      const jSize = 0.52;
      final jBase = [
        v64.Vector3(bx - jSize, fullHeight - jSize, bz - jSize),
        v64.Vector3(bx + jSize, fullHeight - jSize, bz - jSize),
        v64.Vector3(bx + jSize, fullHeight - jSize, bz + jSize),
        v64.Vector3(bx - jSize, fullHeight - jSize, bz + jSize),
      ];
      final jTop = jBase.map((v) => v64.Vector3(v.x, v.y + jSize * 2, v.z)).toList();
      topConnector = TrussConnectorCube(
        nodeId: matchingNode.id,
        center: v64.Vector3(bx, fullHeight, bz),
        halfExtent: jSize,
        baseCorners: jBase,
        topCorners: jTop,
      );
    }

    return TrussTowerGeometry(
      sourceNodeId: pole.sourceNodeId,
      sourceEdgeId: pole.sourceEdgeId,
      bx: bx,
      bz: bz,
      fullHeight: fullHeight,
      verticalChords: List.unmodifiable(verticalChords),
      latticeStruts: List.unmodifiable(latticeStruts),
      transverseTies: List.unmodifiable(transverseTies),
      basePlate: basePlate,
      topConnector: topConnector,
    );
  }
}
