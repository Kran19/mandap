import 'dart:math' as math;

import 'package:flutter/painting.dart';

import '../application/coordinate_transform.dart';
import '../domain/entities/mandap_layout.dart';

/// Manages the 2D editor world↔screen coordinate mapping.
///
/// The world coordinate system is in feet (X right, Z down).
/// Screen coordinates are in logical pixels.
///
/// Transform:  screenX = worldX * scale + panX
///             screenY = worldZ * scale + panY
class ViewportTransform {
  final double scale;
  final double panX;
  final double panY;

  /// Minimum scale (zoom-out limit): 2 px/ft.
  static const double minScale = 2.0;

  /// Maximum scale (zoom-in limit): 60 px/ft.
  static const double maxScale = 60.0;

  const ViewportTransform({
    required this.scale,
    required this.panX,
    required this.panY,
  });

  /// Default transform: fits a 40×30 ft layout in a 400×300 canvas with 40px padding.
  factory ViewportTransform.defaultTransform() {
    return const ViewportTransform(scale: 8.0, panX: 40.0, panY: 40.0);
  }

  // ── Coordinate conversion ─────────────────────────────────────────────────

  /// Converts a world position [wx], [wz] to a screen [Offset].
  Offset worldToScreen(double wx, double wz) {
    return CoordinateTransform.worldToCanvas(
      worldX: wx,
      worldZ: wz,
      scale: scale,
      panX: panX,
      panY: panY,
    );
  }

  /// Converts a screen [Offset] to world coordinates (feet).
  ({double x, double z}) screenToWorld(Offset screen) {
    return CoordinateTransform.canvasToWorld(
      screenPoint: screen,
      scale: scale,
      panX: panX,
      panY: panY,
    );
  }

  /// Snaps a world coordinate pair to the nearest grid increment.
  ({double x, double z}) snapToGrid(double wx, double wz, {double gridSpacing = 0.5}) {
    return (
      x: CoordinateTransform.snapToGrid(wx, gridSpacing),
      z: CoordinateTransform.snapToGrid(wz, gridSpacing),
    );
  }

  // ── Pan & Zoom ────────────────────────────────────────────────────────────

  /// Returns a new transform panned by [dx], [dy] screen pixels.
  ViewportTransform pan(double dx, double dy) {
    return ViewportTransform(scale: scale, panX: panX + dx, panY: panY + dy);
  }

  /// Returns a new transform zoomed by [factor] around screen focus point [focus].
  ViewportTransform zoom(double factor, Offset focus) {
    final newScale = (scale * factor).clamp(minScale, maxScale);
    if (newScale == scale) return this;

    final ratio = newScale / scale;
    return ViewportTransform(
      scale: newScale,
      panX: focus.dx - (focus.dx - panX) * ratio,
      panY: focus.dy - (focus.dy - panY) * ratio,
    );
  }

  // ── Fit to content ────────────────────────────────────────────────────────

  /// Returns a new transform that fits [layout] within [canvasSize] with [padding].
  factory ViewportTransform.fitToLayout({
    required MandapLayout layout,
    required Size canvasSize,
    double padding = 48.0,
  }) {
    if (layout.nodes.isEmpty) return ViewportTransform.defaultTransform();

    var minX = double.infinity, maxX = -double.infinity;
    var minZ = double.infinity, maxZ = -double.infinity;

    for (final node in layout.nodes.values) {
      if (node.x < minX) minX = node.x;
      if (node.x > maxX) maxX = node.x;
      if (node.z < minZ) minZ = node.z;
      if (node.z > maxZ) maxZ = node.z;
    }

    final contentW = (maxX - minX).clamp(1.0, double.infinity);
    final contentH = (maxZ - minZ).clamp(1.0, double.infinity);

    final availW = canvasSize.width - padding * 2;
    final availH = canvasSize.height - padding * 2;

    final scaleX = availW / contentW;
    final scaleZ = availH / contentH;
    final newScale = (scaleX < scaleZ ? scaleX : scaleZ)
        .clamp(minScale, maxScale)
        .toDouble();

    final panX = (canvasSize.width - contentW * newScale) / 2 - minX * newScale;
    final panY =
        (canvasSize.height - contentH * newScale) / 2 - minZ * newScale;

    return ViewportTransform(scale: newScale, panX: panX, panY: panY);
  }

  // ── Hit testing ───────────────────────────────────────────────────────────

  /// Returns true if [screenPoint] is within [radiusPx] of world point ([wx], [wz]).
  bool hitTestNode(
    Offset screenPoint,
    double wx,
    double wz, {
    double radiusPx = 16.0,
  }) {
    final sp = worldToScreen(wx, wz);
    final dx = screenPoint.dx - sp.dx;
    final dy = screenPoint.dy - sp.dy;
    return dx * dx + dy * dy <= radiusPx * radiusPx;
  }

  /// Returns true if [screenPoint] is within [tolerancePx] of the screen segment
  /// from world ([x1],[z1]) to ([x2],[z2]).
  bool hitTestEdge(
    Offset screenPoint,
    double x1,
    double z1,
    double x2,
    double z2, {
    double tolerancePx = 12.0,
  }) {
    final a = worldToScreen(x1, z1);
    final b = worldToScreen(x2, z2);
    final dist = _pointToSegmentDistance(screenPoint, a, b);
    return dist <= tolerancePx;
  }

  static double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final abX = b.dx - a.dx;
    final abY = b.dy - a.dy;
    final len2 = abX * abX + abY * abY;
    if (len2 == 0) {
      final dx = p.dx - a.dx;
      final dy = p.dy - a.dy;
      return math.sqrt(dx * dx + dy * dy);
    }
    final t = ((p.dx - a.dx) * abX + (p.dy - a.dy) * abY) / len2;
    final tc = t.clamp(0.0, 1.0);
    final projX = a.dx + tc * abX;
    final projY = a.dy + tc * abY;
    final dx = p.dx - projX;
    final dy = p.dy - projY;
    return math.sqrt(dx * dx + dy * dy);
  }
}
