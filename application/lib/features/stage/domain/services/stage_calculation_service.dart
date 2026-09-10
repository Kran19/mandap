import 'dart:math';
import '../models/stage_calculation_input.dart';
import '../models/stage_calculation_result.dart';
import '../models/stage_table.dart';

class StageCalculationService {
  const StageCalculationService();

  StageCalculationResult calculate(StageCalculationInput input) {
    if (!input.isValid) {
      throw ArgumentError(
        'Invalid stage input: all dimensions must be positive finite numbers.',
      );
    }

    final double sl = input.stageLength;
    final double sw = input.stageWidth;
    final double sh = input.stageHeight;
    final double tl = input.tableLength;
    final double tw = input.tableWidth;

    // --- Evaluate Orientation A (no rotation) ---
    final int aAlongLength = (sl / tl).ceil();
    final int aAlongWidth  = (sw / tw).ceil();
    final int aTotal       = aAlongLength * aAlongWidth;

    // --- Evaluate Orientation B (table rotated 90 degrees) ---
    final int bAlongLength = (sl / tw).ceil();
    final int bAlongWidth  = (sw / tl).ceil();
    final int bTotal       = bAlongLength * bAlongWidth;

    // --- Choose orientation with fewer tables; A wins on tie ---
    final bool useB = bTotal < aTotal;

    final int   tablesAlongLength   = useB ? bAlongLength : aAlongLength;
    final int   tablesAlongWidth    = useB ? bAlongWidth  : aAlongWidth;
    final int   totalTables         = useB ? bTotal       : aTotal;
    final double orientedTableLength = useB ? tw           : tl; // along stage length
    final double orientedTableWidth  = useB ? tl           : tw; // along stage width

    final double coveredLength = tablesAlongLength * orientedTableLength;
    final double coveredWidth  = tablesAlongWidth  * orientedTableWidth;

    // --- Generate individual table layout ---
    final List<StageTable> tables = [];
    int id = 0;
    for (int row = 0; row < tablesAlongWidth; row++) {
      for (int col = 0; col < tablesAlongLength; col++) {
        tables.add(StageTable(
          id:    id++,
          x:     col * orientedTableLength,
          z:     row * orientedTableWidth,
          width: orientedTableLength,
          depth: orientedTableWidth,
        ));
      }
    }

    // Sanity check
    assert(tables.length == totalTables,
        'Generated ${tables.length} tables but expected $totalTables');

    return StageCalculationResult(
      stageLength:         sl,
      stageWidth:          sw,
      stageHeight:         sh,
      tableLength:         tl,
      tableWidth:          tw,
      orientedTableLength: orientedTableLength,
      orientedTableWidth:  orientedTableWidth,
      tablesAlongLength:   tablesAlongLength,
      tablesAlongWidth:    tablesAlongWidth,
      totalTables:         totalTables,
      coveredLength:       coveredLength,
      coveredWidth:        coveredWidth,
      tableLayoutPoints:   List.unmodifiable(tables),
    );
  }
}
