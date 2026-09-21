import '../../domain/entities/boundary_side.dart';
import '../../domain/entities/boundary_truss_run.dart';
import '../../domain/services/truss_geometry_service.dart';

abstract class BoundaryCommand {
  void execute();
  void undo();
  void redo();
}

class SplitTrussCommand implements BoundaryCommand {
  final BoundarySide beforeSide;
  final String targetRunId;
  final double splitOffset;
  final String newPoleId;
  final void Function(BoundarySide newSide) onApply;

  late BoundarySide _afterSide;

  SplitTrussCommand({
    required this.beforeSide,
    required this.targetRunId,
    required this.splitOffset,
    required this.newPoleId,
    required this.onApply,
  });

  @override
  void execute() {
    _afterSide = TrussGeometryService.splitRun(
      side: beforeSide,
      runId: targetRunId,
      splitOffset: splitOffset,
      newPoleId: newPoleId,
    );
    onApply(_afterSide);
  }

  @override
  void undo() {
    onApply(beforeSide);
  }

  @override
  void redo() {
    onApply(_afterSide);
  }
}

class MergeTrussCommand implements BoundaryCommand {
  final BoundarySide beforeSide;
  final String runIdA;
  final String runIdB;
  final void Function(BoundarySide newSide) onApply;

  late BoundarySide _afterSide;

  MergeTrussCommand({
    required this.beforeSide,
    required this.runIdA,
    required this.runIdB,
    required this.onApply,
  });

  @override
  void execute() {
    _afterSide = TrussGeometryService.mergeRuns(
      side: beforeSide,
      runIdA: runIdA,
      runIdB: runIdB,
    );
    onApply(_afterSide);
  }

  @override
  void undo() {
    onApply(beforeSide);
  }

  @override
  void redo() {
    onApply(_afterSide);
  }
}

class CreateCenterCrossCommand implements BoundaryCommand {
  final Map<String, BoundarySide> beforeFourSides;
  final Map<String, BoundarySide> afterFourSides;
  final List<BoundaryTrussRun> beforeCenterRuns;
  final List<BoundaryTrussRun> afterCenterRuns;
  final void Function(Map<String, BoundarySide> fourSides, List<BoundaryTrussRun> centerRuns) onApply;

  CreateCenterCrossCommand({
    required this.beforeFourSides,
    required this.afterFourSides,
    required this.beforeCenterRuns,
    required this.afterCenterRuns,
    required this.onApply,
  });

  @override
  void execute() {
    onApply(afterFourSides, afterCenterRuns);
  }

  @override
  void undo() {
    onApply(beforeFourSides, beforeCenterRuns);
  }

  @override
  void redo() {
    onApply(afterFourSides, afterCenterRuns);
  }
}

class DeleteCenterRunCommand implements BoundaryCommand {
  final List<BoundaryTrussRun> beforeCenterRuns;
  final String targetRunId;
  final void Function(List<BoundaryTrussRun> newCenterRuns) onApply;

  late List<BoundaryTrussRun> _afterCenterRuns;

  DeleteCenterRunCommand({
    required this.beforeCenterRuns,
    required this.targetRunId,
    required this.onApply,
  }) {
    _afterCenterRuns = beforeCenterRuns.where((r) => r.id != targetRunId).toList();
  }

  @override
  void execute() {
    onApply(_afterCenterRuns);
  }

  @override
  void undo() {
    onApply(beforeCenterRuns);
  }

  @override
  void redo() {
    onApply(_afterCenterRuns);
  }
}
