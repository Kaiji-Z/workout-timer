import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_timer/services/user_preferences_service.dart';

/// 训练偏好持久化契约：写入必须真实落到 SharedPreferences 的 pref_* 键，
/// 回读一致；体重允许显式保存 0（= 清除已存体重，统计侧 bodyWeight<=0
/// 均按未设置处理，见 bodyweight_coefficient_service / stats_calculator_service）。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserPreferencesService.savePreferences', () {
    test('保存全部字段后回读一致', () async {
      final service = UserPreferencesService();
      await service.savePreferences(const UserPreferences(
        goal: 'fat_loss',
        experience: 'advanced',
        equipment: 'bodyweight',
        frequency: 6,
        focusAreas: 'chest,back',
        bodyWeight: 72.5,
      ));

      final loaded = await service.loadPreferences();
      expect(loaded.goal, 'fat_loss');
      expect(loaded.experience, 'advanced');
      expect(loaded.equipment, 'bodyweight');
      expect(loaded.frequency, 6);
      expect(loaded.focusAreasList, ['chest', 'back']);
      expect(loaded.bodyWeight, 72.5);
    });

    test('保存写入底层 SharedPreferences 的 pref_* 键', () async {
      final service = UserPreferencesService();
      await service.savePreferences(const UserPreferences(bodyWeight: 70.0));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('pref_goal'), 'muscle_building');
      expect(prefs.getString('pref_experience'), 'intermediate');
      expect(prefs.getString('pref_equipment'), 'gym');
      expect(prefs.getInt('pref_frequency'), 4);
      expect(prefs.getString('pref_focus_areas'), '');
      expect(prefs.getDouble('pref_body_weight'), 70.0);
    });

    test('保存 bodyWeight=0 清除已存体重（清空体重框场景）', () async {
      final service = UserPreferencesService();
      await service.savePreferences(const UserPreferences(bodyWeight: 70.0));
      expect((await service.loadPreferences()).bodyWeight, 70.0);

      // 用户清空体重输入框 = 明确要求不再使用体重 → 必须能存回 0，
      // 否则重进页面旧体重复活，用户感知「没保存」。
      await service.savePreferences(const UserPreferences(bodyWeight: 0.0));
      expect((await service.loadPreferences()).bodyWeight, 0.0);
    });
  });
}
