import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';
import '../models/user_profile.dart';
import '../models/weekly_plan_import.dart';
import '../services/ai_prompt_service.dart';
import '../services/user_preferences_service.dart';
import '../bloc/plan_provider.dart';
import '../widgets/glass_widgets.dart';

class AIPlanWizardScreen extends StatefulWidget {
  const AIPlanWizardScreen({super.key});

  @override
  State<AIPlanWizardScreen> createState() => _AIPlanWizardScreenState();
}

class _AIPlanWizardScreenState extends State<AIPlanWizardScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _jsonController = TextEditingController();
  
  int _currentStep = 0;
  int _activeTab = 0; // 0 = 新建计划, 1 = 导入分析
  
  // Step 1 state (新建计划)
  String _goal = 'muscle_building';
  int _weeklyFrequency = 4;
  int _sessionDuration = 60;
  String _experience = 'intermediate';
  String _equipment = 'gym';
  List<String> _focusAreas = [];
  
  // Step 2 state
  DateTime _startDate = _nextMonday();
  String? _generatedPrompt;
  
  // Step 3 state (import analysis)
  String? _parseError;
  bool _isParsing = false;
  
  // Step 4 state (preview + import)
  WeeklyPlanImport? _parsedPlan;
  bool _isImporting = false;
  final Map<String, int> _editableSets = {};
  
  bool _preferencesLoaded = false;
  
  static DateTime _nextMonday() {
    final now = DateTime.now();
    final daysUntilMonday = (DateTime.monday - now.weekday + 7) % 7;
    return DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilMonday == 0 ? 7 : daysUntilMonday));
  }
  
  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }
  
  Future<void> _loadPreferences() async {
    try {
      final service = UserPreferencesService();
      final prefs = await service.loadPreferences()
          .timeout(const Duration(seconds: 2));
      if (mounted) {
        setState(() {
          _goal = prefs.goal;
          _weeklyFrequency = prefs.frequency;
          _experience = prefs.experience;
          _equipment = prefs.equipment;
          _focusAreas = prefs.focusAreasList;
          _preferencesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences, using defaults: $e');
      if (mounted) {
        setState(() => _preferencesLoaded = true);
      }
    }
  }
  
  @override
  void dispose() {
    _pageController.dispose();
    _jsonController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>().currentTheme;
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: theme.timerGradientColors),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'AI PLAN GENERATOR',
              style: TextStyle(
                fontFamily: '.SF Pro Display',
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: theme.textColor,
              ),
            ),
          ],
        ),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: _previousStep,
              child: Text(
                '上一步',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  color: theme.accentColor,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildStepIndicator(theme),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: _activeTab == 1
                  ? [
                      // Import analysis flow: 2 pages
                      _buildStep1(theme), // Contains the tab with import form
                      _buildStep4(theme), // Preview + import
                    ]
                  : [
                      // New plan flow: 4 pages (existing)
                      _buildStep1(theme), // Contains the tab with new plan form
                      _buildStep2(theme),
                      _buildStep3(theme),
                      _buildStep4(theme),
                    ],
            ),
          ),
          _buildBottomButton(theme),
        ],
      ),
    );
  }
  
  Widget _buildStepIndicator(AppThemeData theme) {
    final isImport = _activeTab == 1;
    final stepLabels = isImport
        ? ['导入分析', '预览导入']
        : ['个人资料', '生成提示词', '粘贴JSON', '预览导入'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          for (int i = 0; i < stepLabels.length; i++) ...[
            if (i > 0) _buildStepLine(_currentStep >= i, theme),
            _buildStepItem(i + 1, stepLabels[i], _currentStep >= i, theme),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStepItem(int number, String label, bool isActive, AppThemeData theme) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isActive && _currentStep > number - 1
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$number',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isActive ? Colors.white : theme.secondaryTextColor,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 12,
            color: isActive ? theme.textColor : theme.secondaryTextColor,
          ),
        ),
      ],
    );
  }
  
  Widget _buildStepLine(bool isActive, AppThemeData theme) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isActive ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
      ),
    );
  }
  
  // ==================== 第1步：Tab切换（新建计划 / 导入分析） ====================
  Widget _buildStep1(AppThemeData theme) {
    return Column(
      children: [
        // Tab bar
        Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.textColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTab('新建计划', 0, theme),
              _buildTab('导入分析', 1, theme),
            ],
          ),
        ),
        // Tab content
        Expanded(
          child: _activeTab == 0
              ? _buildNewPlanForm(theme)
              : _buildImportAnalysisForm(theme),
        ),
      ],
    );
  }
  
  Widget _buildTab(String label, int index, AppThemeData theme) {
    final isActive = _activeTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTab = index;
            _currentStep = 0;
            _pageController.jumpToPage(0);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? theme.accentColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : theme.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // ==================== 新建计划表单（原Step1内容） ====================
  Widget _buildNewPlanForm(AppThemeData theme) {
    if (!_preferencesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '个人训练资料',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '请回答以下问题，帮助AI生成最适合您的训练计划',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          _buildSingleSelectQuestion(
            '训练目标',
            _goal,
            {'增肌': 'muscle_building', '减脂': 'fat_loss', '力量': 'strength', '耐力': 'endurance'},
            (value) => setState(() => _goal = value),
            theme,
          ),
          const SizedBox(height: 16),
          
          _buildSingleSelectQuestion(
            '每周训练频率',
            '$_weeklyFrequency',
            {'3天': '3', '4天': '4', '5天': '5', '6天': '6'},
            (value) => setState(() => _weeklyFrequency = int.parse(value)),
            theme,
          ),
          const SizedBox(height: 16),
          
          _buildSingleSelectQuestion(
            '训练时长',
            '$_sessionDuration',
            {'45分钟': '45', '60分钟': '60', '75分钟': '75', '90分钟': '90'},
            (value) => setState(() => _sessionDuration = int.parse(value)),
            theme,
          ),
          const SizedBox(height: 16),
          
          _buildSingleSelectQuestion(
            '经验水平',
            _experience,
            {'初学者': 'beginner', '中级': 'intermediate', '高级': 'advanced'},
            (value) => setState(() => _experience = value),
            theme,
          ),
          const SizedBox(height: 16),
          
          _buildSingleSelectQuestion(
            '设备可用性',
            _equipment,
            {'健身房': 'gym', '家用哑铃': 'home_dumbbell', '徒手': 'bodyweight'},
            (value) => setState(() => _equipment = value),
            theme,
          ),
          const SizedBox(height: 16),
          
          _buildMultiSelectQuestion(
            '重点部位',
            _focusAreas,
            ['胸部', '背部', '肩部', '手臂', '腿部', '核心'],
            (value) => setState(() => _focusAreas = value),
            theme,
          ),
        ],
      ),
    );
  }
  
  // ==================== 导入分析表单（新增） ====================
  Widget _buildImportAnalysisForm(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '导入AI分析计划',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '将AI返回的JSON计划粘贴到下方，预览后直接导入',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _jsonController,
            maxLines: 10,
            minLines: 6,
            decoration: InputDecoration(
              labelText: 'JSON内容',
              labelStyle: TextStyle(color: theme.textColor),
              border: const OutlineInputBorder(),
              errorText: _parseError,
              helperText: '请粘贴AI生成的训练计划JSON',
              helperMaxLines: 2,
            ),
            onChanged: (_) {
              if (_parseError != null) {
                setState(() => _parseError = null);
              }
            },
          ),
          const SizedBox(height: 16),
          PrimaryActionButton(
            label: _isParsing ? '解析中...' : '解析JSON',
            onPressed: _isParsing ? null : _parseJsonForImport,
            height: 56,
          ),
          if (_parseError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6E6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE53935)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: const TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  /// Parse JSON for import analysis tab - goes directly to preview
  void _parseJsonForImport() async {
    if (_jsonController.text.isEmpty) {
      setState(() => _parseError = '请输入JSON内容');
      return;
    }
    
    setState(() {
      _isParsing = true;
      _parseError = null;
    });
    
    try {
      final jsonMap = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      final parsedPlan = WeeklyPlanImport.fromJson(jsonMap);
      setState(() {
        _isParsing = false;
        _parsedPlan = parsedPlan;
        _currentStep = 1; // Go to preview step (step 2 in import mode)
        _pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
    } catch (e) {
      setState(() {
        _isParsing = false;
        _parseError = 'JSON解析失败: ${e.toString()}';
      });
    }
  }
  
  Widget _buildSingleSelectQuestion(
    String title,
    String currentValue,
    Map<String, String> options,
    ValueChanged<String> onChanged,
    AppThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.entries.map((entry) {
            final isSelected = entry.value == currentValue;
            return GestureDetector(
              onTap: () => onChanged(entry.value),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.accentColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  Widget _buildMultiSelectQuestion(
    String title,
    List<String> selectedValues,
    List<String> options,
    ValueChanged<List<String>> onChanged,
    AppThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: '.SF Pro Text',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: theme.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return GestureDetector(
              onTap: () {
                final newValues = List<String>.from(selectedValues);
                if (isSelected) {
                  newValues.remove(option);
                } else {
                  newValues.add(option);
                }
                onChanged(newValues);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? theme.accentColor : theme.accentColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : theme.accentColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  // ==================== 第2步：日期 + 生成提示词 ====================
  Widget _buildStep2(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '生成AI提示词',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '设置开始日期并生成提示词，复制到AI应用获取训练计划',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          Text(
            '开始日期',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (context, child) {
                  return Theme(
                    data: ThemeData(
                      useMaterial3: true,
                      colorScheme: ColorScheme.light(
                        primary: theme.accentColor,
                        onPrimary: Colors.white,
                        secondary: theme.accentColor,
                        surface: theme.surfaceColor,
                        onSurface: theme.textColor,
                        error: const Color(0xFFE53935),
                        onError: Colors.white,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) {
                setState(() => _startDate = date);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_startDate.year}年${_startDate.month}月${_startDate.day}日',
                    style: TextStyle(
                      fontFamily: '.SF Pro Text',
                      fontSize: 16,
                      color: theme.textColor,
                    ),
                  ),
                  Icon(
                    Icons.calendar_today,
                    color: theme.accentColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          PrimaryActionButton(
            label: '生成提示词',
            onPressed: _generatePrompt,
            height: 56,
          ),
          const SizedBox(height: 24),
          
          if (_generatedPrompt != null) ...[
            Text(
              '生成的提示词',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Text(
                  _generatedPrompt!,
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            PrimaryActionButton(
              label: '复制到剪贴板',
              onPressed: _copyToClipboard,
              height: 56,
            ),
            const SizedBox(height: 16),
            
            Text(
              '将此提示词复制到豆包/千问等AI应用，获取JSON后返回粘贴',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 12,
                color: theme.secondaryTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  void _generatePrompt() {
    final aiPromptService = AIPromptService();
    final userProfile = UserProfile(
      goal: _goal,
      weeklyFrequency: _weeklyFrequency,
      sessionDuration: _sessionDuration,
      experience: _experience,
      equipment: _equipment,
      focusAreas: _focusAreas,
      startDate: _startDate,
    );
    final prompt = aiPromptService.generatePrompt(userProfile);
    setState(() => _generatedPrompt = prompt);
  }
  
  Future<void> _copyToClipboard() async {
    if (_generatedPrompt != null) {
      await Clipboard.setData(ClipboardData(text: _generatedPrompt!));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已复制到剪贴板'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }
  
  // ==================== 第3步：粘贴JSON ====================
  Widget _buildStep3(AppThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '粘贴AI返回的JSON',
            style: TextStyle(
              fontFamily: '.SF Pro Display',
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: theme.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '将AI生成的JSON粘贴到下方文本框',
            style: TextStyle(
              fontFamily: '.SF Pro Text',
              fontSize: 14,
              color: theme.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _jsonController,
            maxLines: 10,
            minLines: 6,
            decoration: InputDecoration(
              labelText: 'JSON内容',
              labelStyle: TextStyle(color: theme.textColor),
              border: const OutlineInputBorder(),
              errorText: _parseError,
              helperText: '请粘贴AI生成的训练计划JSON',
              helperMaxLines: 2,
            ),
            onChanged: (_) {
              if (_parseError != null) {
                setState(() => _parseError = null);
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          PrimaryActionButton(
            label: _isParsing ? '解析中...' : '解析JSON',
            onPressed: _isParsing ? null : _parseJson,
            height: 56,
          ),
          
          if (_parseError != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF5E6E6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE53935)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Color(0xFFE53935), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _parseError!,
                      style: const TextStyle(
                        fontFamily: '.SF Pro Text',
                        fontSize: 14,
                        color: Color(0xFFE53935),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _parseJson() async {
    if (_jsonController.text.isEmpty) {
      setState(() => _parseError = '请输入JSON内容');
      return;
    }
    
    setState(() {
      _isParsing = true;
      _parseError = null;
    });
    
    try {
      final jsonMap = jsonDecode(_jsonController.text) as Map<String, dynamic>;
      final parsedPlan = WeeklyPlanImport.fromJson(jsonMap);
      setState(() {
        _isParsing = false;
        _parsedPlan = parsedPlan;
      });
      
      if (_currentStep < 3) {
        setState(() => _currentStep = 3);
        _pageController.animateToPage(
          3,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      setState(() {
        _isParsing = false;
        _parseError = 'JSON解析失败: ${e.toString()}';
      });
    }
  }
  
  // ==================== 第4步：预览 + 导入 ====================
  Widget _buildStep4(AppThemeData theme) {
    if (_parsedPlan == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.info_outline, size: 48, color: theme.secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              '请先解析JSON以预览训练计划',
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                color: theme.secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '预览训练计划',
                  style: TextStyle(
                    fontFamily: '.SF Pro Display',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: theme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '计划名称: ${_parsedPlan!.name}',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.secondaryTextColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                ..._parsedPlan!.days.map((day) => _buildDayCard(day, theme)),
              ],
            ),
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.all(20),
          child: PrimaryActionButton(
            label: _isImporting ? '导入中...' : '确认导入',
            onPressed: _isImporting ? null : _importPlan,
            height: 56,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDayCard(DailyPlanImport day, AppThemeData theme) {
    final dayNames = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    final dayName = dayNames[day.dayOfWeek - 1];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '第${day.dayOfWeek}天 - $dayName',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
                Text(
                  day.exercises.isEmpty ? '休息日' : '${day.exercises.length}个动作',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    color: theme.secondaryTextColor,
                  ),
                ),
              ],
            ),
            if (day.targetMuscles.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '目标肌群: ${day.targetMuscles.join(", ")}',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
            const SizedBox(height: 12),
            ...day.exercises.map((exercise) => _buildExerciseRow(exercise, day.dayOfWeek, theme)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExerciseRow(ExerciseEntryImport exercise, int dayOfWeek, AppThemeData theme) {
    final exerciseKey = 'day${dayOfWeek}-${exercise.exerciseName}';
    final currentSets = _editableSets[exerciseKey] ?? exercise.targetSets;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              exercise.exerciseName,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 14,
                color: theme.textColor,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle_outline, color: theme.accentColor, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    final newSets = currentSets - 1;
                    if (newSets >= 1) {
                      _editableSets[exerciseKey] = newSets;
                    }
                  });
                },
              ),
              Container(
                width: 32,
                alignment: Alignment.center,
                child: Text(
                  '$currentSets',
                  style: TextStyle(
                    fontFamily: '.SF Pro Text',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.textColor,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.add_circle_outline, color: theme.accentColor, size: 20),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
                onPressed: () {
                  setState(() {
                    _editableSets[exerciseKey] = currentSets + 1;
                  });
                },
              ),
              const SizedBox(width: 4),
              Text(
                '组',
                style: TextStyle(
                  fontFamily: '.SF Pro Text',
                  fontSize: 12,
                  color: theme.secondaryTextColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Future<void> _importPlan() async {
    if (_parsedPlan == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认导入'),
        content: const Text('确定要导入这个训练计划吗？计划将被添加到日历中。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('确认'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      await context.read<PlanProvider>().importWeeklyPlan(_parsedPlan!, _startDate);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('训练计划导入成功！'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: const Color(0xFFE53935),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }
  
  // ==================== 底部按钮 ====================
  Widget _buildBottomButton(AppThemeData theme) {
    String buttonText;
    bool isEnabled;
    VoidCallback? onPressed;
    
    if (_activeTab == 1) {
      // Import analysis flow
      switch (_currentStep) {
        case 0:
          buttonText = '下一步：预览导入';
          isEnabled = _parsedPlan != null;
          onPressed = isEnabled ? () {
            setState(() => _currentStep = 1);
            _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          } : null;
          break;
        case 1:
          buttonText = '完成';
          isEnabled = _parsedPlan != null && !_isImporting;
          onPressed = isEnabled ? _importPlan : null;
          break;
        default:
          buttonText = '';
          isEnabled = false;
          onPressed = null;
      }
    } else {
      // New plan flow (existing logic)
      switch (_currentStep) {
        case 0:
          buttonText = '下一步：生成提示词';
          isEnabled = true;
          onPressed = _nextStep;
          break;
        case 1:
          buttonText = '下一步：粘贴JSON';
          isEnabled = _generatedPrompt != null;
          onPressed = isEnabled ? _nextStep : null;
          break;
        case 2:
          buttonText = '下一步：预览导入';
          isEnabled = _parsedPlan != null;
          onPressed = isEnabled ? _nextStep : null;
          break;
        case 3:
          buttonText = '完成';
          isEnabled = _parsedPlan != null && !_isImporting;
          onPressed = isEnabled ? _importPlan : null;
          break;
        default:
          buttonText = '';
          isEnabled = false;
          onPressed = null;
      }
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? theme.accentColor : theme.textColor.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              buttonText,
              style: TextStyle(
                fontFamily: '.SF Pro Text',
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : theme.secondaryTextColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _nextStep() {
    final maxStep = _activeTab == 1 ? 1 : 3;
    if (_currentStep < maxStep) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }
}
