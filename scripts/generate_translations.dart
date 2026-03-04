// 生成本地翻译文件脚本
// 运行: dart run scripts/generate_translations.dart

import 'dart:convert';
import 'dart:io';
import '../lib/utils/fitness_vocabulary.dart';

void main() async {
  // 读取动作名称
  final namesFile = File('exercise_names.txt');
  if (!await namesFile.exists()) {
    print('错误: exercise_names.txt 文件不存在');
    print('请先运行: cat assets/data/exercises.json | grep \'"name":\' | sed \'s/.*"name": "//\' | sed \'s/".*//\' > exercise_names.txt');
    return;
  }
  
  final names = await namesFile.readAsLines();
  print('共 ${names.length} 个动作需要翻译');
  
  final translations = <String, String>{};
  
  for (final name in names) {
    if (name.trim().isEmpty) continue;
    final translated = translateExerciseName(name);
    translations[name] = translated;
    print('$name -> $translated');
  }
  
  // 保存到JSON文件
  final outputFile = File('assets/data/exercise_translations.json');
  await outputFile.parent.create(recursive: true);
  
  final encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(translations);
  await outputFile.writeAsString(jsonString);
  
  print('\n翻译完成！共 ${translations.length} 个');
  print('已保存到: ${outputFile.path}');
}
