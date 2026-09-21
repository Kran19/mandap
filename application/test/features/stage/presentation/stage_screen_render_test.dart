import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/stage/presentation/stage_calculator_screen.dart';

void main() {
  testWidgets('StageCalculatorScreen renders full CAD UI with zero grey screen errors', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: StageCalculatorScreen(
          projectId: 'stage_test_1',
          initialLength: 32.0,
          initialWidth: 20.0,
          initialTableLength: 4.0,
          initialTableWidth: 8.0,
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify no grey screen (RenderCustomPaint is in tree, Scaffold is in tree)
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // Verify In-Model Dimension Badge text
    expect(find.textContaining('32/20 ft · 20 Tables'), findsOneWidget);

    // Verify Bottom Status Chip text
    expect(find.textContaining('32 × 20 ft · 20 tables'), findsOneWidget);

    // Verify Left Tool Rail with edit & cleaning icons
    expect(find.byIcon(Icons.edit_rounded), findsWidgets);
    expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);
  });

  testWidgets('StageCalculatorScreen swap button interchanges stage length and width live', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StageCalculatorScreen(
          projectId: 'stage_swap_test',
          initialLength: 32.0,
          initialWidth: 20.0,
          initialTableLength: 4.0,
          initialTableWidth: 8.0,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial dimensions
    expect(find.textContaining('32/20 ft'), findsOneWidget);

    // Tap Swap button in header bar
    final swapIcons = find.byIcon(Icons.swap_horiz_rounded);
    expect(swapIcons, findsWidgets);

    await tester.tap(swapIcons.first);
    await tester.pumpAndSettle();

    // Verify dimensions swapped to 20/32 ft
    expect(find.textContaining('20/32 ft'), findsOneWidget);
  });
}
