import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/flooring/presentation/flooring_calculator_screen.dart';
import 'package:mandap/features/flooring/presentation/widgets/create_flooring_dialog.dart';

Widget createFlooringTestSurface({
  double? length,
  double? width,
  double? carpetLength,
  double? carpetWidth,
}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: FlooringCalculatorScreen(
      initialLength: length ?? 100.0,
      initialWidth: width ?? 60.0,
      initialCarpetLength: carpetLength ?? 12.0,
      initialCarpetWidth: carpetWidth ?? 6.0,
    ),
  );
}

void main() {
  group('Flooring CAD Screen Responsive UI Verification (No Overflow Allowed)', () {
    testWidgets('Renders cleanly at 360 x 800 (Compact Android Phone)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createFlooringTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 390 x 844 (Standard Phone)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createFlooringTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 412 x 915 (Large Phone)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createFlooringTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 1024 x 768 (Desktop/Tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createFlooringTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Flooring CAD Editor UI Components & Interaction Verification', () {
    testWidgets('Verify Header, Dimensions Badge, Tool Rail, and Status Chip', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createFlooringTestSurface(length: 100.0, width: 60.0));
      await tester.pump();
      await tester.pumpAndSettle();

      // Header buttons
      expect(find.byIcon(Icons.meeting_room_outlined), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.save_rounded), findsOneWidget);
      expect(find.text('2D'), findsOneWidget);
      expect(find.text('3D'), findsOneWidget);

      // In-model dimension badge displays total carpets (85 for 100x60 with 12x6 carpets)
      expect(find.text('100/60 ft · 85 Carpets'), findsOneWidget);

      // Left floating tool rail has Pencil and Eraser
      expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);

      expect(tester.takeException(), isNull, reason: 'Overflow occurred on initial build');

      // Tap Save button -> shows "Project saved successfully!"
      await tester.tap(find.byIcon(Icons.save_rounded));
      await tester.pump();
      expect(find.text('Project saved successfully!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));

      // Switch to 2D
      await tester.tap(find.text('2D'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch back to 3D
      await tester.tap(find.text('3D'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('CreateFlooringDialog swap buttons interchange plot and carpet dimensions', (tester) async {
      FlooringConfigurationParams? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                captured = await CreateFlooringDialog.show(
                  context,
                  initialPlotLength: 80.0,
                  initialPlotWidth: 40.0,
                  initialCarpetLength: 10.0,
                  initialCarpetWidth: 5.0,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Find swap buttons / badges
      final swapBadges = find.text('Swap L ⇄ W');
      expect(swapBadges, findsNWidgets(2));

      // Tap plot swap button
      await tester.tap(swapBadges.first);
      await tester.pumpAndSettle();

      // Tap carpet swap button
      await tester.tap(swapBadges.last);
      await tester.pumpAndSettle();

      // Tap Generate
      await tester.tap(find.text('GENERATE 3D MODEL'));
      await tester.pumpAndSettle();

      expect(captured, isNotNull);
      expect(captured!.plotLength, 40.0);
      expect(captured!.plotWidth, 80.0);
      expect(captured!.carpetLength, 5.0);
      expect(captured!.carpetWidth, 10.0);
    });

    testWidgets('FlooringCalculatorScreen swap button interchanges plot length and width live', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FlooringCalculatorScreen(
            projectId: 'swap_test',
            initialLength: 100.0,
            initialWidth: 60.0,
            initialCarpetLength: 12.0,
            initialCarpetWidth: 6.0,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify initial dimensions
      expect(find.textContaining('100/60 ft'), findsOneWidget);

      // Tap Swap button in header bar
      final swapIcons = find.byIcon(Icons.swap_horiz_rounded);
      expect(swapIcons, findsWidgets);

      await tester.tap(swapIcons.first);
      await tester.pumpAndSettle();

      // Verify dimensions swapped to 60/100 ft
      expect(find.textContaining('60/100 ft'), findsOneWidget);
    });
  });
}
