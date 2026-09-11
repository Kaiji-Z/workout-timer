import 'package:flutter_test/flutter_test.dart';
import 'package:workout_timer/providers/record_provider.dart';
import 'package:workout_timer/services/error_reporter_service.dart';

import '../helpers/fake_record_repository.dart';

void main() {
  // loadRecords touches rootBundle via ExerciseService.loadExercises.
  TestWidgetsFlutterBinding.ensureInitialized();

  test('concurrent loadRecords calls share a single repository read', () async {
    final repo = FakeRecordRepository();
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );

    await Future.wait([
      provider.loadRecords(),
      provider.loadRecords(),
      provider.loadRecords(),
    ]);

    expect(repo.getAllRecordsCalls, 1);
  });

  test('a load started after the previous one finished re-reads', () async {
    final repo = FakeRecordRepository();
    final provider = RecordProvider(
      repository: repo,
      errorReporter: ErrorReporter(),
    );

    await provider.loadRecords();
    await provider.loadRecords();

    expect(repo.getAllRecordsCalls, 2);
  });
}
