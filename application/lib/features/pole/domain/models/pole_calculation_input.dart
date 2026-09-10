class PoleCalculationInput {
  final double plotLength;
  final double plotWidth;
  final double poleSize;

  const PoleCalculationInput({
    required this.plotLength,
    required this.plotWidth,
    this.poleSize = 15.0,
  });

  bool get isValid => 
      plotLength > 0 && 
      plotWidth > 0 && 
      poleSize > 0 &&
      !plotLength.isNaN && 
      !plotWidth.isNaN && 
      !poleSize.isNaN &&
      !plotLength.isInfinite && 
      !plotWidth.isInfinite &&
      !poleSize.isInfinite;
}
