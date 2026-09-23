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

    final bool isSwapped = input.isRotated ?? false;

    // Default (Unswapped): tl along Length, tw along Width
    // Swapped (After clicking Swap): tw along Length, tl along Width
    final double orientedTableLength = isSwapped ? tw : tl;
    final double orientedTableWidth  = isSwapped ? tl : tw;

    final int tablesAlongLength = (sl / orientedTableLength).ceil();
    final int tablesAlongWidth  = (sw / orientedTableWidth).ceil();
    final int totalTables       = tablesAlongLength * tablesAlongWidth;

    final double coveredLength = tablesAlongLength * orientedTableLength;
    final double coveredWidth  = tablesAlongWidth  * orientedTableWidth;

    final List<StageTable> tables = [];
    int id = 0;

    // Row-by-row from top to bottom (Row 0: 1, 2, 3... Row 1: 4, 5, 6...)
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
