import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/stage_calculation_input.dart';
import '../domain/models/stage_calculation_result.dart';
import '../domain/services/stage_calculation_service.dart';

enum StageViewMode { mode2D, mode3D }

class StageCalculatorController extends ChangeNotifier {
  final StageCalculationService _service;

  StageCalculatorController({StageCalculationService? service})
      : _service = service ?? const StageCalculationService() {
    calculate();
  }

  double _stageLength = 30.0;
  double _stageWidth = 20.0;
  double _stageHeight = 3.0;
  double _tableLength = 4.0;
  double _tableWidth = 8.0;

  StageViewMode _viewMode = StageViewMode.mode3D;

  StageCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = math.pi / 5;
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;

  double get stageLength => _stageLength;
  double get stageWidth => _stageWidth;
  double get stageHeight => _stageHeight;
  double get tableLength => _tableLength;
  double get tableWidth => _tableWidth;

  StageViewMode get viewMode => _viewMode;
  StageCalculationResult? get result => _result;
  String? get error => _error;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;

  void updateInputs({
    required double stageLength,
    required double stageWidth,
    required double stageHeight,
    required double tableLength,
    required double tableWidth,
  }) {
    _stageLength = stageLength;
    _stageWidth = stageWidth;
    _stageHeight = stageHeight;
    _tableLength = tableLength;
    _tableWidth = tableWidth;
    // Clear stale result per decision lock
    _result = null;
    _error = null;
    notifyListeners();
  }

  void setViewMode(StageViewMode mode) {
    if (_viewMode != mode) {
      _viewMode = mode;
      notifyListeners();
    }
  }

  void resetCamera() {
    _cameraAzimuth = math.pi / 4;
    _cameraElevation = math.pi / 5;
    _cameraZoom = 1.0;
    _baseCameraZoom = 1.0;
    notifyListeners();
  }

  void onScaleStart() {
    _baseCameraZoom = _cameraZoom;
  }

  void onScaleUpdate(double scale, Offset delta) {
    if (scale != 1.0) {
      _cameraZoom = (_baseCameraZoom / scale).clamp(0.1, 10.0);
    }
    if (delta != Offset.zero) {
      _cameraAzimuth -= delta.dx * 0.01;
      _cameraElevation += delta.dy * 0.01;
      _cameraElevation = _cameraElevation.clamp(0.01, math.pi / 2 - 0.01);
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
      );
      if (!input.isValid) {
        _error = 'Please enter valid positive numbers for all dimensions.';
        _result = null;
      } else {
        _result = _service.calculate(input);
      }
    } catch (e) {
      _error = e is ArgumentError ? e.message.toString() : 'Calculation failed.';
      _result = null;
    }
    notifyListeners();
  }
}
