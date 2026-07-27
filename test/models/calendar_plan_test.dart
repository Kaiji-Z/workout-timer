import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/models/calendar_plan.dart';

void main() {
  group('CalendarPlan', () {
    final sample = CalendarPlan(
      id: 'cal-1',
      date: DateTime(2026, 7, 27, 10, 30),
      planId: 'plan-1',
      createdAt: DateTime(2026, 7, 1),
    );

    group('dateKey', () {
      test('formats as yyyy-MM-dd', () {
        expect(sample.dateKey, '2026-07-27');
      });

      test('zero-pads single-digit months and days', () {
        final cp = CalendarPlan(
          id: 'x',
          date: DateTime(2026, 1, 5),
          planId: 'p',
          createdAt: DateTime(2026, 1, 1),
        );
        expect(cp.dateKey, '2026-01-05');
      });
    });

    group('dateText', () {
      test('formats as Chinese long form', () {
        expect(sample.dateText, '2026年07月27日');
      });
    });

    group('toJson / fromJson round-trip', () {
      test('toJson emits camelCase keys with ISO date strings', () {
        final json = sample.toJson();
        expect(json['id'], 'cal-1');
        expect(json['planId'], 'plan-1');
        expect(json['date'], isA<String>());
        expect(json['createdAt'], isA<String>());
      });

      test('fromJson reads camelCase keys', () {
        final cp = CalendarPlan.fromJson(sample.toJson());
        expect(cp.id, sample.id);
        expect(cp.planId, sample.planId);
        expect(cp.date, sample.date);
        expect(cp.createdAt, sample.createdAt);
      });

      test('fromJson reads snake_case plan_id as fallback', () {
        final cp = CalendarPlan.fromJson({
          'id': 'cal-2',
          'date': '2026-08-01T00:00:00.000',
          'plan_id': 'plan-snake',
          'createdAt': '2026-08-01T00:00:00.000',
        });
        expect(cp.planId, 'plan-snake');
      });

      test('fromJson falls back to empty id/planId when missing', () {
        final cp = CalendarPlan.fromJson({
          'date': '2026-08-01T00:00:00.000',
          'createdAt': '2026-08-01T00:00:00.000',
        });
        expect(cp.id, '');
        expect(cp.planId, '');
      });

      test('fromJson falls back to DateTime.now() when date missing', () {
        final before = DateTime.now();
        final cp = CalendarPlan.fromJson({
          'id': 'x',
          'planId': 'p',
          'createdAt': '2026-08-01T00:00:00.000',
        });
        final after = DateTime.now();
        // Date should default to roughly now (within a 5s window).
        expect(cp.date.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
        expect(cp.date.isBefore(after.add(const Duration(seconds: 1))), isTrue);
      });
    });

    group('toMap / fromMap round-trip (DB shape)', () {
      test('toMap emits snake_case keys', () {
        final map = sample.toMap();
        expect(map.containsKey('id'), isTrue);
        expect(map.containsKey('plan_id'), isTrue);
        expect(map.containsKey('created_at'), isTrue);
        expect(map.containsKey('date'), isTrue);
        // toMap must NOT leak the camelCase keys.
        expect(map.containsKey('planId'), isFalse);
        expect(map.containsKey('createdAt'), isFalse);
      });

      test('fromMap parses snake_case keys', () {
        final restored = CalendarPlan.fromMap(sample.toMap());
        expect(restored.id, sample.id);
        expect(restored.planId, sample.planId);
        expect(restored.date, sample.date);
        expect(restored.createdAt, sample.createdAt);
      });

      test('full DB round-trip preserves every field', () {
        final restored = CalendarPlan.fromMap(sample.toMap());
        expect(restored == sample, isTrue);
      });
    });

    group('copyWith', () {
      test('returns a new instance with only specified fields overridden', () {
        final copied = sample.copyWith(planId: 'plan-2');
        expect(copied.id, sample.id); // unchanged
        expect(copied.date, sample.date); // unchanged
        expect(copied.createdAt, sample.createdAt); // unchanged
        expect(copied.planId, 'plan-2'); // overridden
      });

      test('returns a different identity', () {
        final copied = sample.copyWith();
        // Same content but a new instance.
        expect(identical(copied, sample), isFalse);
        // Equality is based on id, so they should still be equal.
        expect(copied == sample, isTrue);
      });

      test('can override every field independently', () {
        final copied = sample.copyWith(
          id: 'new-id',
          date: DateTime(2027, 1, 1),
          planId: 'new-plan',
          createdAt: DateTime(2026, 12, 31),
        );
        expect(copied.id, 'new-id');
        expect(copied.dateKey, '2027-01-01');
        expect(copied.planId, 'new-plan');
        expect(copied.createdAt, DateTime(2026, 12, 31));
      });
    });

    group('equality and hashCode', () {
      test('two instances with the same id are equal', () {
        final a = CalendarPlan(
          id: 'cal-1',
          date: DateTime(2026, 1, 1),
          planId: 'plan-a',
          createdAt: DateTime(2026, 1, 1),
        );
        final b = CalendarPlan(
          id: 'cal-1', // same id
          date: DateTime(2027, 7, 7), // different everything else
          planId: 'plan-b',
          createdAt: DateTime(2028, 8, 8),
        );
        expect(a == b, isTrue);
        expect(a.hashCode, b.hashCode);
      });

      test('two instances with different ids are not equal', () {
        final a = sample;
        final b = sample.copyWith(id: 'cal-other');
        expect(a == b, isFalse);
      });

      test('toString contains id, dateKey, and planId', () {
        final s = sample.toString();
        expect(s, contains('cal-1'));
        expect(s, contains('2026-07-27'));
        expect(s, contains('plan-1'));
      });
    });
  });
}
