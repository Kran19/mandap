import '../../domain/entities/mandap_layout.dart';

/// Abstract base class for executable and undoable layout edit commands.
abstract class MandapCommand {
  /// Executes the command, returning the updated [MandapLayout].
  MandapLayout execute(MandapLayout currentLayout);

  /// Reverses the command, returning the restored [MandapLayout].
  MandapLayout undo(MandapLayout currentLayout);

  /// Human-readable summary of the command.
  String get description;
}
