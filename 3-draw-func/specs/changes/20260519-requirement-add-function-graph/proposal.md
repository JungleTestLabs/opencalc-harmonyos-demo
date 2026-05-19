# 函数图像绘制 需求提案

## 1. 需求概述

### 1.1 功能名称
函数图像绘制（Function Graph Plotter）

### 1.2 需求类型
新增功能（New Requirement）

### 1.3 关联特性
feat-function-graph（新建特性，无既有 spec）

### 1.4 需求描述
在 OpenCalc 计算器中新增"函数绘图"能力：用户输入形如 `sin(x)`、`x^2`、`ln(x+1)` 等以 **x** 为自变量的表达式，应用在指定 x 范围内对 y = f(x) 进行采样并以曲线方式在 Canvas 上绘制函数图像。

### 1.5 使用场景
- 学生预习/复习数学课时，想直观查看 `sin(x)` 的周期性、`x^2` 的抛物线形状
- 用户在四则计算之外，希望快速验证某个函数在区间内的趋势/极值/零点位置
- 教师演示三角函数、对数、多项式等典型函数曲线

### 1.6 预期效果
- 用户从计算器主页面可一键切换到"绘图"界面
- 在表达式输入框输入 `sin(x)` 后点击"绘图"按钮 → Canvas 区域即刻显示一条正弦曲线
- 切换/修改表达式后曲线动态更新
- 支持基本的坐标系（X/Y 轴 + 刻度），同时尊重应用的主题（默认/AMOLED/Material You）

---

## 2. 需求解析报告（rq-parse 输出）

### 2.1 意图分类
- **类型**：新增功能
- **一句话概括**：在 OpenCalc 中新增一个独立的函数绘图能力，复用现有 CalcEngine 求值能力，对含变量 x 的表达式进行采样并在 Canvas 上绘制曲线。

### 2.2 领域映射
- **UI/交互**：新增绘图页面（或独立面板），含表达式输入框、绘图按钮、Canvas 画布；涉及主题适配、横竖屏适配
- **计算引擎扩展**：当前 `CalcEngine` 仅支持常量求值（如 `2π`、`sin(1.2)`），需要扩展为支持自由变量 `x` 的表达式求值（对同一表达式在 x∈[xmin, xmax] 内多次求值）
- **数据建模**：新增"绘图任务/绘图配置/曲线数据"等数据模型
- **导航/路由**：CalculatorPage ↔ GraphPage（或主页内 Tab/区域切换）

### 2.3 影响层次
| 层次 | 变更类型 | 说明 |
|------|---------|------|
| View | new | 新增 `GraphPage.ets`（或 `GraphPanel` 组件），含 Canvas 绘图与输入区 |
| View | modify | `CalculatorPage.ets` 顶部/科学面板增加"绘图"入口（按钮或菜单项） |
| ViewModel/Engine | extend | `Calculator.ets`：抽出可对 `x` 求值的接口（`evalAt(expr, x): number`），或将 `Expression` 预处理与 `CalcEngine` 解耦支持复用 |
| Model | new | `model/Models.ets`：新增 `GraphConfig`（x 范围、y 范围、采样点数、网格开关等）、`PlotResult`（采样点列表 + 错误标志） |
| 基础设施 | extend | 主题色资源（`color.json`）补充绘图相关颜色（轴线/网格/曲线） |
| 数据层 | none | 暂不持久化绘图历史（除非用户决定要） |

### 2.4 关键实体
- **数据实体**：
  - `GraphConfig`：自变量名（默认 `x`）、x 范围 [xMin, xMax]、y 范围（auto 或自定义）、采样点数、是否显示网格
  - `PlotPoint { x: number, y: number, defined: boolean }`：单个采样点
  - `PlotResult`：表达式 + 采样点数组 + 错误信息（语法 / 全段无定义 等）
- **页面实体**：
  - `GraphPage.ets`（或 `pages/CalculatorPage.ets` 内的子面板）
  - 表达式输入区（复用现有键盘按钮 + `x` 按钮）
  - Canvas 画布
- **接口实体**：
  - `CalcEngine.evalAt(exprAst | tokens, x: number): { value: number, error: ErrorFlags }` —— 扩展接口
  - `Plotter.sample(expr: string, cfg: GraphConfig): PlotResult` —— 采样
  - `Plotter.drawTo(canvasCtx, plotResult, cfg)` —— 绘制
- **事件实体**：
  - 用户点击"绘图"按钮 → 触发采样 + 重绘
  - 表达式变化 → 防抖后自动重绘（可选）
  - 横竖屏切换 → 画布尺寸变化 → 重绘

### 2.5 模糊点
| # | 类别 | 描述 | 严重程度 |
|---|------|------|---------|
| 1 | 交互模糊 | 绘图入口：是新建独立页面 `GraphPage`、在主页加 Tab、还是在 CalculatorPage 顶部加按钮临时切换显示？ | **blocker** |
| 2 | 范围模糊 | 自变量是否只允许 `x`？是否支持 `t`、`θ` 等其他符号？是否支持多函数同时绘制（如 sin(x) 与 cos(x) 同图）？ | **blocker** |
| 3 | 行为模糊 | x 轴默认范围是多少？(常见：[-10, 10] 或 [-2π, 2π])  y 轴是否自动适配数据？是否允许用户手动设置范围？ | **blocker** |
| 4 | 交互模糊 | 是否需要支持触摸缩放/平移？还是固定视图? | important |
| 5 | 行为模糊 | 函数在某些 x 处未定义（如 `1/x` 在 0、`tan(x)` 在 π/2、`sqrt(x)` 在 x<0、`log(x)` 在 x≤0）时如何处理？跳过断点 / 显示警告 / 部分绘制？ | important |
| 6 | 数据模糊 | 采样点数是固定（如 200/500/1000）还是基于画布宽度？连续性如何保证（避免折线段过粗显得失真）？ | important |
| 7 | 交互模糊 | 坐标轴是否需要：原点、轴标签（"x"/"y"）、刻度数字、网格线？ | important |
| 8 | 兼容模糊 | 现有 `Expression.ets` 把 `arcsi/arcco/arcta/logtwo/xp` 这些定制 token 转换成标准函数 —— 绘图函数语法是否完全复用同一套？还是需要支持更直观的写法（如直接 `sin`、`asin`）？ | important |
| 9 | 数据模糊 | 是否持久化绘图历史（与计算历史合并 / 分开）？ | nice-to-have |
| 10 | 行为模糊 | 输入空表达式或语法错误时的 UX？错误信息显示在哪里？ | nice-to-have |
| 11 | 行为模糊 | 是否支持导出图像（截图保存）？ | nice-to-have |

### 2.6 复杂度评估
- **等级**：**M（中等）**
- **理由**：
  - 跨 View / Engine / Model 三层
  - 需新建 1 个页面 + 扩展 1 个引擎接口 + 2~3 个数据模型
  - Canvas 绘图需自行实现坐标变换、轴线/网格、曲线采样
  - 代码改动量预估 400~700 行 ArkTS（含 Canvas 绘制逻辑）
  - 无外部依赖、无新增权限、无网络/存储变更，故未达 L

---

## 3. 需求澄清（rq-clarify 输出）

### 3.1 已澄清的关键决策
| # | 原模糊点 | 决策 | 来源 |
|---|---------|------|------|
| 1 | 入口方式（#1 blocker） | 在 CalculatorPage 顶部菜单栏增加"绘图"按钮，点击后通过 ArkUI router 跳转到独立的 `GraphPage` | 用户选择"顶部按钮→新页面" |
| 2 | 自变量与多函数（#2 blocker） | 自变量固定为 `x`，每次只绘制一条曲线（单函数） | 用户选择"仅 x、单函数" |
| 3 | x 默认范围与缩放（#3 + #4） | 默认 x ∈ [-10, 10]，y 自动适配数据范围；本期**不支持**触摸缩放/平移 | 用户选择"默认 [-10,10]，y 自动适配，无缩放" |
| 4 | 坐标系样式（#7） | 仅绘制 X/Y 两条坐标轴 + 原点；**不绘制**数字刻度、**不绘制**网格线、**不绘制**轴标签 | 用户多选只勾选了"X/Y 轴 + 原点" |

### 3.2 待定假设（合理默认值，无需再询问）
以下 important / nice-to-have 模糊点采用默认方案，可在实现阶段微调：

- **不连续点处理（#5 important）**：当采样点 y 值为 NaN/±∞，或相邻两点 y 跨度超过画布高度的 5 倍，则在该位置断开折线（不连线），不显示额外警告。理由：与多数科学计算器表现一致，UI 干净。
- **采样点数（#6 important）**：基于画布宽度像素动态决定，公式 `N = clamp(floor(canvasWidthPx / 2), 200, 600)`。理由：兼顾平滑与性能。
- **Token 兼容（#8 important）**：完全复用现有 `Expression.processInput` 的全部预处理规则（包括 `arcsi/arcco/arcta/logtwo/xp/sqrt/×/÷/%` 等），用户输入 `sin(x)` / `x^2` / `ln(x+1)` 等均能识别。理由：避免双套语法、保持一致性。
- **绘图历史持久化（#9 nice-to-have）**：本期**不**持久化。理由：与"单次会话查看曲线形状"使用场景相符，避免引入数据迁移复杂度。
- **错误显示（#10 nice-to-have）**：表达式语法错误或全段无定义时，在 Canvas 下方以红色文本显示一行错误信息（复用 `ErrorFlags` 的中文文案）。理由：用户感知清晰但不打扰。
- **图像导出/分享（#11 nice-to-have）**：本期**不**实现。

### 3.3 功能边界
- **包含**：
  - 新增独立 `GraphPage`，CalculatorPage 顶部按钮入口
  - 单函数（变量 x）曲线绘制
  - 固定 X 范围 [-10, 10]、Y 自适应
  - X/Y 坐标轴 + 原点
  - 主题（默认/AMOLED/Material You）颜色适配
  - 横竖屏自适应重绘
  - 表达式预处理与错误提示（复用现有引擎）
  - 不连续点自动断开
- **不包含**（本期明确不做）：
  - 多函数同图、多变量
  - 触摸缩放/平移
  - 数字刻度、网格线、轴标签文字
  - 绘图历史持久化
  - 图像导出/分享
  - 坐标点追踪（hover/click 显示坐标值）
  - 3D / 极坐标 / 参数方程

---

## 4. 需求详述

### 4.1 功能需求

#### FR-1: 函数表达式输入
- **描述**：在绘图界面提供与计算器同样风格的表达式输入框，支持键入数字、运算符、函数关键字（sin/cos/tan/ln/log/sqrt/^ 等）以及自变量 `x`
- **验收条件**：
  - 输入 `sin(x)`、`x^2-3*x+1`、`ln(x+1)` 等表达式均能被识别
  - 输入框支持光标定位与编辑，与 CalculatorPage 一致
  - 提供独立的 `x` 按钮，按下后在光标位置插入 `x`

#### FR-2: 函数图像绘制
- **描述**：用户点击"绘图"按钮（或表达式变化触发）后，对当前表达式在默认 x 范围内进行 N 点采样，并在 Canvas 上以折线段方式连接成曲线
- **验收条件**：
  - 输入 `sin(x)` 显示完整的正弦曲线（至少能看到一个完整周期）
  - 输入 `x^2` 显示完整的抛物线
  - 曲线颜色与当前主题前景色对比明显

#### FR-3: 坐标系绘制
- **描述**：Canvas 绘制 X 轴、Y 轴和原点；**不**绘制数字刻度、**不**绘制网格、**不**绘制轴标签文字
- **验收条件**：
  - 当 0 处于可视 x 范围/y 范围内时，绘制贯穿画布的水平 X 轴和垂直 Y 轴
  - 在原点位置可见（轴交点即为原点）
  - 当 0 不在可视范围内（如 y 范围 [2, 10]），对应轴显示在画布边缘附近（与 0 最近的边界）

#### FR-4: 主题与方向自适应
- **描述**：绘图界面颜色随主题切换；横竖屏切换后画布重新布局
- **验收条件**：
  - AMOLED 主题下背景纯黑、曲线显色清晰
  - 切换到横屏后画布占据更大区域，曲线重绘正常无遗留

#### FR-5: 错误与定义域处理
- **描述**：表达式语法错误、采样点为 NaN/±∞ 时，UI 给出明确反馈，不崩溃
- **验收条件**：
  - 输入空表达式或语法错误，显示中文错误信息（复用 `ErrorFlags`）
  - 输入 `1/x`：曲线在 x=0 附近断开但仍绘制两段
  - 输入 `sqrt(x)`：x<0 段不绘制，x≥0 段正常

### 4.2 可靠性需求（如有）

#### REQ-DFR-001: 绘图引擎健壮性
- **描述**：函数求值过程中可能出现 NaN/Infinity、长时间循环、数值溢出，需要预防主线程阻塞与崩溃
- **关注点**：
  - 故障检测：单次表达式求值超过 N ms 中止；采样过程出现 ≥M 次异常即中止并提示
  - 故障恢复：异常表达式不影响下一次绘图；UI 永远保持可响应
  - 降级策略：极端情况下退化为不绘制曲线，仅显示坐标系与错误提示

#### REQ-DFR-002: 资源占用约束
- **描述**：避免一次绘制创建过多对象/触发频繁 GC 导致界面卡顿
- **关注点**：
  - 采样点数限制在 [200, 1000] 之间
  - Canvas 重绘节流（输入变更 → 300ms 防抖）
  - 横竖屏切换重绘只触发一次

#### REQ-DFR-003: 数值精度
- **描述**：现有 CalcEngine 使用 number（64-bit float），需避免精度噪声导致曲线出现毛刺
- **关注点**：
  - 故障检测：相邻采样点 y 值跨度超过画布 5 倍高度时视为不连续，断开折线
  - 降级策略：极小数（< 1e-10）截断为 0

---

## 5. 影响范围分析

### 5.1 涉及的模块
| 模块 | 现有功能 | 新增/修改 |
|------|---------|-----------|
| `pages/CalculatorPage.ets` | 主计算器页面 | **修改**：增加"绘图"入口按钮 |
| `pages/GraphPage.ets` | （不存在） | **新增**：绘图主页面，含输入区 + Canvas |
| `calculator/Calculator.ets` | `CalcEngine` 递归下降求值器 | **扩展**：暴露支持自变量绑定的求值接口 |
| `calculator/Expression.ets` | 表达式预处理 | **复用** + 小幅扩展（保留 `x` 这个 token） |
| `model/Models.ets` | 历史项、错误标志 | **新增**：`GraphConfig`、`PlotPoint`、`PlotResult` |
| `model/ErrorFlags.ets` | 错误标志位 | **复用**，可能补充"绘图相关"错误 |
| `preferences/PreferencesStore.ets` | 偏好持久化 | **暂不修改**（除非要保存默认 x 范围） |
| `resources/.../color.json` | 主题颜色 | **修改**：补充曲线/轴/网格颜色 |
| `resources/.../main_pages.json` | 页面路由 | **修改**：注册 GraphPage |
| `resources/.../string.json` | 字符串资源 | **修改**：增加"绘图"、错误提示等文案 |

### 5.2 代码依赖分析

```
GraphPage (new)
 ├── ExpressionInput (新或复用 CalculatorPage 输入逻辑)
 ├── Plotter (新模块，calculator/Plotter.ets)
 │    ├── CalcEngine.evalAt(expr, x)   ← 现有 CalcEngine 的扩展接口
 │    └── Expression.preprocess(raw)   ← 复用
 └── Canvas (HarmonyOS ArkUI CanvasRenderingContext2D)

CalculatorPage (modify)
 └── 顶部菜单 → router.pushUrl('pages/GraphPage')
```

关键接口：
- `CalcEngine.evalAt(prepared: string, x: number): { value: number, ok: boolean }` —— 新增
- `Plotter.plot(expr: string, cfg: GraphConfig, ctx: CanvasRenderingContext2D): PlotResult` —— 新增
- 现有的 `Expression.processInput`、`CalcEngine.eval` 不破坏向后兼容

---

## 6. 复杂度评估

### 6.1 评估结果
- **复杂度等级**：复杂（M-上限）
- **影响模块数**：~6 个（CalculatorPage、GraphPage 新、Calculator 扩展、Models 扩展、color.json、main_pages.json、string.json）
- **架构变更**：**否**（仍在现有 MVVM-Lite 分层：Page + Engine + Model）
- **数据模型变更**：**是**（新增 GraphConfig / PlotPoint / PlotResult）

### 6.2 跳过策略
| 制品 | 是否产出 |
|------|---------|
| proposal.md | 必须 |
| delta-spec.md | 必须 |
| new-arch.md | **可跳过**（无架构变更） |
| delta-design.md | 必须 |
| tasks.md | 必须 |

---

## 7. 待解决问题

step3 `rq-clarify` 已完成 4 个关键决策的澄清（见 §3.1），其余 important / nice-to-have 模糊点采用合理默认值（见 §3.2）。**无剩余待解决问题，可进入 step4 需求 spec 设计**。
