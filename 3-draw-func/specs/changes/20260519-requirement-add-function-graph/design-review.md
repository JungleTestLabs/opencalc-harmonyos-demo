# 设计审视报告 — 函数图像绘制

> 对 `specs/changes/20260519-requirement-add-function-graph/` 下的全部设计制品进行完整性、一致性、规范性审视。

**审视时间**:2026-05-19
**审视人**:AID Workflow(step9)
**审视范围**:PLANNING 阶段产出的全部制品

---

## 1. 完整性评估

### 1.1 制品齐全性

| 制品 | 路径 | 是否必须 | 是否存在 | 状态 |
|------|------|---------|---------|------|
| 任务进度 | `todo.md` | 必须 | ✅ | 通过 |
| 需求提案 | `proposal.md` | 必须 | ✅ | 通过 |
| 增量规格 | `delta-spec.md` | 必须 | ✅ | 通过 |
| 代码仓理解 | `info.md` | 必须 | ✅ | 通过 |
| 新架构设计 | `new-arch.md` | 可选(无架构变更时跳过) | ❌(已确认跳过) | 通过(跳过理由见 todo.md step7) |
| 增量设计 | `delta-design.md` | 必须 | ✅ | 通过 |
| 设计审视报告 | `design-review.md` | 必须 | ✅(本文档) | 通过 |

**完整性评估**:**通过**。所有必需制品齐全;`new-arch.md` 因复杂度评估为 M-下限、无架构变更,按 aid-planning step7 规则合规跳过。

### 1.2 需求覆盖度

- IR-001(函数图像绘制 V1):1 个顶层 IR
- SR-001 ~ SR-013:13 个 SR,均能追溯到 delta-design.md §3-§11 的设计承接位置
- FM-01 ~ FM-13:13 条 FMEA,均在 delta-design.md §3.5.9 / §3.6.9 / §11 中得到具体承接

**需求覆盖度**:**100%**(13/13 SR 全覆盖,13/13 FMEA 全覆盖)

---

## 2. 一致性评估

### 2.1 proposal.md → delta-spec.md

| 项 | proposal 中描述 | delta-spec 中承接 | 一致性 |
|----|----------------|-------------------|-------|
| 入口方式 | §3.1 顶部按钮 → 新页面 | SR-001 + UC-001-01 主成功路径 | ✅ |
| 自变量与曲线数量 | §3.1 仅 x、单函数 | §术语表 "自变量"、SR-003 | ✅ |
| x 范围与缩放 | §3.1 [-10, 10],无缩放 | C-02 约束、SR-002 + GraphConfig | ✅ |
| 坐标系样式 | §3.1 仅 X/Y 轴 + 原点 | SR-005 | ✅ |
| 不连续点处理 | §3.2 NaN/|Δy| 阈值断开 | SR-010 + FM-03/04/06 | ✅ |
| 采样点数 | §3.2 clamp(canvasWidthPx/2, 200, 600) | UC-001-01 步骤 5 | ✅ |
| Token 兼容 | §3.2 完全复用 Expression | UC-001-01 步骤 4 | ✅ |
| 错误显示 | §3.2 Canvas 下方红字 | SR-008 + UC-003-01 | ✅ |
| 不持久化 | §3.2 本期不持久化 | C-05、§5.3 Preferences 不修改 | ✅ |
| 不导出 | §3.2 本期不实现 | 4.8 文件交换接口 不涉及 | ✅ |

**评估**:**通过**。delta-spec 完整承接 proposal 的所有澄清决策,无遗漏或冲突。

### 2.2 delta-spec.md → delta-design.md

| SR 编号 | 是否在 delta-design 中有对应设计 | 设计位置 |
|---------|-------------------------------|---------|
| SR-001 | ✅ | §3.9 CalculatorPage 修改 |
| SR-002 | ✅ | §3.5 GraphPage 设计 |
| SR-003 | ✅ | §3.7 CalcEngine 扩展、§4.2 |
| SR-004 | ✅ | §3.6 Plotter 设计、§3.6.8 |
| SR-005 | ✅ | §3.6.8 算法四 |
| SR-006 | ✅ | §3.4.1、§3.4.2、§3.5.7 |
| SR-007 | ✅ | §3.4.7、§3.5.6 |
| SR-008 | ✅ | §3.5.9 |
| SR-009 | ✅ | §3.6.8 算法一 + §11 |
| SR-010 | ✅ | §3.6.8 算法一 + 算法三 |
| SR-011 | ✅ | §3.4 + info.md §5 |
| SR-012 | ✅ | §3.5.9 + §11 |
| SR-013 | ✅ | §3.5.6 aboutToDisappear |

| FMEA 编号 | 是否在 delta-design 中有承接 | 承接位置 |
|----------|---------------------------|---------|
| FM-01(语法错误) | ✅ | §3.5.9 |
| FM-02(全段未定义) | ✅ | §3.5.9 + §3.6.8 算法一 |
| FM-03(不连续点) | ✅ | §3.6.8 算法三 |
| FM-04(NaN/Infinity) | ✅ | §3.6.8 算法一 defined 判定 |
| FM-05(求值超时) | ✅ | §3.6.8 算法一 softTimeoutBudget |
| FM-06(数值溢出) | ✅ | §3.6.8 算法一 |y|<=1e15 判定 |
| FM-07(极小数噪声) | ✅ | §3.6.8 算法一 Math.abs(y)<1e-10 归零 |
| FM-08(Canvas 未就绪) | ✅ | §3.5.7 canvasReady 状态 + §3.5.4 状态机 |
| FM-09(横竖屏切换) | ✅ | §3.5.6 onAreaChangeRedraw 防抖 |
| FM-10(常函数) | ✅ | §3.6.8 算法二 yMax-yMin<1e-6 兜底 |
| FM-11(连续点击) | ✅ | §3.5.7 isPlotting + §11 防抖 |
| FM-12(内存压力) | ✅ | §11(PlotResult 局部变量) |
| FM-13(残留 timer) | ✅ | §3.5.6 aboutToDisappear |

**评估**:**通过**。所有 SR 与 FMEA 在 delta-design 中均有具体设计承接,无遗漏。

### 2.3 info.md ↔ delta-design.md

| info.md 关键事实 | delta-design 是否引用并落地 |
|-----------------|------------------------------|
| CalcEngine 不可重入(R-01) | ✅ §3.6.6 注释"必须串行使用";§3.7.7 |
| ErrorFlags 静态全局(R-02) | ✅ §3.6.8 算法一每点 reset;§11 决策 |
| x 与 xp 冲突(R-03) | ✅ §3.7.6 前瞻判断代码;§11 决策 |
| 主线程阻塞风险(R-04) | ✅ §3.6.8 算法一 softTimeoutBudget |
| Canvas 就绪时序(R-06) | ✅ §3.5.4 状态机;§3.5.7 canvasReady |
| ThemeColors 不抽取(建议) | ✅ §3.4.1 + §11 决策 |
| Plotter 无状态(建议) | ✅ §3.6.7 |

**评估**:**通过**。info.md 中的 10 个风险点均在 delta-design 中有缓解措施;3 条小重构建议按 info.md 建议**不**强求实现,避免引入回归。

---

## 3. 规范性评估

### 3.1 格式规范

| 制品 | 章节结构完整 | Markdown 格式规范 | 表格规范 | 代码块语言标记 |
|------|-------------|-------------------|---------|----------------|
| proposal.md | ✅ | ✅ | ✅ | ✅ |
| delta-spec.md | ✅(13 SR + 5 SC + FMEA) | ✅ | ✅ | ✅ |
| info.md | ✅(rq-codebase 模板) | ✅ | ✅ | ✅ |
| delta-design.md | ✅(D1-D10 完整 + 11 决策汇总 + 12 交叉校验) | ✅ | ✅ | ✅(plantuml/typescript) |

**评估**:**通过**。

### 3.2 命名规范

- 文件命名:`proposal.md` / `delta-spec.md` / `info.md` / `delta-design.md` — 符合 aid-planning 模板
- 路径前缀:`specs/changes/20260519-requirement-add-function-graph/` — 符合 `{YYYYMMDD}-{type}-{name}` 规范
- 内部 ID:SR-XXX / IR-XXX / FM-XX / UC-XXX-XX / SC-XXX — 编号规范、可追溯

**评估**:**通过**。

### 3.3 ArkTS / HarmonyOS 规范

| 检查项 | 状态 |
|--------|------|
| ArkTS 版本明确(V1 状态管理) | ✅ delta-design §1.3 |
| Stage 模型 | ✅ §1.3 |
| 最低 API version | ✅ §9.3(API 14 / HarmonyOS 6.0.0) |
| Kit 引用使用 `@kit.*` | ✅ §9.3 |
| 不涉及未声明权限 | ✅ §9.2 |

**评估**:**通过**。

---

## 4. 风险与遗留问题

### 4.1 已识别风险(均有缓解)

| 风险 | 缓解措施 | 状态 |
|------|---------|------|
| R-03 x/xp 冲突 | parseFactor 前瞻 | ✅ 已设计 |
| R-04 主线程阻塞 | 软超时 200ms / 100 点 | ✅ 已设计 |
| R-06 Canvas 时序 | canvasReady 状态机 | ✅ 已设计 |
| R-10 timer 残留 | aboutToDisappear 清理 | ✅ 已设计 |

### 4.2 实现期需注意的点

1. **CalcEngine 改动范围严格控制**:仅添加 `currentX` 字段、`evalAt` 方法、`parseFactor` 单段前瞻代码;**不得**修改其他逻辑(避免对计算器主页回归)
2. **CalculatorPage 改动严格控制**:仅在 ToggleRow 中加 1 个按钮 + router 调用;**不得**修改 onEquals、history、theme 等逻辑
3. **Expression 不修改**:本期 V1 用户必须写 `2*x`(显式乘号);`2x` 不自动加 `*` 是已知约束(详见 info.md §6 / proposal.md §3.2)
4. **ErrorFlags 每点 reset**:Plotter.sample 循环中务必每点 reset,绘图完成后再 reset 一次

### 4.3 遗留问题

**无遗留问题**。所有 blocker / important 级模糊点已在 rq-clarify 阶段澄清(proposal.md §3.1);nice-to-have 项采用合理默认值并已声明本期范围内不实现。

---

## 5. 审视结论

### 5.1 总体评估

| 维度 | 评估 |
|------|------|
| 完整性 | ✅ 通过 |
| 一致性 | ✅ 通过 |
| 规范性 | ✅ 通过 |
| 风险可控性 | ✅ 通过 |

**总体结论**:**通过审视,可进入 IMPLEMENTING 阶段**。

### 5.2 进入下一阶段需要确认的事项

1. PLANNING 阶段全部制品(proposal.md / delta-spec.md / info.md / delta-design.md / design-review.md)已就绪
2. 复杂度评估:M-下限,无架构变更,跳过 new-arch.md 合规
3. 13 SR + 13 FMEA 全部有设计承接
4. 改动面控制在 5 个模块(GraphPage 新增、Plotter 新增、Calculator 扩展、Models 扩展、CalculatorPage 修改) + 2 个资源文件(main_pages.json / string.json),预计代码改动量 ~540 行

### 5.3 后续阶段产出预期

| 阶段 | Skill | 产出物 |
|------|-------|--------|
| IMPLEMENTING | aid-implementing | `tasks.md`(任务分解与排序) |
| APPLYING | aid-applying | `apply-report.md`(代码应用与测试报告) |

---

> 本文档由 aid-planning step9 设计审视生成。
> 生成时间:2026-05-19
