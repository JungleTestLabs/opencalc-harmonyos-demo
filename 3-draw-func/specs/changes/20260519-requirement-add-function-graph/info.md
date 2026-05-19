# 函数图像绘制 — 代码仓理解（info.md）

## 基本信息

- **需求类别**：新增功能
- **需求名称**：函数图像绘制（Function Graph Plotter）
- **分析时间**：2026-05-19
- **分析范围**：`entry/src/main/ets/{calculator, pages, model, preferences, resources}`

---

## 1. 需求类别与重点分析

### 需求类别
**新增功能（New Requirement）**。依据：需求描述包含"支持"、"绘制"、"新增"语义；现有代码无 Plotter / Graph 相关任何模块；CalcEngine 当前不识别变量 `x`。

### 本次重点分析类别（依据侧重点匹配表）
| 类别 | 优先级 | 说明 |
|------|-------|------|
| 架构分析 | ✓✓ | 新功能要嵌入现有 MVVM-Lite 分层 |
| 公共组件/函数识别 | ✓✓ | 复用 CalcEngine / Expression 是核心 |
| 接口/契约识别 | ✓✓ | CalcEngine.evaluate 必须扩展为 evalAt |
| 影响范围分析 | ✓ | 需要确认对现有调用方零侵入 |
| 风险识别 | ✓ | x 与 xp 函数名冲突的前瞻处理 |
| 现有代码分析 | ○ | 仅需了解相关模块 |
| 测试验证策略 | ○ | 由 IMPLEMENTING 阶段细化 |
| 监控运维支持 | △ | 不涉及监控 |

---

## 2. 架构分析

### 当前架构（MVVM-Lite）

```
pages/Index.ets ──router.replaceUrl──▶ pages/CalculatorPage.ets (@Entry)
                                              │
                                              ├─ uses ─▶ calculator/Expression  (预处理)
                                              ├─ uses ─▶ calculator/Calculator  (CalcEngine)
                                              ├─ uses ─▶ calculator/NumberFormatter
                                              ├─ uses ─▶ model/Models           (HistoryItem, NumberingSystem ...)
                                              ├─ uses ─▶ model/ErrorFlags       (静态错误标志)
                                              └─ uses ─▶ preferences/PreferencesStore (主题/振动/历史)
```

### 关键架构事实
- **单 Entry 页面**：当前只有 `CalculatorPage` 是 @Entry。`Index` 仅作为启动跳板。
- **直接调用，无 ViewModel 层**：CalculatorPage 直接 new CalcEngine() / new Expression()，状态全在 @State 中。
- **静态错误标志**：`ErrorFlags` 是类级静态字段（全局可变状态）。CalculatorPage 在 `onEquals` 中 `ErrorFlags.reset()` → `evaluate` → 读取 flags → 显示错误。
- **资源驱动主题**：主题颜色不通过资源系统切换，而是通过 `getBg() / getOp() / ...` 函数根据 `themeIdx` 返回硬编码色值。
- **页面路由**：在 `entry/src/main/resources/base/profile/main_pages.json` 注册：
  ```json
  { "src": ["pages/Index", "pages/CalculatorPage"] }
  ```

### GraphPage 嵌入方案
- **新增 1 个 @Component 页面** `pages/GraphPage.ets`（非 @Entry，由 router 跳入）
- **新增 1 个工具模块** `calculator/Plotter.ets`
- **扩展 CalcEngine**：新增 `evalAt(equation, x, isDegree)` 方法，保留 `evaluate()` 完全不变
- **扩展 Models**：新增 `GraphConfig` / `PlotPoint` / `PlotResult` 三个 interface/class
- **不改 ErrorFlags**（静态字段方案保留）
- **不改 PreferencesStore**（暂不持久化绘图参数）

---

## 3. 接口/契约识别

### 现有关键接口

| 模块 | 接口 | 签名 | 调用方 | 说明 |
|------|------|------|--------|------|
| Expression | `getCleanExpression` | `(calc, decSep, grpSep) => string` | CalculatorPage.onEquals | 表达式预处理：替换 `×÷`、添加隐式乘法、`%→/100`、`√→sqrt`、`!→factorial`、补齐括号 |
| CalcEngine | `evaluate` | `(equation, isDegree) => number` | CalculatorPage.onEquals | 递归下降求值，依赖实例字段 `eq/p/c/deg`，**不可重入** |
| CalcEngine（私有） | `parseFactor` | `() => number` | 内部递归 | 在第 138-140 行：遇到无法识别的字符 → `ErrorFlags.syntax_error = true; x = 0` |
| ErrorFlags | `reset` / 5 个 boolean 静态字段 | static | 任何模块 | **静态全局状态**，多线程/多请求场景需注意 |
| PreferencesStore | `getTheme` | `() => Promise<number>` | CalculatorPage.loadPrefs | 0=默认 1=AMOLED 2=Material |
| router | `pushUrl` / `replaceUrl` / `back` | `(opt: { url, params? })` | Index | 标准 ArkUI 路由 |

### 新增/扩展接口（设计）

| 模块 | 接口 | 签名 | 说明 |
|------|------|------|------|
| CalcEngine | `evalAt`（**新增**） | `(equation: string, x: number, isDegree: boolean) => number` | 设置内部 `currentX` 后调用 `evaluate` 内部 helper；`parseFactor` 中增加 `x` 识别 |
| Plotter（**新模块**） | `sample` | `(prepared: string, cfg: GraphConfig, engine: CalcEngine, isDegree: boolean) => PlotResult` | 等间隔采样 |
| Plotter | `drawTo` | `(ctx: CanvasRenderingContext2D, result: PlotResult, cfg: GraphConfig, theme: ThemeColors) => void` | Canvas 绘制 |

### 关键技术约束
- `CalcEngine.evaluate` **不可重入**：依赖实例字段。多次采样必须**串行**调用，不能并发。
- ArkTS 不支持 `String.prototype.replace(regex, ...)` 的完整正则功能（受限）。若用字符串替换实现 `x` 注入，需用循环 indexOf 替换。**更优**：在 `parseFactor` 中识别 `x` token。

---

## 4. 公共组件或函数识别

### 可复用清单

| 模块/函数 | 复用方式 | 注意事项 |
|----------|---------|---------|
| `Expression.getCleanExpression()` | **直接复用**：在 Plotter.sample 内调用 1 次（不在循环内重复） | 入参 `decSep / grpSep` 可固定为 `'.', ','`，与 CalculatorPage 保持一致 |
| `CalcEngine`（扩展后） | **扩展复用**：新增 `evalAt`，调用方使用 evalAt | 注意 ErrorFlags 在循环中需每点 reset |
| `ErrorFlags` | **复用错误文案映射**：CalculatorPage.onEquals 的 if-else 链可抽取为辅助函数 | 当前是内联代码，重用需小先抽函数 |
| 主题色函数 `getBg/getOp/getT1/getT2/getErr` | **建议拷贝到 GraphPage** 或**抽取为公共 ThemeHelper.ets** | 当前是 CalculatorPage 的实例方法，无法直接 import。需要小重构。 |
| `Models.CalculatorError` 枚举 | 可直接复用 | 但 CalculatorPage 当前实际用的是 ErrorFlags + 内联字符串，不是枚举 |

### 建议小重构（**可选，非阻塞**）
- 抽取 `entry/src/main/ets/common/ThemeColors.ets`：把 `getBg/getOp/getT1/getT2/getErr/getBtnBg/...` 改为根据 themeIdx 返回常量的纯函数，CalculatorPage 与 GraphPage 同时复用
- 抽取 `entry/src/main/ets/common/ErrorMessages.ets`：把 ErrorFlags → 中文文案的映射函数化

**判断**：本次需求范围内，**不强求**这两个重构。直接在 GraphPage 内复制主题色函数即可（与 CalculatorPage 的 themeIdx 一致），代价 ~30 行，避免引入修改 CalculatorPage 的回归风险。

---

## 5. 影响范围分析

### 文件清单

| 路径 | 操作 | 改动量预估 |
|------|------|-----------|
| `entry/src/main/ets/pages/GraphPage.ets` | **新建** | ~350 行（UI + Canvas 集成） |
| `entry/src/main/ets/calculator/Plotter.ets` | **新建** | ~150 行（采样 + 绘制） |
| `entry/src/main/ets/calculator/Calculator.ets` | **修改**：增加 `currentX` 字段、`evalAt` 方法、`parseFactor` 识别 `x` token | ~25 行新增 |
| `entry/src/main/ets/model/Models.ets` | **修改**：新增 GraphConfig / PlotPoint / PlotResult 类型 | ~30 行新增 |
| `entry/src/main/ets/pages/CalculatorPage.ets` | **修改**：ToggleRow 增加"绘图"按钮 + router.pushUrl | ~10 行修改 |
| `entry/src/main/resources/base/profile/main_pages.json` | **修改**：注册 GraphPage | 1 行 |
| `entry/src/main/resources/base/element/string.json` | **修改**：新增字符串（绘图、请输入表达式、函数在该区间未定义、采样提前结束等） | 6~8 条 |
| `entry/src/main/resources/base/element/color.json` | **暂不修改**（GraphPage 自行包装主题色函数） | 0 |
| 测试代码 | **新建**：（按规则未提及单测目录，由 IMPLEMENTING 阶段确定） | TBD |

### 调用链分析

```
用户点击"绘图"按钮
  │
  ▼
CalculatorPage.ToggleRow → router.pushUrl({ url: 'pages/GraphPage' })
  │
  ▼
GraphPage.aboutToAppear → 读 PreferencesStore.getTheme → 设置 themeIdx
  │
  ▼
用户输入 "sin(x)" → 点击"绘图"按钮
  │
  ▼
GraphPage.onPlot
  │
  ├─▶ Expression.getCleanExpression("sin(x)", ".", ",")  → 预处理 1 次
  │
  ├─▶ Plotter.sample(prepared, cfg, engine, isDegree)
  │     │
  │     └─▶ for i in 0..N: 
  │           ErrorFlags.reset()
  │           y = engine.evalAt(prepared, x_i, isDegree)
  │           if any ErrorFlag → defined=false
  │
  └─▶ Plotter.drawTo(ctx, plotResult, cfg, themeColors)
        │
        └─▶ Canvas API: clearRect + moveTo/lineTo 折线段绘制
```

### 对现有功能的影响评估

| 现有功能 | 是否受影响 | 说明 |
|---------|-----------|------|
| CalculatorPage.onEquals 求值通路 | **否** | `evaluate` 接口完全保留，仅扩展 `evalAt` |
| 历史记录 | **否** | 不持久化绘图，独立通路 |
| 主题切换 | **否** | GraphPage 自行读取 themeIdx，CalculatorPage 不受影响 |
| 表达式预处理 | **轻微** | Expression 完全不改动；但需验证 `x` 字符在 `addMultiply` 流程中不被破坏 |
| 错误标志 | **轻微** | ErrorFlags 仍为静态全局，但采样循环每次 reset，不会污染 CalculatorPage 后续使用 |

---

## 6. 现有代码分析（关键片段）

### CalcEngine.parseFactor 中 'x' 字符的处理

`Calculator.ets:102-140` 当前流程：
- 遇到 `c >= 97 && c <= 122`（小写字母）→ 进入函数名 while 循环读取整个标识符
- 例如：`xp(2)` → 读到 `xp` → 匹配 `else if (fn === 'xp') x = this.powx(Math.E, x)`
- 例如：`x+1` → 读到 `x`（while 循环立即结束因 `+` 不是小写字母）→ fn="x" → 不匹配任何 if 分支 → 落入 `else ErrorFlags.syntax_error = true`

**结论**：单字符 `x` 当前被当作"未知函数名"处理，触发语法错误。

### 实现 evalAt 的最优方案

在 `parseFactor` 中**先**做单字符 `x` 识别（在函数名 while 循环**之前**）：

```ts
// 单字符 'x' 变量识别（必须在函数名扫描之前）
if (this.c === 120 /* 'x' */) {
  const nextC: number = this.p + 1 < this.eq.length ? this.eq.charCodeAt(this.p + 1) : -1
  // 前瞻：若 x 后跟小写字母（如 xp），让函数名扫描处理；否则视为变量
  const isPartOfFunctionName: boolean = (nextC >= 97 && nextC <= 122)
  if (!isPartOfFunctionName) {
    this.nx()
    x = this.currentX
    // 接着允许 ^ 幂运算
    if (this.eat(94)) x = this.powx(x, this.parseFactor())
    return x
  }
  // 否则继续走函数名扫描分支
}
```

新增字段 `currentX: number = 0`，新增方法：

```ts
evalAt(equation: string, x: number, isDegree: boolean): number {
  this.currentX = x
  return this.evaluate(equation, isDegree)
}
```

### Expression.addMultiply 对 `x` 的处理

`Expression.ets:43-98` 检查：
- 遇到 `x` 字符，落入 else 分支（98 行往后）→ functionsList = ['arcco','arcsi','arcta','cos','sin','tan','ln','log','xp']
- text.endsWith('xp') 检查时，前面字符 `x` 不会单独匹配任何 list 项
- **结论**：`sin(x)` → 预处理后仍为 `sin(x)`，OK
- `2*x` → 用户必须显式写乘号；如果写 `2x`，**不会**自动加 `*`
- **设计决策**：本期 V1 要求用户写 `2*x`；后续可在 `addMultiply` 中扩展（**不在本期范围**）

### Canvas 在 ArkUI 中的使用要点
- `Canvas(this.ctx)` 配合 `private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(new RenderingContextSettings(true))`
- `.onReady(() => { ... })` 在 Canvas 尺寸就绪后调用一次
- `.onAreaChange(...)` 在尺寸变化时触发
- 绘制 API 与 W3C Canvas 2D 基本一致：`clearRect / beginPath / moveTo / lineTo / stroke / fillText / fillStyle / strokeStyle / lineWidth`

---

## 7. 风险识别

| 编号 | 风险描述 | 等级 | 缓解措施 |
|------|---------|------|---------|
| R-01 | CalcEngine 的 `evaluate` 不可重入，多采样并发会破坏 `eq/p/c` 状态 | 中 | 严格串行调用；GraphPage 用同一个 engine 实例，主线程单线程已天然保证 |
| R-02 | ErrorFlags 是静态全局，与 CalculatorPage 共享 | 中 | 每个采样点前 `ErrorFlags.reset()`；绘图完成后再 reset 一次，确保不影响后续 CalculatorPage 计算 |
| R-03 | `x` 与 `xp` 函数名首字母冲突 | 高 | 在 parseFactor 中加前瞻：x 后跟小写字母时让函数名扫描接管 |
| R-04 | 长表达式 + 600 采样点 + 复杂函数 → 主线程阻塞 | 中 | 软超时检查（每 100 点检测 `Date.now() - start`），>200ms 提前结束并显示已采样部分 |
| R-05 | ArkTS 不支持完整 JS 特性（如复杂正则、某些泛型） | 低 | 字符串处理用 indexOf/substring；类型严格匹配 |
| R-06 | Canvas onReady 在 onAreaChange 之前还是之后？时序问题 | 中 | 用 `canvasReady: boolean` 状态机，确保只在 ready 后绘制；onAreaChange 触发时若未 ready 则等待 |
| R-07 | tan(x) 在 π/2 附近 y 跨越 ±∞，折线穿越画布 | 低 | |Δy| > 5 × canvasHeight 阈值断开折线 |
| R-08 | 用户在 GraphPage 内修改主题（如果实现的话），需要重绘 | 低 | 本期不在 GraphPage 内提供主题设置入口，必须返回 CalculatorPage 切换；进入 GraphPage 时读取一次 |
| R-09 | 内存累积：连续多次绘图未释放 PlotResult | 低 | PlotResult 用局部变量，每次绘图后 Canvas.clearRect；不缓存 |
| R-10 | aboutToDisappear 未清理 timer | 中 | 防抖 timer 用 setTimeout id 保存，aboutToDisappear 中 clearTimeout |

---

## 8. 测试验证策略

### 单元测试范围
- `CalcEngine.evalAt` 对常见函数：`sin(x)`, `cos(x)`, `x^2`, `2*x+1`, `1/x`, `sqrt(x)`, `ln(x)`, `tan(x)`, `xp(x)`（即 e^x）
- 验证 `x` 与 `xp` 区分：`xp(x)` 应正确计算 e^x（即 currentX → 求 e^currentX）
- ErrorFlags 在错误表达式后能恢复（reset + 下一次正常）
- 数值边界：`1/x` 在 x=0 时返回 Infinity（被 defined=false 捕获）

### UI / 集成测试
- 输入 `sin(x)` → 看到正弦曲线
- 输入空 → 看到"请输入表达式"
- 输入 `sin(` → 看到"表达式语法错误"
- 输入 `1/x` → 曲线在 x=0 处断开
- 横竖屏切换后曲线无残留
- 三种主题下颜色对比正确

### 回归测试范围
- CalculatorPage 所有原有功能（四则、科学、历史、设置、关于）— 由于 `evaluate` API 未变，预期零回归
- 主题切换 — 由于 GraphPage 只读 themeIdx，不写，预期零回归

---

## 9. 监控运维支持

无监控需求（本地应用，无云服务）。日志埋点建议：
- 采样耗时 > 200ms → `console.warn('plot sample timeout', expr, duration)`
- 全段未定义 → `console.info('plot no valid points', expr)`
- 渲染异常（catch 块）→ `console.error('plot render error', e)`

均使用 hilog 等价 console.* 即可，不引入新日志系统。

---

## 关键发现总结

### 可复用组件或函数
- ✅ `Expression.getCleanExpression()` — 预处理直接复用
- ✅ `CalcEngine.evaluate()` — 通过新增 evalAt 方法间接复用其全部求值能力
- ✅ `ErrorFlags` — 错误标志直接复用
- ✅ `PreferencesStore.getTheme()` — 主题索引直接复用
- ✅ 主题色调色板（getBg/getOp/getT1/getT2/getErr）— 拷贝模式复用（不重构）

### 风险提示
1. **R-03（高）**：`x` token 必须在 `parseFactor` 中以前瞻方式识别，避免污染 `xp` 函数名
2. **R-02 & R-10（中）**：静态 ErrorFlags + setTimeout 资源在 aboutToDisappear 必须清理
3. **R-04 & R-06（中）**：性能软超时 + Canvas 就绪状态机

### 建议事项
1. **不修改 Expression**：保持表达式预处理通路不变；用户需写 `2*x` 而非 `2x`（本期约束）
2. **CalcEngine 改动最小化**：仅新增 currentX + evalAt，parseFactor 加 1 段前瞻判断；不删旧逻辑
3. **GraphPage 独立维护主题色**：避免抽取 ThemeColors 的连带修改风险
4. **Plotter 设计为无状态纯模块**：sample/drawTo 函数式风格，便于单元测试
5. **新增类型集中放在 Models.ets**：保持单一数据模型文件
