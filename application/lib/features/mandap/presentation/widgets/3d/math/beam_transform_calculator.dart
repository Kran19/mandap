import 'dart:math' as math;
import 'package:vector_math/vector_math_64.dart' as v64;
import '../../../../domain/entities/mandap_node.dart';
import 'beam_transform.dart';

/// Pure math calculator for computing 3D beam spatial transforms.
class BeamTransformCalculator {
  /// Default visual height of the Mandap top structure above ground level (in feet).
  static const double defaultMandapHeightFeet = 10.0;

  /// Calculates a [BeamTransform] given two domain [MandapNode] endpoints.
  static BeamTransform calculate({
    required MandapNode startNode,
    required MandapNode endNode,
    double height = defaultMandapHeightFeet,
  }) {
    final start = v64.Vector3(startNode.x, height, startNode.z);
    final end = v64.Vector3(endNode.x, height, endNode.z);

    final diff = end - start;
    final length = diff.length;

    final direction = length > 1e-6
        ? (diff / length)
        : v64.Vector3(1.0, 0.0, 0.0);

    final center = v64.Vector3(
      (startNode.x + endNode.x) / 2.0,
      height,
      (startNode.z + endNode.z) / 2.0,
    );

    // Azimuth angle on X-Z plane relative to +X axis
    final dx = endNode.x - startNode.x;
    final dz = endNode.z - startNode.z;
    final azimuthAngle = math.atan2(dz, dx);

    return BeamTransform(
      center: center,
      start: start,
      end: end,
      length: length,
      direction: direction,
      azimuthAngle: azimuthAngle,
    );
  }
}
