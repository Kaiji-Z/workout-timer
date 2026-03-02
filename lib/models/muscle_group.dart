/// 肌肉部位分类
///
/// 参考Hevy/Strong等主流健身应用的分类方式
library;

/// 主要肌肉部位（6大类）
enum PrimaryMuscleGroup {
  chest,      // 胸
  back,       // 背
  shoulders,  // 肩
  arms,       // 手臂
  legs,       // 腿
  core,       // 核心
}

/// 次要肌肉部位（15个子分类）
enum SecondaryMuscleGroup {
  // 胸部
  upperChest,    // 上胸
  middleChest,   // 中胸
  lowerChest,    // 下胸
  // 背部
  lats,          // 背阔肌
  upperBack,     // 上背/斜方肌
  rhomboids,     // 菱形肌
  lowerBack,     // 下背
  // 肩部
  frontDelt,     // 前束
  sideDelt,      // 中束
  rearDelt,      // 后束
  // 手臂
  biceps,        // 二头肌
  triceps,       // 三头肌
  forearms,      // 前臂
  // 腿部
  quads,         // 股四头肌
  hamstrings,    // 腘绳肌
  glutes,        // 臀肌
  calves,        // 小腿
  // 核心
  abs,           // 腹直肌
  obliques,      // 腹外斜肌
}

/// 主要肌肉部位扩展方法
extension PrimaryMuscleGroupExtension on PrimaryMuscleGroup {
  /// 中文名称
  String get displayName {
    switch (this) {
      case PrimaryMuscleGroup.chest:
        return '胸';
      case PrimaryMuscleGroup.back:
        return '背';
      case PrimaryMuscleGroup.shoulders:
        return '肩';
      case PrimaryMuscleGroup.arms:
        return '手臂';
      case PrimaryMuscleGroup.legs:
        return '腿';
      case PrimaryMuscleGroup.core:
        return '核心';
    }
  }

  /// 英文名称
  String get nameEn {
    switch (this) {
      case PrimaryMuscleGroup.chest:
        return 'Chest';
      case PrimaryMuscleGroup.back:
        return 'Back';
      case PrimaryMuscleGroup.shoulders:
        return 'Shoulders';
      case PrimaryMuscleGroup.arms:
        return 'Arms';
      case PrimaryMuscleGroup.legs:
        return 'Legs';
      case PrimaryMuscleGroup.core:
        return 'Core';
    }
  }

  /// 对应的次要肌肉部位列表
  List<SecondaryMuscleGroup> get secondaryMuscles {
    switch (this) {
      case PrimaryMuscleGroup.chest:
        return [
          SecondaryMuscleGroup.upperChest,
          SecondaryMuscleGroup.middleChest,
          SecondaryMuscleGroup.lowerChest,
        ];
      case PrimaryMuscleGroup.back:
        return [
          SecondaryMuscleGroup.lats,
          SecondaryMuscleGroup.upperBack,
          SecondaryMuscleGroup.rhomboids,
          SecondaryMuscleGroup.lowerBack,
        ];
      case PrimaryMuscleGroup.shoulders:
        return [
          SecondaryMuscleGroup.frontDelt,
          SecondaryMuscleGroup.sideDelt,
          SecondaryMuscleGroup.rearDelt,
        ];
      case PrimaryMuscleGroup.arms:
        return [
          SecondaryMuscleGroup.biceps,
          SecondaryMuscleGroup.triceps,
          SecondaryMuscleGroup.forearms,
        ];
      case PrimaryMuscleGroup.legs:
        return [
          SecondaryMuscleGroup.quads,
          SecondaryMuscleGroup.hamstrings,
          SecondaryMuscleGroup.glutes,
          SecondaryMuscleGroup.calves,
        ];
      case PrimaryMuscleGroup.core:
        return [
          SecondaryMuscleGroup.abs,
          SecondaryMuscleGroup.obliques,
        ];
    }
  }

  /// 从字符串解析（支持 free-exercise-db 格式）
static PrimaryMuscleGroup? fromString(String value) {
switch (value.toLowerCase()) {
case 'chest':
return PrimaryMuscleGroup.chest;
      case 'back':
      case 'middle back':
      case 'lats':
      case 'lower back':
      case 'traps':
      case 'upper back':
return PrimaryMuscleGroup.back;
case 'shoulders':
case 'shoulder':
return PrimaryMuscleGroup.shoulders;
case 'arms':
      case 'arm':
      case 'biceps':
      case 'triceps':
      case 'forearms':
return PrimaryMuscleGroup.arms;
case 'legs':
      case 'leg':
      case 'quadriceps':
      case 'quads':
      case 'hamstrings':
      case 'glutes':
      case 'calves':
      case 'adductors':
      case 'abductors':
return PrimaryMuscleGroup.legs;
case 'core':
case 'abs':
case 'abdominals':
return PrimaryMuscleGroup.core;
default:
return null;
}
}
}

/// 次要肌肉部位扩展方法
extension SecondaryMuscleGroupExtension on SecondaryMuscleGroup {
  /// 中文名称
  String get displayName {
    switch (this) {
      case SecondaryMuscleGroup.upperChest:
        return '上胸';
      case SecondaryMuscleGroup.middleChest:
        return '中胸';
      case SecondaryMuscleGroup.lowerChest:
        return '下胸';
      case SecondaryMuscleGroup.lats:
        return '背阔肌';
      case SecondaryMuscleGroup.upperBack:
        return '上背';
      case SecondaryMuscleGroup.rhomboids:
        return '菱形肌';
      case SecondaryMuscleGroup.lowerBack:
        return '下背';
      case SecondaryMuscleGroup.frontDelt:
        return '前束';
      case SecondaryMuscleGroup.sideDelt:
        return '中束';
      case SecondaryMuscleGroup.rearDelt:
        return '后束';
      case SecondaryMuscleGroup.biceps:
        return '二头肌';
      case SecondaryMuscleGroup.triceps:
        return '三头肌';
      case SecondaryMuscleGroup.forearms:
        return '前臂';
      case SecondaryMuscleGroup.quads:
        return '股四头肌';
      case SecondaryMuscleGroup.hamstrings:
        return '腘绳肌';
      case SecondaryMuscleGroup.glutes:
        return '臀肌';
      case SecondaryMuscleGroup.calves:
        return '小腿';
      case SecondaryMuscleGroup.abs:
        return '腹直肌';
      case SecondaryMuscleGroup.obliques:
        return '腹外斜肌';
    }
  }

  /// 英文名称
  String get nameEn {
    switch (this) {
      case SecondaryMuscleGroup.upperChest:
        return 'Upper Chest';
      case SecondaryMuscleGroup.middleChest:
        return 'Middle Chest';
      case SecondaryMuscleGroup.lowerChest:
        return 'Lower Chest';
      case SecondaryMuscleGroup.lats:
        return 'Lats';
      case SecondaryMuscleGroup.upperBack:
        return 'Upper Back';
      case SecondaryMuscleGroup.rhomboids:
        return 'Rhomboids';
      case SecondaryMuscleGroup.lowerBack:
        return 'Lower Back';
      case SecondaryMuscleGroup.frontDelt:
        return 'Front Delt';
      case SecondaryMuscleGroup.sideDelt:
        return 'Side Delt';
      case SecondaryMuscleGroup.rearDelt:
        return 'Rear Delt';
      case SecondaryMuscleGroup.biceps:
        return 'Biceps';
      case SecondaryMuscleGroup.triceps:
        return 'Triceps';
      case SecondaryMuscleGroup.forearms:
        return 'Forearms';
      case SecondaryMuscleGroup.quads:
        return 'Quads';
      case SecondaryMuscleGroup.hamstrings:
        return 'Hamstrings';
      case SecondaryMuscleGroup.glutes:
        return 'Glutes';
      case SecondaryMuscleGroup.calves:
        return 'Calves';
      case SecondaryMuscleGroup.abs:
        return 'Abs';
      case SecondaryMuscleGroup.obliques:
        return 'Obliques';
    }
  }

  /// 所属的主要肌肉部位
  PrimaryMuscleGroup get primaryMuscle {
    switch (this) {
      case SecondaryMuscleGroup.upperChest:
      case SecondaryMuscleGroup.middleChest:
      case SecondaryMuscleGroup.lowerChest:
        return PrimaryMuscleGroup.chest;
      case SecondaryMuscleGroup.lats:
      case SecondaryMuscleGroup.upperBack:
      case SecondaryMuscleGroup.rhomboids:
      case SecondaryMuscleGroup.lowerBack:
        return PrimaryMuscleGroup.back;
      case SecondaryMuscleGroup.frontDelt:
      case SecondaryMuscleGroup.sideDelt:
      case SecondaryMuscleGroup.rearDelt:
        return PrimaryMuscleGroup.shoulders;
      case SecondaryMuscleGroup.biceps:
      case SecondaryMuscleGroup.triceps:
      case SecondaryMuscleGroup.forearms:
        return PrimaryMuscleGroup.arms;
      case SecondaryMuscleGroup.quads:
      case SecondaryMuscleGroup.hamstrings:
      case SecondaryMuscleGroup.glutes:
      case SecondaryMuscleGroup.calves:
        return PrimaryMuscleGroup.legs;
      case SecondaryMuscleGroup.abs:
      case SecondaryMuscleGroup.obliques:
        return PrimaryMuscleGroup.core;
    }
  }
}
