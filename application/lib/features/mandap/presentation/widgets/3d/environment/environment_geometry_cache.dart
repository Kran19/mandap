import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

class CachedQuad {
  final v64.Vector3 v1;
  final v64.Vector3 v2;
  final v64.Vector3 v3;
  final v64.Vector3 v4;
  final Paint fill;
  final Paint? stroke;

  const CachedQuad({
    required this.v1,
    required this.v2,
    required this.v3,
    required this.v4,
    required this.fill,
    this.stroke,
  });
}

class CachedBox {
  final List<v64.Vector3> base;
  final List<v64.Vector3> top;
  final Paint fill;
  final Paint stroke;
  final bool drawSides;

  const CachedBox({
    required this.base,
    required this.top,
    required this.fill,
    required this.stroke,
    this.drawSides = true,
  });
}

class CachedLine {
  final v64.Vector3 start;
  final v64.Vector3 end;
  final Paint paint;

  const CachedLine({
    required this.start,
    required this.end,
    required this.paint,
  });
}

class CachedCircle {
  final v64.Vector3 center;
  final double radius;
  final Paint paint;

  const CachedCircle({
    required this.center,
    required this.radius,
    required this.paint,
  });
}

class CachedPoly {
  final List<v64.Vector3> points;
  final Paint fill;
  final Paint? stroke;

  const CachedPoly({
    required this.points,
    required this.fill,
    this.stroke,
  });
}

/// Pre-allocated static Paint objects to avoid garbage collection churn in 3D frame rendering.
class EnvironmentPaints {
  static final Paint outerEarth = Paint()
    ..color = const Color(0xFF4A5531)
    ..style = PaintingStyle.fill;

  static final Paint festivalLawn = Paint()
    ..color = const Color(0xFF869E58)
    ..style = PaintingStyle.fill;

  static final Paint stripeA = Paint()
    ..color = const Color(0xFF8DA65D)
    ..style = PaintingStyle.fill;

  static final Paint stripeB = Paint()
    ..color = const Color(0xFF7E9652)
    ..style = PaintingStyle.fill;

  static final Paint barrierPanel = Paint()
    ..color = const Color(0xFF1E2226)
    ..style = PaintingStyle.fill;

  static final Paint barrierRail = Paint()
    ..color = const Color(0xFF475569)
    ..strokeWidth = 2.4
    ..strokeCap = StrokeCap.round;

  static final Paint barrierLeg = Paint()
    ..color = const Color(0xFF181B1E)
    ..strokeWidth = 2.0;

  static final Paint stageDeckFill = Paint()
    ..color = const Color(0xFF18181B)
    ..style = PaintingStyle.fill;

  static final Paint stageDeckBorder = Paint()
    ..color = const Color(0xFF3F3F46)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint screenBorder = Paint()
    ..color = const Color(0xFFF97316)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  static final Paint imagScreenFill = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.fill;

  static final Paint imagScreenBorder = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint canopyFill = Paint()
    ..color = const Color(0xFFF8FAFC)
    ..style = PaintingStyle.fill;

  static final Paint canopyBorder = Paint()
    ..color = const Color(0xFFCBD5E1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.6;

  static final Paint speakerCable = Paint()
    ..color = const Color(0xFF0F172A)
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  static final Paint speakerCluster = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.fill;

  static final Paint pylonFill = Paint()
    ..color = const Color(0xFFB91C1C)
    ..style = PaintingStyle.fill;

  static final Paint pylonBorder = Paint()
    ..color = const Color(0xFF991B1B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint checkerWhite = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint checkerDark = Paint()
    ..color = const Color(0xFF18181B)
    ..style = PaintingStyle.fill;

  static final Paint archBeamFill = Paint()
    ..color = const Color(0xFF18181B)
    ..style = PaintingStyle.fill;

  static final Paint archBeamBorder = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.8;

  static final Paint portalSignFace = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.fill;

  static final Paint asphaltRamp = Paint()
    ..color = const Color(0xFF334155)
    ..style = PaintingStyle.fill;

  static final Paint camperTeal = Paint()
    ..color = const Color(0xFF0D9488)
    ..style = PaintingStyle.fill;

  static final Paint camperYellow = Paint()
    ..color = const Color(0xFFEAB308)
    ..style = PaintingStyle.fill;

  static final Paint camperWhite = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint camperDarkBorder = Paint()
    ..color = const Color(0xFF1E293B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint camperLightBorder = Paint()
    ..color = const Color(0xFFCBD5E1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  static final Paint wheelPaint = Paint()
    ..color = const Color(0xFF0F172A)
    ..style = PaintingStyle.fill;

  static final Paint redRoof = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.fill;

  static final Paint redRoofBorder = Paint()
    ..color = const Color(0xFF991B1B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint woodTableFill = Paint()
    ..color = const Color(0xFF92400E)
    ..style = PaintingStyle.fill;

  static final Paint woodTableBorder = Paint()
    ..color = const Color(0xFF78350F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;

  static final Paint lightPole = Paint()
    ..color = const Color(0xFFB45309)
    ..strokeWidth = 3.2
    ..strokeCap = StrokeCap.round;

  static final Paint festoonCable = Paint()
    ..color = const Color(0xFF334155)
    ..strokeWidth = 1.2;

  static final Paint bulbGlow = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.fill;

  static final Paint vendorFloor = Paint()
    ..color = const Color(0xFFE2E8F0)
    ..style = PaintingStyle.fill;

  static final Paint vendorPost = Paint()
    ..color = const Color(0xFFDC2626)
    ..strokeWidth = 3.6
    ..strokeCap = StrokeCap.round;

  static final Paint fohBoothFill = Paint()
    ..color = const Color(0xFF18181B)
    ..style = PaintingStyle.fill;

  static final Paint fohBoothBorder = Paint()
    ..color = const Color(0xFFDC2626)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4;

  static final Paint mastPaint = Paint()
    ..color = const Color(0xFF64748B)
    ..strokeWidth = 4.5
    ..strokeCap = StrokeCap.round;

  static final Paint mastCrossbar = Paint()
    ..color = const Color(0xFF334155)
    ..strokeWidth = 3.5;

  static final Paint mastBulb = Paint()
    ..color = const Color(0xFFFEF08A)
    ..style = PaintingStyle.fill;

  static final Paint mastBulbWhite = Paint()
    ..color = Colors.white
    ..style = PaintingStyle.fill;

  static final Paint screenShaderFill = Paint()
    ..shader = const LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [Color(0xFFEA580C), Color(0xFFDC2626), Color(0xFF18181B)],
    ).createShader(const Rect.fromLTWH(0, 0, 400, 300));
}

/// Cache of precomputed world-space geometry for the 3D event environment.
///
/// Guaranteed: Camera movement (orbit, pan, zoom) causes ZERO environment rebuilds.
class EnvironmentGeometryCache {
  final double minX;
  final double minZ;
  final double plotWidth;
  final double plotDepth;

  final List<CachedQuad> quads = [];
  final List<CachedBox> boxes = [];
  final List<CachedLine> lines = [];
  final List<CachedCircle> circles = [];
  final List<CachedPoly> polys = [];

  static EnvironmentGeometryCache? _instance;
  static int rebuildCount = 0;

  EnvironmentGeometryCache._({
    required this.minX,
    required this.minZ,
    required this.plotWidth,
    required this.plotDepth,
  }) {
    _buildGeometry();
  }

  static EnvironmentGeometryCache getOrCreate({
    required double minX,
    required double minZ,
    required double plotWidth,
    required double plotDepth,
  }) {
    if (_instance != null &&
        (_instance!.minX - minX).abs() < 0.01 &&
        (_instance!.minZ - minZ).abs() < 0.01 &&
        (_instance!.plotWidth - plotWidth).abs() < 0.01 &&
        (_instance!.plotDepth - plotDepth).abs() < 0.01) {
      return _instance!;
    }
    rebuildCount++;
    _instance = EnvironmentGeometryCache._(
      minX: minX,
      minZ: minZ,
      plotWidth: plotWidth,
      plotDepth: plotDepth,
    );
    return _instance!;
  }

  void _buildGeometry() {
    final maxX = minX + plotWidth;
    final maxZ = minZ + plotDepth;
    final plotW = maxX - minX;
    final plotD = maxZ - minZ;
    final centerX = (minX + maxX) / 2.0;
    final centerZ = (minZ + maxZ) / 2.0;

    // 1. Terrain & Festival Lawn Turf - Generous clearance around the mandap structure
    final fenceMarginX = math.max(85.0, plotW * 0.80);
    final fenceMarginZSouth = math.max(65.0, plotD * 0.60);
    final fenceMarginZNorth = math.max(75.0, plotD * 0.70);

    final fMinX = minX - fenceMarginX;
    final fMaxX = maxX + fenceMarginX;
    final fMinZ = minZ - fenceMarginZSouth;
    final fMaxZ = maxZ + fenceMarginZNorth;

    final groundMargin = math.max(1200.0, math.max(plotW, plotD) * 10.0);
    final gMinX = minX - groundMargin;
    final gMaxX = maxX + groundMargin;
    final gMinZ = minZ - groundMargin;
    final gMaxZ = maxZ + groundMargin;

    // Outer Earth
    quads.add(CachedQuad(
      v1: v64.Vector3(gMinX, -0.02, gMinZ),
      v2: v64.Vector3(gMaxX, -0.02, gMinZ),
      v3: v64.Vector3(gMaxX, -0.02, gMaxZ),
      v4: v64.Vector3(gMinX, -0.02, gMaxZ),
      fill: EnvironmentPaints.outerEarth,
    ));

    // Festival Arena Lawn Turf
    final arenaMargin = math.max(24.0, math.max(plotW, plotD) * 0.22);
    final aMinX = fMinX - arenaMargin;
    final aMaxX = fMaxX + arenaMargin;
    final aMinZ = fMinZ - arenaMargin;
    final aMaxZ = fMaxZ + arenaMargin;

    quads.add(CachedQuad(
      v1: v64.Vector3(aMinX, 0.0, aMinZ),
      v2: v64.Vector3(aMaxX, 0.0, aMinZ),
      v3: v64.Vector3(aMaxX, 0.0, aMaxZ),
      v4: v64.Vector3(aMinX, 0.0, aMaxZ),
      fill: EnvironmentPaints.festivalLawn,
    ));

    // Alternating stadium lawn mower stripes
    const stripeWidth = 12.0;
    int sIdx = 0;
    for (double sx = aMinX; sx < aMaxX; sx += stripeWidth) {
      final ex = math.min(sx + stripeWidth, aMaxX);
      final paint = (sIdx % 2 == 0) ? EnvironmentPaints.stripeA : EnvironmentPaints.stripeB;
      quads.add(CachedQuad(
        v1: v64.Vector3(sx, 0.005, aMinZ),
        v2: v64.Vector3(ex, 0.005, aMinZ),
        v3: v64.Vector3(ex, 0.005, aMaxZ),
        v4: v64.Vector3(sx, 0.005, aMaxZ),
        fill: paint,
      ));
      sIdx++;
    }

    // 2. Perimeter Fencing
    const fenceHeight = 5.0;
    final gateWidth = math.min(32.0, math.max(20.0, plotW * 0.35));
    final gateLeftX = centerX - gateWidth / 2.0;
    final gateRightX = centerX + gateWidth / 2.0;

    void addBarrier(double x1, double z1, double x2, double z2) {
      final segLen = math.sqrt((x2 - x1) * (x2 - x1) + (z2 - z1) * (z2 - z1));
      if (segLen < 0.5) return;

      quads.add(CachedQuad(
        v1: v64.Vector3(x1, 0.15, z1),
        v2: v64.Vector3(x2, 0.15, z2),
        v3: v64.Vector3(x2, fenceHeight, z2),
        v4: v64.Vector3(x1, fenceHeight, z1),
        fill: EnvironmentPaints.barrierPanel,
      ));

      lines.add(CachedLine(
        start: v64.Vector3(x1, fenceHeight, z1),
        end: v64.Vector3(x2, fenceHeight, z2),
        paint: EnvironmentPaints.barrierRail,
      ));
      lines.add(CachedLine(
        start: v64.Vector3(x1, fenceHeight * 0.5, z1),
        end: v64.Vector3(x2, fenceHeight * 0.5, z2),
        paint: EnvironmentPaints.barrierRail,
      ));

      final numSections = (segLen / 8.0).ceil().clamp(1, 40);
      for (int i = 0; i <= numSections; i++) {
        final t = i / numSections;
        final px = x1 + (x2 - x1) * t;
        final pz = z1 + (z2 - z1) * t;
        lines.add(CachedLine(
          start: v64.Vector3(px, 0.0, pz),
          end: v64.Vector3(px, fenceHeight + 0.3, pz),
          paint: EnvironmentPaints.barrierRail,
        ));
        lines.add(CachedLine(
          start: v64.Vector3(px, 0.0, pz),
          end: v64.Vector3(px, 0.0, pz + 1.8),
          paint: EnvironmentPaints.barrierLeg,
        ));
      }
    }

    addBarrier(fMinX, fMaxZ, fMaxX, fMaxZ);
    addBarrier(fMinX, fMinZ, fMinX, fMaxZ);
    addBarrier(fMaxX, fMinZ, fMaxX, fMaxZ);
    addBarrier(fMinX, fMinZ, gateLeftX, fMinZ);
    addBarrier(gateRightX, fMinZ, fMaxX, fMinZ);

    // 3. North Main Concert Stage
    final stageW = math.min(80.0, math.max(50.0, plotW * 0.70));
    const stageD = 18.0;
    final stageLeftX = centerX - stageW / 2.0;
    final stageRightX = centerX + stageW / 2.0;
    final stageFrontZ = fMaxZ - 6.0;
    final stageBackZ = stageFrontZ + stageD;
    const stageDeckH = 3.5;
    const stageRoofH = 26.0;

    final deckBase = [
      v64.Vector3(stageLeftX, 0.0, stageFrontZ),
      v64.Vector3(stageRightX, 0.0, stageFrontZ),
      v64.Vector3(stageRightX, 0.0, stageBackZ),
      v64.Vector3(stageLeftX, 0.0, stageBackZ),
    ];
    final deckTop = deckBase.map((v) => v64.Vector3(v.x, stageDeckH, v.z)).toList();
    boxes.add(CachedBox(
      base: deckBase,
      top: deckTop,
      fill: EnvironmentPaints.stageDeckFill,
      stroke: EnvironmentPaints.stageDeckBorder,
    ));

    // Stage Rear LED Screen
    final screenLeft = stageLeftX + 6.0;
    final screenRight = stageRightX - 6.0;
    final screenBackZ = stageBackZ - 1.0;
    quads.add(CachedQuad(
      v1: v64.Vector3(screenLeft, stageDeckH + 1.0, screenBackZ),
      v2: v64.Vector3(screenRight, stageDeckH + 1.0, screenBackZ),
      v3: v64.Vector3(screenRight, stageRoofH - 4.0, screenBackZ),
      v4: v64.Vector3(screenLeft, stageRoofH - 4.0, screenBackZ),
      fill: EnvironmentPaints.screenShaderFill,
      stroke: EnvironmentPaints.screenBorder,
    ));

    // IMAG Screens
    void addImag(double sx1, double sx2) {
      quads.add(CachedQuad(
        v1: v64.Vector3(sx1, stageDeckH + 2.0, stageFrontZ + 4.0),
        v2: v64.Vector3(sx2, stageDeckH + 2.0, stageFrontZ + 4.0),
        v3: v64.Vector3(sx2, stageRoofH - 6.0, stageFrontZ + 4.0),
        v4: v64.Vector3(sx1, stageRoofH - 6.0, stageFrontZ + 4.0),
        fill: EnvironmentPaints.imagScreenFill,
        stroke: EnvironmentPaints.imagScreenBorder,
      ));
    }
    addImag(stageLeftX + 1.0, stageLeftX + 5.5);
    addImag(stageRightX - 5.5, stageRightX - 1.0);

    // Peaked Stage Roof Canopy
    const roofPeakH = stageRoofH + 4.0;
    polys.add(CachedPoly(
      points: [
        v64.Vector3(stageLeftX - 1.0, stageRoofH, stageFrontZ),
        v64.Vector3(centerX, roofPeakH, stageFrontZ),
        v64.Vector3(stageRightX + 1.0, stageRoofH, stageFrontZ),
      ],
      fill: EnvironmentPaints.canopyFill,
      stroke: EnvironmentPaints.canopyBorder,
    ));

    quads.add(CachedQuad(
      v1: v64.Vector3(stageLeftX - 1.0, stageRoofH, stageFrontZ),
      v2: v64.Vector3(centerX, roofPeakH, stageFrontZ),
      v3: v64.Vector3(centerX, roofPeakH, stageBackZ),
      v4: v64.Vector3(stageLeftX - 1.0, stageRoofH, stageBackZ),
      fill: EnvironmentPaints.canopyFill,
      stroke: EnvironmentPaints.canopyBorder,
    ));
    quads.add(CachedQuad(
      v1: v64.Vector3(centerX, roofPeakH, stageFrontZ),
      v2: v64.Vector3(stageRightX + 1.0, stageRoofH, stageFrontZ),
      v3: v64.Vector3(stageRightX + 1.0, stageRoofH, stageBackZ),
      v4: v64.Vector3(centerX, roofPeakH, stageBackZ),
      fill: EnvironmentPaints.canopyFill,
      stroke: EnvironmentPaints.canopyBorder,
    ));

    // Line Array Speakers
    void addLineArray(double lx, double lz) {
      v64.Vector3? prev;
      for (double y = stageRoofH - 2.0; y >= stageDeckH + 4.0; y -= 2.2) {
        final cur = v64.Vector3(lx, y, lz);
        circles.add(CachedCircle(
          center: cur,
          radius: 3.0,
          paint: EnvironmentPaints.speakerCluster,
        ));
        if (prev != null) {
          lines.add(CachedLine(start: prev, end: cur, paint: EnvironmentPaints.speakerCable));
        }
        prev = cur;
      }
    }
    addLineArray(stageLeftX - 2.5, stageFrontZ + 1.5);
    addLineArray(stageRightX + 2.5, stageFrontZ + 1.5);

    // 4. South Grand Festival Entrance
    const archH = 14.0;
    const pylonW = 4.0;

    void addPylon(double px, double pz) {
      final pBase = [
        v64.Vector3(px - pylonW / 2, 0.0, pz - pylonW / 2),
        v64.Vector3(px + pylonW / 2, 0.0, pz - pylonW / 2),
        v64.Vector3(px + pylonW / 2, 0.0, pz + pylonW / 2),
        v64.Vector3(px - pylonW / 2, 0.0, pz + pylonW / 2),
      ];
      final pTop = pBase.map((v) => v64.Vector3(v.x, archH, v.z)).toList();
      boxes.add(CachedBox(
        base: pBase,
        top: pTop,
        fill: EnvironmentPaints.pylonFill,
        stroke: EnvironmentPaints.pylonBorder,
      ));

      for (double y = 1.5; y < archH - 1.0; y += 3.0) {
        final fill = ((y.toInt() % 2 == 0) ? EnvironmentPaints.checkerWhite : EnvironmentPaints.checkerDark);
        quads.add(CachedQuad(
          v1: v64.Vector3(px - pylonW / 2 + 0.5, y, pz - pylonW / 2 - 0.1),
          v2: v64.Vector3(px + pylonW / 2 - 0.5, y, pz - pylonW / 2 - 0.1),
          v3: v64.Vector3(px + pylonW / 2 - 0.5, y + 2.0, pz - pylonW / 2 - 0.1),
          v4: v64.Vector3(px - pylonW / 2 + 0.5, y + 2.0, pz - pylonW / 2 - 0.1),
          fill: fill,
        ));
      }
    }

    addPylon(gateLeftX, fMinZ);
    addPylon(gateRightX, fMinZ);

    // Overhead Arch Beam
    final archBeamBase = [
      v64.Vector3(gateLeftX - pylonW / 2, archH - 3.0, fMinZ - pylonW / 2),
      v64.Vector3(gateRightX + pylonW / 2, archH - 3.0, fMinZ - pylonW / 2),
      v64.Vector3(gateRightX + pylonW / 2, archH - 3.0, fMinZ + pylonW / 2),
      v64.Vector3(gateLeftX - pylonW / 2, archH - 3.0, fMinZ + pylonW / 2),
    ];
    final archBeamTop = archBeamBase.map((v) => v64.Vector3(v.x, archH + 2.0, v.z)).toList();
    boxes.add(CachedBox(
      base: archBeamBase,
      top: archBeamTop,
      fill: EnvironmentPaints.archBeamFill,
      stroke: EnvironmentPaints.archBeamBorder,
    ));

    quads.add(CachedQuad(
      v1: v64.Vector3(gateLeftX, archH - 2.5, fMinZ - pylonW / 2 - 0.1),
      v2: v64.Vector3(gateRightX, archH - 2.5, fMinZ - pylonW / 2 - 0.1),
      v3: v64.Vector3(gateRightX, archH + 1.5, fMinZ - pylonW / 2 - 0.1),
      v4: v64.Vector3(gateLeftX, archH + 1.5, fMinZ - pylonW / 2 - 0.1),
      fill: EnvironmentPaints.portalSignFace,
    ));

    // Entrance Ramps
    quads.add(CachedQuad(
      v1: v64.Vector3(gateLeftX + 1.5, 0.02, fMinZ - 14.0),
      v2: v64.Vector3(gateRightX - 1.5, 0.02, fMinZ - 14.0),
      v3: v64.Vector3(gateRightX - 1.5, 0.02, fMinZ + 8.0),
      v4: v64.Vector3(gateLeftX + 1.5, 0.02, fMinZ + 8.0),
      fill: EnvironmentPaints.asphaltRamp,
    ));

    // 5. West Activation Village
    final westVillageX = fMinX + 12.0;

    void addCamper(double vx, double vz, Paint mainFill) {
      const vL = 14.0;
      const vW = 6.5;
      const vH = 7.0;

      final vBase = [
        v64.Vector3(vx - vW / 2, 0.6, vz - vL / 2),
        v64.Vector3(vx + vW / 2, 0.6, vz - vL / 2),
        v64.Vector3(vx + vW / 2, 0.6, vz + vL / 2),
        v64.Vector3(vx - vW / 2, 0.6, vz + vL / 2),
      ];
      final vBelt = vBase.map((v) => v64.Vector3(v.x, 4.0, v.z)).toList();
      final vTop = vBase.map((v) => v64.Vector3(v.x, vH, v.z)).toList();

      boxes.add(CachedBox(
        base: vBase,
        top: vBelt,
        fill: mainFill,
        stroke: EnvironmentPaints.camperDarkBorder,
      ));
      boxes.add(CachedBox(
        base: vBelt,
        top: vTop,
        fill: EnvironmentPaints.camperWhite,
        stroke: EnvironmentPaints.camperLightBorder,
      ));

      for (final offZ in [-vL * 0.3, vL * 0.3]) {
        circles.add(CachedCircle(
          center: v64.Vector3(vx - vW / 2, 0.6, vz + offZ),
          radius: 3.5,
          paint: EnvironmentPaints.wheelPaint,
        ));
        circles.add(CachedCircle(
          center: v64.Vector3(vx + vW / 2, 0.6, vz + offZ),
          radius: 3.5,
          paint: EnvironmentPaints.wheelPaint,
        ));
      }
    }

    addCamper(westVillageX, centerZ - 18.0, EnvironmentPaints.camperTeal);
    addCamper(westVillageX, centerZ - 2.0, EnvironmentPaints.camperYellow);

    // Sloped Roof Canopy Stall
    const stallW = 16.0;
    const stallD = 18.0;
    quads.add(CachedQuad(
      v1: v64.Vector3(westVillageX - stallW / 2 - 1.0, 9.5, centerZ + 14.0 - 1.0),
      v2: v64.Vector3(westVillageX + stallW / 2 + 1.0, 9.5, centerZ + 14.0 - 1.0),
      v3: v64.Vector3(westVillageX + stallW / 2 + 1.0, 7.5, centerZ + 14.0 + stallD + 1.0),
      v4: v64.Vector3(westVillageX - stallW / 2 - 1.0, 7.5, centerZ + 14.0 + stallD + 1.0),
      fill: EnvironmentPaints.redRoof,
      stroke: EnvironmentPaints.redRoofBorder,
    ));

    // Picnic Tables
    void addTable(double tx, double tz) {
      final tBase = [
        v64.Vector3(tx - 2.2, 2.2, tz - 3.2),
        v64.Vector3(tx + 2.2, 2.2, tz - 3.2),
        v64.Vector3(tx + 2.2, 2.2, tz + 3.2),
        v64.Vector3(tx - 2.2, 2.2, tz + 3.2),
      ];
      final tTop = tBase.map((v) => v64.Vector3(v.x, 2.6, v.z)).toList();
      boxes.add(CachedBox(
        base: tBase,
        top: tTop,
        fill: EnvironmentPaints.woodTableFill,
        stroke: EnvironmentPaints.woodTableBorder,
      ));
    }
    addTable(westVillageX + 9.0, centerZ - 12.0);
    addTable(westVillageX + 9.0, centerZ - 2.0);
    addTable(westVillageX + 9.0, centerZ + 8.0);

    // Festoon Lights
    final fA = v64.Vector3(westVillageX + 4.0, 9.0, centerZ - 22.0);
    final fB = v64.Vector3(westVillageX + 12.0, 9.0, centerZ + 14.0);

    lines.add(CachedLine(start: v64.Vector3(fA.x, 0.0, fA.z), end: fA, paint: EnvironmentPaints.lightPole));
    lines.add(CachedLine(start: v64.Vector3(fB.x, 0.0, fB.z), end: fB, paint: EnvironmentPaints.lightPole));

    const festoonSteps = 8;
    v64.Vector3? prevFestoon;
    for (int i = 0; i <= festoonSteps; i++) {
      final t = i / festoonSteps;
      final sag = math.sin(t * math.pi) * 1.8;
      final cur = v64.Vector3(
        fA.x + (fB.x - fA.x) * t,
        fA.y + (fB.y - fA.y) * t - sag,
        fA.z + (fB.z - fA.z) * t,
      );
      if (prevFestoon != null) {
        lines.add(CachedLine(start: prevFestoon, end: cur, paint: EnvironmentPaints.festoonCable));
      }
      circles.add(CachedCircle(center: cur, radius: 2.2, paint: EnvironmentPaints.bulbGlow));
      prevFestoon = cur;
    }

    // 6. East Vendor Village
    final eastVillageX = fMaxX - 16.0;
    void addVendorStall(double vz) {
      const vW = 16.0;
      const vD = 14.0;
      quads.add(CachedQuad(
        v1: v64.Vector3(eastVillageX - vW / 2, 0.02, vz - vD / 2),
        v2: v64.Vector3(eastVillageX + vW / 2, 0.02, vz - vD / 2),
        v3: v64.Vector3(eastVillageX + vW / 2, 0.02, vz + vD / 2),
        v4: v64.Vector3(eastVillageX - vW / 2, 0.02, vz + vD / 2),
        fill: EnvironmentPaints.vendorFloor,
      ));

      quads.add(CachedQuad(
        v1: v64.Vector3(eastVillageX - vW / 2 - 1.0, 9.5, vz - vD / 2 - 1.0),
        v2: v64.Vector3(eastVillageX + vW / 2 + 1.0, 9.5, vz - vD / 2 - 1.0),
        v3: v64.Vector3(eastVillageX + vW / 2 + 1.0, 7.5, vz + vD / 2 + 1.0),
        v4: v64.Vector3(eastVillageX - vW / 2 - 1.0, 7.5, vz + vD / 2 + 1.0),
        fill: EnvironmentPaints.redRoof,
        stroke: EnvironmentPaints.redRoofBorder,
      ));

      for (final px in [eastVillageX - vW / 2, eastVillageX + vW / 2]) {
        for (final pz in [vz - vD / 2, vz + vD / 2]) {
          lines.add(CachedLine(
            start: v64.Vector3(px, 0.0, pz),
            end: v64.Vector3(px, 8.5, pz),
            paint: EnvironmentPaints.vendorPost,
          ));
        }
      }
    }

    addVendorStall(centerZ - 20.0);
    addVendorStall(centerZ);
    addVendorStall(centerZ + 20.0);

    // 7. Center FOH Sound Booth
    final fohZ = fMinZ + (minZ - fMinZ) * 0.35;
    const fohW = 12.0;
    const fohD = 12.0;
    const fohH = 8.5;

    final fohBase = [
      v64.Vector3(centerX - fohW / 2, 0.0, fohZ - fohD / 2),
      v64.Vector3(centerX + fohW / 2, 0.0, fohZ - fohD / 2),
      v64.Vector3(centerX + fohW / 2, 0.0, fohZ + fohD / 2),
      v64.Vector3(centerX - fohW / 2, 0.0, fohZ + fohD / 2),
    ];
    final fohTop = fohBase.map((v) => v64.Vector3(v.x, fohH, v.z)).toList();
    boxes.add(CachedBox(
      base: fohBase,
      top: fohTop,
      fill: EnvironmentPaints.fohBoothFill,
      stroke: EnvironmentPaints.fohBoothBorder,
    ));

    quads.add(CachedQuad(
      v1: v64.Vector3(centerX - fohW / 2 - 1.0, fohH, fohZ - fohD / 2 - 1.0),
      v2: v64.Vector3(centerX + fohW / 2 + 1.0, fohH, fohZ - fohD / 2 - 1.0),
      v3: v64.Vector3(centerX + fohW / 2 + 1.0, fohH + 2.5, fohZ + fohD / 2 + 1.0),
      v4: v64.Vector3(centerX - fohW / 2 - 1.0, fohH + 2.5, fohZ + fohD / 2 + 1.0),
      fill: EnvironmentPaints.redRoof,
      stroke: EnvironmentPaints.redRoofBorder,
    ));

    // 8. Stadium Floodlight Masts
    const mastH = 42.0;
    void addMast(double mx, double mz) {
      lines.add(CachedLine(
        start: v64.Vector3(mx, 0.0, mz),
        end: v64.Vector3(mx, mastH, mz),
        paint: EnvironmentPaints.mastPaint,
      ));
      lines.add(CachedLine(
        start: v64.Vector3(mx - 4.5, mastH, mz),
        end: v64.Vector3(mx + 4.5, mastH, mz),
        paint: EnvironmentPaints.mastCrossbar,
      ));
      for (double fx = mx - 4.0; fx <= mx + 4.0; fx += 2.6) {
        circles.add(CachedCircle(
          center: v64.Vector3(fx, mastH, mz),
          radius: 3.2,
          paint: EnvironmentPaints.mastBulb,
        ));
        circles.add(CachedCircle(
          center: v64.Vector3(fx, mastH, mz),
          radius: 1.8,
          paint: EnvironmentPaints.mastBulbWhite,
        ));
      }
    }

    addMast(fMinX - 8.0, fMaxZ + 4.0);
    addMast(fMaxX + 8.0, fMaxZ + 4.0);
  }
}
