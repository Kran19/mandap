import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../domain/entities/edge_id.dart';
import '../../../domain/entities/mandap_edge.dart';
import '../../../domain/entities/mandap_layout.dart';
import '../../../domain/entities/mandap_node.dart';
import '../../../domain/entities/mandap_zone.dart';
import '../../../domain/entities/node_id.dart';
import '../../../domain/value_objects/mandap_calculation_result.dart';
import '../../../application/editor_mode.dart';
import '../../../application/mandap_editor_controller.dart';
import 'mandap_3d_controller.dart';
import 'math/beam_transform_calculator.dart';
import 'environment/festival_world_environment.dart';
import '../../../domain/services/truss_display_numbering_service.dart';
import 'geometry/truss_geometry_cache.dart';
import 'geometry/truss_member_geometry.dart';
import '../../../domain/services/truss_bay_detector.dart';

class Truss3DPaints {
  // ── Authentic Industrial Stage Aluminum Grey Palette (Matching Image 3 Reference) ────
  // Neutral brushed aluminum grey tones:
  // BASE ALUMINIUM GREY: #6E7B8B | SUNLIT GREY: #8692A0 | DARK SHADOW GREY: #353E48
  // HIGHLIGHT GREY: #A0ACB9 | SPECULAR GREY: #C8D3DE | CONNECTOR: #727E8C

  // 1. Primary Chord Tubular Paints (Multi-pass 3D cylindrical geometry)
  static final Paint chordShadow = Paint()
    ..color = const Color(0xFF353E48) // Dark industrial slate shadow
    ..strokeWidth = 4.2
    ..strokeCap = StrokeCap.round;

  static final Paint chordSunlitBody = Paint()
    ..color = const Color(0xFF8692A0) // Authentic brushed aluminum grey
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

  static final Paint chordShadedBody = Paint()
    ..color = const Color(0xFF5A6674) // Shaded aluminum underside grey
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round;

  static final Paint chordHighlight = Paint()
    ..color = const Color(0xFFA0ACB9) // Metallic aluminum highlight
    ..strokeWidth = 1.4
    ..strokeCap = StrokeCap.round;

  static final Paint chordSpecularHighlight = Paint()
    ..color = const Color(0xFFC8D3DE) // Muted metallic glint (neutral grey-silver, not white)
    ..strokeWidth = 0.7
    ..strokeCap = StrokeCap.round;

  // Backward compatibility aliases
  static Paint get beamChordShadow => chordShadow;
  static Paint get beamChordBase => chordShadow;
  static Paint get topChord => chordSunlitBody;
  static Paint get bottomChord => chordShadedBody;
  static Paint get poleChordShadow => chordShadow;
  static Paint get poleChord => chordSunlitBody;
  static Paint get poleChordHighlight => chordHighlight;
  static Paint get poleChordBase => chordShadow;

  // 2. Warren Lattice Tubular Strut Paints (Multi-pass 3D tubular diagonals)
  static final Paint webShadow = Paint()
    ..color = const Color(0xFF353E48)
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round;

  static final Paint webBody = Paint()
    ..color = const Color(0xFF758190) // Industrial aluminum grey
    ..strokeWidth = 1.6
    ..strokeCap = StrokeCap.round;

  static final Paint webHighlight = Paint()
    ..color = const Color(0xFF96A2B0) // Subtle metallic sheen
    ..strokeWidth = 0.7
    ..strokeCap = StrokeCap.round;

  static Paint get beamWeb => webBody;
  static Paint get poleWeb => webBody;

  // 3. Transverse Tie Rungs & End Frames
  static final Paint tieShadow = Paint()
    ..color = const Color(0xFF353E48)
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round;

  static final Paint tieBody = Paint()
    ..color = const Color(0xFF7E8A98)
    ..strokeWidth = 1.8
    ..strokeCap = StrokeCap.round;

  static final Paint tieHighlight = Paint()
    ..color = const Color(0xFFA8B4C2)
    ..strokeWidth = 0.8
    ..strokeCap = StrokeCap.round;

  // 4. Single Tube Profile
  static final Paint tubeShadow = Paint()
    ..color = const Color(0xFF353E48)
    ..strokeWidth = 4.8
    ..strokeCap = StrokeCap.round;

  static final Paint tube = Paint()
    ..color = const Color(0xFF7E8A98)
    ..strokeWidth = 3.4
    ..strokeCap = StrokeCap.round;

  static final Paint tubeHighlight = Paint()
    ..color = const Color(0xFFA0ACB9)
    ..strokeWidth = 1.2
    ..strokeCap = StrokeCap.round;

  // 5. Ground Contact & Base Plate
  static final Paint groundBeamShadow = Paint()
    ..color = const Color(0x380A140A) // Soft ambient ground contact shadow
    ..strokeWidth = 5.5
    ..strokeCap = StrokeCap.round;

  static final Paint basePlateGroundShadow = Paint()
    ..color = const Color(0x550B180B)
    ..style = PaintingStyle.fill;

  static final Paint basePlateSlabSide = Paint()
    ..color = const Color(0xFF464F5A) // Industrial steel plate rim
    ..style = PaintingStyle.fill;

  static final Paint basePlateTop = Paint()
    ..color = const Color(0xFF687380) // Machined steel grey surface
    ..style = PaintingStyle.fill;

  static final Paint basePlateBorder = Paint()
    ..color = const Color(0xFF8893A0) // Steel bevel rim
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint collarSide = Paint()
    ..color = const Color(0xFF3A424C) // Spigot collar sides
    ..style = PaintingStyle.fill;

  static final Paint collarTop = Paint()
    ..color = const Color(0xFF56606D) // Spigot collar top
    ..style = PaintingStyle.fill;

  static final Paint boltShadow = Paint()
    ..color = const Color(0xFF262E37) // Bolt recessed ring
    ..style = PaintingStyle.fill;

  static final Paint boltPaint = Paint()
    ..color = const Color(0xFF94A0AE) // Zinc bolt head grey
    ..style = PaintingStyle.fill;

  // 6. Modular 6-Way Corner Junction Cubes
  static final Paint junctionTopFace = Paint()
    ..color = const Color(0xFF8692A0) // Top face grey
    ..style = PaintingStyle.fill;

  static final Paint junctionTopBorder = Paint()
    ..color = const Color(0xFFA8B4C0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint junctionFrontFace = Paint()
    ..color = const Color(0xFF727E8C) // Sunlit front/side faces
    ..style = PaintingStyle.fill;

  static final Paint junctionFrontBorder = Paint()
    ..color = const Color(0xFF909CA8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;

  static final Paint junctionShadedFace = Paint()
    ..color = const Color(0xFF4C5662) // Shaded side faces
    ..style = PaintingStyle.fill;

  static final Paint junctionShadedBorder = Paint()
    ..color = const Color(0xFF626E7A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint junctionBottomFace = Paint()
    ..color = const Color(0xFF38424E)
    ..style = PaintingStyle.fill;

  static final Paint junctionCouplingRing = Paint()
    ..color = const Color(0xFF323B44)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint junctionCouplingCenter = Paint()
    ..color = const Color(0xFF222830)
    ..style = PaintingStyle.fill;

  // Backward compatibility aliases
  static Paint get basePlateFill => basePlateTop;
  static Paint get basePlateShadow => basePlateGroundShadow;
  static Paint get collarFill => collarSide;
  static Paint get junctionCubeFill => junctionFrontFace;
  static Paint get junctionCubeBorder => junctionFrontBorder;

  // Selection
  static final Paint selectedChord = Paint()
    ..color = const Color(0xFF00F0FF) // Electric Cyan Selection
    ..strokeWidth = 4.2
    ..strokeCap = StrokeCap.round;

  static final Paint selectedWeb = Paint()
    ..color = const Color(0xFF00F0FF).withValues(alpha: 0.9)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  static final Paint selectedTube = Paint()
    ..color = const Color(0xFF00F0FF)
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round;

  static final Paint selectedGlow = Paint()
    ..color = const Color(0xFF00F0FF).withValues(alpha: 0.4)
    ..strokeWidth = 9.0
    ..strokeCap = StrokeCap.round;

  // Support Pole Dots (Red when unselected, Vibrant Blue when selected)
  static final Paint supportPoleUnselected = Paint()
    ..color = const Color(0xFFEF4444) // Vibrant Red unselected
    ..style = PaintingStyle.fill;

  static final Paint supportPoleSelected = Paint()
    ..color = const Color(0xFF00E5FF) // Vibrant Electric Blue / Cyan selected
    ..style = PaintingStyle.fill;

  static final Paint supportPoleBorder = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  static final Paint supportPoleSelectedGlow = Paint()
    ..color = const Color(0xFF00E5FF).withValues(alpha: 0.45)
    ..style = PaintingStyle.fill;
}

/// CustomPainter executing the CAD 3D rendering pipeline for Mandap truss structures.
/// Silver/aluminum dual-tone lattice chords, 4-chord vertical towers with square base plates,
/// blueprint grid, coordinate triad, and dimension badges.
class Mandap3DPainter extends CustomPainter {
  static final Path _scratchPath = Path();

  final MandapLayout layout;
  final MandapCalculationResult result;
  final Mandap3DController controller;
  final MandapEditorController? editorController;
  final EdgeId? selectedEdgeId;
  final NodeId? selectedNodeId;
  final NodeId? pendingEdgeSourceId;
  final NodeId? activeHandleNodeId;
  final double? dragPreviewLengthFeet;
  final double animationProgress;
  final double? plotWidth;
  final double? plotDepth;
  final String? selectedBayId;

  Mandap3DPainter({
    required this.layout,
    required this.result,
    required this.controller,
    this.editorController,
    this.selectedEdgeId,
    this.selectedNodeId,
    this.selectedBayId,
    this.pendingEdgeSourceId,
    this.activeHandleNodeId,
    this.dragPreviewLengthFeet,
    this.animationProgress = 1.0,
    this.plotWidth,
    this.plotDepth,
  }) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 1.0 || size.height <= 1.0) return;

    // 0. Screen-Space Atmospheric Sky Backdrop (Identical to Pole, Stage, & Flooring)
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF6BA3D6), // Open sunny daytime sky
          Color(0xFF90C2E7), // Atmospheric soft sky
          Color(0xFFC7E2F5), // Horizon haze
          Color(0xFFE8F2FA), // Horizon warm glow
        ],
        stops: [0.0, 0.40, 0.75, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, skyPaint);

    // View & Projection Matrix setup
    final centerTarget = controller.cameraCenterTarget;
    final cosElev = math.cos(controller.cameraElevation);
    final sinElev = math.sin(controller.cameraElevation);
    final cosAzim = math.cos(controller.cameraAzimuth);
    final sinAzim = math.sin(controller.cameraAzimuth);

    final eyeOffset = v64.Vector3(
      controller.cameraDistance * cosElev * sinAzim,
      controller.cameraDistance * sinElev,
      controller.cameraDistance * cosElev * cosAzim,
    );

    final eyePosition = centerTarget + eyeOffset;
    final viewMatrix = v64.makeViewMatrix(
      eyePosition,
      centerTarget,
      v64.Vector3(0.0, 1.0, 0.0),
    );
    final aspect = size.width / size.height;
    final projectionMatrix = v64.makePerspectiveMatrix(
      45.0 * math.pi / 180.0,
      aspect,
      1.0,
      math.max(15000.0, controller.cameraDistance * 4.0),
    );

    // Precompute View-Projection Matrix ONCE per frame for 60+ FPS zero-allocation projection
    final viewProj = projectionMatrix * viewMatrix;
    final m = viewProj.storage;
    final halfW = size.width * 0.5;
    final halfH = size.height * 0.5;

    Offset? project(v64.Vector3 worldPoint) {
      final x = worldPoint.x;
      final y = worldPoint.y;
      final z = worldPoint.z;

      final w = m[3] * x + m[7] * y + m[11] * z + m[15];
      if (w <= 0.05) return null;

      final invW = 1.0 / w;
      final ndcX = (m[0] * x + m[4] * y + m[8] * z + m[12]) * invW;
      final ndcY = (m[1] * x + m[5] * y + m[9] * z + m[13]) * invW;

      return Offset(
        (ndcX + 1.0) * halfW,
        (1.0 - ndcY) * halfH,
      );
    }

    // Precompute / retrieve cached world-space geometry (fingerprint ensures ZERO rebuilds during orbit/pan/zoom)
    final cached = TrussGeometryCache.getOrCreate(
      layout: layout,
      result: result,
      defaultHeight: controller.mandapHeight,
    );

    // PASS 1: World Event Ground Environment & Custom Zones
    _paintWorldEnvironment(canvas, size, project, eyePosition, cached);
    _paintZones(canvas, project);
    _paintTrussBayGroundFills(canvas, project);
    _paintPolymorphicNodes(canvas, project);

    // PASS 2: Structural Truss (Cached 4-chord box beams, single tubes, and tower columns)
    _paintStructuralTruss(canvas, project, cached);

    // PASS 3: Connectors & Base Plates (Node-topology junction cubes & ground plates)
    _paintConnectorsAndBasePlates(canvas, project, cached);
    _paintSupportPoleMarkers(canvas, project, cached);

    // PASS 4: Selection Highlight (Electric cyan overlay for selected member/tower)
    _paintSelectionHighlights(canvas, project, cached);
    _paintTrussBayHighlightsAndLabels(canvas, project);

    // PASS 5: Live Pen Drawing Preview & Active Handles
    _paintPenPreview(canvas, project);
    _paintHandles(canvas, project);

    // PASS 6: Dimension / UI Overlays
    final bool showMarkings = editorController?.showMarkings ?? true;
    if (showMarkings) {
      _paintDimensionOverlays(canvas, size, project);
      _paintPlot3DDimensionsAndPerimeter(canvas, size, project);
    }

    // 9. Paint CAD Coordinate Triad Gizmo (Bottom-Left - hidden for clean scene presentation)
    // _paintCoordinateGizmo(canvas, size, viewMatrix);
  }

  void _paintWorldEnvironment(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
    v64.Vector3 eyePosition,
    TrussCachedWorldGeometry cached,
  ) {
    // 1. Determine dynamic plot bounds (Authoritative project bounds with layout node fallback)
    double minX = 0.0;
    double maxX = plotWidth ?? 100.0;
    double minZ = 0.0;
    double maxZ = plotDepth ?? 100.0;

    for (final n in layout.nodes.values) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.z < minZ) minZ = n.z;
      if (n.z > maxZ) maxZ = n.z;
    }

    final plotW = maxX - minX;
    final plotD = maxZ - minZ;

    // 2. Delegate to the Festival Live Event World Environment
    FestivalWorldEnvironment.paint(
      canvas: canvas,
      size: size,
      project: project,
      eyePosition: eyePosition,
      plotWidth: plotW,
      plotDepth: plotD,
      minX: minX,
      minZ: minZ,
    );

    // 3. Realistic Sunlight Ground Shadows from Upper Truss Beams
    for (final beam in cached.boxBeams.values) {
      if (beam.primaryChords.isEmpty) continue;
      final c0 = beam.primaryChords[0];
      final yElev = c0.start.y;
      final sP1 = project(v64.Vector3(c0.start.x + yElev * 0.28, 0.02, c0.start.z + yElev * 0.38));
      final sP2 = project(v64.Vector3(c0.end.x + yElev * 0.28, 0.02, c0.end.z + yElev * 0.38));
      if (sP1 != null && sP2 != null) {
        canvas.drawLine(sP1, sP2, Truss3DPaints.groundBeamShadow);
      }
    }

    // 4. Ground-Contact Shadows Beneath All Mandap Towers / Base Plates
    final shadowPaint = Paint()
      ..color = const Color(0x660B180B) // Translucent dark ground contact shadow
      ..style = PaintingStyle.fill;
    for (final pole in result.poles) {
      final bx = pole.x;
      final bz = pole.z;
      const sRad = 2.4;
      final sp1 = project(v64.Vector3(bx - sRad, 0.015, bz - sRad));
      final sp2 = project(v64.Vector3(bx + sRad, 0.015, bz - sRad));
      final sp3 = project(v64.Vector3(bx + sRad, 0.015, bz + sRad));
      final sp4 = project(v64.Vector3(bx - sRad, 0.015, bz + sRad));
      if (sp1 != null && sp2 != null && sp3 != null && sp4 != null) {
        _scratchPath.reset();
        _scratchPath.moveTo(sp1.dx, sp1.dy);
        _scratchPath.lineTo(sp2.dx, sp2.dy);
        _scratchPath.lineTo(sp3.dx, sp3.dy);
        _scratchPath.lineTo(sp4.dx, sp4.dy);
        _scratchPath.close();
        canvas.drawPath(_scratchPath, shadowPaint);
      }
    }
  }

  void _paintZones(Canvas canvas, Offset? Function(v64.Vector3) project) {
    for (final zone in layout.zones) {
      final left = math.min(zone.x1, zone.x2);
      final right = math.max(zone.x1, zone.x2);
      final top = math.min(zone.y1, zone.y2);
      final bottom = math.max(zone.y1, zone.y2);

      final h = zone.type == ZoneType.flooring ? 0.01 : 2.0;

      final color = zone.type == ZoneType.stage 
          ? const Color(0xFF1E293B).withValues(alpha: 0.9) 
          : const Color(0xFF0F172A).withValues(alpha: 0.7);

      final paint = Paint()..color = color..style = PaintingStyle.fill;
      final strokePaint = Paint()
        ..color = const Color(0xFF475569).withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      const double tileSize = 10.0;
      for (double x = left; x < right; x += tileSize) {
        for (double z = top; z < bottom; z += tileSize) {
          final xEnd = math.min(x + tileSize, right);
          final zEnd = math.min(z + tileSize, bottom);

          final worldCornersBase = [
            v64.Vector3(x, 0, z),
            v64.Vector3(xEnd, 0, z),
            v64.Vector3(xEnd, 0, zEnd),
            v64.Vector3(x, 0, zEnd),
          ];

          final worldCornersTop = worldCornersBase.map((c) => v64.Vector3(c.x, c.y + h, c.z)).toList();

          _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: zone.type == ZoneType.stage);
        }
      }
    }
  }

  void _paintPolymorphicNodes(Canvas canvas, Offset? Function(v64.Vector3) project) {
    for (final node in layout.nodes.values) {
      if (node.type == NodeType.corner || node.type == NodeType.junction || node.type == NodeType.openEnd || node.type == NodeType.generatedSupport || node.type == NodeType.pole) {
        continue;
      }

      final w = node.width ?? 10.0;
      final d = node.depth ?? 10.0;
      final h = node.type == NodeType.carpet 
          ? 0.01 
          : node.height ?? (node.type == NodeType.pole ? controller.mandapHeight : 0.0);
          
      final elev = node.elevation;
      final rot = node.rotation;

      final halfW = w / 2;
      final halfD = d / 2;

      final localCorners = [
        v64.Vector3(-halfW, 0, -halfD),
        v64.Vector3(halfW, 0, -halfD),
        v64.Vector3(halfW, 0, halfD),
        v64.Vector3(-halfW, 0, halfD),
      ];

      final cosR = math.cos(rot);
      final sinR = math.sin(rot);

      final worldCornersBase = localCorners.map((c) {
        final rx = c.x * cosR - c.z * sinR;
        final rz = c.x * sinR + c.z * cosR;
        return v64.Vector3(node.x + rx, elev, node.z + rz);
      }).toList();

      final worldCornersTop = worldCornersBase.map((c) => v64.Vector3(c.x, c.y + h, c.z)).toList();

      final isSelected = node.id == selectedNodeId;

      if (node.type == NodeType.stage || node.type == NodeType.carpet) {
        final color = node.type == NodeType.stage 
            ? const Color(0xFF1E293B).withValues(alpha: 0.9) 
            : const Color(0xFF0F172A).withValues(alpha: 0.7);

        final paint = Paint()..color = color..style = PaintingStyle.fill;
        final strokePaint = Paint()
          ..color = (isSelected ? const Color(0xFF00F0FF) : const Color(0xFF475569))
          ..style = PaintingStyle.stroke
          ..strokeWidth = isSelected ? 2.0 : 1.0;

        _draw3DBox(canvas, project, worldCornersBase, worldCornersTop, paint, strokePaint, drawSides: node.type == NodeType.stage);
      }
    }
  }

  void _draw3DBox(Canvas canvas, Offset? Function(v64.Vector3) project, List<v64.Vector3> base, List<v64.Vector3> top, Paint fill, Paint stroke, {bool drawSides = true}) {
    final projBase = base.map(project).toList();
    final projTop = top.map(project).toList();

    if (projBase.any((p) => p == null) || projTop.any((p) => p == null)) return;

    final pb = projBase.cast<Offset>();
    final pt = projTop.cast<Offset>();

    void drawPoly(List<Offset> pts) {
      _scratchPath.reset();
      _scratchPath.moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) _scratchPath.lineTo(pts[i].dx, pts[i].dy);
      _scratchPath.close();
      canvas.drawPath(_scratchPath, fill);
      canvas.drawPath(_scratchPath, stroke);
    }

    drawPoly(pt);
    drawPoly(pb);

    if (drawSides) {
      for (int i = 0; i < 4; i++) {
        final next = (i + 1) % 4;
        drawPoly([pb[i], pb[next], pt[next], pt[i]]);
      }
    }
  }

  void _paintStructuralTruss(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    TrussCachedWorldGeometry cached,
  ) {
    final isFull = animationProgress >= 0.999;
    final towerProgress = isFull ? 1.0 : ((animationProgress - 0.10) / 0.50).clamp(0.0, 1.0);
    final beamProgress = isFull ? 1.0 : ((animationProgress - 0.45) / 0.45).clamp(0.0, 1.0);

    // 1. Single Tubes
    if (beamProgress > 0.0) {
      for (final tube in cached.singleTubes) {
        final start = tube.start;
        final end = isFull ? tube.end : (start + (tube.end - start) * beamProgress);
        final p1 = project(start);
        final p2 = project(end);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, Truss3DPaints.tubeShadow);
          canvas.drawLine(p1, p2, Truss3DPaints.tube);
        }
      }
    }

    // 2. 4-Chord Box Beams with 4-Face Warren Lattice
    if (beamProgress > 0.0) {
      for (final geom in cached.boxBeams.values) {
        double boxDist = 8.0;
        if (geom.primaryChords.length >= 2) {
          final p0 = project(geom.primaryChords[0].start);
          final p1 = project(geom.primaryChords[1].start);
          if (p0 != null && p1 != null) {
            boxDist = (p1 - p0).distance;
          }
        }

        final chordW = (boxDist * 0.16).clamp(1.1, 3.2);
        final chordShadowW = chordW + 1.2;
        final strutW = (boxDist * 0.10).clamp(0.8, 1.8);
        final strutShadowW = strutW + 1.0;
        final tieW = (boxDist * 0.12).clamp(0.9, 2.0);
        final tieShadowW = tieW + 1.0;

        Truss3DPaints.tieShadow.strokeWidth = tieShadowW;
        Truss3DPaints.tieBody.strokeWidth = tieW;

        Truss3DPaints.webShadow.strokeWidth = strutShadowW;
        Truss3DPaints.webBody.strokeWidth = strutW;

        Truss3DPaints.chordShadow.strokeWidth = chordShadowW;
        Truss3DPaints.chordSunlitBody.strokeWidth = chordW;
        Truss3DPaints.chordShadedBody.strokeWidth = chordW;
        Truss3DPaints.chordHighlight.strokeWidth = math.max(0.6, chordW * 0.45);

        // Transverse frame ties & lattice struts (Rendered at LOD when beam is reasonably sized on screen)
        final bool renderLattice = boxDist >= 2.2;

        if (renderLattice) {
          // Transverse frame ties
          for (final tie in geom.transverseTies) {
            if (!isFull && geom.primaryChords.isNotEmpty) {
              final beamStart = geom.primaryChords[0].start;
              final beamEnd = geom.primaryChords[0].end;
              final totalDist = (beamEnd - beamStart).length;
              if (totalDist > 0.01) {
                final d = (tie.start - beamStart).length;
                if (d > totalDist * beamProgress) continue;
              }
            }
            final p1 = project(tie.start);
            final p2 = project(tie.end);
            if (p1 != null && p2 != null) {
              canvas.drawLine(p1, p2, Truss3DPaints.tieShadow);
              canvas.drawLine(p1, p2, Truss3DPaints.tieBody);
            }
          }

          // 4-Face Warren lattice diagonal struts
          for (final strut in geom.latticeStruts) {
            if (!isFull && geom.primaryChords.isNotEmpty) {
              final beamStart = geom.primaryChords[0].start;
              final beamEnd = geom.primaryChords[0].end;
              final totalDist = (beamEnd - beamStart).length;
              if (totalDist > 0.01) {
                final d = (strut.start - beamStart).length;
                if (d > totalDist * beamProgress) continue;
              }
            }
            final p1 = project(strut.start);
            final p2 = project(strut.end);
            if (p1 != null && p2 != null) {
              canvas.drawLine(p1, p2, Truss3DPaints.webShadow);
              canvas.drawLine(p1, p2, Truss3DPaints.webBody);
            }
          }
        }

        // 4 Primary Longitudinal Chords
        for (final chord in geom.primaryChords) {
          final start = chord.start;
          final end = isFull ? chord.end : (start + (chord.end - start) * beamProgress);
          final p1 = project(start);
          final p2 = project(end);
          if (p1 != null && p2 != null) {
            canvas.drawLine(p1, p2, Truss3DPaints.chordShadow);
            canvas.drawLine(
              p1,
              p2,
              chord.isTopChord ? Truss3DPaints.chordSunlitBody : Truss3DPaints.chordShadedBody,
            );
            if (chord.isTopChord) {
              canvas.drawLine(p1, p2, Truss3DPaints.chordHighlight);
            }
          }
        }
      }
    }

    // 3. 4-Chord Vertical Tower Columns
    if (towerProgress > 0.0) {
      for (final tower in cached.towers) {
        double towerDist = 8.0;
        if (tower.verticalChords.length >= 2) {
          final p0 = project(tower.verticalChords[0].start);
          final p1 = project(tower.verticalChords[1].start);
          if (p0 != null && p1 != null) {
            towerDist = (p1 - p0).distance;
          }
        }

        final tChordW = (towerDist * 0.16).clamp(1.1, 3.2);
        final tChordShadowW = tChordW + 1.2;
        final tStrutW = (towerDist * 0.10).clamp(0.8, 1.8);
        final tStrutShadowW = tStrutW + 1.0;
        final tTieW = (towerDist * 0.12).clamp(0.9, 2.0);
        final tTieShadowW = tTieW + 1.0;

        Truss3DPaints.tieShadow.strokeWidth = tTieShadowW;
        Truss3DPaints.tieBody.strokeWidth = tTieW;

        Truss3DPaints.webShadow.strokeWidth = tStrutShadowW;
        Truss3DPaints.webBody.strokeWidth = tStrutW;

        Truss3DPaints.chordShadow.strokeWidth = tChordShadowW;
        Truss3DPaints.chordSunlitBody.strokeWidth = tChordW;
        Truss3DPaints.chordShadedBody.strokeWidth = tChordW;
        Truss3DPaints.chordHighlight.strokeWidth = math.max(0.6, tChordW * 0.45);

        final currentHeight = isFull
            ? 9999.0
            : (tower.verticalChords.isNotEmpty
                ? tower.verticalChords[0].end.y * towerProgress
                : 9999.0);

        final bool renderTowerLattice = towerDist >= 2.2;

        if (renderTowerLattice) {
          // Transverse tower tie rungs
          for (final tie in tower.transverseTies) {
            if (!isFull && tie.start.y > currentHeight) continue;
            final p1 = project(tie.start);
            final p2 = project(tie.end);
            if (p1 != null && p2 != null) {
              canvas.drawLine(p1, p2, Truss3DPaints.tieShadow);
              canvas.drawLine(p1, p2, Truss3DPaints.tieBody);
            }
          }

          // 4-Face Warren lattice diagonal struts
          for (final strut in tower.latticeStruts) {
            if (!isFull && strut.start.y > currentHeight) continue;
            final p1 = project(strut.start);
            final strutEnd = isFull
                ? strut.end
                : (strut.end.y <= currentHeight
                    ? strut.end
                    : v64.Vector3(strut.end.x, currentHeight, strut.end.z));
            final p2 = project(strutEnd);
            if (p1 != null && p2 != null) {
              canvas.drawLine(p1, p2, Truss3DPaints.webShadow);
              canvas.drawLine(p1, p2, Truss3DPaints.webBody);
            }
          }
        }

        // 4 Primary Vertical Chords
        for (final chord in tower.verticalChords) {
          final start = chord.start;
          final end = isFull
              ? chord.end
              : v64.Vector3(chord.end.x, chord.end.y * towerProgress, chord.end.z);
          final p1 = project(start);
          final p2 = project(end);
          if (p1 != null && p2 != null) {
            canvas.drawLine(p1, p2, Truss3DPaints.chordShadow);
            canvas.drawLine(
              p1,
              p2,
              chord.isTopChord ? Truss3DPaints.chordSunlitBody : Truss3DPaints.chordShadedBody,
            );
            if (chord.isTopChord) {
              canvas.drawLine(p1, p2, Truss3DPaints.chordHighlight);
            }
          }
        }
      }
    }
  }

  void _paintConnectorsAndBasePlates(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    TrussCachedWorldGeometry cached,
  ) {
    final isFull = animationProgress >= 0.999;
    final baseProgress = isFull ? 1.0 : (animationProgress / 0.25).clamp(0.0, 1.0);

    // 1. Heavy Metal Base Plates with 3D Slab & Corner Hex Bolts under all vertical towers
    if (baseProgress > 0.001) {
      for (final tower in cached.towers) {
        final bp = tower.basePlate;
        final bx = bp.center.x;
        final bz = bp.center.z;
        final plateHalfW = bp.halfW * baseProgress;
        final collarHalfW = bp.collarHalfW * baseProgress;

        // Soft ambient ground shadow underneath base plate on lawn
        const shadowExpand = 0.35;
        final sp1 = project(v64.Vector3(bx - plateHalfW - shadowExpand, 0.015, bz - plateHalfW - shadowExpand));
        final sp2 = project(v64.Vector3(bx + plateHalfW + shadowExpand, 0.015, bz - plateHalfW - shadowExpand));
        final sp3 = project(v64.Vector3(bx + plateHalfW + shadowExpand, 0.015, bz + plateHalfW + shadowExpand));
        final sp4 = project(v64.Vector3(bx - plateHalfW - shadowExpand, 0.015, bz + plateHalfW + shadowExpand));
        if (sp1 != null && sp2 != null && sp3 != null && sp4 != null) {
          final shadowPath = Path()
            ..moveTo(sp1.dx, sp1.dy)
            ..lineTo(sp2.dx, sp2.dy)
            ..lineTo(sp3.dx, sp3.dy)
            ..lineTo(sp4.dx, sp4.dy)
            ..close();
          canvas.drawPath(shadowPath, Truss3DPaints.basePlateGroundShadow);
        }

        // Base Plate 3D slab
        final slabH = 0.12 * baseProgress;
        final bpBase = [
          v64.Vector3(bx - plateHalfW, 0.0, bz - plateHalfW),
          v64.Vector3(bx + plateHalfW, 0.0, bz - plateHalfW),
          v64.Vector3(bx + plateHalfW, 0.0, bz + plateHalfW),
          v64.Vector3(bx - plateHalfW, 0.0, bz + plateHalfW),
        ];
        final bpTop = [
          v64.Vector3(bx - plateHalfW, slabH, bz - plateHalfW),
          v64.Vector3(bx + plateHalfW, slabH, bz - plateHalfW),
          v64.Vector3(bx + plateHalfW, slabH, bz + plateHalfW),
          v64.Vector3(bx - plateHalfW, slabH, bz + plateHalfW),
        ];

        final projB = bpBase.map(project).toList();
        final projT = bpTop.map(project).toList();

        if (!projB.any((p) => p == null) && !projT.any((p) => p == null)) {
          final b = projB.cast<Offset>();
          final t = projT.cast<Offset>();

          // Side skirts
          for (int i = 0; i < 4; i++) {
            final next = (i + 1) % 4;
            _scratchPath.reset();
            _scratchPath.moveTo(b[i].dx, b[i].dy);
            _scratchPath.lineTo(b[next].dx, b[next].dy);
            _scratchPath.lineTo(t[next].dx, t[next].dy);
            _scratchPath.lineTo(t[i].dx, t[i].dy);
            _scratchPath.close();
            canvas.drawPath(_scratchPath, Truss3DPaints.basePlateSlabSide);
          }

          // Top face of base plate
          _scratchPath.reset();
          _scratchPath.moveTo(t[0].dx, t[0].dy);
          _scratchPath.lineTo(t[1].dx, t[1].dy);
          _scratchPath.lineTo(t[2].dx, t[2].dy);
          _scratchPath.lineTo(t[3].dx, t[3].dy);
          _scratchPath.close();
          canvas.drawPath(_scratchPath, Truss3DPaints.basePlateTop);
          canvas.drawPath(_scratchPath, Truss3DPaints.basePlateBorder);

          // Raised mounting spigot collar
          final collarTopH = 0.30 * baseProgress;
          final cB = [
            v64.Vector3(bx - collarHalfW, slabH, bz - collarHalfW),
            v64.Vector3(bx + collarHalfW, slabH, bz - collarHalfW),
            v64.Vector3(bx + collarHalfW, slabH, bz + collarHalfW),
            v64.Vector3(bx - collarHalfW, slabH, bz + collarHalfW),
          ].map(project).toList();
          final cT = [
            v64.Vector3(bx - collarHalfW, collarTopH, bz - collarHalfW),
            v64.Vector3(bx + collarHalfW, collarTopH, bz - collarHalfW),
            v64.Vector3(bx + collarHalfW, collarTopH, bz + collarHalfW),
            v64.Vector3(bx - collarHalfW, collarTopH, bz + collarHalfW),
          ].map(project).toList();

          if (!cB.any((p) => p == null) && !cT.any((p) => p == null)) {
            final cb = cB.cast<Offset>();
            final ct = cT.cast<Offset>();

            for (int i = 0; i < 4; i++) {
              final next = (i + 1) % 4;
              _scratchPath.reset();
              _scratchPath.moveTo(cb[i].dx, cb[i].dy);
              _scratchPath.lineTo(cb[next].dx, cb[next].dy);
              _scratchPath.lineTo(ct[next].dx, ct[next].dy);
              _scratchPath.lineTo(ct[i].dx, ct[i].dy);
              _scratchPath.close();
              canvas.drawPath(_scratchPath, Truss3DPaints.collarSide);
            }

            _scratchPath.reset();
            _scratchPath.moveTo(ct[0].dx, ct[0].dy);
            _scratchPath.lineTo(ct[1].dx, ct[1].dy);
            _scratchPath.lineTo(ct[2].dx, ct[2].dy);
            _scratchPath.lineTo(ct[3].dx, ct[3].dy);
            _scratchPath.close();
            canvas.drawPath(_scratchPath, Truss3DPaints.collarTop);
          }

          // 4 corner hex mounting bolts (only when base plate is large enough on screen)
          final plateScreenW = (t[1].dx - t[0].dx).abs();
          if (plateScreenW >= 5.5) {
            final boltRadius = (plateScreenW * 0.045).clamp(0.8, 2.0);
            final boltShadowRadius = boltRadius + 0.6;
            for (final bolt in bp.cornerBolts) {
              final pBolt = project(v64.Vector3(bolt.x, slabH + 0.01, bolt.z));
              if (pBolt != null) {
                canvas.drawCircle(pBolt, boltShadowRadius, Truss3DPaints.boltShadow);
                canvas.drawCircle(pBolt, boltRadius, Truss3DPaints.boltPaint);
              }
            }
          }
        }
      }
    }

    // 2. Modular 6-Way Cube Corner/Junction Connectors
    final connProgress = isFull ? 1.0 : ((animationProgress - 0.75) / 0.25).clamp(0.0, 1.0);
    if (connProgress > 0.0) {
      for (final conn in cached.connectors.values) {
        _draw3DJunctionCube(canvas, project, conn);
      }
    }
  }

  void _draw3DJunctionCube(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    TrussConnectorCube conn,
  ) {
    final projB = conn.baseCorners.map(project).toList();
    final projT = conn.topCorners.map(project).toList();

    if (projB.any((p) => p == null) || projT.any((p) => p == null)) return;

    final b = projB.cast<Offset>();
    final t = projT.cast<Offset>();
    final cubeScreenW = (t[1].dx - t[0].dx).abs();

    // Fast LOD: For small cubes at distance, draw a simple box/quad
    if (cubeScreenW < 3.2) {
      final centerTop = Offset(
        (t[0].dx + t[1].dx + t[2].dx + t[3].dx) / 4.0,
        (t[0].dy + t[1].dy + t[2].dy + t[3].dy) / 4.0,
      );
      final halfW = math.max(1.2, cubeScreenW * 0.5);
      canvas.drawRect(
        Rect.fromCenter(center: centerTop, width: halfW * 2.0, height: halfW * 2.0),
        Truss3DPaints.junctionFrontFace,
      );
      return;
    }

    void drawFace(List<Offset> pts, Paint fill, Paint stroke) {
      _scratchPath.reset();
      _scratchPath.moveTo(pts[0].dx, pts[0].dy);
      for (int i = 1; i < pts.length; i++) _scratchPath.lineTo(pts[i].dx, pts[i].dy);
      _scratchPath.close();
      canvas.drawPath(_scratchPath, fill);
      canvas.drawPath(_scratchPath, stroke);
    }

    // Bottom face
    drawFace(b, Truss3DPaints.junctionBottomFace, Truss3DPaints.junctionShadedBorder);

    // Rear / Shaded faces
    drawFace([b[2], b[3], t[3], t[2]], Truss3DPaints.junctionShadedFace, Truss3DPaints.junctionShadedBorder);
    drawFace([b[3], b[0], t[0], t[3]], Truss3DPaints.junctionShadedFace, Truss3DPaints.junctionShadedBorder);

    // Front / Sunlit faces
    drawFace([b[1], b[2], t[2], t[1]], Truss3DPaints.junctionFrontFace, Truss3DPaints.junctionFrontBorder);
    drawFace([b[0], b[1], t[1], t[0]], Truss3DPaints.junctionFrontFace, Truss3DPaints.junctionFrontBorder);

    // Sunlit top face
    drawFace(t, Truss3DPaints.junctionTopFace, Truss3DPaints.junctionTopBorder);

    // Circular coupling spigot ring on top face, scaled proportionally
    final centerTop = Offset(
      (t[0].dx + t[1].dx + t[2].dx + t[3].dx) / 4.0,
      (t[0].dy + t[1].dy + t[2].dy + t[3].dy) / 4.0,
    );
    final ringRadius = (cubeScreenW * 0.28).clamp(2.0, 4.5);
    final pinRadius = (cubeScreenW * 0.12).clamp(1.0, 2.0);
    final boltRadius = (cubeScreenW * 0.06).clamp(0.6, 1.2);

    canvas.drawCircle(centerTop, ringRadius, Truss3DPaints.junctionCouplingRing);
    canvas.drawCircle(centerTop, pinRadius, Truss3DPaints.junctionCouplingCenter);

    // 4 corner connection bolt glints on top face
    for (int i = 0; i < 4; i++) {
      final bx = centerTop.dx + (t[i].dx - centerTop.dx) * 0.65;
      final by = centerTop.dy + (t[i].dy - centerTop.dy) * 0.65;
      canvas.drawCircle(Offset(bx, by), boltRadius, Truss3DPaints.boltPaint);
    }
  }

  void _paintSupportPoleMarkers(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    TrussCachedWorldGeometry cached,
  ) {
    if (animationProgress < 0.3) return;

    final selectedEdge = selectedEdgeId != null ? layout.edges[selectedEdgeId] : null;
    final effectivePenStartNodeId = editorController?.penStartNodeId ?? pendingEdgeSourceId;

    final unselectedRadius = (6.5 * (300.0 / math.max(300.0, controller.cameraDistance))).clamp(3.0, 6.5);

    // Red circular markers on all support poles (turn vibrant blue when selected or active in pencil tool)
    final renderedPositions = <String>{};

    for (final node in layout.nodes.values) {
      if (node.isControlPoint) continue;
      final isSupport = node.support == NodeSupport.pole || node.type == NodeType.corner || node.type == NodeType.pole;
      if (!isSupport) continue;

      final key = '${node.x.toStringAsFixed(1)}_${node.z.toStringAsFixed(1)}';
      if (renderedPositions.contains(key)) continue;
      renderedPositions.add(key);

      final pTop = project(v64.Vector3(node.x, node.elevation, node.z));
      if (pTop != null) {
        final isSelected = node.id == selectedNodeId ||
            node.id == effectivePenStartNodeId ||
            node.id == activeHandleNodeId ||
            (selectedEdge != null && (selectedEdge.startNodeId == node.id || selectedEdge.endNodeId == node.id));

        if (isSelected) {
          // Luminous blue glow + blue core when selected
          canvas.drawCircle(pTop, 11.5, Truss3DPaints.supportPoleSelectedGlow);
          canvas.drawCircle(pTop, 7.5, Truss3DPaints.supportPoleSelected);
          canvas.drawCircle(pTop, 7.5, Truss3DPaints.supportPoleBorder);
        } else {
          // Unselected: standard red marker
          canvas.drawCircle(pTop, unselectedRadius, Truss3DPaints.supportPoleUnselected);
          canvas.drawCircle(pTop, unselectedRadius, Truss3DPaints.supportPoleBorder);
        }
      }
    }

    for (final tower in cached.towers) {
      final key = '${tower.bx.toStringAsFixed(1)}_${tower.bz.toStringAsFixed(1)}';
      if (renderedPositions.contains(key)) continue;
      renderedPositions.add(key);

      final pTop = project(v64.Vector3(tower.bx, controller.mandapHeight, tower.bz));
      if (pTop != null) {
        final isSelected = tower.sourceEdgeId == selectedEdgeId ||
            (selectedEdge != null && layout.edges.values.any((e) =>
                e.id == selectedEdgeId &&
                ((layout.getNode(e.startNodeId)?.x ?? -999) - tower.bx).abs() < 0.2 &&
                ((layout.getNode(e.startNodeId)?.z ?? -999) - tower.bz).abs() < 0.2));

        if (isSelected) {
          canvas.drawCircle(pTop, 11.5, Truss3DPaints.supportPoleSelectedGlow);
          canvas.drawCircle(pTop, 7.5, Truss3DPaints.supportPoleSelected);
          canvas.drawCircle(pTop, 7.5, Truss3DPaints.supportPoleBorder);
        } else {
          canvas.drawCircle(pTop, unselectedRadius, Truss3DPaints.supportPoleUnselected);
          canvas.drawCircle(pTop, unselectedRadius, Truss3DPaints.supportPoleBorder);
        }
      }
    }
  }

  void _paintSelectionHighlights(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
    TrussCachedWorldGeometry cached,
  ) {
    if (selectedEdgeId == null) return;

    // 1. Selected box beam
    final selectedBeam = cached.boxBeams[selectedEdgeId];
    if (selectedBeam != null) {
      for (final chord in selectedBeam.primaryChords) {
        final p1 = project(chord.start);
        final p2 = project(chord.end);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, Truss3DPaints.selectedGlow);
          canvas.drawLine(p1, p2, Truss3DPaints.selectedChord);
        }
      }
      for (final strut in selectedBeam.latticeStruts) {
        final p1 = project(strut.start);
        final p2 = project(strut.end);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, Truss3DPaints.selectedWeb);
        }
      }
      return;
    }

    // 2. Selected tower
    for (final tower in cached.towers) {
      final isMatchingTower = tower.sourceEdgeId == selectedEdgeId ||
          layout.edges.values.any((e) =>
              e.id == selectedEdgeId &&
              (e.role == TrussMemberRole.tower ||
                  ((layout.getNode(e.startNodeId)?.x ?? -999) - tower.bx).abs() < 0.2 &&
                  ((layout.getNode(e.startNodeId)?.z ?? -999) - tower.bz).abs() < 0.2));

      if (isMatchingTower) {
        for (final chord in tower.verticalChords) {
          final p1 = project(chord.start);
          final p2 = project(chord.end);
          if (p1 != null && p2 != null) {
            canvas.drawLine(p1, p2, Truss3DPaints.selectedGlow);
            canvas.drawLine(p1, p2, Truss3DPaints.selectedChord);
          }
        }
        for (final strut in tower.latticeStruts) {
          final p1 = project(strut.start);
          final p2 = project(strut.end);
          if (p1 != null && p2 != null) {
            canvas.drawLine(p1, p2, Truss3DPaints.selectedWeb);
          }
        }
        return;
      }
    }

    // 3. Selected single tube
    for (final tube in cached.singleTubes) {
      if (tube.edgeId == selectedEdgeId) {
        final p1 = project(tube.start);
        final p2 = project(tube.end);
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, Truss3DPaints.selectedGlow);
          canvas.drawLine(p1, p2, Truss3DPaints.selectedTube);
        }
      }
    }
  }

  void _paintPenPreview(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final ed = editorController;
    if (ed == null || ed.mode != EditorMode.addEdge) return;

    if (ed.penStartPoint != null) {
      final pStart = project(ed.penStartPoint!);
      if (pStart != null) {
        // Glowing start point anchor
        canvas.drawCircle(
          pStart,
          10.0,
          Paint()..color = const Color(0xFF22C55E).withValues(alpha: 0.35)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pStart,
          6.0,
          Paint()..color = const Color(0xFF22C55E)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pStart,
          6.0,
          Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0,
        );
      }

      if (ed.penPreviewEndPoint != null) {
        final pEnd = project(ed.penPreviewEndPoint!);
        if (pStart != null && pEnd != null) {
          // Dominant axis straight line
          final linePaint = Paint()
            ..color = const Color(0xFF00F0FF)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round;
          final haloPaint = Paint()
            ..color = const Color(0xFF00F0FF).withValues(alpha: 0.3)
            ..strokeWidth = 9.0
            ..strokeCap = StrokeCap.round;

          canvas.drawLine(pStart, pEnd, haloPaint);
          canvas.drawLine(pStart, pEnd, linePaint);

          // End point marker
          canvas.drawCircle(
            pEnd,
            6.0,
            Paint()..color = const Color(0xFF00F0FF)..style = PaintingStyle.fill,
          );
          canvas.drawCircle(
            pEnd,
            6.0,
            Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0,
          );

          // Midpoint dimension badge
          final midScreen = Offset((pStart.dx + pEnd.dx) / 2.0, (pStart.dy + pEnd.dy) / 2.0);
          final axisName = ed.penDominantAxis ?? 'X';
          final lenText = '${(ed.penPreviewLength ?? 0.0).toStringAsFixed(1)} ft [$axisName-Axis]';

          final tp = TextPainter(
            text: TextSpan(
              text: lenText,
              style: const TextStyle(
                color: Color(0xFF00F0FF),
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();

          final badgeRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              midScreen.dx - tp.width / 2.0 - 6,
              midScreen.dy - 22,
              tp.width + 12,
              tp.height + 6,
            ),
            const Radius.circular(6),
          );

          canvas.drawRRect(
            badgeRect,
            Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.92),
          );
          canvas.drawRRect(
            badgeRect,
            Paint()
              ..color = const Color(0xFF00F0FF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2,
          );
          tp.paint(canvas, Offset(midScreen.dx - tp.width / 2.0, midScreen.dy - 19));
        }
      }
    }
  }

  void _paintHandles(Canvas canvas, Offset? Function(v64.Vector3) project) {
    final pendingSourcePaint = Paint()..color = const Color(0xFF22C55E); // Bright Green
    final nodeNumbers = editorController?.displayNumbering.nodeNumbers ??
        const TrussDisplayNumberingService().buildNodeNumbers(layout);

    // Draw Center Dot (+) if not created yet
    final hasCrossEdges = layout.edges.values.any((e) => e.id.value.contains('cross') || e.id.value.contains('mid'));
    if (!hasCrossEdges) {
      final cX = editorController?.centerControlNode?.x ?? ((plotWidth ?? 100.0) / 2.0);
      final cZ = editorController?.centerControlNode?.z ?? ((plotDepth ?? 100.0) / 2.0);
      final cElev = controller.mandapHeight;
      final pCenter = project(v64.Vector3(cX, cElev, cZ));
      if (pCenter != null) {
        // Glowing cyan/white center dot (+) indicator
        canvas.drawCircle(
          pCenter,
          13.0,
          Paint()
            ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pCenter,
          6.5,
          Paint()..color = const Color(0xFF00F0FF)..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          pCenter,
          6.5,
          Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2.0,
        );
      }
    }

    for (final node in layout.nodes.values) {
      final p = project(v64.Vector3(node.x, node.elevation, node.z));
      if (p != null) {
        if (node.id == pendingEdgeSourceId) {
          canvas.drawCircle(p, 8.0, pendingSourcePaint);
        } else if (node.type == NodeType.controlPoint || node.id.value.contains('center')) {
          final isSel = node.id == selectedNodeId;
          if (isSel) {
            // Selected: High-contrast Cyan indicator with directional front/back arrows
            final centerPaint = Paint()..color = const Color(0xFF00F0FF);
            canvas.drawCircle(p, 8.0, centerPaint);
            canvas.drawCircle(
              p,
              13.0,
              Paint()
                ..color = const Color(0xFF00F0FF).withValues(alpha: 0.35)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 2.0,
            );

            // Front / Back directional indicator arrows along Z axis
            final pFront = project(v64.Vector3(node.x, node.elevation, node.z - 4.0));
            final pBack = project(v64.Vector3(node.x, node.elevation, node.z + 4.0));
            if (pFront != null && pBack != null) {
              final arrowPaint = Paint()
                ..color = const Color(0xFF00F0FF)
                ..strokeWidth = 2.0
                ..strokeCap = StrokeCap.round;
              canvas.drawLine(p, pFront, arrowPaint);
              canvas.drawLine(p, pBack, arrowPaint);
              canvas.drawCircle(pFront, 3.5, centerPaint);
              canvas.drawCircle(pBack, 3.5, centerPaint);
            }

            // Dimension badge above center handle with dynamic node number
            final bool showMarkings = editorController?.showMarkings ?? true;
            if (showMarkings) {
              final nodeNum = nodeNumbers[node.id];
              final nodeNumPrefix = nodeNum != null ? '#$nodeNum · ' : '';
              final textSpan = TextSpan(
                text: '${nodeNumPrefix}Z: ${node.z.toStringAsFixed(1)} ft',
                style: const TextStyle(
                  color: Color(0xFF00F0FF),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              );
              final tp = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
              final badgeRect = RRect.fromRectAndRadius(
                Rect.fromLTWH(p.dx - tp.width / 2.0 - 5, p.dy - 24, tp.width + 10, tp.height + 4),
                const Radius.circular(4),
              );
              canvas.drawRRect(badgeRect, Paint()..color = const Color(0xEE0F172A));
              canvas.drawRRect(badgeRect, Paint()..color = const Color(0xFF00F0FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
              tp.paint(canvas, Offset(p.dx - tp.width / 2.0, p.dy - 22));
            }
          } else {
            // Unselected: Clean structural aluminum junction point without oversized orange halo
            final unselectedPaint = Paint()..color = const Color(0xFF94A3B8);
            canvas.drawCircle(p, 5.5, unselectedPaint);
            canvas.drawCircle(
              p,
              5.5,
              Paint()
                ..color = const Color(0xFF334155)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.4,
            );
          }
        }
      }
    }
  }

  void _paintDimensionOverlays(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
  ) {
    if (animationProgress < 0.85) return;
    final bool showMarkings = editorController?.showMarkings ?? true;
    if (!showMarkings) return;

    final drawnBadgeEntries = <({Offset pt, bool isSelected, String label})>[];

    for (final edge in layout.edges.values) {
      final isSelected = edge.id == selectedEdgeId;

      final startNode = layout.getNode(edge.startNodeId);
      final endNode = layout.getNode(edge.endNodeId);
      if (startNode == null || endNode == null) continue;

      final isTower = edge.role == TrussMemberRole.tower ||
          (startNode.x == endNode.x && startNode.z == endNode.z);

      if (isTower && !isSelected) continue;

      final p1 = project(v64.Vector3(startNode.x, startNode.elevation, startNode.z));
      final p2 = project(v64.Vector3(endNode.x, endNode.elevation, endNode.z));
      final screenLen = (p1 != null && p2 != null) ? (p2 - p1).distance : 0.0;

      if (!isSelected && screenLen < 4.0) continue;

      final transform = BeamTransformCalculator.calculate(
        startNode: startNode,
        endNode: endNode,
        height: controller.mandapHeight,
      );

      final displayLength = (isSelected && dragPreviewLengthFeet != null)
          ? dragPreviewLengthFeet!
          : transform.length;
      if (displayLength < 1.0) continue;

      final polePoints = _getEdgePolePoints(edge, startNode, endNode);

      if (polePoints.length > 2) {
        for (int i = 0; i < polePoints.length - 1; i++) {
          final ptA = polePoints[i];
          final ptB = polePoints[i + 1];
          final spanLen = (ptB - ptA).length;
          if (spanLen < 0.5) continue;

          final spanMid = (ptA + ptB) * 0.5;
          final midScreen = project(spanMid);
          if (midScreen != null) {
            final spanStr = spanLen == spanLen.roundToDouble()
                ? '${spanLen.toInt()} ft'
                : '${spanLen.toStringAsFixed(1)} ft';
            _addDeduplicatedBadge(drawnBadgeEntries, midScreen, spanStr, isSelected: false);
          }
        }
      } else {
        final midpointScreen = project(transform.center);
        if (midpointScreen != null) {
          final lenStr = displayLength == displayLength.roundToDouble()
              ? '${displayLength.toInt()} ft'
              : '${displayLength.toStringAsFixed(1)} ft';
          _addDeduplicatedBadge(drawnBadgeEntries, midpointScreen, lenStr, isSelected: isSelected);
        }
      }

      if (isSelected && polePoints.length > 2) {
        final midpointScreen = project(transform.center);
        if (midpointScreen != null) {
          final lenStr = displayLength == displayLength.roundToDouble()
              ? '${displayLength.toInt()} ft'
              : '${displayLength.toStringAsFixed(1)} ft';
          _addDeduplicatedBadge(drawnBadgeEntries, midpointScreen, lenStr, isSelected: true);
        }
      }
    }

    // Render all deduplicated badges
    for (final entry in drawnBadgeEntries) {
      _drawBadge(canvas, entry.pt, entry.label, isSelected: entry.isSelected);
    }
  }

  void _addDeduplicatedBadge(
    List<({Offset pt, bool isSelected, String label})> entries,
    Offset pt,
    String label, {
    required bool isSelected,
  }) {
    int existingIdx = -1;
    for (int i = 0; i < entries.length; i++) {
      if ((entries[i].pt - pt).distance < 6.0 && entries[i].label == label) {
        existingIdx = i;
        break;
      }
    }

    if (existingIdx >= 0) {
      if (isSelected && !entries[existingIdx].isSelected) {
        entries[existingIdx] = (pt: pt, isSelected: true, label: label);
      }
      return;
    }

    entries.add((pt: pt, isSelected: isSelected, label: label));
  }

  List<v64.Vector3> _getEdgePolePoints(MandapEdge edge, MandapNode startNode, MandapNode endNode) {
    final startPt = v64.Vector3(startNode.x, startNode.elevation, startNode.z);
    final endPt = v64.Vector3(endNode.x, endNode.elevation, endNode.z);
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final lenSq = dx * dx + dz * dz;

    final items = <({double t, v64.Vector3 pt})>[
      (t: 0.0, pt: startPt),
      (t: 1.0, pt: endPt),
    ];

    if (editorController != null) {
      for (final pole in editorController!.result.poles) {
        final px = pole.x - startNode.x;
        final pz = pole.z - startNode.z;
        final dot = px * dx + pz * dz;
        final t = dot / lenSq;
        if (t > 0.01 && t < 0.99) {
          final projX = startNode.x + t * dx;
          final projZ = startNode.z + t * dz;
          final distSq = (pole.x - projX) * (pole.x - projX) + (pole.z - projZ) * (pole.z - projZ);
          if (distSq < 0.25) {
            items.add((t: t, pt: v64.Vector3(pole.x, startNode.elevation, pole.z)));
          }
        }
      }
    }

    items.sort((a, b) => a.t.compareTo(b.t));

    final uniquePoints = <v64.Vector3>[];
    for (final item in items) {
      if (uniquePoints.isEmpty || (uniquePoints.last - item.pt).length > 0.5) {
        uniquePoints.add(item.pt);
      }
    }
    return uniquePoints;
  }

  void _drawBadge(
    Canvas canvas,
    Offset screenPt,
    String labelText, {
    required bool isSelected,
  }) {
    final textSpan = TextSpan(
      text: labelText,
      style: TextStyle(
        color: isSelected ? const Color(0xFF00F0FF) : const Color(0xFFF1F5F9),
        fontSize: isSelected ? 9.5 : 8.5,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final badgeWidth = textPainter.width + 10.0;
    final badgeHeight = isSelected ? 17.0 : 15.0;

    final badgeLeft = screenPt.dx - badgeWidth / 2.0;
    final badgeTop = screenPt.dy - badgeHeight / 2.0;

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(badgeLeft, badgeTop, badgeWidth, badgeHeight),
      const Radius.circular(5),
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = (isSelected ? const Color(0xFF0F172A) : const Color(0xEE0F172A))
            .withValues(alpha: isSelected ? 0.95 : 0.90),
    );

    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = isSelected ? const Color(0xFF00F0FF) : const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 1.4 : 0.9,
    );

    textPainter.paint(
      canvas,
      Offset(
        screenPt.dx - textPainter.width / 2.0,
        badgeTop + (badgeHeight - textPainter.height) / 2.0,
      ),
    );
  }

  void _paintCoordinateGizmo(Canvas canvas, Size size, v64.Matrix4 viewMatrix) {
    // Bottom-left CAD coordinate triad
    final origin = Offset(52, size.height - 52);
    const axisLen = 32.0;

    // Extract upper 3x3 camera rotation to project unit axes
    final r = viewMatrix.getRotation();
    final xProj = Offset(r.entry(0, 0), -r.entry(1, 0)) * axisLen;
    final yProj = Offset(r.entry(0, 1), -r.entry(1, 1)) * axisLen;
    final zProj = Offset(r.entry(0, 2), -r.entry(1, 2)) * axisLen;

    // Gizmo backdrop circle
    canvas.drawCircle(
      origin,
      38,
      Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.8),
    );
    canvas.drawCircle(
      origin,
      38,
      Paint()
        ..color = const Color(0xFF334155)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    void drawAxis(Offset delta, Color color, String label) {
      final pEnd = origin + delta;
      canvas.drawLine(
        origin,
        pEnd,
        Paint()
          ..color = color
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, pEnd - Offset(tp.width / 2, tp.height / 2));
    }

    drawAxis(zProj, const Color(0xFF3B82F6), 'Z');
    drawAxis(xProj, const Color(0xFFEF4444), 'X');
    drawAxis(yProj, const Color(0xFF22C55E), 'Y');
  }

  void _paintTrussBayGroundFills(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
  ) {
    final activeBayId = selectedBayId ?? editorController?.selectedBayId;
    if (activeBayId == null) return;

    final bays = editorController?.bays ?? const TrussBayDetector().detectBays(layout);
    for (final bay in bays) {
      if (bay.id == activeBayId) {
        final pNW = project(v64.Vector3(bay.minX, 0.03, bay.minZ));
        final pNE = project(v64.Vector3(bay.maxX, 0.03, bay.minZ));
        final pSE = project(v64.Vector3(bay.maxX, 0.03, bay.maxZ));
        final pSW = project(v64.Vector3(bay.minX, 0.03, bay.maxZ));

        if (pNW != null && pNE != null && pSE != null && pSW != null) {
          final fillPath = Path()
            ..moveTo(pNW.dx, pNW.dy)
            ..lineTo(pNE.dx, pNE.dy)
            ..lineTo(pSE.dx, pSE.dy)
            ..lineTo(pSW.dx, pSW.dy)
            ..close();

          canvas.drawPath(
            fillPath,
            Paint()
              ..color = const Color(0x3300E5FF) // Subtle translucent cyan bay floor fill
              ..style = PaintingStyle.fill,
          );
        }
        break;
      }
    }
  }

  void _paintTrussBayHighlightsAndLabels(
    Canvas canvas,
    Offset? Function(v64.Vector3) project,
  ) {
    if (animationProgress < 0.85) return;
    final bays = editorController?.bays ?? const TrussBayDetector().detectBays(layout);
    if (bays.isEmpty) return;

    final activeBayId = selectedBayId ?? editorController?.selectedBayId;
    final h = controller.mandapHeight;

    for (final bay in bays) {
      final isSelected = bay.id == activeBayId;

      // 1. If selected: Draw luminous cyan boundary and 4 glowing corner node rings at elevated corners
      if (isSelected) {
        final eNW = project(v64.Vector3(bay.minX, h, bay.minZ));
        final eNE = project(v64.Vector3(bay.maxX, h, bay.minZ));
        final eSE = project(v64.Vector3(bay.maxX, h, bay.maxZ));
        final eSW = project(v64.Vector3(bay.minX, h, bay.maxZ));

        if (eNW != null && eNE != null && eSE != null && eSW != null) {
          final borderPath = Path()
            ..moveTo(eNW.dx, eNW.dy)
            ..lineTo(eNE.dx, eNE.dy)
            ..lineTo(eSE.dx, eSE.dy)
            ..lineTo(eSW.dx, eSW.dy)
            ..close();

          // Outer halo
          canvas.drawPath(
            borderPath,
            Paint()
              ..color = const Color(0x4400E5FF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 6.0,
          );

          // Solid bright cyan boundary
          canvas.drawPath(
            borderPath,
            Paint()
              ..color = const Color(0xFF00E5FF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.0,
          );

          // 4 circular corner node handles (matching Image 2)
          for (final pt in [eNW, eNE, eSE, eSW]) {
            canvas.drawCircle(pt, 5.5, Paint()..color = const Color(0xFF00E5FF));
            canvas.drawCircle(pt, 2.5, Paint()..color = Colors.white);
          }
        }
      }

      // 2. Center Dimension Label (00/00 format, e.g. 30/30) for all created/detected bays
      final bool showMarkings = editorController?.showMarkings ?? true;
      final pCenter = project(v64.Vector3(bay.centerX, 0.05, bay.centerZ));
      if (showMarkings && pCenter != null) {
        final w = bay.widthFt.toInt().toString().padLeft(2, '0');
        final l = bay.lengthFt.toInt().toString().padLeft(2, '0');
        final labelText = '$w/$l';
        final textPainter = TextPainter(
          text: TextSpan(
            text: labelText,
            style: TextStyle(
              color: isSelected ? const Color(0xFF00E5FF) : Colors.white.withValues(alpha: 0.95),
              fontSize: isSelected ? 10.5 : 8.5,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final bWidth = textPainter.width + 8.0;
        final bHeight = textPainter.height + 4.0;
        final bRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: pCenter, width: bWidth, height: bHeight),
          const Radius.circular(4),
        );

        // Dark badge background
        canvas.drawRRect(
          bRect,
          Paint()
            ..color = isSelected
                ? const Color(0xDD0F172A)
                : const Color(0xCC0F172A)
            ..style = PaintingStyle.fill,
        );

        // Badge border
        canvas.drawRRect(
          bRect,
          Paint()
            ..color = isSelected
                ? const Color(0xFF00E5FF)
                : const Color(0xFF334155)
            ..style = PaintingStyle.stroke
            ..strokeWidth = isSelected ? 1.4 : 0.8,
        );

        textPainter.paint(
          canvas,
          Offset(pCenter.dx - textPainter.width / 2.0, pCenter.dy - textPainter.height / 2.0),
        );
      }
    }
  }

  void _paintPlot3DDimensionsAndPerimeter(
    Canvas canvas,
    Size size,
    Offset? Function(v64.Vector3) project,
  ) {
    double minX = 0.0;
    double maxX = plotWidth ?? 100.0;
    double minZ = 0.0;
    double maxZ = plotDepth ?? 100.0;

    for (final n in layout.nodes.values) {
      if (n.x < minX) minX = n.x;
      if (n.x > maxX) maxX = n.x;
      if (n.z < minZ) minZ = n.z;
      if (n.z > maxZ) maxZ = n.z;
    }

    final pw = maxX - minX;
    final pd = maxZ - minZ;

    void draw3DDimensionLine({
      required v64.Vector3 startWorld,
      required v64.Vector3 endWorld,
      required String text,
      Color lineColor = const Color(0xFF00E5FF),
      Color badgeBg = const Color(0xEE0F172A),
      Color badgeBorder = const Color(0xFF00E5FF),
      Color textColor = Colors.white,
    }) {
      final pStart = project(startWorld);
      final pEnd = project(endWorld);
      if (pStart == null || pEnd == null) return;

      final linePaint = Paint()
        ..color = lineColor
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(pStart, pEnd, linePaint);

      final dir = pEnd - pStart;
      final dist = dir.distance;
      if (dist > 3.0) {
        final norm = Offset(dir.dx / dist, dir.dy / dist);
        final perp = Offset(-norm.dy, norm.dx) * 4.0;

        // End-ticks
        canvas.drawLine(pStart - perp, pStart + perp, linePaint);
        canvas.drawLine(pEnd - perp, pEnd + perp, linePaint);

        // Arrowheads
        final arrowArm1 = (-norm + Offset(-norm.dy, norm.dx) * 0.5) * 5.0;
        final arrowArm2 = (-norm - Offset(-norm.dy, norm.dx) * 0.5) * 5.0;
        canvas.drawLine(pEnd, pEnd + arrowArm1, linePaint);
        canvas.drawLine(pEnd, pEnd + arrowArm2, linePaint);

        final startArm1 = (norm + Offset(-norm.dy, norm.dx) * 0.5) * 5.0;
        final startArm2 = (norm - Offset(-norm.dy, norm.dx) * 0.5) * 5.0;
        canvas.drawLine(pStart, pStart + startArm1, linePaint);
        canvas.drawLine(pStart, pStart + startArm2, linePaint);
      }

      final mid = Offset((pStart.dx + pEnd.dx) / 2.0, (pStart.dy + pEnd.dy) / 2.0);
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: textColor,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final badgeW = tp.width + 12.0;
      final badgeH = tp.height + 6.0;
      final badgeRRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: mid, width: badgeW, height: badgeH),
        const Radius.circular(5),
      );

      canvas.drawRRect(badgeRRect, Paint()..color = badgeBg);
      canvas.drawRRect(
        badgeRRect,
        Paint()
          ..color = badgeBorder
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
      tp.paint(canvas, Offset(mid.dx - tp.width / 2.0, mid.dy - tp.height / 2.0));
    }

    // 1. Plot Perimeter Ground Box (Cyan luminous outline)
    final pNW = project(v64.Vector3(minX, 0.05, minZ));
    final pNE = project(v64.Vector3(maxX, 0.05, minZ));
    final pSE = project(v64.Vector3(maxX, 0.05, maxZ));
    final pSW = project(v64.Vector3(minX, 0.05, maxZ));

    if (pNW != null && pNE != null && pSE != null && pSW != null) {
      final groundPath = Path()
        ..moveTo(pNW.dx, pNW.dy)
        ..lineTo(pNE.dx, pNE.dy)
        ..lineTo(pSE.dx, pSE.dy)
        ..lineTo(pSW.dx, pSW.dy)
        ..close();

      // Cyan glow halo
      canvas.drawPath(
        groundPath,
        Paint()
          ..color = const Color(0x3300E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.5,
      );
      canvas.drawPath(
        groundPath,
        Paint()
          ..color = const Color(0xFF00E5FF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }

    // 2. Width CAD 3D Dimension Line (along X axis at Z = minZ - 3.5)
    final extPaint = Paint()
      ..color = const Color(0x6600E5FF)
      ..strokeWidth = 1.0;

    final extW0Start = project(v64.Vector3(minX, 0.05, minZ));
    final extW0End = project(v64.Vector3(minX, 0.05, minZ - 3.5));
    final extW1Start = project(v64.Vector3(maxX, 0.05, minZ));
    final extW1End = project(v64.Vector3(maxX, 0.05, minZ - 3.5));
    if (extW0Start != null && extW0End != null) canvas.drawLine(extW0Start, extW0End, extPaint);
    if (extW1Start != null && extW1End != null) canvas.drawLine(extW1Start, extW1End, extPaint);

    draw3DDimensionLine(
      startWorld: v64.Vector3(minX, 0.05, minZ - 3.5),
      endWorld: v64.Vector3(maxX, 0.05, minZ - 3.5),
      text: '${pw.toInt()} ft',
      lineColor: const Color(0xFF00E5FF),
      badgeBorder: const Color(0xFF00E5FF),
    );

    // 3. Depth CAD 3D Dimension Line (along Z axis at X = minX - 3.5)
    final extD0Start = project(v64.Vector3(minX, 0.05, minZ));
    final extD0End = project(v64.Vector3(minX - 3.5, 0.05, minZ));
    final extD1Start = project(v64.Vector3(minX, 0.05, maxZ));
    final extD1End = project(v64.Vector3(minX - 3.5, 0.05, maxZ));
    if (extD0Start != null && extD0End != null) canvas.drawLine(extD0Start, extD0End, extPaint);
    if (extD1Start != null && extD1End != null) canvas.drawLine(extD1Start, extD1End, extPaint);

    draw3DDimensionLine(
      startWorld: v64.Vector3(minX - 3.5, 0.05, minZ),
      endWorld: v64.Vector3(minX - 3.5, 0.05, maxZ),
      text: '${pd.toInt()} ft',
      lineColor: const Color(0xFF00E5FF),
      badgeBorder: const Color(0xFF00E5FF),
    );
  }

  @override
  bool shouldRepaint(covariant Mandap3DPainter oldDelegate) {
    return oldDelegate.layout != layout ||
        oldDelegate.result != result ||
        oldDelegate.selectedEdgeId != selectedEdgeId ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.selectedBayId != selectedBayId ||
        oldDelegate.editorController?.selectedBayId != editorController?.selectedBayId ||
        oldDelegate.editorController?.showMarkings != editorController?.showMarkings ||
        oldDelegate.pendingEdgeSourceId != pendingEdgeSourceId ||
        oldDelegate.activeHandleNodeId != activeHandleNodeId ||
        oldDelegate.dragPreviewLengthFeet != dragPreviewLengthFeet ||
        oldDelegate.animationProgress != animationProgress ||
        oldDelegate.plotWidth != plotWidth ||
        oldDelegate.plotDepth != plotDepth ||
        oldDelegate.editorController?.displayNumbering != editorController?.displayNumbering;
  }
}
