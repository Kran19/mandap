/// Approved Truss Sizes in MANDAP BUILDER.
enum TrussSize {
  ten(10.0, '10 ft'),
  twenty(20.0, '20 ft'),
  twentyFive(25.0, '25 ft'),
  thirty(30.0, '30 ft'),
  forty(40.0, '40 ft'),
  fifty(50.0, '50 ft'),
  custom(0.0, 'Custom');

  final double spanInFeet;
  final String label;

  const TrussSize(this.spanInFeet, this.label);

  static TrussSize fromLength(double length) {
    for (final size in TrussSize.values) {
      if (size == TrussSize.custom) continue;
      if ((size.spanInFeet - length).abs() < 0.01) {
        return size;
      }
    }
    return TrussSize.custom;
  }
}

