import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/pole/presentation/pole_calculator_screen.dart';
import 'package:mandap/features/pole/presentation/widgets/create_pole_dialog.dart';

Widget createPoleTestSurface({double? length, double? width, double? pipeSize}) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    home: PoleCalculatorScreen(
      initialLength: length ?? 100.0,
      initialWidth: width ?? 100.0,
      initialPipeSize: pipeSize ?? 15.0,
    ),
  );
}

void main() {
  group('Pole CAD Screen Responsive UI Verification (No Overflow Allowed)', () {
    testWidgets('Renders cleanly at 360 x 800 (Compact Android Phone)', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createPoleTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 390 x 844 (Standard Phone)', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createPoleTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 412 x 915 (Large Phone)', (tester) async {
      tester.view.physicalSize = const Size(412, 915);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createPoleTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('Renders cleanly at 1024 x 768 (Desktop/Tablet)', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createPoleTestSurface());
      await tester.pump();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Pole CAD Editor UI Components & Interaction Verification', () {
    testWidgets('Verify Header, Dimensions Badge, Tool Rail, and Pole Summary Chip', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(createPoleTestSurface(length: 100.0, width: 100.0, pipeSize: 15.0));
      await tester.pump();
      await tester.pumpAndSettle();

      // Header buttons
      expect(find.byIcon(Icons.meeting_room_outlined), findsOneWidget);
      expect(find.byIcon(Icons.undo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.redo_rounded), findsOneWidget);
      expect(find.byIcon(Icons.save_rounded), findsOneWidget);
      expect(find.text('2D'), findsOneWidget);
      expect(find.text('3D'), findsOneWidget);

      // In-model dimension badge
      expect(find.text('100/100 ft · 15 ft'), findsOneWidget);

      // Top-center Pipes Breakdown Badge (in green marked box area)
      expect(find.text('Poles'), findsOneWidget);
      expect(find.text('Upper Pipes'), findsOneWidget);
      expect(find.text('Total Pipes'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
      expect(find.text('112'), findsOneWidget);
      expect(find.text('176'), findsOneWidget);
      expect(find.byIcon(Icons.all_inbox_rounded), findsOneWidget);

      // Left floating tool rail has strictly Pencil and Eraser
      expect(find.byIcon(Icons.cleaning_services_rounded), findsOneWidget);

      expect(tester.takeException(), isNull, reason: 'Overflow occurred on initial build');

      // Tap Save button -> shows "Project saved successfully!"
      await tester.tap(find.byIcon(Icons.save_rounded));
      await tester.pump();
      expect(find.text('Project saved successfully!'), findsOneWidget);

      await tester.pump(const Duration(seconds: 3));

      expect(tester.takeException(), isNull);
    });

    testWidgets('CreatePoleDialog parses input and returns valid configuration', (tester) async {
      late CreatePoleConfig? resultConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                resultConfig = await CreatePoleDialog.show(
                  context,
                  initialLength: 100,
                  initialWidth: 100,
                  initialPipeSize: 15,
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('CREATE PIPE STRUCTURE'), findsOneWidget);
      expect(find.text('GENERATE 3D MODEL'), findsOneWidget);

      // Submit
      await tester.tap(find.text('GENERATE 3D MODEL'));
      await tester.pumpAndSettle();

      expect(resultConfig, isNotNull);
      expect(resultConfig!.plotLength, 100.0);
      expect(resultConfig!.plotWidth, 100.0);
      expect(resultConfig!.pipeSize, 15.0);
    });
  });
}
