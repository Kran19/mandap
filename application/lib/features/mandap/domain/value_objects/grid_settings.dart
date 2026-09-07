class GridSettings {
  /// Whether the grid is visibly drawn.
  final bool enabled;

  /// Whether objects snap to the grid during movement/resizing.
  final bool snapEnabled;

  /// The major grid line spacing (e.g., 1.0 ft or 10.0 ft).
  final double majorSpacing;

  /// The minor grid line subdivision spacing (e.g., 0.1 ft or 1.0 ft).
  final double minorSpacing;

  /// The X coordinate offset of the grid origin.
  final double originX;

  /// The Z coordinate offset of the grid origin.
  final double originZ;

  /// Number of decimal places to display in coordinate labels.
  final int displayPrecision;

  const GridSettings({
    this.enabled = true,
    this.snapEnabled = true,
    this.majorSpacing = 1.0,
    this.minorSpacing = 0.1,
    this.originX = 0.0,
    this.originZ = 0.0,
    this.displayPrecision = 2,
  });

  /// The default precision engineering grid settings.
  factory GridSettings.defaultSettings() {
    return const GridSettings(
      enabled: true,
      snapEnabled: true,
      majorSpacing: 1.0,
      minorSpacing: 0.1,
      displayPrecision: 2,
    );
  }

  GridSettings copyWith({
    bool? enabled,
    bool? snapEnabled,
    double? majorSpacing,
    double? minorSpacing,
    double? originX,
    double? originZ,
    int? displayPrecision,
  }) {
    return GridSettings(
      enabled: enabled ?? this.enabled,
      snapEnabled: snapEnabled ?? this.snapEnabled,
      majorSpacing: majorSpacing ?? this.majorSpacing,
      minorSpacing: minorSpacing ?? this.minorSpacing,
      originX: originX ?? this.originX,
      originZ: originZ ?? this.originZ,
      displayPrecision: displayPrecision ?? this.displayPrecision,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridSettings &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          snapEnabled == other.snapEnabled &&
          majorSpacing == other.majorSpacing &&
          minorSpacing == other.minorSpacing &&
          originX == other.originX &&
          originZ == other.originZ &&
          displayPrecision == other.displayPrecision;

  @override
  int get hashCode =>
      enabled.hashCode ^
      snapEnabled.hashCode ^
      majorSpacing.hashCode ^
      minorSpacing.hashCode ^
      originX.hashCode ^
      originZ.hashCode ^
      displayPrecision.hashCode;
}
