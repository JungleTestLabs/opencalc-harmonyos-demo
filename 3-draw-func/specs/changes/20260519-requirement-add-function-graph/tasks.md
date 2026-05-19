# 函数图像绘制 开发任务(tasks.md)

## 任务概述

- **功能名称**:函数图像绘制(Function Graph Plotter)
- **变更类型**:新增功能(New Requirement)
- **关联特性**:feat-function-graph(新建)
- **开发阶段**:V1 — 单函数固定区间绘图
- **预计任务数**:13 个任务(分 4 个阶段)
- **预计改动量**:~540 行(新增 ~530 + 修改 ~10)
- **影响文件数**:7 个(新增 2、修改 3、资源修改 2)

---

## 任务列表

### 阶段 1:基础设施

#### Task 1.1: Models 扩展 — 新增 GraphConfig / PlotPoint / PlotResult

**描述**:在 `Models.ets` 中追加 3 个 interface,作为 Plotter 与 GraphPage 之间的数据契约。

**涉及文件**:
- `entry/src/main/ets/model/Models.ets`(修改,+30 行)

**实现要点**:
- 使用 `export interface`(与现有 `HistoryItem`、`CalculatorPreferences` 风格一致)
- 严格按 delta-design.md §3.8.2 中的字段定义
- 不引入 class、不加方法

**依赖任务**:无

**验收标准**:
- 文件编译通过(ArkTS 严格模式)
- 3 个 interface 字段完整(GraphConfig 6 个字段、PlotPoint 3 个字段、PlotResult 4 个字段)
- 与 delta-design.md §5.2 的字段表 100% 对齐

---

#### Task 1.2: 资源补充 — string.json 新增绘图相关字符串

**描述**:在 `base/element/string.json` 中追加 6 条绘图相关字符串资源(中文)。

**涉及文件**:
- `entry/src/main/resources/base/element/string.json`(修改,+6 条)

**新增字符串清单**:
| name | value | 用途 |
|------|-------|------|
| `graph_button` | 绘图 | CalculatorPage 顶部按钮文本 |
| `graph_title` | 函数绘图 | GraphPage 标题 |
| `graph_hint_empty` | 请输入表达式 | 空输入提示 |
| `graph_hint_syntax_error` | 表达式语法错误 | 语法错误提示 |
| `graph_hint_undefined` | 函数在该区间未定义 | 全段未定义提示 |
| `graph_hint_timeout` | 采样提前结束 | 软超时提示 |

**依赖任务**:无

**验收标准**:
- JSON 格式合法(`hvigorw assembleHap` 不报错)
- 字符串内容与 delta-spec.md §FMEA 中文文案一致

---

#### Task 1.3: 路由注册 — main_pages.json 增加 GraphPage

**描述**:在路由清单中追加 `pages/GraphPage`。

**涉及文件**:
- `entry/src/main/resources/base/profile/main_pages.json`(修改,+1 行)

**修改后内容**:
```json
{
  "src": [
    "pages/Index",
    "pages/CalculatorPage",
    "pages/GraphPage"
  ]
}
```

**依赖任务**:无

**验收标准**:
- JSON 合法
- `router.pushUrl({ url: 'pages/GraphPage' })` 在调试阶段不报"page not registered"错误

---

### 阶段 2:核心引擎层

#### Task 2.1: CalcEngine 扩展 — 添加 currentX 字段

**描述**:在 `Calculator.ets` 的 `CalcEngine` 类中追加 `currentX` 实例字段,作为 `x` 变量求值的数据源。

**涉及文件**:
- `entry/src/main/ets/calculator/Calculator.ets`(修改,+1 行)

**实现要点**:
- 字段位置:与 `eq / p / c / deg` 同区域(类的私有字段区)
- 初始值:`currentX: number = 0`
- 可见性:public(允许 evalAt 写入,parseFactor 读取;考虑到 ArkTS 类内访问已默认允许,保持 public 简化)

**依赖任务**:无

**验收标准**:
- 编译通过
- 现有 `evaluate()` 测试用例全部仍通过(不破坏现有行为)

---

#### Task 2.2: CalcEngine 扩展 — parseFactor 增加 `x` 变量识别(含前瞻)

**描述**:在 `parseFactor` 的函数名扫描分支之**前**插入 8-10 行代码,识别单字符 `x` 为变量;若 `x` 后跟小写字母(如 `xp`),让函数名扫描接管。

**涉及文件**:
- `entry/src/main/ets/calculator/Calculator.ets`(修改,~10 行新增)

**实现要点**(严格按 delta-design.md §3.7.6):
```typescript
// 必须在函数名 (97-122 范围) 扫描之前
if (this.c === 120 /* 'x' */) {
  const nextC: number = this.p + 1 < this.eq.length
    ? this.eq.charCodeAt(this.p + 1) : -1
  const isPartOfFunctionName: boolean = (nextC >= 97 && nextC <= 122)
  if (!isPartOfFunctionName) {
    this.nx()
    let x: number = this.currentX
    if (this.eat(94 /* '^' */)) x = this.powx(x, this.parseFactor())
    return x
  }
  // 否则:继续走原有函数名扫描分支(xp/xpow 等)
}
```

**依赖任务**:Task 2.1

**验收标准**:
- 编译通过
- 现有所有 evaluate 用例不回归(尤其是 `xp(...)` 函数)
- 自检:
  - `evaluate("x", false)` 在 currentX=5 时返回 5
  - `evaluate("xp(2)", false)` 返回 e^2 ≈ 7.389(不受 x 识别影响)
  - `evaluate("x+xp(0)", false)` 在 currentX=3 时返回 4(3 + 1)

---

#### Task 2.3: CalcEngine 扩展 — 新增 evalAt 方法

**描述**:在 `CalcEngine` 类中追加公开方法 `evalAt`,作为外部调用 x 变量求值的统一入口。

**涉及文件**:
- `entry/src/main/ets/calculator/Calculator.ets`(修改,+3 行)

**实现要点**:
```typescript
evalAt(equation: string, x: number, isDegree: boolean): number {
  this.currentX = x
  return this.evaluate(equation, isDegree)
}
```

**依赖任务**:Task 2.1、Task 2.2

**验收标准**:
- 编译通过
- 自检:
  - `engine.evalAt("sin(x)", Math.PI / 2, false)` ≈ 1.0
  - `engine.evalAt("x^2", 3, false)` = 9
  - `engine.evalAt("1/x", 0, false)` 返回 Infinity(被 isFinite 判定为 false)
  - 连续调用 100 次不破坏内部状态

---

#### Task 2.4: 新增 Plotter 模块 — 采样能力(sample)

**描述**:新建 `Plotter.ets`,实现 `Plotter.sample` 静态方法(等间隔采样 + ErrorFlags 守护 + 软超时)。

**涉及文件**:
- `entry/src/main/ets/calculator/Plotter.ets`(**新建**,~80 行)

**实现要点**(严格按 delta-design.md §3.6.8 算法一):
- 文件顶部导出 `ThemeColors` interface
- `Plotter` class 含静态方法 `sample`
- 每点前 `ErrorFlags.reset()`、捕获异常、检查 `isFinite + |y|<=1e15`、`Math.abs(y)<1e-10` 归零
- 软超时:每 100 点检查 `Date.now() - start > 200`,触发则 break
- 全部点循环结束后 `ErrorFlags.reset()` 一次(R-02 隔离)

**依赖任务**:Task 1.1(Models)、Task 2.3(evalAt)

**验收标准**:
- 编译通过
- `Plotter.sample("sin(x)", cfg, engine, false)` 在 sampleCount=600 时返回 600 点,validCount=600
- `Plotter.sample("1/x", cfg, engine, false)` 包含 ≥1 个 `defined=false` 的点(x≈0 附近)
- `Plotter.sample("sqrt(x)", cfg, engine, false)` 在 x<0 部分全部 `defined=false`

---

#### Task 2.5: 新增 Plotter 模块 — 绘制能力(drawTo + helpers)

**描述**:在 `Plotter.ets` 中追加 `drawTo` 静态方法及私有辅助函数(坐标变换、轴绘制、断点折线绘制)。

**涉及文件**:
- `entry/src/main/ets/calculator/Plotter.ets`(继续 Task 2.4 的文件,追加 ~70 行)

**实现要点**(严格按 delta-design.md §3.6.8 算法二/三/四):
- `drawTo(ctx, result, cfg, theme)`:入口校验 ctx 非空、clearRect、调用 drawAxes、调用 drawCurve
- 私有 `fitYRange(yMin, yMax)`:常函数兜底(差值<1e-6 时返回 [yMin-1, yMax+1])、+10% padding;全无效点返回 [-1, 1]
- 私有 `toPx(x, y, cfg, yRange)`:数学坐标 → 像素坐标
- 私有 `drawAxes(ctx, cfg, yRange, theme)`:y=0 / x=0 对应像素的 X/Y 轴线
- 私有 `drawCurve(ctx, result, cfg, yRange, theme)`:`inSegment` 状态机、|Δy| > 5 × (yMax-yMin) 断开

**依赖任务**:Task 2.4

**验收标准**:
- 编译通过
- 通过 mock Canvas API 验证:
  - 输入 sin(x) 的 PlotResult,ctx 至少接收 1 次 `clearRect`、2 次轴线 `stroke`、1 次曲线 `stroke`
  - 输入 1/x 的 PlotResult,curve 部分至少有 2 次 `beginPath`(对应两段)
- ctx 为 null 时方法不抛错,console.warn 输出警告

---

### 阶段 3:表现层

#### Task 3.1: 新增 GraphPage — UI 骨架与状态字段

**描述**:新建 `pages/GraphPage.ets`,搭建 UI 骨架(标题栏 + 输入行 + 操作行 + Canvas + 错误行)和 @State 字段,主题色 getter 函数,生命周期方法空实现。

**涉及文件**:
- `entry/src/main/ets/pages/GraphPage.ets`(**新建**,~180 行)

**实现要点**(严格按 delta-design.md §3.5):
- `@Component export struct GraphPage`
- @State 字段:`expression / errorMsg / isPlotting / themeIdx / canvasReady`
- 非响应式字段:`ctx / engine / debounceTimer / canvasWidthPx / canvasHeightPx`
- 主题色 getter(拷贝模式):`getBg() / getT1() / getT2() / getAxis() / getCurve() / getErr() / getBtnBg()`
  - 色值常量按 delta-design.md §3.4.1 表
- `aboutToAppear`:`PreferencesStore.getTheme()` → 写入 themeIdx;`engine = new CalcEngine()`
- `aboutToDisappear`:`clearTimeout(this.debounceTimer)`
- `onPlot()` / `onAreaChangeRedraw()`:**空实现**,留待 Task 3.2

**依赖任务**:Task 1.1(Models)、Task 1.2(string.json)

**验收标准**:
- 编译通过
- 路由跳转 `router.pushUrl('pages/GraphPage')` 显示空白页面(含标题、输入框、按钮、空 Canvas)
- 不抛 NPE
- 三种主题下颜色对比清晰可辨

---

#### Task 3.2: GraphPage 联动 — onPlot / onAreaChange 实现

**描述**:实现 GraphPage 的核心交互逻辑:点击"绘图"按钮触发 `onPlot`、Canvas `onAreaChange` 触发防抖重绘、Canvas `onReady` 设置 canvasReady。

**涉及文件**:
- `entry/src/main/ets/pages/GraphPage.ets`(继续 Task 3.1 的文件,追加 ~50 行)

**实现要点**:
- `onPlot()`:
  1. 入口校验:expression 为空 → `errorMsg = $r('app.string.graph_hint_empty')` 文本 → return
  2. `isPlotting = true`
  3. try { `prepared = Expression.getCleanExpression(expression, '.', ',')` } catch { `errorMsg = "表达式语法错误"`; isPlotting=false; return }
  4. 构造 `GraphConfig`(xMin=-10, xMax=10, sampleCount=clamp(canvasWidthPx/2, 200, 600), 其余从字段读取)
  5. `result = Plotter.sample(prepared, cfg, this.engine, false)` // V1 弧度
  6. 若 `result.validCount === 0` → `errorMsg = "函数在该区间未定义"`
  7. `Plotter.drawTo(this.ctx, result, cfg, { axis, curve, bg })`
  8. `isPlotting = false`
- `onAreaChangeRedraw(w, h)`:
  - 更新 canvasWidthPx / canvasHeightPx
  - clearTimeout(debounceTimer);`debounceTimer = setTimeout(() => this.onPlot(), 300)`
  - 仅 canvasReady=true 时触发
- Canvas `.onReady`:设置 canvasReady=true、读取宽高
- Canvas `.onAreaChange((_, n) => this.onAreaChangeRedraw(n.width, n.height))`

**依赖任务**:Task 2.5(Plotter)、Task 3.1(GraphPage UI 骨架)

**验收标准**:
- 编译通过
- 设备上输入 `sin(x)` 点击"绘图" → 显示正弦曲线
- 输入 `x^2` → 显示抛物线
- 输入 `1/x` → 显示双曲线,x=0 附近断开
- 输入 `sin(` → 显示"表达式语法错误"
- 输入空 → 显示"请输入表达式"
- 横竖屏切换后曲线重绘正常(300ms 内)
- 连续点击"绘图"按钮在 300ms 内只触发一次绘图

---

#### Task 3.3: CalculatorPage 修改 — 顶部菜单新增"绘图"按钮

**描述**:在 `CalculatorPage.ets` 的 `ToggleRow` @Builder 中追加 1 个"绘图"按钮,onClick 调用 `router.pushUrl('pages/GraphPage')`。

**涉及文件**:
- `entry/src/main/ets/pages/CalculatorPage.ets`(修改,+~10 行)

**实现要点**(严格按 delta-design.md §3.9.2):
- 仅在 ToggleRow Row 内部追加 Button,放置在"历史"和"⚙"之间(或末尾,具体位置参考现有按钮排列)
- Button 样式与现有兼容(`.height(36) .backgroundColor(this.getBtnBg()) .fontColor(this.getT1()) .fontSize(14)`)
- 文本使用 `$r('app.string.graph_button')` 或直接字符串 "绘图"(以现有按钮风格为准)
- onClick 内 `router.pushUrl({ url: 'pages/GraphPage' })`(从 `@kit.ArkUI` import,沿用文件已有 import)
- **禁止**改动 onEquals、history、theme 等其他逻辑

**依赖任务**:Task 1.3(main_pages.json)、Task 3.1(GraphPage 至少 UI 骨架可路由)

**验收标准**:
- 编译通过
- CalculatorPage 在三种主题、横竖屏下显示正常,新增按钮可见且色值正确
- 点击"绘图"按钮 → 跳转到 GraphPage(500ms 内)
- 计算器主体功能(四则、科学、历史、设置)零回归

---

### 阶段 4:联调与验证

#### Task 4.1: 静态检查 — ArkTS Check

**描述**:对所有新增/修改的 ets 文件运行静态语法检查。

**涉及文件**(检查范围):
- `entry/src/main/ets/model/Models.ets`
- `entry/src/main/ets/calculator/Calculator.ets`
- `entry/src/main/ets/calculator/Plotter.ets`
- `entry/src/main/ets/pages/GraphPage.ets`
- `entry/src/main/ets/pages/CalculatorPage.ets`

**实现要点**:
- 使用 codegenie `check_ets_files` 工具检查
- 修复所有 error 级别诊断
- warning 级别诊断按规则处理

**依赖任务**:Task 1.1 ~ Task 3.3 全部完成

**验收标准**:
- 5 个文件均无 error 级别 ArkTS 诊断
- 关键 warning(如未使用变量、类型推断模糊)清理干净

---

#### Task 4.2: 编译验证 — debug 构建

**描述**:执行 `hvigorw assembleHap` debug 构建,验证完整工程编译通过。

**涉及文件**:
- 整个 entry 模块

**实现要点**:
- 使用 codegenie `build_project` 工具(mode=debug)
- 关注:类型错误、import 错误、资源引用错误

**依赖任务**:Task 4.1

**验收标准**:
- 构建产物 `entry-default-signed.hap` 生成成功
- 无 error 级别构建错误

---

#### Task 4.3: 设备运行验证 — 核心场景

**描述**:在模拟器/真机上验证 P0 场景(主成功路径 + 错误恢复 + 不连续点)。

**涉及文件**:
- 无(运行时验证)

**测试场景清单**:
| 场景 | 输入 | 预期 |
|------|------|------|
| 主路径 1 | sin(x) | 显示正弦曲线 |
| 主路径 2 | x^2 | 显示抛物线 |
| 主路径 3 | 2*x+1 | 显示直线 |
| 断点 1 | 1/x | x=0 处断开的双曲线 |
| 断点 2 | tan(x) | π/2、3π/2 处断开 |
| 断点 3 | sqrt(x) | x<0 无曲线 |
| 错误 1 | (空) | "请输入表达式" |
| 错误 2 | sin( | "表达式语法错误" |
| 错误 3 | log(-x) | "函数在该区间未定义"(常量函数情况) |
| 恢复 | 错误后输入 sin(x) | 正常绘制(KEI-003) |
| 退化 | 2+3 | 显示水平直线 y=5 |
| 横竖屏 | 旋转设备 | 曲线重绘无残留 |

**实现要点**:
- 使用 codegenie `verify_ui` 工具或 `start_app` + 手动操作
- 关注首屏时延(KEI-001 ≤ 300ms)

**依赖任务**:Task 4.2

**验收标准**:
- 12 个场景全部通过
- 无崩溃 / ANR / 控制台 error 日志

---

## 任务依赖关系图

```
阶段 1(可并行):
  Task 1.1 (Models) ──┐
  Task 1.2 (string) ──┼─────────┐
  Task 1.3 (routes) ──┘         │
                                │
阶段 2(线性):                   │
  Task 2.1 (currentX) ──┐       │
        ↓                │       │
  Task 2.2 (parseFactor)─┼─→ Task 2.3 (evalAt)
                          │           ↓
                          │     Task 2.4 (sample) ←── Task 1.1
                          │           ↓
                          │     Task 2.5 (drawTo)
                          │           ↓
阶段 3:                   │           │
  Task 3.1 (GraphPage UI) ←── 1.1+1.2 │
        ↓                              │
  Task 3.2 (onPlot/onArea) ←──────── 2.5
        ↓
  Task 3.3 (CalcPage btn) ←── 1.3 + 3.1
        ↓
阶段 4(线性):
  Task 4.1 (ets-check)
        ↓
  Task 4.2 (build)
        ↓
  Task 4.3 (device verify)
```

---

## 开发顺序

```
Task 1.1 → Task 1.2 → Task 1.3
       ↓
Task 2.1 → Task 2.2 → Task 2.3 → Task 2.4 → Task 2.5
       ↓
Task 3.1 → Task 3.2 → Task 3.3
       ↓
Task 4.1 → Task 4.2 → Task 4.3 → 完成
```

> **并行机会**:阶段 1 的 1.1/1.2/1.3 三个任务相互独立,可并行;阶段 2-4 内部存在依赖,需串行。

---

## 验收计划

| 任务 | 验收方式 | 关键产物 |
|------|---------|---------|
| Task 1.1 | 代码审查 + ets-check | Models.ets 编译通过 |
| Task 1.2 | JSON 校验 + 构建 | string.json 合法 |
| Task 1.3 | JSON 校验 | main_pages.json 合法 |
| Task 2.1 | 代码审查 | currentX 字段存在 |
| Task 2.2 | 单元自检(parseFactor) | x 和 xp 区分正确 |
| Task 2.3 | 单元自检(evalAt) | 5+ 函数样例验证 |
| Task 2.4 | 单元自检(sample) | sin/1/x/sqrt 用例 |
| Task 2.5 | 单元自检(drawTo) | mock ctx 调用次数 |
| Task 3.1 | 代码审查 + 路由可达 | GraphPage 显示空白 |
| Task 3.2 | 单设备 UI 测试 | sin(x) 显示曲线 |
| Task 3.3 | 单设备 UI 测试 + 回归 | 按钮可见、跳转、计算器零回归 |
| Task 4.1 | 自动化静态检查 | 0 error |
| Task 4.2 | 自动化构建 | hap 生成 |
| Task 4.3 | 设备综合验证 | 12 场景通过 |

---

## 改动量预估汇总

| 文件 | 操作 | 行数变化 |
|------|------|---------|
| entry/src/main/ets/model/Models.ets | 修改 | +30 |
| entry/src/main/ets/calculator/Calculator.ets | 修改 | +14 |
| entry/src/main/ets/calculator/Plotter.ets | 新建 | +150 |
| entry/src/main/ets/pages/GraphPage.ets | 新建 | +230 |
| entry/src/main/ets/pages/CalculatorPage.ets | 修改 | +10 |
| entry/src/main/resources/base/element/string.json | 修改 | +6 条 |
| entry/src/main/resources/base/profile/main_pages.json | 修改 | +1 行 |
| **总计** | — | **~440 行**(含 JSON;ets 部分 ~434 行,与设计预估 540 行有合理余量) |

> **说明**:实际改动可能因 ArkTS 类型注解、import 语句等略有浮动。设计阶段预估 540 行为上限;任务分解后核算 440 行更精确。

---

> 本文档由 aid-implementing skill 生成。
> 生成时间:2026-05-19
