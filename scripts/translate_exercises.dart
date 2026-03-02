// 批量翻译动作名称脚本
// 运行: dart run scripts/translate_exercises.dart

import 'dart:convert';
import 'dart:io';

const String apiUrl = 'https://translate.appworlds.cn';
const int delayMs = 2100; // 2.1秒间隔，避免频率限制

void main() async {
  // 读取动作名称
  final namesFile = File('exercise_names.txt');
  final names = await namesFile.readAsLines();
  
  print('共 ${names.length} 个动作需要翻译');
  
  final translations = <String, String>{};
  int completed = 0;
  
  for (final name in names) {
    if (name.trim().isEmpty) continue;
    
    try {
      // 调用翻译API
      final translated = await translate(name);
      translations[name] = translated;
      completed++;
      
      print('[$completed/${names.length}] $name -> $translated');
      
      // 延迟避免频率限制
      await Future.delayed(Duration(milliseconds: delayMs));
      
      // 每100个保存一次（防止中断丢失）
      if (completed % 100 == 0) {
        await saveTranslations(translations);
        print('已保存 $completed 个翻译');
      }
    } catch (e) {
      print('翻译失败: $name, 错误: $e');
      translations[name] = name; // 失败时保留英文
    }
  }
  
  // 最终保存
  await saveTranslations(translations);
  print('翻译完成！共 ${translations.length} 个');
}

Future<String> translate(String text) async {
  final encodedText = Uri.encodeComponent(text);
  final url = '$apiUrl?text=$encodedText&from=en&to=zh-CN';
  
  final client = HttpClient();
  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    
    if (response.statusCode == 200) {
      final body = await response.transform(utf8.decoder).join();
      final json = jsonDecode(body) as Map<String, dynamic>;
      
      if (json['code'] == 200) {
        return json['data'] as String? ?? text;
      } else {
        throw Exception('API error: ${json['msg']}');
      }
    } else {
      throw Exception('HTTP error: ${response.statusCode}');
    }
  } finally {
    client.close();
  }
}

Future<void> saveTranslations(Map<String, String> translations) async {
  final file = File('assets/data/exercise_translations.json');
  final encoder = JsonEncoder.withIndent('  ');
  final jsonString = encoder.convert(translations);
  await file.writeAsString(jsonString);
}
