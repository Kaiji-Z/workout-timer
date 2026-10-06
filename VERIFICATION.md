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

### 8.3 Flag mechanism [auto-fill]
- 现状：无开发用 flag 机制 → **design during remediation**。候选方案（待治理轮确认）：
  a) 行为类新功能必须携带 SharedPreferences dev flag（命名 `flag_*`），回归双态跑；
  b) 复用既有用户设置作行为开关（`detailed_recording` 先例）；
  c) UI 文案/布局类变更豁免 flag（记入 DoD 例外），但必须有回归测试。

### 8.4 Supervisor design [must-ask] ⚠️ pending
> 待开发者回答：
1. 哪个模型给模糊部分打分？（或：确认本项目暂无模糊输出、Layer 2 整体豁免？）
2. 打分维度有哪些？
3. 每维度通过阈值？
4. 监督者 prompt 禁止包含什么？（默认禁止：代码实现 / PR 描述 / commit / 开发对话）

### 8.5 Acceptance criteria [must-ask] ⚠️ pending
> 待开发者回答：
1. 核心工作流的 happy path？（输入 → 动作 → 分支 → 输出；本项目核心流候选：建计划(AI/手动)→排期→按计划训练→组间休息→每组记录→保存→历史/统计可见）
2. 3–5 条验收标准，形如「在条件 X 下，应当 Y」？
3. 反向验收标准（绝不允许发生的行为）？

### 8.6 Fill status (maintained by the agent)

| Item | Category | Status | Source |
|---|---|---|---|
| 8.1 | auto-fill | 已填 | pubspec.yaml / .github/workflows/android-build.yml / lib/main.dart |
| 8.2 | auto-fill | 已填 | test/ 树 61 文件、629 测试基线 |
| 8.3 | auto-fill | 无机制，治理轮设计 | 全库无 flag_* 键；先例 detailed_recording |
| 8.4 | must-ask | pending | — |
| 8.5 | must-ask | pending | — |
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

## 附：验证缺口清单（诊断 2026-10-06，按优先级；治理轮按此施工）

| 级别 | 缺口 | 补救方案 |
|---|---|---|
| P0 | 关键 UI 流程回归缺口：PlanScreen 当日列表渲染（重复 key 类崩溃守卫）、详情弹窗→日历联动、创建→自动排期链路无测试 | 补 widget 测试；把人工验证清单固化为用例 |
| P0 | 端到端太薄：integration_test/ 仅 1 个启动冒烟；「选计划→开始→休息→记录→保存→历史可见」全流程无自动化 | 补 2-3 条 integration 用例，`flutter test integration_test/ -d <emulator>` CLI 可跑 |
| P1 | 无 flag 机制 | 按 §8.3 候选方案治理 |
| P1 | 无覆盖率度量与阈值 | `flutter test --coverage` + 核心层阈值接入 CI |
| P2 | 模拟器冒烟未脚本化 | 固化为一键 smoke 脚本（android-emulator 工具链） |
| P2 | 无结构化运行 trace | 视需要引入；当前 DB+Provider 检索已够用 |
