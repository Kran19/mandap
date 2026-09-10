import 'stage_table.dart';

class StageCalculationResult {
  // User inputs echoed back
  final double stageLength;
  final double stageWidth;
  final double stageHeight;
  final double tableLength;
  final double tableWidth;

  // Chosen orientation after evaluating both A and B
  final double orientedTableLength; // dimension along stage length axis
  final double orientedTableWidth;  // dimension along stage width axis

  // Grid counts
  final int tablesAlongLength;
  final int tablesAlongWidth;
  final int totalTables;

  // Actual physical coverage (may exceed requested stage size due to ceil)
  final double coveredLength;
  final double coveredWidth;

  // Individual table objects in world-space
  final List<StageTable> tableLayoutPoints;

  const StageCalculationResult({
    required this.stageLength,
    required this.stageWidth,
    required this.stageHeight,
    required this.tableLength,
    required this.tableWidth,
    required this.orientedTableLength,
    required this.orientedTableWidth,
    required this.tablesAlongLength,
    required this.tablesAlongWidth,
    required this.totalTables,
    required this.coveredLength,
    required this.coveredWidth,
    required this.tableLayoutPoints,
  });
}
