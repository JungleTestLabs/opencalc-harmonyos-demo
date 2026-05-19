# Tip Calculator - TODO

## 路径配置
- SPECS_FEATURE_ROOT: specs/specs (尚未存在,本变更为首批)
- CHANGES_ROOT: specs/changes
- 当前变更: specs/changes/20260519-requirement-add-tip-calculator/

## 元信息
- 变更类型: New Requirement (新增功能)
- 变更名称: tip-calculator
- 创建日期: 2026-05-19
- 当前分支: demo2
- git_branch_adopted: false (已在 demo2 分支,无需新建)

## PLANNING 阶段进度

- [x] step1 用户意图理解 ✓ 新增功能
- [x] step1.1 Git 分支检查 ✓ 当前在 demo2,跳过
- [x] step2 需求理解 (rq-parse) ✓ 输出含 8 个模糊点
- [x] step3 需求澄清 (rq-clarify) ✓ 8 个模糊点全部澄清
- [x] step4 需求spec设计 (delta-spec.md) ✓
- [x] step5 项目和代码仓理解 (rq-codebase → info.md) ✓ 关键发现: 真主页是 CalculatorPage
- [x] step6 需求复杂度评估 ✓ 简单
- [x] step7 架构设计 ✓ 跳过 new-arch.md(无架构变更)
- [x] step8 组件设计 (mod-design → delta-design.md) ✓
- [x] step9 设计审视 (design-review.md) ✓ 三大维度通过

## PLANNING 产出物
- specs/changes/20260519-requirement-add-tip-calculator/proposal.md
- specs/changes/20260519-requirement-add-tip-calculator/delta-spec.md
- specs/changes/20260519-requirement-add-tip-calculator/info.md
- specs/changes/20260519-requirement-add-tip-calculator/delta-design.md
- specs/changes/20260519-requirement-add-tip-calculator/design-review.md

## IMPLEMENTING 阶段进度

- [x] step2-1 任务分解 ✓ 4 阶段 6 任务
- [x] step2-2 任务排序 ✓ 线性串行(1.1→2.1→3.1→3.2→4.1→4.2)
- [x] step2-3 tasks.md ✓
- 说明: 不引入 hypium 测试脚手架(ohosTest 目录不存在,O-01),改为 verify_ui 端到端 + 手工真机验证

## IMPLEMENTING 产出物
- specs/changes/20260519-requirement-add-tip-calculator/tasks.md

## APPLYING 阶段进度

- [x] Task 1.1 TipCalculator 纯函数 ✓ arkts-check 0 诊断
- [x] Task 2.1 TipCalculatorPage 页面 ✓ arkts-check 仅 Info + 预期 colorConsistentWarning
- [x] Task 3.1 main_pages.json 注册 ✓
- [x] Task 3.2 CalculatorPage 入口注入 ✓ 不污染既有质量基线
- [x] Task 4.1 工程编译验证 ✓ hvigorw debug 编译通过(BUILD SUCCESSFUL in 4s 126ms),HAP 打包成功;DEVECO_SDK_HOME 路径已记入 apply-report B-01
- [⚠] Task 4.2 端到端 UI 验证 — verify_ui 缺 UI_VERIFY_* 环境变量,环境阻塞(详见 apply-report B-02)
- [x] 后置缺陷修复 P-01 ✓ TipCalculatorPage: `private get perPerson()` getter → `private computePerPerson()` 方法,Text 调用同步更新;arkts-check 0 新增错误
- [⏳] 后置 P-01 运行时复测 — hvigorw CLI 复编译受 B-03 阻塞,建议在 DevEco Studio IDE 一键 Run 重打包后真机键盘输入 100 / 4 → 期望渲染 `28.75`

## APPLYING 产出物
- specs/changes/20260519-requirement-add-tip-calculator/apply-report.md
- entry/src/main/ets/calculator/TipCalculator.ets (新增)
- entry/src/main/ets/pages/TipCalculatorPage.ets (新增)
- entry/src/main/resources/base/profile/main_pages.json (修改)
- entry/src/main/ets/pages/CalculatorPage.ets (修改 ToggleRow + import)
