import '../../domain/entities/mandap_layout.dart';
import 'mandap_command.dart';

/// Manages undo and redo history stacks for [MandapCommand] operations.
class CommandHistory {
  final List<MandapCommand> _undoStack = [];
  final List<MandapCommand> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;
  int get redoCount => _redoStack.length;

  /// Executes [command] on [currentLayout], pushes to undo stack, and clears redo stack.
  MandapLayout executeCommand(
    MandapCommand command,
    MandapLayout currentLayout,
  ) {
    final updatedLayout = command.execute(currentLayout);
    _undoStack.add(command);
    _redoStack.clear();
    return updatedLayout;
  }

  /// Undoes top command, returning updated layout.
  MandapLayout undo(MandapLayout currentLayout) {
    if (!canUndo) return currentLayout;

    final command = _undoStack.removeLast();
    final restoredLayout = command.undo(currentLayout);
    _redoStack.add(command);

    return restoredLayout;
  }

  /// Redoes top command from redo stack, returning updated layout.
  MandapLayout redo(MandapLayout currentLayout) {
    if (!canRedo) return currentLayout;

    final command = _redoStack.removeLast();
    final reexecutedLayout = command.execute(currentLayout);
    _undoStack.add(command);

    return reexecutedLayout;
  }

  /// Clears undo and redo histories.
  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
