# OpenCalc HarmonyOS Demo

> 客户实验手册 · 三个增量需求的完整 Demo
> 仓库：https://github.com/JungleTestLabs/opencalc-harmonyos-demo

---

## 目录结构

```
0-basic/              ← 原始 OpenCalc 计算器（基线版本）
1-percent-button/     ← 需求 1：百分号按钮（demo1）
2-tip-calculator/     ← 需求 2：小费计算器（demo2）
3-draw-func/          ← 需求 3：函数图像绘制（demo3）
```

## 三个需求一览

| # | 需求 | 复杂度 | 主要改动 | 编译 | 详细手册 |
|---|------|:--:|--------|:--:|------|
| 1 | 百分号按钮 | **S** | CalculatorPage.ets +6/-1（新增 `BtnOp5` / `BtnAct5` Builder，首行 5 列 `AC ( ) % ÷`） | ✅ IDE | [DEMO_GUIDE.md](1-percent-button/DEMO_GUIDE.md) |
| 2 | 小费计算器 | **S** | 新增 `TipCalculator.ets`（纯函数 32 行）+ `TipCalculatorPage.ets`（~208 行）+ CalculatorPage +13 行 + main_pages.json +1 | ✅ IDE | [DEMO_GUIDE.md](2-tip-calculator/DEMO_GUIDE.md) |
| 3 | 函数图像绘制 | **M** | 新增 `Plotter.ets`（202 行）+ `GraphPage.ets`（207 行）+ Calculator.ets +29（`evalAt` + `x` 变量识别）+ Models +25 + CalculatorPage +4 | ✅ CLI | [DEMO_GUIDE.md](3-draw-func/DEMO_GUIDE.md) |

三个需求层层递进：
- **demo1（S 级）** — 纯 UI 改造，算法层零改动（智能 `%` 已存在）。
- **demo2（S 级）** — 首个独立页面改造，引入 `router.pushUrl`，算法层与 UI 层解耦，主页零侵入。
- **demo3（M 级）** — 多文件特性，含 Canvas 渲染 + 递归下降解析器扩展 + FMEA 风险闭环。

## 快速开始

每个需求都是独立的 HarmonyOS 应用。编译任一：

```bash
cd <目录>
# 推荐 DevEco Studio IDE 编译（Build → Make Project → Run 'entry'）

# 或 CLI（demo3 自带 SDK 修复脚本）：
cd 3-draw-func
sudo bash scripts/fix-deveco-sdk.sh   # 一次性，幂等
hvigorw clean && hvigorw assembleApp --mode debug --daemon
```

安装到设备：

```bash
export PATH="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains:$PATH"
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
hdc shell aa start -b com.darkempire78.opencalculator -a EntryAbility
```

## 开发流程

三个需求均使用标准化 AID 工作流（`/aid-workflow`）一站式开发：

1. **PLANNING** — rq-parse / rq-clarify → proposal.md / info.md / delta-spec.md（含 FMEA）/ delta-design.md / design-review.md
2. **IMPLEMENTING** — tasks.md + todo.md（任务拆分 + 排序）
3. **APPLYING** — 代码应用 + 静态等价审查 → apply-report.md
4. **验证** — 模拟器实测 + UI 截图 + 数学验证 → verification-report.md

每个需求文件夹内包含完整的 SPEC 文件、验证报告、DEMO 手册。

## AID 制品位置

- 需求 1：[`1-percent-button/specs/changes/20260518-requirement-add-percentage-button/`](1-percent-button/specs/changes/20260518-requirement-add-percentage-button/)
- 需求 2：[`2-tip-calculator/specs/changes/20260519-requirement-add-tip-calculator/`](2-tip-calculator/specs/changes/20260519-requirement-add-tip-calculator/)
- 需求 3：[`3-draw-func/specs/changes/20260519-requirement-add-function-graph/`](3-draw-func/specs/changes/20260519-requirement-add-function-graph/)

每个变更目录包含：`proposal.md` / `info.md` / `delta-spec.md` / `delta-design.md` / `design-review.md` / `tasks.md` / `todo.md` / `apply-report.md` / `verification-report.md`（含模拟器实测截图）。

## SDK 兼容性

- 开发 SDK：API 14（6.0.0）
- 验证 SDK：API 22（6.0.2，Pura 80 模拟器 1256×2760）
- demo3 在 `scripts/fix-deveco-sdk.sh` 中提供 DevEco 6.0.2 嵌套 SDK 布局修复脚本，解决 hvigor `00303168 SDK component missing` 问题
- 如需在不同 SDK 版本编译，修改 `build-profile.json5` 中的 `compatibleSdkVersion`

## 验证结果概览

| 需求 | 模拟器用例 | 数学验证 | 截图 | 爹助 / 辅助审查 |
|------|:--:|:--:|:--:|:--:|
| 1 百分号按钮 | 5 | `50±10% = 55/45`、`50×10% = 5`、`25% = 0.25` | 5 张 | 7 维度全部 PASS |
| 2 小费计算器 | 8 | `100×1.15/4 = 28.75`、`100×1.18/4 = 29.50`、`100×1.25/4 = 31.25` | 7 张 | 8 维度全部 PASS（含 P-01 缺陷复盘） |
| 3 函数图像绘制 | 12（P0） | `sin(x)` / `x^2` / `2x+1` / `1/x` / `tan(x)` / `sqrt(x)` | 16 张 | 7 维度全部 PASS，FMEA R-01..R-10 闭环 |

## 问题排查

每个需求的 DEMO_GUIDE.md 包含：

- 需求是什么 + 与早期 demo 仓的差别
- AID 工作流各阶段产物对应表
- 改了哪些文件 + 核心代码片段
- 编译结果（CLI / IDE 差异说明）
- 功能展示 + 功能验证表（含截图）
- 客户 DEMO 操作指南（编译运行 / 演示 / 问题对比）

---

*开发：狗助（JungleAssistant）· 验证：爹助（IntelliJungle）· 2026-05-19*
