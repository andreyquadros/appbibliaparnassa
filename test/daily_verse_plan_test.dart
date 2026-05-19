import 'package:flutter_test/flutter_test.dart';
import 'package:palavra_viva/features/study/data/daily_verse_plan.dart';

void main() {
  test(
    'daily verse plan has one unique reference for each day of a leap year',
    () {
      final references = DailyVersePlan.entries
          .map((entry) => entry.reference)
          .toList(growable: false);

      expect(references, hasLength(366));
      expect(references.toSet(), hasLength(366));
    },
  );

  test('daily verse plan follows the calendar day of year', () {
    expect(DailyVersePlan.forDate(DateTime(2026)).reference, 'Salmos 1:1');
    expect(
      DailyVersePlan.forDate(DateTime(2024, 12, 31)).reference,
      'Colossenses 4:1',
    );
  });
}
