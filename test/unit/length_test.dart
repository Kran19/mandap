import 'package:flutter_test/flutter_test.dart';
import 'package:mandap/core/geometry/length.dart';

void main() {
  group('Length Value Object Tests', () {
    test('Constructs correctly from ticks', () {
      final len = Length.fromTicks(21);
      expect(len.ticks, equals(21));
      expect(len.feet, equals(10.5));
      expect(len.toString(), equals('10.5 ft'));
    });

    test('Constructs correctly from exact 0.5 ft feet', () {
      final l10 = Length.fromFeet(10.0);
      expect(l10.ticks, equals(20));

      final l10_5 = Length.fromFeet(10.5);
      expect(l10_5.ticks, equals(21));
    });

    test('Rejects non-0.5 ft increments with ArgumentError', () {
      expect(() => Length.fromFeet(10.3), throwsArgumentError);
      expect(() => Length.fromFeet(10.1), throwsArgumentError);
      expect(() => Length.fromFeet(0.2), throwsArgumentError);
    });

    test('Rejects negative lengths with ArgumentError', () {
      expect(() => Length.fromTicks(-1), throwsArgumentError);
      expect(() => Length.fromFeet(-5.0), throwsArgumentError);
    });

    test('Arithmetic operations and comparisons', () {
      final l5 = Length.fromFeet(5.0);
      final l10 = Length.fromFeet(10.0);

      expect((l5 + l10).feet, equals(15.0));
      expect((l10 - l5).feet, equals(5.0));
      expect(() => l5 - l10, throwsArgumentError);

      expect(l5 < l10, isTrue);
      expect(l10 > l5, isTrue);
      expect(l5 == Length.fromFeet(5.0), isTrue);
    });
  });
}
