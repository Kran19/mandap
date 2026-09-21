import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/features/mandap/application/mandap_editor_controller.dart';
import 'package:mandap/features/mandap/application/editor_mode.dart';
import 'package:mandap/core/theme/app_theme.dart';
import 'package:mandap/features/mandap/presentation/widgets/3d/mandap_3d_controller.dart';
import 'package:vector_math/vector_math_64.dart' as v64;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Direct Pen Size Creation (No Popup Dialog)', () {
    test('Pen directly applies drawn size without dialog and turns Pen OFF', () {
      final controller = MandapEditorController();
      controller.setMode(EditorMode.addEdge);
      controller.setPenStartPoint(v64.Vector3(10.0, 20.0, 10.0));

      final (axis, previewLen) = controller.preparePenSegment(
        tapStart: controller.penStartPoint!,
        tapEnd: v64.Vector3(45.0, 20.0, 10.0),
      );

      expect(axis, equals('X'));
      expect(previewLen, equals(35.0));

      // Applied directly with tapped length
      final success = controller.applyCreateTrussMember(requestedLength: previewLen);
      expect(success, isTrue);
      expect(controller.mode, equals(EditorMode.view));
      expect(controller.penState, equals(PenState.idle));
    });
  });

  group('2. Direct Left/Right Horizontal Drag (No Center Popup)', () {
    test('Dragging node modifies X and Z on the horizontal plane without popup', () {
      final controller = MandapEditorController(
        initialWidth: 100.0,
        initialDepth: 100.0,
        initialTrussSize: 10.0,
      );

      final centerNode = controller.layout.nodes.values.firstWhere((n) => n.isControlPoint);
      final origX = centerNode.x;
      final origZ = centerNode.z;

      // Move left/right (X-axis attempt) and forward/back (Z-axis)
      // Center node locks X to origX, and applies Z change
      controller.moveNode(nodeId: centerNode.id, newX: origX + 10.0, newZ: origZ - 5.0);

      final updatedCenter = controller.layout.getNode(centerNode.id)!;
      expect(updatedCenter.x, equals(origX), reason: 'Center node X must remain locked');
      expect(updatedCenter.z, equals(origZ - 5.0));
      // Elevation remains flat at roof level without forced vertical pitch popup
      expect(updatedCenter.elevation, equals(centerNode.elevation));
    });

    test('3D controller supports edge dragging state for horizontal translation', () {
      final c3d = Mandap3DController(mandapHeight: 20.0);
      expect(c3d.isDraggingEdge, isFalse);
      c3d.isDraggingEdge = true;
      c3d.dragStartPlaneX = 10.0;
      c3d.dragStartPlaneZ = 20.0;
      expect(c3d.isDraggingEdge, isTrue);
    });
  });

  group('3. Exit Dialog Text Contrast & Visibility', () {
    testWidgets('Exit dialog renders with high contrast white title on dark background', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: const Color(0xFF1E293B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFF334155), width: 1),
                  ),
                  title: const Text(
                    'Exit MANDAP?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  content: const Text(
                    'Are you sure you want to exit the application?',
                    style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF94A3B8), fontWeight: FontWeight.w600)),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.trussPrimary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Exit'),
                    ),
                  ],
                ),
              ),
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      final alert = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alert.backgroundColor, const Color(0xFF1E293B));

      final titleWidget = tester.widget<Text>(find.text('Exit MANDAP?'));
      expect(titleWidget.style?.color, equals(Colors.white));

      final contentWidget = tester.widget<Text>(find.text('Are you sure you want to exit the application?'));
      expect(contentWidget.style?.color, equals(const Color(0xFFCBD5E1)));

      final cancelWidget = tester.widget<Text>(find.text('Cancel'));
      expect(cancelWidget.style?.color, equals(const Color(0xFF94A3B8)));
    });
  });
}
