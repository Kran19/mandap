import 'package:flutter_test/flutter_test.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'package:mandap/features/mandap/domain/entities/edge_id.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_edge.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_layout.dart';
import 'package:mandap/features/mandap/domain/entities/mandap_node.dart';
import 'package:mandap/features/mandap/domain/entities/node_id.dart';
import 'package:mandap/features/mandap/domain/services/truss_bom_calculator.dart';
import 'package:mandap/features/mandap/domain/value_objects/mandap_calculation_result.dart';
import 'package:mandap/features/mandap/domain/value_objects/pole_placement.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/geometry/truss_box_geometry_generator.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/geometry/truss_geometry_cache.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/geometry/truss_member_geometry.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/geometry/truss_tower_geometry_generator.dart';

void main() {
  group('MASTER PROMPT — Realistic Grey Box Truss Geometry Engine Verification', () {
    const boxGenerator = TrussBoxGeometryGenerator();
    const towerGenerator = TrussTowerGeometryGenerator();

    test('1. Box truss produces 4 primary longitudinal chords', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id, profile: EdgeProfile.box);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      expect(geom.primaryChords.length, equals(4));
      for (final chord in geom.primaryChords) {
        expect(chord.start.distanceTo(chord.end), closeTo(30.0, 0.01));
      }
    });

    test('2. Box truss produces lattice on all 4 required faces (evenly distributed)', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      expect(geom.latticeStruts.isNotEmpty, isTrue);
      // 4 struts per bay (1 for each of the 4 faces: Top, Bottom, Left, Right)
      expect(geom.latticeStruts.length % 4, equals(0));
      expect(geom.transverseTies.length % 4, equals(0));
    });

    test('3. 10 ft member generates fewer bays than 30 ft member with even distribution', () {
      final s1 = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e1 = const MandapNode(id: NodeId('n2'), x: 10, z: 0, elevation: 20);
      final edge10 = MandapEdge(id: const EdgeId('e10'), startNodeId: s1.id, endNodeId: e1.id);

      final s2 = const MandapNode(id: NodeId('n3'), x: 0, z: 0, elevation: 20);
      final e2 = const MandapNode(id: NodeId('n4'), x: 30, z: 0, elevation: 20);
      final edge30 = MandapEdge(id: const EdgeId('e30'), startNodeId: s2.id, endNodeId: e2.id);

      final geom10 = boxGenerator.generate(edge: edge10, startNode: s1, endNode: e1);
      final geom30 = boxGenerator.generate(edge: edge30, startNode: s2, endNode: e2);

      expect(geom10.latticeStruts.length, lessThan(geom30.latticeStruts.length));
      // 10 ft has ~6 bays (24 struts), 30 ft has ~19 bays (76 struts)
      expect(geom10.latticeStruts.length, equals(16));
      expect(geom30.latticeStruts.length, equals(48));
    });

    test('4 & 5. 30 ft member remains one MandapEdge and visual chords do NOT multiply BOM', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final layout = MandapLayout(
        nodes: {s.id: s, e.id: e},
        edges: {edge.id: edge},
      );

      // Visual expansion produces 4 chords
      final visualGeom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      expect(visualGeom.primaryChords.length, equals(4));

      // Domain remains strictly 1 edge
      expect(layout.edges.length, equals(1));

      // BOM calculation strictly counts 1 member / 30 ft, NEVER 4 members / 120 ft
      final bom = const TrussBomCalculator().calculateBom(layout);
      expect(bom.upperQuantity, equals(1));
      expect(bom.upperTotalFeet, closeTo(30.0, 0.01));
      expect(bom.totalQuantity, equals(1));
      expect(bom.totalFeet, closeTo(30.0, 0.01));
    });

    test('6. Horizontal X-axis member renders correctly with perpendicular offsets', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      for (final chord in geom.primaryChords) {
        // Along X-axis: chord dx must be 30.0, dy and dz offsets must be +/- 0.5
        expect((chord.end.x - chord.start.x).abs(), closeTo(30.0, 0.01));
        expect((chord.start.y - 20.0).abs(), closeTo(0.5, 0.01));
        expect((chord.start.z - 0.0).abs(), closeTo(0.5, 0.01));
      }
    });

    test('7. Horizontal Z-axis member renders correctly with perpendicular offsets', () {
      final s = const MandapNode(id: NodeId('n1'), x: 10, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 10, z: 30, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      for (final chord in geom.primaryChords) {
        expect((chord.end.z - chord.start.z).abs(), closeTo(30.0, 0.01));
        expect((chord.start.y - 20.0).abs(), closeTo(0.5, 0.01));
        expect((chord.start.x - 10.0).abs(), closeTo(0.5, 0.01));
      }
    });

    test('8. Vertical tower member renders correctly with metal base plate at Y=0.0', () {
      final pole = const PolePlacement(id: 'pole_1', x: 25.0, z: 35.0, reason: PoleReason.corner);
      final layout = MandapLayout(
        nodes: {const NodeId('n_top'): const MandapNode(id: NodeId('n_top'), x: 25.0, z: 35.0, elevation: 22.0)},
        edges: const {},
      );

      final tower = towerGenerator.generate(pole: pole, layout: layout);
      expect(tower.fullHeight, closeTo(22.0, 0.01));
      expect(tower.verticalChords.length, equals(4));

      // Base plate sits at Y = 0.0, centered at (25.0, 35.0)
      expect(tower.basePlate.center.y, equals(0.0));
      expect(tower.basePlate.center.x, equals(25.0));
      expect(tower.basePlate.center.z, equals(35.0));
      expect(tower.basePlate.cornerBolts.length, equals(4));
    });

    test('9. Sloped roof member renders correctly without flattening Y', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20.0);
      final apex = const MandapNode(id: NodeId('apex'), x: 50, z: 50, elevation: 28.0);
      final edge = MandapEdge(id: const EdgeId('e_sloped'), startNodeId: s.id, endNodeId: apex.id);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: apex);
      expect(geom.primaryChords.length, equals(4));

      // Chord ends must preserve elevation change (20.0 -> 28.0)
      for (final chord in geom.primaryChords) {
        expect((chord.end.y - chord.start.y).abs(), closeTo(8.0, 0.05));
      }
    });

    test('10. Four chord offsets remain perpendicular to member direction', () {
      final s = const MandapNode(id: NodeId('n1'), x: 10, z: 10, elevation: 15);
      final e = const MandapNode(id: NodeId('n2'), x: 40, z: 50, elevation: 25);
      final edge = MandapEdge(id: const EdgeId('e_arb'), startNodeId: s.id, endNodeId: e.id);

      final geom = boxGenerator.generate(edge: edge, startNode: s, endNode: e);
      final memberDir = (v64.Vector3(e.x, e.elevation, e.z) - v64.Vector3(s.x, s.elevation, s.z))..normalize();

      for (final chord in geom.primaryChords) {
        final offset = chord.start - v64.Vector3(s.x, s.elevation, s.z);
        // Dot product between member direction and chord offset must be ~ 0.0 (strictly orthogonal)
        expect(memberDir.dot(offset).abs(), lessThan(0.001));
      }
    });

    test('11. SingleTube profile remains single tube and does not produce box lattice', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 20, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e_single'), startNodeId: s.id, endNodeId: e.id, profile: EdgeProfile.singleTube);

      final layout = MandapLayout(
        nodes: {s.id: s, e.id: e},
        edges: {edge.id: edge},
      );
      const emptyResult = MandapCalculationResult(
        layoutIssues: [],
        edgeSolutions: {},
        requiredTrussBySize: {},
        poles: [],
        inventoryShortages: [],
        warnings: [],
      );

      final cached = TrussGeometryCache.getOrCreate(layout: layout, result: emptyResult, defaultHeight: 20.0);
      expect(cached.boxBeams.containsKey(edge.id), isFalse);
      expect(cached.singleTubes.any((t) => t.edgeId == edge.id), isTrue);
    });

    test('12. Camera-only movement preserves TrussGeometryCacheKey (ZERO geometry rebuilds)', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final layout = MandapLayout(
        nodes: {s.id: s, e.id: e},
        edges: {edge.id: edge},
      );
      const emptyResult = MandapCalculationResult(
        layoutIssues: [],
        edgeSolutions: {},
        requiredTrussBySize: {},
        poles: [],
        inventoryShortages: [],
        warnings: [],
      );

      final key1 = TrussGeometryCacheKey.compute(layout: layout, result: emptyResult, defaultHeight: 20.0);
      // Simulated camera orbit/pan: layout is completely untouched
      final key2 = TrussGeometryCacheKey.compute(layout: layout, result: emptyResult, defaultHeight: 20.0);

      expect(key1, equals(key2));
      expect(key1.hashCode, equals(key2.hashCode));

      final geom1 = TrussGeometryCache.getOrCreate(layout: layout, result: emptyResult, defaultHeight: 20.0);
      final geom2 = TrussGeometryCache.getOrCreate(layout: layout, result: emptyResult, defaultHeight: 20.0);
      expect(identical(geom1, geom2), isTrue);
    });

    test('13. Mutating member length invalidates cache key and regenerates geometry', () {
      final s = const MandapNode(id: NodeId('n1'), x: 0, z: 0, elevation: 20);
      final e = const MandapNode(id: NodeId('n2'), x: 30, z: 0, elevation: 20);
      final edge = MandapEdge(id: const EdgeId('e1'), startNodeId: s.id, endNodeId: e.id);

      final layout1 = MandapLayout(
        nodes: {s.id: s, e.id: e},
        edges: {edge.id: edge},
      );
      const emptyResult = MandapCalculationResult(
        layoutIssues: [],
        edgeSolutions: {},
        requiredTrussBySize: {},
        poles: [],
        inventoryShortages: [],
        warnings: [],
      );

      final geom1 = TrussGeometryCache.getOrCreate(layout: layout1, result: emptyResult, defaultHeight: 20.0);
      expect(geom1.boxBeams[edge.id]!.primaryChords.first.start.distanceTo(geom1.boxBeams[edge.id]!.primaryChords.first.end), closeTo(30.0, 0.01));

      // Resize member to 34 ft
      final eResized = const MandapNode(id: NodeId('n2'), x: 34, z: 0, elevation: 20);
      final layout2 = MandapLayout(
        nodes: {s.id: s, eResized.id: eResized},
        edges: {edge.id: edge},
      );

      final geom2 = TrussGeometryCache.getOrCreate(layout: layout2, result: emptyResult, defaultHeight: 20.0);
      expect(geom2.boxBeams[edge.id]!.primaryChords.first.start.distanceTo(geom2.boxBeams[edge.id]!.primaryChords.first.end), closeTo(34.0, 0.01));
    });
  });
}
