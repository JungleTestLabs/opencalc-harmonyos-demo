# Todo - 20260519-requirement-add-function-graph

## 路径配置
- SPECS_FEATURE_ROOT: specs/specs（不存在，本次不依赖现有 feat 规格）
- CHANGES_ROOT: specs/changes
- 变更目录: specs/changes/20260519-requirement-add-function-graph/

## 变更概览
- **Intent**: Design/Development - New Requirement
- **Category**: 新增功能
- **Name**: function-graph（函数图像绘制）
- **One-liner**: 支持在计算器中输入 sin(x) 等函数表达式，绘制函数曲线

## Git 信息
- 当前分支: demo3
- git_branch_adopted: false（已在非 main 分支，沿用 demo3，不另起 feat 分支）

## PLANNING 阶段进度

| Step | 名称 | Skill | 状态 | 产出物 |
|------|------|-------|------|--------|
| step1 | 用户意图理解 | - | ✅ done | 意图识别(新增功能) |
| step1.1 | Git 分支检查 | - | ✅ done | 沿用 demo3 |
| step2 | 需求理解 | rq-parse | ✅ done | proposal.md |
| step3 | 需求澄清 | rq-clarify | ✅ done | proposal.md §3 已回填 |
| step4 | 需求 spec 设计 | - | ✅ done | delta-spec.md（13 个 SR + 13 条 FMEA） |
| step5 | 代码仓理解 | rq-codebase | ✅ done | info.md |
| step6 | 复杂度评估 | - | ✅ done | 见下文 |
| step7 | 架构设计 | - | ✅ skipped | 不涉及架构变更（理由见下文） |
| step8 | 组件设计 | mod-design | ✅ done | delta-design.md |
| step9 | 设计审视 | - | ✅ done | design-review.md |

## PLANNING 阶段完成

所有 PLANNING 制品已产出:
- ✅ proposal.md(需求提案)
- ✅ delta-spec.md(增量规格,13 SR + 13 FMEA)
- ✅ info.md(代码仓理解)
- ✅ delta-design.md(增量设计,D1-D10 完整章节)
- ✅ design-review.md(设计审视报告)
- ⏭️ new-arch.md(跳过 — 无架构变更)

**等待用户确认进入 IMPLEMENTING 阶段**

## 复杂度评估结果（step6）

| 维度 | 评估 |
|------|------|
| 复杂度等级 | **简单偏中（M-下限）** |
| 影响模块数 | 5（GraphPage 新增、Plotter 新增、Calculator 扩展、Models 扩展、CalculatorPage 修改 + 资源 main_pages.json/string.json） |
| 代码改动量 | ~530 行新增 + ~10 行修改 |
| 架构变更 | **否**（仍在 Page + Engine + Model 分层；新增 Page 不改变层级结构） |
| 数据模型变更 | **是**（新增 GraphConfig / PlotPoint / PlotResult，非破坏性） |
| 接口变更 | 新增 `CalcEngine.evalAt`，保留 `evaluate` 完全不变 |
| 依赖关系 | 单一新页面 → 复用现有 Engine / Expression，无交叉依赖 |

### 跳过策略

| 制品 | 是否产出 | 说明 |
|------|---------|------|
| proposal.md | ✅ 必须 | 已产出 |
| delta-spec.md | ✅ 必须 | 已产出 |
| info.md | ✅ 必须 | 已产出 |
| **new-arch.md** | ❌ **跳过** | 无架构变更（仅新增页面/模块，分层结构不变） |
| delta-design.md | ✅ 必须 | step8 产出 |
| tasks.md | ✅ 必须 | IMPLEMENTING 阶段产出 |
| apply-report.md | ✅ 必须 | APPLYING 阶段产出 |

### step7 跳过原因
按需求复杂度评估标准：
- 无新增"核心模块"层级（GraphPage 是 pages 层内的新增页面，Plotter 是 calculator 层内的新增工具模块，两者仍归属现有 MVVM-Lite 分层）
- 无改变模块间主要交互关系（CalculatorPage 与 Engine 的关系不变；GraphPage 与 Engine 是新增的同型关系）
- 无新增外部依赖（无网络、无新权限、无新 SDK 引入）
- 无改变数据流（不持久化、不引入跨层数据流）

按 aid-planning step7 原则"非必要情况下不要变更架构"，**跳过 new-arch.md 产出**。

## IMPLEMENTING 阶段进度
| Step | 状态 | 产出物 |
|------|------|--------|
| 任务分解 | ✅ done | tasks.md(13 个任务、4 个阶段) |

## APPLYING 阶段进度
| Step | 状态 | 产出物 |
|------|------|--------|
| 代码应用与测试 | ✅ done | apply-report.md |

## APPLYING 阶段完成

13 个任务完成情况:
- Task 1.1-1.3 基础设施 ✅
- Task 2.1-2.5 核心引擎 + Plotter ✅
- Task 3.1-3.3 GraphPage + CalculatorPage 按钮 ✅
- Task 4.1 ets-check ✅(0 error)
- Task 4.2 build ⚠️ 环境 SDK 配置问题,代码无问题
- Task 4.3 device verify ⏭️ 待环境恢复后执行
