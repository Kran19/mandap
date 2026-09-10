class StageCalculationInput {
  final double stageLength;
  final double stageWidth;
  final double stageHeight;
  final double tableLength;
  final double tableWidth;

  const StageCalculationInput({
    required this.stageLength,
    required this.stageWidth,
    required this.stageHeight,
    required this.tableLength,
    required this.tableWidth,
  });

  bool get isValid =>
      _isValidDimension(stageLength) &&
      _isValidDimension(stageWidth) &&
      _isValidDimension(stageHeight) &&
      _isValidDimension(tableLength) &&
      _isValidDimension(tableWidth);

  static bool _isValidDimension(double v) =>
      v > 0 && !v.isNaN && !v.isInfinite;
}
