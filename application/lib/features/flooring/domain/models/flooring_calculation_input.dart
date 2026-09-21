class FlooringCalculationInput {
  final double plotLength;
  final double plotWidth;
  final double carpetLength;
  final double carpetWidth;
  final bool? isRotated;

  const FlooringCalculationInput({
    required this.plotLength,
    required this.plotWidth,
    required this.carpetLength,
    required this.carpetWidth,
    this.isRotated,
  });

  bool get isValid =>
      _isValidDimension(plotLength) &&
      _isValidDimension(plotWidth) &&
      _isValidDimension(carpetLength) &&
      _isValidDimension(carpetWidth);

  static bool _isValidDimension(double v) =>
      v > 0 && !v.isNaN && !v.isInfinite;
}
