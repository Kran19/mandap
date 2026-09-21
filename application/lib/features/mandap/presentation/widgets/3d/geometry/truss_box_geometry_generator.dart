import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/mandap_edge.dart';
import '../../../../domain/entities/mandap_node.dart';
import 'truss_member_geometry.dart';

/// Pure, deterministic geometry generator that transforms a single [MandapEdge]
/// into a physically believable 4-chord aluminum box truss with 4-face Warren lattice.
///
/// Invariant:
/// 1 MandapEdge = 1 structural run -> 4 primary longitudinal chords + 4-face lattice + transverse ties.
/// BOM is never affected by visual chord expansion.
class TrussBoxGeometryGenerator {
  const TrussBoxGeometryGenerator();

  /// Generates the world-space visual geometry for [edge].
  TrussBoxGeometry generate({
    required MandapEdge edge,
    required MandapNode startNode,
    required MandapNode endNode,
    double defaultHeight = 20.0,
  }) {
    final startElev = startNode.elevation > 0 ? startNode.elevation : defaultHeight;
    final endElev = endNode.elevation > 0 ? endNode.elevation : defaultHeight;

    final start = v64.Vector3(startNode.x, startElev, startNode.z);
    final end = v64.Vector3(endNode.x, endElev, endNode.z);

    final length = start.distanceTo(end);
    if (length < 0.001) {
      return TrussBoxGeometry(
        edgeId: edge.id,
        primaryChords: const [],
        latticeStruts: const [],
        transverseTies: const [],
      );
    }

    // 1. Stable Perpendicular Orthogonal Basis with Explicit Fallback
    final dir = (end - start)..normalize();
    final worldUp = v64.Vector3(0, 1, 0);
    final worldForward = v64.Vector3(0, 0, 1);

    // If dir is collinear with worldUp (e.g. vertical or near-vertical), fallback to worldForward
    final reference = (dir.dot(worldUp).abs() < 0.99) ? worldUp : worldForward;
    final right = dir.cross(reference)..normalize();
    final up = right.cross(dir)..normalize();

    // 2. 4 Primary Longitudinal Chords with Standard 1.0 ft (12") Cross-Section
    const halfW = boxTrussVisualWidthFeet / 2.0; // 0.50 ft
    final offsets = [
      (right * -halfW) + (up * -halfW), // 0: bottom-left
      (right * halfW) + (up * -halfW),  // 1: bottom-right
      (right * halfW) + (up * halfW),   // 2: top-right
      (right * -halfW) + (up * halfW),  // 3: top-left
    ];

    final primaryChords = <TrussTubeSegment>[];
    for (int i = 0; i < 4; i++) {
      primaryChords.add(TrussTubeSegment(
        start: start + offsets[i],
        end: end + offsets[i],
        edgeId: edge.id,
        isTopChord: i >= 2,
      ));
    }

    // 3. Evenly Distributed 4-Face Warren Lattice Bracing (No ugly fractional leftover sections)
    final latticeStruts = <TrussTubeSegment>[];
    final transverseTies = <TrussTubeSegment>[];

    final bayCount = math.max(2, (length / 2.5).round().clamp(2, 40));
    final bayLength = length / bayCount;

    for (int k = 0; k < bayCount; k++) {
      final dStart = k * bayLength;
      final dEnd = (k + 1) * bayLength;

      for (int i = 0; i < 4; i++) {
        final offA = offsets[i];
        final offB = offsets[(i + 1) % 4];

        // Transverse frame tie at dStart
        final tieStart = start + (dir * dStart) + offA;
        final tieEnd = start + (dir * dStart) + offB;
        transverseTies.add(TrussTubeSegment(
          start: tieStart,
          end: tieEnd,
          edgeId: edge.id,
        ));

        // Alternating diagonal Warren strut on each of the 4 faces (/\/\/\/\)
        final v64.Vector3 strutStart;
        final v64.Vector3 strutEnd;
        if (k.isEven) {
          strutStart = start + (dir * dStart) + offA;
          strutEnd = start + (dir * dEnd) + offB;
        } else {
          strutStart = start + (dir * dStart) + offB;
          strutEnd = start + (dir * dEnd) + offA;
        }

        latticeStruts.add(TrussTubeSegment(
          start: strutStart,
          end: strutEnd,
          edgeId: edge.id,
        ));
      }
    }

    // Closing transverse frame ties at member end
    for (int i = 0; i < 4; i++) {
      final offA = offsets[i];
      final offB = offsets[(i + 1) % 4];
      transverseTies.add(TrussTubeSegment(
        start: end + offA,
        end: end + offB,
        edgeId: edge.id,
      ));
    }

    return TrussBoxGeometry(
      edgeId: edge.id,
      primaryChords: List.unmodifiable(primaryChords),
      latticeStruts: List.unmodifiable(latticeStruts),
      transverseTies: List.unmodifiable(transverseTies),
    );
  }
}
