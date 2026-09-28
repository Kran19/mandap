import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import 'environment_geometry_cache.dart';

/// Renders the complete, immersive 3D Festival & Live Event Arena environment
/// powered by precomputed world-space geometry cache and pooled static Paint objects.
///
/// Guaranteed: Camera movement (orbit, pan, zoom) causes ZERO environment rebuilds.
class FestivalWorldEnvironment {
  static final Path _reusablePath = Path();

  static void paint({
    required Canvas canvas,
    required Size size,
    required Offset? Function(v64.Vector3) project,
    required v64.Vector3 eyePosition,
    required double plotWidth,
    required double plotDepth,
    double minX = 0.0,
    double minZ = 0.0,
  }) {
    final cache = EnvironmentGeometryCache.getOrCreate(
      minX: minX,
      minZ: minZ,
      plotWidth: plotWidth,
      plotDepth: plotDepth,
    );

    // 1. Quads (Ground, Turf, Stripes, Barriers, Screens, Canopies, Ramps, Booths)
    for (final q in cache.quads) {
      final p1 = project(q.v1);
      final p2 = project(q.v2);
      final p3 = project(q.v3);
      final p4 = project(q.v4);
      if (p1 == null || p2 == null || p3 == null || p4 == null) continue;

      _reusablePath.reset();
      _reusablePath.moveTo(p1.dx, p1.dy);
      _reusablePath.lineTo(p2.dx, p2.dy);
      _reusablePath.lineTo(p3.dx, p3.dy);
      _reusablePath.lineTo(p4.dx, p4.dy);
      _reusablePath.close();

      canvas.drawPath(_reusablePath, q.fill);
      if (q.stroke != null) canvas.drawPath(_reusablePath, q.stroke!);
    }

    // 2. Boxes (Stage Platform, Entrance Pylons, Arch Header, Campers, Tables, FOH Booth)
    for (final b in cache.boxes) {
      final projBase = b.base.map(project).toList();
      final projTop = b.top.map(project).toList();
      if (projBase.any((p) => p == null) || projTop.any((p) => p == null)) continue;

      final pb = projBase.cast<Offset>();
      final pt = projTop.cast<Offset>();

      void drawPoly(List<Offset> pts) {
        _reusablePath.reset();
        _reusablePath.moveTo(pts[0].dx, pts[0].dy);
        for (int i = 1; i < pts.length; i++) {
          _reusablePath.lineTo(pts[i].dx, pts[i].dy);
        }
        _reusablePath.close();
        canvas.drawPath(_reusablePath, b.fill);
        canvas.drawPath(_reusablePath, b.stroke);
      }

      drawPoly(pt);
      drawPoly(pb);
      if (b.drawSides) {
        for (int i = 0; i < 4; i++) {
          final next = (i + 1) % 4;
          drawPoly([pb[i], pb[next], pt[next], pt[i]]);
        }
      }
    }

    // 3. Polygons (Canopy gable peaks)
    for (final poly in cache.polys) {
      final pts = poly.points.map(project).toList();
      if (pts.any((p) => p == null)) continue;

      final offsets = pts.cast<Offset>();
      _reusablePath.reset();
      _reusablePath.moveTo(offsets[0].dx, offsets[0].dy);
      for (int i = 1; i < offsets.length; i++) {
        _reusablePath.lineTo(offsets[i].dx, offsets[i].dy);
      }
      _reusablePath.close();

      canvas.drawPath(_reusablePath, poly.fill);
      if (poly.stroke != null) canvas.drawPath(_reusablePath, poly.stroke!);
    }

    // 4. Lines (Rails, Posts, Speaker Arrays, Festoon Cables, Floodlight Masts)
    for (final l in cache.lines) {
      final p1 = project(l.start);
      final p2 = project(l.end);
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, l.paint);
      }
    }

    // 5. Circles (Wheels, Bulbs, Speaker Nodes)
    for (final c in cache.circles) {
      final pt = project(c.center);
      if (pt != null) {
        canvas.drawCircle(pt, c.radius, c.paint);
      }
    }
  }
}
