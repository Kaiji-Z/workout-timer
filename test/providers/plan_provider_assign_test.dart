import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:workout_timer/core/service_locator.dart';
import 'package:workout_timer/models/muscle_group.dart';
import 'package:workout_timer/models/workout_plan.dart';
import 'package:workout_timer/providers/plan_provider.dart';
import 'package:workout_timer/services/database_helper.dart';

/// 同一计划重复排到同一天不应产生重复条目——
/// 计划页按 plan.id 生成 Dismissible key，内存列表重复会直接崩
/// （Duplicate keys found）。
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await DatabaseHelper.resetForTesting();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ServiceLocator.setup();
  });

  WorkoutPlan planFixture({String id = 'plan-dupe-1'}) {
    return WorkoutPlan(
      id: id,
      name: '推举日',
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [
        PlanExercise(exerciseId: 'e1', targetSets: 3, order: 0),
      ],
      createdAt: DateTime(2026, 1, 1),
    );
  }

  test('重复 assignPlanToDate 内存列表不重复', () async {
    final provider = PlanProvider();
    final plan = planFixture();
    await provider.createPlan(plan);

    final date = DateTime(2026, 10, 6);
    await provider.assignPlanToDate(plan.id, date);
    await provider.assignPlanToDate(plan.id, date);

    expect(provider.getPlansForDate(date).length, 1);
  });

  test('newestPlan 返回 createdAt 最新的计划', () async {
    final provider = PlanProvider();
    final older = WorkoutPlan(
      id: 'plan-old',
      name: '旧计划',
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [PlanExercise(exerciseId: 'e1', targetSets: 1, order: 0)],
      createdAt: DateTime(2026, 1, 1),
    );
    final newer = WorkoutPlan(
      id: 'plan-new',
      name: '新计划',
      targetMuscles: const [PrimaryMuscleGroup.chest],
      exercises: [PlanExercise(exerciseId: 'e1', targetSets: 1, order: 0)],
      createdAt: DateTime(2026, 2, 1),
    );
    // 先建新的再建旧的，证明不是依赖插入顺序。
    await provider.createPlan(newer);
    await provider.createPlan(older);

    expect(provider.newestPlan?.id, 'plan-new');
  });

  test('空计划库时 newestPlan 为 null', () {
    final provider = PlanProvider();
    expect(provider.newestPlan, isNull);
  });
}
