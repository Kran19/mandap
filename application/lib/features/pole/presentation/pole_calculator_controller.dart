import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/models/pole_calculation_input.dart';
import '../domain/models/pole_calculation_result.dart';
import '../domain/services/pole_calculation_service.dart';

enum PoleViewMode { mode2D, mode3D }

class PoleCalculatorController extends ChangeNotifier {
  final PoleCalculationService _service;

  PoleCalculatorController({PoleCalculationService? service})
      : _service = service ?? const PoleCalculationService() {
    calculate();
  }

  double _length = 100.0;
  double _width = 100.0;
  double _poleSize = 15.0;
  
  PoleViewMode _viewMode = PoleViewMode.mode3D;

  PoleCalculationResult? _result;
  String? _error;

  double _cameraAzimuth = math.pi / 4;
  double _cameraElevation = math.pi / 6;
  double _cameraZoom = 1.0;
  double _baseCameraZoom = 1.0;

  double get length => _length;
  double get width => _width;
  double get poleSize => _poleSize;
  PoleViewMode get viewMode => _viewMode;
  PoleCalculationResult? get result => _result;
  String? get error => _error;

  double get cameraAzimuth => _cameraAzimuth;
  double get cameraElevation => _cameraElevation;
  double get cameraZoom => _cameraZoom;

  void updateDimensions(double length, double width, double poleSize) {
    _length = length;
    _width = width;
    _poleSize = poleSize;
  }

  void setViewMode(PoleViewMode mode) {
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
