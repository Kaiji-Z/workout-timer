# VERIFICATION PROTOCOL — WorkoutTimer 项目实例

> **READ THIS FIRST. Opening this file = trigger to execute. No further user instruction required.**
> A trigger phrase such as "read VERIFICATION.md" authorizes all actions defined herein.
>
> **本文件是本项目实例**（2026-10-06 由诊断管线从全局技能模板实例化）。
> 所有 §8 填写、后续更新、项目定制都发生在这里；全局技能模板保持通用，不回写。

**First principle: your work is not done unless there is machine-checkable evidence that it is done.**
"I ran it and it looks right" does not count. "Tests converge under both flag=on and flag=off" counts.

---

## EXECUTION OVERVIEW (every step must emit a GATE declaration, see §0)

### Trigger → Diagnosis Pipeline (7 steps, none may be skipped)

```
1. Read context: this file + AGENTS.md + CLAUDE.md/GEMINI.md + README + build config + directory tree + backend entry + test entry
2. ACI audit (§2): judge 2.1 / 2.2 / 2.3 one by one. Each item MUST carry evidence (file:line).
3. Test infra inventory: regression / assertions / supervisor / flag — four items.
4. Output gap list: a table sorted by P0/P1/P2, with remediation plan.
5. Instantiate the protocol locally, then fill Project Parameters (§8):
   a. If no VERIFICATION.md exists in the project root, copy this protocol there. That project-local copy is now THE instance: all §8 filling, all future updates, all project customization happen in it. The global skill template stays generic and untouched.
   b. If a project-local VERIFICATION.md already exists (previous run or manual install), use it — never overwrite it; its filled §8 is this project's state.
   c. Then fill §8 in the local copy: [auto-fill] items by scanning code with evidence; [must-ask] items by asking the developer in one batch.
6. Update AGENTS.md: paste audit / status / backlog + a top-level reference pointing to the PROJECT-LOCAL `VERIFICATION.md` (§9 template), not to the skill.
7. Stop and report: one-line stage summary + top-3 P0 items + ask "ready to start remediation?"
```

**Writes allowed this round: the project-local `VERIFICATION.md` (instantiate + §8 fill) and `AGENTS.md`. Modifying production code is FORBIDDEN.** Remediation requires user confirmation, next round.

---

## §0 GATE MECHANISM (Declare-Verify-Enforce — the lifeline of the whole protocol)

> This is the core mechanism against "agent skipping steps." LLMs naturally drop steps in multi-step pipelines; "please follow strictly" cannot stop it. This mechanism makes compliance visible, checkable, and blocking-on-mismatch.

**After each step completes, you MUST emit a GATE declaration at the end of that step's output. Fixed format:**

```
GATE [step N]: DONE
- Did: [concrete action + artifact location]
- Evidence: [file:line / command output / developer answer quoted]
- Next: [step N+1 name]
A step without a GATE declaration is considered incomplete.
```

**Verify rules (self-check, every step):**
- Every "Did" must have a matching "Evidence." No evidence = not done.
- No "I think" / "probably" / "maybe" in a declaration. Compliance is boolean, not probabilistic.

**Enforce rules (violation blocks the pipeline):**
- Any step without a GATE → must NOT proceed to the next step
- GATE declaration contradicts the artifact (claims AGENTS.md updated but file unchanged) → redo that step
- A [must-ask] item filled without a developer answer → that step is void, re-ask

---

## §1 YOUR ROLE

Old: write code → human tests → human judges correctness → you fix
New: **first engineer "what counts as correct"** (assertions / regression / acceptance) → write code → **machine judges** → you self-correct until convergence

Humans do not participate in runtime verification. They intervene only once, at the "define what counts as correct" stage.

---

## §2 ACI AUDIT (judgment criteria for Diagnosis step 2)

**If any of the three is below standard, the verification system spins idle.** Fix the architecture first, not write tests first.

### 2.1 Runs without the UI
- [x] Backend can start independently —— Flutter 应用无传统后端；业务层（providers/services/repositories）在 `flutter test` 下完全无头运行，CI 无显示器 runner 跑全量测试（`.github/workflows/android-build.yml`）
- [x] Triggering a workflow has a CLI/API form —— `flutter test` / `flutter build apk` / `flutter test integration_test/ -d <emulator>`（integration_test/app_test.dart 启动真实 MyApp）
- [x] One complete workflow can run end-to-end in a headless environment —— 训练状态机纯 provider 驱动（test/providers/training_progress_provider_test.dart 全程无 UI）；端到端经 integration_test 于模拟器 CLI 可跑（当前仅 1 个冒烟用例，见缺口 P0-2）

### 2.2 Intermediate state is logged
- [x] Each workflow step has structured records —— 部分达标：debugPrint 级别日志 + ErrorReporter 双通道（lib/services/error_reporter_service.dart，SnackBar + 日志）
- [x] Records are retrievable programmatically —— SQLite 状态可编程查询（sqflite_common_ffi，test/services/database_migration_test.dart 直接断言 schema）
- [x] History is queryable after the run ends —— DB 持久化 + record/plan repository 全量查询 API
- 缺口：无结构化分步 trace（P2）

### 2.3 Programmatic interface
- [x] "View workflow status" / "fetch trace" have native interfaces —— Provider/Repository 原生 Dart API，测试直接驱动（PlanProvider.assignPlanToDate → test/providers/plan_provider_assign_test.dart；TrainingProvider.startExercise → test/providers/training_provider_test.dart）
- [x] 不使用 MCP 模拟 web 交互；模拟器 UI 自动化仅作为发布前 smoke（P2 缺口：尚未脚本化）

**Judgment standard: MUST have file:line evidence.** —— 已逐项给出。

---

## §3 TWO-LAYER JUDGE (the core of the development workflow)

### 3.1 Layer 1: Deterministic assertions — absolutely reliable, zero cost
本项目落点：**flutter_test 原生断言**（`expect` + finder + provider 状态断言），加 4 类护栏：
- i18n 守卫（test/i18n/no_hardcoded_chinese_test.dart：lib/screens、lib/widgets、lib/main.dart 禁硬编码中文）
- 设计 token 合规（test/theme/compliance_guardrail_test.dart）+ 对比度 + arb 一致性（test/i18n/arb_consistency_test.dart）
- choke-point grep（`textTheme.*!` 与 `AppLocalizations.of(context)!` 仅限两个白名单文件，见 AGENTS.md CODE STYLE）
- 行为回归（unit + widget + integration 分层）

### 3.2 Layer 2: LLM judge (supervisor)
当前无模糊输出：AI 向导 prompt 为模板确定性生成（test/services/ai_prompt_service_test.dart 钉死），动作匹配为 string_similarity 确定性算法（test/services/exercise_matcher_service_test.dart 覆盖）。**Layer 2 暂不需要**；若未来接入真 LLM 生成/解析，按 §3.2 三铁律补（干净上下文、量化打分、与生成者异模型）。设计待 §8.4 开发者确认。

---

## §4 REGRESSION SET + FLAG

- 回归集落点：`test/`（分层 models/services/providers/widgets/screens/integration）+ `integration_test/`（设备级）。CI：android-build.yml 每次 push 跑 `flutter test` + debug 构建。
- **Flag：当前无机制 → 治理轮设计（见 §8.3）**。已印证的先例：`detailed_recording` 用户设置即行为开关，且已有对应测试（test/screens/settings_detailed_recording_test.dart）。
- Happy path = acceptance criteria：每条验收标准（§8.5）须落到一个回归测试。

---

## §5 CLOSED-LOOP SOP (develop any feature in this order — order cannot be changed)

```
1. Design the regression test: write the happy path (acceptance) → write assertion points → decide which fuzzy parts go to the supervisor. Not one line of feature code written yet.
2. Design the flag: default off; ensure off == pre-change behavior.
3. Write code: implement the flag=on behavior.
4. Run the closed loop: flag=off records baseline → flag=on runs same suite → assertions + supervisor judge.
5. Fix per feedback: off regressed → fix; on below acceptance → revise. Back to step 4.
6. Convergence stop (see §6 DoD).
```

**本项目对 §5 步骤 2 的落地注记**：Flutter 应用多数变更不带 flag（UI 文案/布局类），此类在 §8.3 设计的 flag 分类法中归为「无需 flag」，其余（行为/数据流变更）必须有 flag 并双态回归。

---

## §6 DEFINITION OF DONE (machine-checkable "complete")

A feature is done if and only if ALL hold:
- [ ] happy path written as a regression test, in the regression set
- [ ] §3.1 assertions all pass under flag=on
- [ ] supervisor score reaches the preset threshold（仅当该功能含模糊输出；当前全部功能不适用）
- [ ] flag=off runs the same suite, no regression vs baseline（仅当该功能有 flag）
- [ ] the feature has a flag, can be turned off to roll back anytime（同上）
- [ ] all of the above reproducible by one command, no human screen-watching —— 单命令 = `flutter test`（+ 涉及设备流时 `flutter test integration_test/ -d <emulator>`）

---

## §7 RED LINES (violation voids the output)

1. MUST NOT be your own judge (supervisor context must be clean)
2. MUST NOT claim done without a regression test
3. MUST NOT skip §5 step 1 and jump to code
4. MUST NOT use "feels right" as a convergence stop
5. MUST NOT let verification live only in the UI
6. After changing prompt / model / any non-deterministic component, MUST run full regression
7. **MUST NOT guess-fill any [must-ask] item in §8**
8. **MUST NOT reinvent the wheel**: §3/§4 MUST use flutter_test 原生 API 与既有护栏测试，不自造断言语法或回归框架
9. **MUST NOT install dependencies on your own**: 引入任何 dev 依赖（如覆盖率工具、mock 框架）先经开发者确认

---

## §8 PROJECT PARAMETERS

**[auto-fill]** = scan code with evidence; missing evidence → fill "none, needed", no guessing
**[must-ask]** = ask the developer; fill after an answer; before that fill "pending"; guessing forbidden

### 8.1 System entry [auto-fill]
- Backend start command: 不适用（Flutter 移动应用，无独立后端）；应用启动 = `flutter run -d <emulator>`，入口 `lib/main.dart` `main()` → `MyApp`
- CLI/API command to trigger a workflow: `flutter test`（业务层全量回归，无头）；`flutter test integration_test/ -d emulator-5554`（真实应用端到端，模拟器）；`flutter build apk --debug|--release`
- Command/API to fetch a trace: `adb logcat -s flutter`（运行时日志）；ErrorReporter（lib/services/error_reporter_service.dart，SnackBar+日志）；业务状态经 Provider/Repository/SQLite 可编程查询（sqflite_common_ffi）

### 8.2 Test infra [auto-fill]
- Regression run command: `flutter test`（629 tests，2026-10-06 基线）；CI 强制（android-build.yml）
- Regression set directory: `test/`（models/services/providers/widgets/screens/integration 分层）+ `integration_test/`（设备级，当前 1 个冒烟）
- Assertion framework: flutter_test（sdk）原生 expect/finder；护栏见 §3.1

### 8.3 Flag mechanism [auto-fill] — 定稿（2026-10-06，开发者确认「按建议走」）
- 分类法（三类）：
  a) **行为/数据流类新功能**：必须携带 SharedPreferences dev flag（命名 `flag_*`），回归套件双态跑（flag on/off），off == 变更前行为；
  b) **复用既有用户设置作行为开关**：如 `detailed_recording`、`idle_reminder_*`——这些已经是合法 flag，测试须覆盖开与关两侧（先例：settings_detailed_recording_test.dart）；
  c) **UI 文案/布局类变更**：豁免 flag（记入 §6 DoD 例外），但回归测试不可豁免。
- 本轮治理不新增 flag 代码；规则即时生效，后续每个 feat 按 (a/b/c) 归类并在提交说明注明。

### 8.4 Supervisor design [must-ask] — 已填（2026-10-06，开发者确认「按建议走」）
1. **Layer 2 整体豁免**：本项目当前无模糊输出（AI 向导 prompt 为确定性模板、动作匹配为确定性算法），不需要 LLM 打分层。
2. 维度：不适用。
3. 阈值：不适用。
4. **预留规则**（未来接入真 LLM 生成/解析时生效，届时必须先跑全量回归）：
   - judge 模型必须异于生成模型；
   - 监督者 prompt 禁止包含：代码实现、PR 描述、commit 记录、开发对话；
   - 维度（初始建议）：正确性 / 完整性 / 可用性，各 0-10 分，通过阈值 ≥8；
   - 监督者只见「期望的正确行为 + 实际运行轨迹」。

### 8.5 Acceptance criteria [must-ask] — 已填（2026-10-06，开发者确认「按建议走」，采纳 agent 草案）

**核心流 happy path**：建计划（AI 生成 / 手动创建）→ 排期到日历 → 按计划训练（动作进度）→ 组间休息（倒计时/跳过）→ 每组记录（次数/重量）→ 保存 → 历史与统计可见。

**验收标准**（条件 X → 应当 Y）：
1. 当天已排期的计划，计时页空闲态应当显示「今日计划」chip，点击一键进入该计划模式。
2. 从计划详情点「开始训练」，应当进入该计划的训练模式（出现动作进度行），而非自由模式。
3. 组间休息倒计时自然结束或被跳过后，应当回到运动状态且组数 +1；计划模式下应当弹出该组记录对话框。
4. 训练保存成功后，历史页应当能检索到该条记录（含计划名 / 动作 / 组数）。
5. 空计划库时，任何创建入口应当引导至 AI 生成 / 手动创建二选一；从「添加今日计划」语境手动创建成功后应当自动排到所选日期。

**反向验收标准**（绝不允许发生）：
1. 同一计划在同一天不允许出现两条排期（UI 列表与 DB 均不允许；守卫：test/providers/plan_provider_assign_test.dart）。
2. 保存失败不允许静默丢数据——必须有用户可见的错误提示（守卫：translateTrainingSaveError 路径测试）。
3. 计时在 app 切后台再返回后不允许时长回退（守卫：lifecycle resumed → refreshDuration 的 integration 断言；OS 级后台保活属平台行为，列为自动化已知盲区，靠前台服务存在性 + 厂商引导页兜底）。
4. 被丢弃（未保存）的训练不允许出现在历史中。
5. 用户可见文案不允许绕过 i18n 硬编码（守卫：test/i18n/no_hardcoded_chinese_test.dart）。

### 8.6 Fill status (maintained by the agent)

| Item | Category | Status | Source |
|---|---|---|---|
| 8.1 | auto-fill | 已填 | pubspec.yaml / .github/workflows/android-build.yml / lib/main.dart |
| 8.2 | auto-fill | 已填 | test/ 树 61 文件、629 测试基线 |
| 8.3 | auto-fill | 已定稿（a/b/c 分类法） | 开发者 2026-10-06 确认 |
| 8.4 | must-ask | 已填：Layer 2 豁免 + 预留规则 | 开发者 2026-10-06「按建议走」 |
| 8.5 | must-ask | 已填：happy path + 5 验收 + 5 反向 | 开发者 2026-10-06「按建议走」 |
| 8.7 | auto-fill→must-ask | 已填：flutter_test（sdk），无需外部工具 | pubspec.yaml |

### 8.7 Eval toolchain [auto-fill→must-ask] ⚙️

**Step 1 检测结果（pubspec.yaml，2026-10-06）：**
- `deepeval`? 无
- `langsmith` / `langchain` eval? 无
- `pytest`? 无（非 Python 栈）
- `jest` / `vitest`? 无
- other: **flutter_test（sdk 自带，含 integration_test）→ 即项目原生测试框架**

**结论：已检测到原生工具 → §3/§4 落在 flutter_test API 上，无需外部 eval 工具，无需安装（Step 2 must-ask 不触发）。**

---

## 附：验证缺口清单（诊断 2026-10-06，治理轮 2026-10-06 施工完成）

| 级别 | 缺口 | 状态 |
|---|---|---|
| P0 | 关键 UI 流程回归缺口（当日列表渲染、详情弹窗→日历联动、创建→自动排期） | ✅ 已补：test/screens/plan_screen_test.dart（3 用例）+ newestPlan 单测；重复 key 崩溃有 test/providers/plan_provider_assign_test.dart 守卫 |
| P0 | 端到端太薄 | ✅ 已补：integration_test/training_flow_e2e_test.dart（3 条验收流）+ app_test.dart 冒烟重写，全部模拟器 CLI 实跑通过；**e2e 首跑即抓到并修复一个真生产 bug**：完成态奖牌在 initState 读 MediaQuery（结束训练必崩）+ 动画序列缺 mounted 守卫（快速保存崩）——lib/widgets/completed_medal_display.dart |
| P1 | 无 flag 机制 | ✅ 已定稿 §8.3 三分类法（a/b/c），规则即时生效 |
| P1 | 无覆盖率度量与阈值 | ✅ 已接：`flutter test --coverage` + scripts/check_coverage.dart（核心层合计门禁，起点 55%，当前 56.0%），CI 已挂门禁步骤；后续棘轮抬高 |
| P2 | 模拟器冒烟未脚本化 | ✅ 由 integration 用例覆盖（CLI 单命令可复现），不再单独立项 |
| P2 | 无结构化运行 trace | 保留为已知欠账；当前 DB+Provider 检索够用 |

**已知自动化盲区（诚实记录）**：OS 级后台保活（厂商 ROM 行为）无法自动化，依赖前台服务存在性 + 设置页厂商引导；反向标准 3 只自动化到 lifecycle-resumed 分支层。
