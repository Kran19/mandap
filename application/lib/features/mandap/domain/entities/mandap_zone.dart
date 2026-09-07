import 'package:flutter/foundation.dart';

enum ZoneType {
  flooring,
  stage,
}

@immutable
class MandapZone {
  final String id;
  final ZoneType type;
  
  // Coordinates are in grid space (feet).
  // A rectangle is defined by top-left (x1, y1) and bottom-right (x2, y2)
  final double x1;
  final double y1;
  final double x2;
  final double y2;

  const MandapZone({
    required this.id,
    required this.type,
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  /// Width in feet
  double get width => (x2 - x1).abs();
  
  /// Height in feet
  double get height => (y2 - y1).abs();

  /// Normalized top-left x
  double get left => x1 < x2 ? x1 : x2;

  /// Normalized top-left y
  double get top => y1 < y2 ? y1 : y2;

  /// Normalized bottom-right x
  double get right => x1 > x2 ? x1 : x2;

  /// Normalized bottom-right y
  double get bottom => y1 > y2 ? y1 : y2;

  MandapZone copyWith({
    String? id,
    ZoneType? type,
    double? x1,
    double? y1,
    double? x2,
    double? y2,
  }) {
    return MandapZone(
      id: id ?? this.id,
      type: type ?? this.type,
      x1: x1 ?? this.x1,
      y1: y1 ?? this.y1,
      x2: x2 ?? this.x2,
      y2: y2 ?? this.y2,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'x1': x1,
      'y1': y1,
      'x2': x2,
      'y2': y2,
    };
  }

  factory MandapZone.fromJson(Map<String, dynamic> json) {
    return MandapZone(
      id: json['id'] as String,
      type: ZoneType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ZoneType.flooring,
      ),
      x1: (json['x1'] as num).toDouble(),
      y1: (json['y1'] as num).toDouble(),
      x2: (json['x2'] as num).toDouble(),
      y2: (json['y2'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MandapZone &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          x1 == other.x1 &&
          y1 == other.y1 &&
          x2 == other.x2 &&
          y2 == other.y2;

  @override
  int get hashCode =>
      id.hashCode ^
      type.hashCode ^
      x1.hashCode ^
      y1.hashCode ^
      x2.hashCode ^
      y2.hashCode;
}
