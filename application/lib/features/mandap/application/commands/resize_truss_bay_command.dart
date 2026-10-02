import 'dart:math' as math;
import '../../domain/entities/mandap_layout.dart';
import '../../domain/entities/mandap_node.dart';
import '../../domain/entities/node_id.dart';
import '../../domain/entities/truss_bay.dart';
import '../../domain/services/truss_bay_detector.dart';
import 'mandap_command.dart';

/// Command to resize a selected [TrussBay] along its X (width) and/or Z (length) axes
/// by redistributing adjacent boundary partitions while strictly preserving outer plot boundaries.
class ResizeTrussBayCommand implements MandapCommand {
  final String bayId;
  final double? targetWidthFt;
  final double? targetLengthFt;
  final double minimumBayDimension;
  final bool preserveOuterBoundaries;

  MandapLayout? _previousLayout;
  MandapLayout? _updatedLayout;
  bool _executed = false;

  ResizeTrussBayCommand({
    required this.bayId,
    this.targetWidthFt,
    this.targetLengthFt,
    this.minimumBayDimension = 1.0,
    this.preserveOuterBoundaries = false,
  });

  @override
  String get description => 'Resize truss bay $bayId';

  @override
  MandapLayout execute(MandapLayout currentLayout) {
    _previousLayout ??= currentLayout;
    if (_executed && _updatedLayout != null) {
      return _updatedLayout!;
    }

    const detector = TrussBayDetector();
    final bays = detector.detectBays(currentLayout);
    final bayIndex = bays.indexWhere((b) => b.id == bayId);
    if (bayIndex == -1) {
      throw StateError('Bay with ID "$bayId" not found in layout.');
    }

    final bay = bays[bayIndex];
    if (bay.hasInternalMembers) {
      throw StateError('This bay contains internal structure and cannot be resized.');
    }

    // Extract all unique X and Z coordinate boundaries from the detected bays
    final xSet = <double>{};
    final zSet = <double>{};
    for (final b in bays) {
      xSet.add(b.minX);
      xSet.add(b.maxX);
      zSet.add(b.minZ);
      zSet.add(b.maxZ);
    }
    var xBoundaries = _extractBoundaries(xSet.toList());
    var zBoundaries = _extractBoundaries(zSet.toList());

    final elevatedNodes = currentLayout.nodes.values.where((n) => n.elevation > 0.1).toList();
    final candidateNodes = elevatedNodes.isNotEmpty ? elevatedNodes : currentLayout.nodes.values.toList();
    final allXBoundaries = _extractBoundaries(candidateNodes.map((n) => n.x).toList());
    final allZBoundaries = _extractBoundaries(candidateNodes.map((n) => n.z).toList());

    final xReplacements = <double, double>{};
    final zReplacements = <double, double>{};

    final isReset = targetWidthFt == null && targetLengthFt == null;

    final numColumns = bays.map((b) => b.columnIndex).toSet().length;
    final numRows = bays.map((b) => b.rowIndex).toSet().length;
    final totalWidth = xBoundaries.last - xBoundaries.first;
    final totalLength = zBoundaries.last - zBoundaries.first;

    final effectiveTargetWidth = isReset
        ? (numColumns > 0 ? (totalWidth / numColumns) : totalWidth)
        : targetWidthFt;
    final effectiveTargetLength = isReset
        ? (numRows > 0 ? (totalLength / numRows) : totalLength)
        : targetLengthFt;

    final xPartitionCount = math.max(xBoundaries.length - 1, (totalWidth / 30.0).ceil());
    final zPartitionCount = math.max(zBoundaries.length - 1, (totalLength / 30.0).ceil());

    // 1. Process X axis (Width) resize
    if (effectiveTargetWidth != null && (effectiveTargetWidth - bay.widthFt).abs() > 0.01) {
      final newX = _redistributePartition(
        boundaries: xBoundaries,
        bayIndex: bay.columnIndex,
        targetSize: effectiveTargetWidth,
        minSize: minimumBayDimension,
        totalPartitionsCount: xPartitionCount,
        preserveOuterBoundaries: preserveOuterBoundaries,
      );
      for (int i = 0; i < xBoundaries.length; i++) {
        if ((xBoundaries[i] - newX[i]).abs() > 0.001) {
          xReplacements[xBoundaries[i]] = newX[i];
        }
      }
      xBoundaries = newX;
    }

    // 2. Process Z axis (Length) resize
    if (effectiveTargetLength != null && (effectiveTargetLength - bay.lengthFt).abs() > 0.01) {
      final newZ = _redistributePartition(
        boundaries: zBoundaries,
        bayIndex: bay.rowIndex,
        targetSize: effectiveTargetLength,
        minSize: minimumBayDimension,
        totalPartitionsCount: zPartitionCount,
        preserveOuterBoundaries: preserveOuterBoundaries,
      );
      for (int i = 0; i < zBoundaries.length; i++) {
        if ((zBoundaries[i] - newZ[i]).abs() > 0.001) {
          zReplacements[zBoundaries[i]] = newZ[i];
        }
      }
      zBoundaries = newZ;
    }

    if (xReplacements.isEmpty && zReplacements.isEmpty) {
      _updatedLayout = currentLayout;
      _executed = true;
      return currentLayout;
    }

    // 3. Mutate nodes in layout with X/Z synchronization and strictly preserved Y elevation
    final updatedNodes = <NodeId, MandapNode>{};

    double mapCoordinate(double currentVal, List<double> oldBoundaries, List<double> newBoundaries) {
      if (oldBoundaries.length < 2 || oldBoundaries.length != newBoundaries.length) {
        return currentVal;
      }
      for (int i = 0; i < oldBoundaries.length; i++) {
        if ((currentVal - oldBoundaries[i]).abs() < 0.25) {
          return newBoundaries[i];
        }
      }
      if (currentVal <= oldBoundaries.first) {
        return newBoundaries.first + (currentVal - oldBoundaries.first);
      }
      if (currentVal >= oldBoundaries.last) {
        return newBoundaries.last + (currentVal - oldBoundaries.last);
      }
      for (int i = 0; i < oldBoundaries.length - 1; i++) {
        final b1 = oldBoundaries[i];
        final b2 = oldBoundaries[i + 1];
        if (currentVal >= b1 && currentVal <= b2) {
          final spanOld = b2 - b1;
          if (spanOld.abs() < 0.001) return newBoundaries[i];
          final t = (currentVal - b1) / spanOld;
          final b1New = newBoundaries[i];
          final b2New = newBoundaries[i + 1];
          return b1New + t * (b2New - b1New);
        }
      }
      return currentVal;
    }

    for (final entry in currentLayout.nodes.entries) {
      final node = entry.value;
      final newX = xReplacements.isNotEmpty ? mapCoordinate(node.x, xSet.toList()..sort(), xBoundaries) : node.x;
      final newZ = zReplacements.isNotEmpty ? mapCoordinate(node.z, zSet.toList()..sort(), zBoundaries) : node.z;

      if ((newX - node.x).abs() > 0.001 || (newZ - node.z).abs() > 0.001) {
        updatedNodes[entry.key] = node.copyWith(
          x: double.parse(newX.toStringAsFixed(4)),
          z: double.parse(newZ.toStringAsFixed(4)),
          elevation: node.elevation,
          height: node.height,
        );
      } else {
        updatedNodes[entry.key] = node;
      }
    }

    _updatedLayout = MandapLayout(
      nodes: Map.unmodifiable(updatedNodes),
      edges: currentLayout.edges,
      zones: currentLayout.zones,
    );
    _executed = true;
    return _updatedLayout!;
  }

  @override
  MandapLayout undo(MandapLayout currentLayout) {
    if (!_executed || _previousLayout == null) return currentLayout;
    return _previousLayout!;
  }

  MandapLayout redo(MandapLayout currentLayout) {
    if (!_executed || _updatedLayout == null) return currentLayout;
    return _updatedLayout!;
  }

  static List<double> _extractBoundaries(List<double> values, [double tolerance = 0.25]) {
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

  /// Redistributes partition boundaries deterministically when [bayIndex] changes to [targetSize].
  static List<double> _redistributePartition({
    required List<double> boundaries,
    required int bayIndex,
    required double targetSize,
    required double minSize,
    int? totalPartitionsCount,
    bool preserveOuterBoundaries = false,
  }) {
    final numPartitions = boundaries.length - 1;
    if (bayIndex < 0 || bayIndex >= numPartitions) {
      throw ArgumentError('Invalid bay index $bayIndex for ${boundaries.length} boundaries.');
    }

    if (targetSize < minSize) {
      throw ArgumentError(
        'Requested size (${targetSize.toStringAsFixed(1)} ft) is below minimum allowed ($minSize ft).',
      );
    }

    // Convert boundaries to individual partition interval lengths
    final sizes = <double>[];
    for (int i = 0; i < numPartitions; i++) {
      sizes.add(boundaries[i + 1] - boundaries[i]);
    }

    final currentSize = sizes[bayIndex];
    final delta = targetSize - currentSize;
    if (delta.abs() < 0.001) return boundaries;

    final canPreserveOuter = preserveOuterBoundaries && numPartitions > 1;

    if (canPreserveOuter) {
      final totalPlot = boundaries.last - boundaries.first;
      final otherPartitionsCount = (totalPartitionsCount != null && totalPartitionsCount > numPartitions)
          ? (totalPartitionsCount - 1)
          : (numPartitions - 1);
      final maxAvailable = totalPlot - (otherPartitionsCount * minSize);

      if (targetSize > maxAvailable) {
        throw ArgumentError(
          'Requested size (${targetSize.toStringAsFixed(1)} ft) exceeds maximum available for this layout (${maxAvailable.toStringAsFixed(1)} ft).',
        );
      }

      sizes[bayIndex] = targetSize;
      double deficit = delta;

      if (deficit > 0) {
        // Bay grows: absorb length from immediate right neighbor(s) first
        for (int i = bayIndex + 1; i < numPartitions && deficit > 0.001; i++) {
          final available = sizes[i] - minSize;
          if (available > 0) {
            final take = available < deficit ? available : deficit;
            sizes[i] -= take;
            deficit -= take;
          }
        }
        // If right neighbors are exhausted, absorb from left neighbor(s)
        for (int i = bayIndex - 1; i >= 0 && deficit > 0.001; i--) {
          final available = sizes[i] - minSize;
          if (available > 0) {
            final take = available < deficit ? available : deficit;
            sizes[i] -= take;
            deficit -= take;
          }
        }
      } else {
        // Bay shrinks: expand immediate right neighbor first, or left if at the end
        double surplus = -deficit;
        if (bayIndex + 1 < numPartitions) {
          sizes[bayIndex + 1] += surplus;
          surplus = 0;
        } else if (bayIndex - 1 >= 0) {
          sizes[bayIndex - 1] += surplus;
          surplus = 0;
        }
      }

      if (deficit > 0.01) {
        throw StateError('Cannot satisfy requested resize without violating minimum bay sizes.');
      }
    } else {
      // Direct resize: update target bay size and shift structure size
      sizes[bayIndex] = targetSize;
    }

    // Reconstruct new boundaries from partition sizes starting from boundaries.first
    final newBoundaries = <double>[boundaries.first];
    for (int i = 0; i < sizes.length; i++) {
      newBoundaries.add(newBoundaries.last + sizes[i]);
    }

    if (canPreserveOuter) {
      if ((newBoundaries.first - boundaries.first).abs() > 0.001 ||
          (newBoundaries.last - boundaries.last).abs() > 0.001) {
        throw StateError('Partition redistribution violated outer plot boundary constraint.');
      }
    }

    for (int i = 0; i < newBoundaries.length - 1; i++) {
      if (newBoundaries[i + 1] - newBoundaries[i] < (minSize - 0.001)) {
        throw StateError('Partition size fell below minimum threshold.');
      }
    }

    return newBoundaries;
  }
}
