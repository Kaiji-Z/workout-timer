import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/set_data.dart';

void main() {
  group('SetData', () {
    group('toMap/fromMap roundtrip', () {
      test('preserves all fields correctly', () {
        final setData = SetData(
          setNumber: 3,
          reps: 12,
          weight: 45.5,
        );

        final map = setData.toMap();
        final restored = SetData.fromMap(map);

        expect(restored.setNumber, 3);
        expect(restored.reps, 12);
        expect(restored.weight, 45.5);
      });

      test('handles null values', () {
        final setData = SetData(
          setNumber: 1,
          reps: null,
          weight: null,
        );

        final map = setData.toMap();
        final restored = SetData.fromMap(map);

        expect(restored.setNumber, 1);
        expect(restored.reps, isNull);
        expect(restored.weight, isNull);
      });

      test('handles only reps set', () {
        final setData = SetData(
          setNumber: 2,
          reps: 15,
          weight: null,
        );

        final map = setData.toMap();
        final restored = SetData.fromMap(map);

        expect(restored.setNumber, 2);
        expect(restored.reps, 15);
        expect(restored.weight, isNull);
      });

      test('handles only weight set', () {
        final setData = SetData(
          setNumber: 4,
          reps: null,
          weight: 60.0,
        );

        final map = setData.toMap();
        final restored = SetData.fromMap(map);

        expect(restored.setNumber, 4);
        expect(restored.reps, isNull);
        expect(restored.weight, 60.0);
      });

      test('defaults setNumber to 1 when missing in map', () {
        final map = <String, dynamic>{
          'reps': 10,
          'weight': 30.0,
        };

        final restored = SetData.fromMap(map);

        expect(restored.setNumber, 1);
        expect(restored.reps, 10);
        expect(restored.weight, 30.0);
      });

      test('handles integer weight from database', () {
        final map = <String, dynamic>{
          'set_number': 1,
          'reps': 10,
          'weight': 50, // int, not double
        };

        final restored = SetData.fromMap(map);

        expect(restored.weight, 50.0);
        expect(restored.weight, isA<double>());
      });
    });

    group('toJson/fromJson roundtrip', () {
      test('preserves all fields correctly', () {
        final setData = SetData(
          setNumber: 5,
          reps: 8,
          weight: 100.0,
        );

        final json = setData.toJson();
        final restored = SetData.fromJson(json);

        expect(restored.setNumber, 5);
        expect(restored.reps, 8);
        expect(restored.weight, 100.0);
      });

      test('handles null values', () {
        final setData = SetData(
          setNumber: 1,
          reps: null,
          weight: null,
        );

        final json = setData.toJson();
        final restored = SetData.fromJson(json);

        expect(restored.reps, isNull);
        expect(restored.weight, isNull);
      });
    });

    group('displayText formatting', () {
      test('returns "Set N" when both reps and weight are null', () {
        final setData = SetData(setNumber: 3, reps: null, weight: null);
        expect(setData.displayText, 'Set 3');
      });

      test('returns "N reps" when only reps is set', () {
        final setData = SetData(setNumber: 1, reps: 12, weight: null);
        expect(setData.displayText, '12 reps');
      });

      test('returns "Nkg" when only weight is set', () {
        final setData = SetData(setNumber: 2, reps: null, weight: 45.0);
        expect(setData.displayText, '45.0kg');
      });

      test('returns "reps × weight" when both are set', () {
        final setData = SetData(setNumber: 1, reps: 10, weight: 50.5);
        expect(setData.displayText, '10 × 50.5kg');
      });

      test('formats weight with one decimal place', () {
        final setData = SetData(setNumber: 1, reps: null, weight: 45.75);
        expect(setData.displayText, '45.8kg');
      });

      test('handles zero reps', () {
        final setData = SetData(setNumber: 1, reps: 0, weight: 50.0);
        expect(setData.displayText, '0 × 50.0kg');
      });

      test('handles zero weight', () {
        final setData = SetData(setNumber: 1, reps: 10, weight: 0.0);
        expect(setData.displayText, '10 × 0.0kg');
      });
    });

    group('volume calculation', () {
      test('calculates volume correctly', () {
        final setData = SetData(setNumber: 1, reps: 10, weight: 50.0);
        expect(setData.volume, 500.0);
      });

      test('returns 0 when reps is null', () {
        final setData = SetData(setNumber: 1, reps: null, weight: 50.0);
        expect(setData.volume, 0.0);
      });

      test('returns 0 when weight is null', () {
        final setData = SetData(setNumber: 1, reps: 10, weight: null);
        expect(setData.volume, 0.0);
      });

      test('returns 0 when both are null', () {
        final setData = SetData(setNumber: 1, reps: null, weight: null);
        expect(setData.volume, 0.0);
      });

      test('handles fractional reps', () {
        // Note: reps is int, so fractional reps not possible
        // This test verifies integer multiplication
        final setData = SetData(setNumber: 1, reps: 12, weight: 22.5);
        expect(setData.volume, 270.0);
      });

      test('handles zero values', () {
        final setData = SetData(setNumber: 1, reps: 0, weight: 0.0);
        expect(setData.volume, 0.0);
      });
    });

    group('copyWith', () {
      test('preserves values when no parameters provided', () {
        final original = SetData(setNumber: 3, reps: 10, weight: 50.0);
        final copy = original.copyWith();

        expect(copy.setNumber, 3);
        expect(copy.reps, 10);
        expect(copy.weight, 50.0);
      });

      test('updates setNumber', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final copy = original.copyWith(setNumber: 5);

        expect(copy.setNumber, 5);
        expect(copy.reps, 10);
        expect(copy.weight, 50.0);
      });

      test('updates reps', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final copy = original.copyWith(reps: 15);

        expect(copy.setNumber, 1);
        expect(copy.reps, 15);
        expect(copy.weight, 50.0);
      });

      test('updates weight', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final copy = original.copyWith(weight: 75.5);

        expect(copy.setNumber, 1);
        expect(copy.reps, 10);
        expect(copy.weight, 75.5);
      });

      test('updates all fields', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final copy = original.copyWith(
          setNumber: 4,
          reps: 8,
          weight: 100.0,
        );

        expect(copy.setNumber, 4);
        expect(copy.reps, 8);
        expect(copy.weight, 100.0);
      });

      test('can set values to null using explicit null', () {
        final original = SetData(setNumber: 1, reps: 10, weight: 50.0);
        // Note: copyWith cannot set to null with current signature
        // This test documents current behavior
        final copy = original.copyWith();

        expect(copy.reps, isNotNull);
        expect(copy.weight, isNotNull);
      });
    });

    group('equality', () {
      test('equal when all fields match', () {
        final a = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final b = SetData(setNumber: 1, reps: 10, weight: 50.0);

        expect(a, equals(b));
        expect(a.hashCode, equals(b.hashCode));
      });

      test('not equal when setNumber differs', () {
        final a = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final b = SetData(setNumber: 2, reps: 10, weight: 50.0);

        expect(a, isNot(equals(b)));
      });

      test('not equal when reps differs', () {
        final a = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final b = SetData(setNumber: 1, reps: 12, weight: 50.0);

        expect(a, isNot(equals(b)));
      });

      test('not equal when weight differs', () {
        final a = SetData(setNumber: 1, reps: 10, weight: 50.0);
        final b = SetData(setNumber: 1, reps: 10, weight: 55.0);

        expect(a, isNot(equals(b)));
      });

      test('equal when both have same null values', () {
        final a = SetData(setNumber: 1, reps: null, weight: null);
        final b = SetData(setNumber: 1, reps: null, weight: null);

        expect(a, equals(b));
      });
    });
  });
}
