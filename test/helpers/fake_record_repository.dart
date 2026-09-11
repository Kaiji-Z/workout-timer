import 'package:workout_timer/models/exercise.dart';
import 'package:workout_timer/models/workout_record.dart';
import 'package:workout_timer/services/record_repository.dart';

/// In-memory [RecordRepository] fake: `dbRecords` plays the role of the
/// `workout_records` table, so tests can simulate rows that exist only in the
/// database and not yet in RecordProvider's in-memory list.
///
/// Members the providers under test never touch are rejected via
/// [noSuchMethod] to keep the fake explicit.
class FakeRecordRepository implements RecordRepository {
  final List<WorkoutRecord> dbRecords = [];

  /// Number of times the "database" was queried for the full record list.
  int getAllRecordsCalls = 0;

  @override
  Future<List<WorkoutRecord>> getAllRecords({
    int? limit,
    int? offset,
    List<Exercise>? exercises,
  }) async {
    getAllRecordsCalls++;
    return List.of(dbRecords);
  }

  @override
  Future<String> saveRecord(WorkoutRecord record) async {
    dbRecords.insert(0, record);
    return record.id;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} not faked');
}
