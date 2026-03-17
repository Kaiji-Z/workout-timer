# AI Stats Analysis Feature - Design Document

**Created:** 2026-03-17
**Author:** AI (Plan Agent)
**Status:** Draft

## Overview
在统计页面新增"AI 分析"功能，允许用户将训练数据导出给 AI 分析，并导入 AI 生成的训练计划。
## User Flow
```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│  统计页面        │    │ 弹窗配置        │    │  计划导入向导     │
│ 点击"AI 分析"   │    │ 选择目标/重点    │    │ 选择"统计AI分析"  │
│                 │    │                 │    │                 │
│                 │    │ 复制 Prompt    │    │ 粘贴 JSON        │
│                 │    │                 │    │                 │
│                 │    │ 跳转到向导   │    │ 逾览/确认导入        │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## Components
### 1. StatsScreen 修改
- 删除4个图表组件引用
- 添加"AI 分析"按钮（周视图/月视图）
- 新增 `_showAIAnalysisDialog()` 方法
- 新增 `_AIAnalysisConfig` 数据类

### 2. 新增 _AIAnalysisConfig 数据类
```dart
class _AIAnalysisConfig {
  final String goal; // muscle_building, fat_loss, strength, endurance
  final List<String> focusMuscles; // 重点加强部位
  final bool isPromptCopied; // Prompt 是否已复制

  _AIAnalysisConfig({
    required this.goal,
    required this.focusMuscles,
    this.isPromptCopied = false,
  });
  _AIAnalysisConfig copyWith({
    String? goal,
    List<String>? focusMuscles,
    bool? isPromptCopied,
  });
}
```
### 3. 新增 _showAIAnalysisDialog 方法
显示配置弹窗,包含
- 训练目标单选
- 重点部位多选
- 生成的 Prompt 展示区域
- 复制/导入按钮
- 操作说明
- 关闭按钮
- 复制后启用"导入 AI 建议"按钮
- 点击导入跳转到 AI 计划向导
### 4. 新增 AIStatsPromptService
```dart
class AIStatsPromptService {
  /// 生成统计导出 prompt
  String generateStatsPrompt({...});
  /// 生成导入提示 prompt
  String generateImportPrompt();
}
```
### 5. 修改 AIPlanWizardScreen
- 添加 `statsAnalysis` 导入模式
- 添加模式选择逻辑
- 添加导入处理流程
### 6. 扩展 StatsCalculatorService
- 添加趋势计算方法
### 7. 新增数据模型 (可选)
- StatsAnalysisImport
### 8. 新增测试
- AIStatsPromptService 单元测试
- StatsScreen widget 测试
- AIPlanWizardScreen 鷷成测试
### 9. 新增文档
- 本设计文档

## Implementation Order
1. Phase 1: 删除图表组件 (2h)
2. Phase 2: 添加 AI 分析 UI (3h)
3. Phase 3: 创建 AIStatsPromptService (1.5h)
4. Phase 4: 修改 AI 计划向导 (1.5h)
5. Phase 5: 扩展 StatsCalculatorService (30m)
6. Phase 6: 新增测试 (30m)
7. Phase 7: 添加文档 (15m)
8. Phase 8: 最终验证 (30m)
## Dependencies
- provider: 状态管理
- uuid: ID 生成
- intl: 日期格式化
- flutter/material:: UI 框架
- workout_repository: 训练数据获取
- exercise_service: 动作匹配
- stats_calculator_service: 统计计算
## File Changes
| File | Changes |
|------|--------|
| `lib/screens/stats_screen.dart` | 删除图表引用， 添加按钮、弹窗、 数据类 |
| `lib/services/ai_stats_prompt_service.dart` | 新建 |
| `lib/screens/ai_plan_wizard_screen.dart` | 添加导入模式 |
| `lib/services/stats_calculator_service.dart` | 扩展趋势计算 |
| `lib/models/stats_analysis_import.dart` | 新建 (可选) |
| `test/services/ai_stats_prompt_service_test.dart` | 新建 |
| `test/widgets/stats_screen_test.dart` | 新建 |
| `test/plan_screen_test.dart` | 新建 |
| `docs/plans/2026-03-17-ai-stats-analysis-feature.md` | 新建 |

## Estimated Time
6-10 小时
