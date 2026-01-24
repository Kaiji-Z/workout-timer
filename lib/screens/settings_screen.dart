import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/workout_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final WorkoutRepository _repository = WorkoutRepository();
  late SharedPreferences _prefs;

  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _customMessage = '准备开始下一组！';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = _prefs.getBool('sound_enabled') ?? true;
      _vibrationEnabled = _prefs.getBool('vibration_enabled') ?? true;
      _customMessage = _prefs.getString('custom_message') ?? '准备开始下一组！';
    });
  }

  Future<void> _saveSettings() async {
    await _prefs.setBool('sound_enabled', _soundEnabled);
    await _prefs.setBool('vibration_enabled', _vibrationEnabled);
    await _prefs.setString('custom_message', _customMessage);
  }

  Future<void> _clearHistory() async {
    await _repository.clearAllSessions();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('历史记录已清除')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('通知设置', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('启用声音'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _saveSettings();
            },
          ),
          SwitchListTile(
            title: const Text('启用振动'),
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _saveSettings();
            },
          ),
          const SizedBox(height: 16),
          const Text('自定义提醒消息', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextField(
            controller: TextEditingController(text: _customMessage),
            onChanged: (value) => _customMessage = value,
            onSubmitted: (_) => _saveSettings(),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '输入提醒消息',
            ),
          ),
          const SizedBox(height: 32),
          const Text('数据管理', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _clearHistory,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('清除所有历史记录'),
          ),
        ],
      ),
    );
  }
}