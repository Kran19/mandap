import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/flooring_calculation_input.dart';
import '../domain/models/flooring_calculation_result.dart';
import '../domain/services/flooring_calculation_service.dart';

enum FlooringViewMode { mode2D, mode3D }

class FlooringCalculatorController extends ChangeNotifier {
  final FlooringCalculationService _service;

  FlooringCalculatorController({FlooringCalculationService? service})
      : _service = service ?? const FlooringCalculationService() {
    calculate();
  }

  double _plotLength = 100.0;
  double _plotWidth = 60.0;
  double _carpetLength = 12.0;
  double _carpetWidth = 6.0;

  FlooringViewMode _viewMode = FlooringViewMode.mode3D;

  FlooringCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = math.pi / 5;
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;

  double get plotLength => _plotLength;
  double get plotWidth => _plotWidth;
  double get carpetLength => _carpetLength;
  double get carpetWidth => _carpetWidth;

  FlooringViewMode get viewMode => _viewMode;
  FlooringCalculationResult? get result => _result;
  String? get error => _error;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;

  void updateInputs({
    required double plotLength,
    required double plotWidth,
    required double carpetLength,
    required double carpetWidth,
  }) {
    _plotLength = plotLength;
    _plotWidth = plotWidth;
    _carpetLength = carpetLength;
    _carpetWidth = carpetWidth;
    // Clear stale result per decision lock until Calculate is pressed
    _result = null;
    _error = null;
    notifyListeners();
  }

  void setViewMode(FlooringViewMode mode) {
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
      final input = FlooringCalculationInput(
        plotLength: _plotLength,
        plotWidth: _plotWidth,
        carpetLength: _carpetLength,
        carpetWidth: _carpetWidth,
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
