import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as v64;
import '../domain/models/pole_calculation_input.dart';
import '../domain/models/pole_calculation_result.dart';
import '../domain/services/pole_calculation_service.dart';

enum PoleViewMode { mode2D, mode3D }

class PoleCalculatorController extends ChangeNotifier {
  final PoleCalculationService _service;

  PoleCalculatorController({
    PoleCalculationService? service,
    double initialLength = 100.0,
    double initialWidth = 100.0,
    double initialPoleSize = 15.0,
  })  : _service = service ?? const PoleCalculationService(),
        _length = initialLength > 0 ? initialLength : 100.0,
        _width = initialWidth > 0 ? initialWidth : 100.0,
        _poleSize = initialPoleSize > 0 ? initialPoleSize : 15.0 {
    _cameraCenterTarget = v64.Vector3(_width / 2.0, 0.0, _length / 2.0);
    calculate();
  }

  double _length = 100.0;
  double _width = 100.0;
  double _poleSize = 15.0;

  final List<({double length, double width, double poleSize})> _undoStack = [];
  final List<({double length, double width, double poleSize})> _redoStack = [];

  PoleViewMode _viewMode = PoleViewMode.mode3D;

  PoleCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = 58.0 * math.pi / 180.0; // High-angle upward overhead view
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;
  late v64.Vector3 _cameraCenterTarget;

  double get length => _length;
  double get width => _width;
  double get poleSize => _poleSize;
  PoleViewMode get viewMode => _viewMode;
  PoleCalculationResult? get result => _result;
  String? get error => _error;

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;
  v64.Vector3 get cameraCenterTarget => _cameraCenterTarget;

  void updateDimensions(double length, double width, double poleSize, {bool recordHistory = true}) {
    if (recordHistory && (_length != length || _width != width || _poleSize != poleSize)) {
      _undoStack.add((length: _length, width: _width, poleSize: _poleSize));
      _redoStack.clear();
    }
    _length = length;
    _width = width;
    _poleSize = poleSize;
    _cameraCenterTarget = v64.Vector3(_width / 2.0, 0.0, _length / 2.0);
  }

  void undo() {
    if (!canUndo) return;
    final prev = _undoStack.removeLast();
    _redoStack.add((length: _length, width: _width, poleSize: _poleSize));
    _length = prev.length;
    _width = prev.width;
    _poleSize = prev.poleSize;
    _cameraCenterTarget = v64.Vector3(_width / 2.0, 0.0, _length / 2.0);
    calculate();
  }

  void redo() {
    if (!canRedo) return;
    final next = _redoStack.removeLast();
    _undoStack.add((length: _length, width: _width, poleSize: _poleSize));
    _length = next.length;
    _width = next.width;
    _poleSize = next.poleSize;
    _cameraCenterTarget = v64.Vector3(_width / 2.0, 0.0, _length / 2.0);
    calculate();
  }

  void setViewMode(PoleViewMode mode) {
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
    _cameraCenterTarget = v64.Vector3(_width / 2.0, 0.0, _length / 2.0);
    notifyListeners();
  }

  void onScaleStart() {
    _baseCameraZoom = _cameraZoom;
  }

  void onScaleUpdate(double scale, Offset delta, {int pointerCount = 1}) {
    if (scale != 1.0) {
      _cameraZoom = (_baseCameraZoom / scale).clamp(0.2, 5.0);
    }
    if (pointerCount >= 2 && delta != Offset.zero) {
      // Two-finger pan
      panCamera(delta.dx, delta.dy);
      return;
    }
    if (delta != Offset.zero) {
      // Orbit
      _cameraAzimuth -= delta.dx * 0.01;
      _cameraElevation += delta.dy * 0.01;
      _cameraElevation = _cameraElevation.clamp(0.01, math.pi / 2 - 0.01);
    }
    notifyListeners();
  }

  void panCamera(double deltaX, double deltaY) {
    final cosAzim = math.cos(_cameraAzimuth);
    final sinAzim = math.sin(_cameraAzimuth);
    final cosElev = math.cos(_cameraElevation);
    final sinElev = math.sin(_cameraElevation);

    final right = v64.Vector3(cosAzim, 0.0, -sinAzim);
    final up = v64.Vector3(-sinAzim * sinElev, cosElev, -cosAzim * sinElev);

    final maxDim = math.max(_width, _length);
    final distance = math.max(maxDim * 2.5, 60.0) * _cameraZoom;
    final scale = distance / 800.0;
    final displacement = (right * (-deltaX * scale)) + (up * (deltaY * scale));

    _cameraCenterTarget += displacement;
    notifyListeners();
  }

  void calculate() {
    _error = null;
    try {
      final input = PoleCalculationInput(
        plotLength: _length, 
        plotWidth: _width,
        poleSize: _poleSize,
      );
      if (!input.isValid) {
        _error = 'Please enter valid positive dimensions.';
        _result = null;
      } else {
        _result = _service.calculate(input);
      }
    } catch (e) {
      _error = 'Calculation failed. Please check your dimensions.';
      _result = null;
    }
    notifyListeners();
  }
}
