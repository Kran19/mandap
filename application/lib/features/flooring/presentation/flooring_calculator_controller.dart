import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../domain/models/flooring_calculation_input.dart';
import '../domain/models/flooring_calculation_result.dart';
import '../domain/services/flooring_calculation_service.dart';

enum FlooringViewMode { mode2D, mode3D }

class FlooringCalculatorController extends ChangeNotifier {
  final FlooringCalculationService _service;

  FlooringCalculatorController({
    FlooringCalculationService? service,
    double initialLength = 100.0,
    double initialWidth = 60.0,
    double initialCarpetLength = 15.0,
    double initialCarpetWidth = 30.0,
  })  : _service = service ?? const FlooringCalculationService(),
        _plotLength = initialLength > 0 ? initialLength : 100.0,
        _plotWidth = initialWidth > 0 ? initialWidth : 60.0,
        _carpetLength = initialCarpetLength > 0 ? initialCarpetLength : 15.0,
        _carpetWidth = initialCarpetWidth > 0 ? initialCarpetWidth : 30.0 {
    _cameraCenterTarget = v64.Vector3(_plotLength / 2.0, 0.1, _plotWidth / 2.0);
    calculate();
  }

  double _plotLength = 100.0;
  double _plotWidth = 60.0;
  double _carpetLength = 15.0;
  double _carpetWidth = 30.0;
  bool _isRotated = false;

  final List<({double plotLength, double plotWidth, double carpetLength, double carpetWidth, bool isRotated})> _undoStack = [];
  final List<({double plotLength, double plotWidth, double carpetLength, double carpetWidth, bool isRotated})> _redoStack = [];

  FlooringViewMode _viewMode = FlooringViewMode.mode3D;

  FlooringCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = 58.0 * math.pi / 180.0; // High-angle upward overhead view
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;
  late v64.Vector3 _cameraCenterTarget;

  double get plotLength => _plotLength;
  double get plotWidth => _plotWidth;
  double get carpetLength => _carpetLength;
  double get carpetWidth => _carpetWidth;
  bool get isRotated => _isRotated;

  FlooringViewMode get viewMode => _viewMode;
  FlooringCalculationResult? get result => _result;
  String? get error => _error;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;
  v64.Vector3 get cameraCenterTarget => _cameraCenterTarget;

  void updateDimensions(
    double plotLength,
    double plotWidth, {
    double? carpetLength,
    double? carpetWidth,
    bool? isRotated,
    bool recordHistory = true,
  }) {
    final cl = carpetLength ?? _carpetLength;
    final cw = carpetWidth ?? _carpetWidth;
    final rot = isRotated ?? _isRotated;

    if (recordHistory &&
        (_plotLength != plotLength || _plotWidth != plotWidth || _carpetLength != cl || _carpetWidth != cw || _isRotated != rot)) {
      _undoStack.add((
        plotLength: _plotLength,
        plotWidth: _plotWidth,
        carpetLength: _carpetLength,
        carpetWidth: _carpetWidth,
        isRotated: _isRotated,
      ));
      _redoStack.clear();
    }

    _plotLength = plotLength;
    _plotWidth = plotWidth;
    _carpetLength = cl;
    _carpetWidth = cw;
    _isRotated = rot;
    _cameraCenterTarget = v64.Vector3(_plotLength / 2.0, 0.1, _plotWidth / 2.0);
    calculate();
  }

  /// Swaps internal carpet layout arrangement inside the same boundary.
  void swapDimensions() {
    _undoStack.add((
      plotLength: _plotLength,
      plotWidth: _plotWidth,
      carpetLength: _carpetLength,
      carpetWidth: _carpetWidth,
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
      plotLength: _plotLength,
      plotWidth: _plotWidth,
      carpetLength: _carpetLength,
      carpetWidth: _carpetWidth,
      isRotated: _isRotated,
    ));
    _plotLength = prev.plotLength;
    _plotWidth = prev.plotWidth;
    _carpetLength = prev.carpetLength;
    _carpetWidth = prev.carpetWidth;
    _isRotated = prev.isRotated;
    _cameraCenterTarget = v64.Vector3(_plotLength / 2.0, 0.1, _plotWidth / 2.0);
    calculate();
  }

  void redo() {
    if (!canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add((
      plotLength: _plotLength,
      plotWidth: _plotWidth,
      carpetLength: _carpetLength,
      carpetWidth: _carpetWidth,
      isRotated: _isRotated,
    ));
    _plotLength = next.plotLength;
    _plotWidth = next.plotWidth;
    _carpetLength = next.carpetLength;
    _carpetWidth = next.carpetWidth;
    _isRotated = next.isRotated;
    _cameraCenterTarget = v64.Vector3(_plotLength / 2.0, 0.1, _plotWidth / 2.0);
    calculate();
  }

  void setViewMode(FlooringViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void resetCamera() {
    _cameraAzimuth = math.pi / 4;
    _cameraElevation = 58.0 * math.pi / 180.0;
    _cameraZoom = 1.0;
    _baseCameraZoom = 1.0;
    if (_result != null) {
      _cameraCenterTarget = v64.Vector3(_result!.coveredLength / 2.0, 0.1, _result!.coveredWidth / 2.0);
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
      final input = FlooringCalculationInput(
        plotLength: _plotLength,
        plotWidth: _plotWidth,
        carpetLength: _carpetLength,
        carpetWidth: _carpetWidth,
        isRotated: _isRotated,
      );
      if (!input.isValid) {
        _error = 'Please enter valid positive numbers for plot and carpet dimensions.';
        _result = null;
      } else {
        _result = _service.calculate(input);
        _cameraCenterTarget = v64.Vector3(_result!.coveredLength / 2.0, 0.1, _result!.coveredWidth / 2.0);
      }
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Calculation failed.';
      _result = null;
    }
    notifyListeners();
  }

  // Backwards compatibility method
  void updateInputs({
    required double plotLength,
    required double plotWidth,
    required double carpetLength,
    required double carpetWidth,
  }) {
    updateDimensions(
      plotLength,
      plotWidth,
      carpetLength: carpetLength,
      carpetWidth: carpetWidth,
    );
  }
}
