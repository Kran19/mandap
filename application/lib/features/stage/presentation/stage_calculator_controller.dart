import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../domain/models/stage_calculation_input.dart';
import '../domain/models/stage_calculation_result.dart';
import '../domain/services/stage_calculation_service.dart';

enum StageViewMode { mode2D, mode3D }

class StageCalculatorController extends ChangeNotifier {
  final StageCalculationService _service;

  StageCalculatorController({
    StageCalculationService? service,
    double initialLength = 32.0,
    double initialWidth = 20.0,
    double initialTableLength = 4.0,
    double initialTableWidth = 8.0,
  })  : _service = service ?? const StageCalculationService(),
        _stageLength = initialLength > 0 ? initialLength : 32.0,
        _stageWidth = initialWidth > 0 ? initialWidth : 20.0,
        _tableLength = initialTableLength > 0 ? initialTableLength : 4.0,
        _tableWidth = initialTableWidth > 0 ? initialTableWidth : 8.0 {
    _cameraCenterTarget = v64.Vector3(_stageLength / 2.0, 1.5, _stageWidth / 2.0);
    calculate();
  }

  double _stageLength = 32.0;
  double _stageWidth = 20.0;
  final double _stageHeight = 3.0; // Standard deck height locked internally
  double _tableLength = 4.0;
  double _tableWidth = 8.0;
  bool _isRotated = false;

  final List<({double stageLength, double stageWidth, double tableLength, double tableWidth, bool isRotated})> _undoStack = [];
  final List<({double stageLength, double stageWidth, double tableLength, double tableWidth, bool isRotated})> _redoStack = [];

  StageViewMode _viewMode = StageViewMode.mode3D;

  StageCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = math.pi / 6;
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;
  late v64.Vector3 _cameraCenterTarget;

  double get stageLength => _stageLength;
  double get stageWidth => _stageWidth;
  double get stageHeight => _stageHeight;
  double get tableLength => _tableLength;
  double get tableWidth => _tableWidth;
  bool get isRotated => _isRotated;

  StageViewMode get viewMode => _viewMode;
  StageCalculationResult? get result => _result;
  String? get error => _error;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;
  v64.Vector3 get cameraCenterTarget => _cameraCenterTarget;

  void updateDimensions(
    double stageLength,
    double stageWidth, {
    double? tableLength,
    double? tableWidth,
    bool? isRotated,
    bool recordHistory = true,
  }) {
    final tl = tableLength ?? _tableLength;
    final tw = tableWidth ?? _tableWidth;
    final rot = isRotated ?? _isRotated;

    if (recordHistory &&
        (_stageLength != stageLength || _stageWidth != stageWidth || _tableLength != tl || _tableWidth != tw || _isRotated != rot)) {
      _undoStack.add((
        stageLength: _stageLength,
        stageWidth: _stageWidth,
        tableLength: _tableLength,
        tableWidth: _tableWidth,
        isRotated: _isRotated,
      ));
      _redoStack.clear();
    }

    _stageLength = stageLength;
    _stageWidth = stageWidth;
    _tableLength = tl;
    _tableWidth = tw;
    _isRotated = rot;
    _cameraCenterTarget = v64.Vector3(_stageLength / 2.0, 1.5, _stageWidth / 2.0);
    calculate();
  }

  /// Swaps internal stage table layout arrangement inside the same boundary.
  void swapDimensions() {
    _undoStack.add((
      stageLength: _stageLength,
      stageWidth: _stageWidth,
      tableLength: _tableLength,
      tableWidth: _tableWidth,
      isRotated: _isRotated,
    ));
    _redoStack.clear();
    _isRotated = !_isRotated;
    calculate();
  }

  void undo() {
    if (!canUndo) return;
    final prev = _undoStack.removeLast();
    _redoStack.add((
      stageLength: _stageLength,
      stageWidth: _stageWidth,
      tableLength: _tableLength,
      tableWidth: _tableWidth,
      isRotated: _isRotated,
    ));
    _stageLength = prev.stageLength;
    _stageWidth = prev.stageWidth;
    _tableLength = prev.tableLength;
    _tableWidth = prev.tableWidth;
    _isRotated = prev.isRotated;
    _cameraCenterTarget = v64.Vector3(_stageLength / 2.0, 1.5, _stageWidth / 2.0);
    calculate();
  }

  void redo() {
    if (!canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add((
      stageLength: _stageLength,
      stageWidth: _stageWidth,
      tableLength: _tableLength,
      tableWidth: _tableWidth,
      isRotated: _isRotated,
    ));
    _stageLength = next.stageLength;
    _stageWidth = next.stageWidth;
    _tableLength = next.tableLength;
    _tableWidth = next.tableWidth;
    _isRotated = next.isRotated;
    _cameraCenterTarget = v64.Vector3(_stageLength / 2.0, 1.5, _stageWidth / 2.0);
    calculate();
  }

  void setViewMode(StageViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void resetCamera() {
    _cameraAzimuth = math.pi / 4;
    _cameraElevation = math.pi / 6;
    _cameraZoom = 1.0;
    _baseCameraZoom = 1.0;
    if (_result != null) {
      _cameraCenterTarget = v64.Vector3(_result!.coveredLength / 2.0, 1.5, _result!.coveredWidth / 2.0);
    }
    notifyListeners();
  }

  void orbitCamera(double deltaX, double deltaY) {
    _cameraAzimuth -= deltaX * 0.008;
    _cameraElevation = (_cameraElevation + deltaY * 0.008).clamp(0.05, math.pi / 2 - 0.05);
    notifyListeners();
  }

  void panCamera(double deltaX, double deltaY) {
    final cosAzim = math.cos(_cameraAzimuth);
    final sinAzim = math.sin(_cameraAzimuth);
    final right = v64.Vector3(cosAzim, 0.0, -sinAzim);
    final up = v64.Vector3(0.0, 1.0, 0.0);

    const panSensitivity = 0.08;
    final moveVector = (right * (-deltaX * panSensitivity)) + (up * (deltaY * panSensitivity));
    _cameraCenterTarget += moveVector;
    notifyListeners();
  }

  void zoomCamera(double zoomDelta) {
    _cameraZoom = (_cameraZoom * zoomDelta).clamp(0.3, 3.5);
    notifyListeners();
  }

  void onScaleStart() {
    _baseCameraZoom = _cameraZoom;
  }

  void onScaleUpdate(double scale, Offset delta, {int pointerCount = 1}) {
    if (scale != 1.0) {
      _cameraZoom = (_baseCameraZoom / scale).clamp(0.3, 3.5);
    }

    if (pointerCount >= 2) {
      panCamera(delta.dx, delta.dy);
    } else if (delta != Offset.zero) {
      orbitCamera(delta.dx, delta.dy);
    }
    notifyListeners();
  }

  void calculate() {
    _error = null;
    try {
      final input = StageCalculationInput(
        stageLength: _stageLength,
        stageWidth: _stageWidth,
        stageHeight: _stageHeight,
        tableLength: _tableLength,
        tableWidth: _tableWidth,
        isRotated: _isRotated,
      );
      if (!input.isValid) {
        _error = 'Please enter valid positive numbers for stage dimensions.';
        _result = null;
      } else {
        _result = _service.calculate(input);
        _cameraCenterTarget = v64.Vector3(_result!.coveredLength / 2.0, 1.5, _result!.coveredWidth / 2.0);
      }
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Calculation failed.';
      _result = null;
    }
    notifyListeners();
  }

  // Backwards compatibility method
  void updateInputs({
    required double stageLength,
    required double stageWidth,
    required double stageHeight,
    required double tableLength,
    required double tableWidth,
  }) {
    updateDimensions(
      stageLength,
      stageWidth,
      tableLength: tableLength,
      tableWidth: tableWidth,
    );
  }
}
