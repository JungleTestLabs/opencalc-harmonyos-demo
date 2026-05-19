# 百分号按钮 - 代码仓理解（info.md）

## 基本信息

- **需求类别**：新增功能（New Requirement）
- **需求名称**：在主界面新增 `%` 按钮，支持智能百分号语义
- **分析时间**：2026-05-18
- **分析范围**：`entry/src/main/ets/pages/CalculatorPage.ets`、`entry/src/main/ets/calculator/Expression.ets`

## Step 1-2：需求类别与重点分析项

- **需求类别**：新增功能（依据：触发词 "加一个"、"新增"）
- **重点分析（依据侧重点匹配表）**：
  - 架构分析 ✓✓
  - 公共组件或函数识别 ✓✓
  - 接口/契约识别 ✓✓
  - 影响范围分析 ✓（次要）
  - 风险识别 ✓（次要）
- **简化项**：监控运维（不涉及）、版本兼容（不涉及）

---

## 架构分析

### 系统模块结构（与本需求相关）

```
entry/src/main/ets/
├── pages/
│   └── CalculatorPage.ets        ← @Entry 主页面（409 行）─── 【本次唯一修改点】
├── calculator/
│   ├── Calculator.ets            ← 计算引擎（180 行）
│   ├── Expression.ets            ← 表达式预处理器（298 行）─── 【关键复用：getPercentString】
│   └── NumberFormatter.ets       ← 数字格式化（176 行）
├── model/
│   ├── Models.ets                ← HistoryItem 等数据模型
│   └── ErrorFlags.ets            ← 计算错误标志（静态字段类）
└── preferences/
    └── PreferencesStore.ets      ← 偏好/历史持久化
```

### 调用链（点击 `%` → 求值 → 显示结果）

```
[用户点击 %]
    ↓
CalculatorPage.@Builder ButtonGrid()
    │   currently no % button — 本次需新增
    ↓
this.onOp('%')                            (CalculatorPage.ets:71)
    │   this.expression += '%'
    ↓
[用户点击 =]
    ↓
CalculatorPage.onEquals()                 (CalculatorPage.ets:77-99)
    ├─→ ErrorFlags.reset()
    ├─→ Expression.getCleanExpression(expression, '.', ',')
    │       ├─→ replaceSymbols()         (Expression.ets:25)
    │       ├─→ addMultiply()            (Expression.ets:43)
    │       │       └── 已处理 % 后接数字/( 自动插 * (Expression.ets:58-62)
    │       └─→ getPercentString()       (Expression.ets:169-255) ─── 【智能 % 语义】
    │               ├── case '%' 前为 '!' → ((expr!)/100)
    │               ├── case '%' 前为 ')' → ((subExpr)/100)
    │               └── case 普通数字 → 根据前置运算符决定 a*(b/100) 或 (b/100)
    ├─→ CalcEngine.evaluate(clean, !radianMode)
    ├─→ NumberFormatter.format(raw, ...)
    └─→ 写 result 状态 + 入 history
```

### 关键发现

> 计算引擎对 `%` 的支持是**完整且自洽**的，本次需求**没有任何计算层改动**。仅缺失 UI 暴露入口。

---

## 接口/契约识别

### 已有可调用接口（无需改动）

| 接口 | 位置 | 说明 |
|------|------|------|
| `CalculatorPage.onOp(op: string)` | CalculatorPage.ets:71 | 通用运算符点击处理（向 expression 追加字符）|
| `Expression.getCleanExpression(calc, dec, group)` | Expression.ets:8 | 已包含 `%` 的预处理调用 |
| `Expression.getPercentString(calc)` | Expression.ets:169 | 智能 `%` 语义内核 |
| `CalcEngine.evaluate(eq, isDegree)` | Calculator.ets:28 | 求值入口 |
| `ErrorFlags.reset() / .syntax_error / ...` | ErrorFlags.ets | 错误状态共享（静态字段）|

### 本次需要新增的「内部接口」

无新增对外接口；仅在 `CalculatorPage` 内新增一个 `@Builder` 方法（例如 `BtnPctOp` 或复用 `BtnOp`）。

### 契约保持

- 点击 `%` 必须走 `onOp('%')` —— 保持与其他运算符（`+ - × ÷`）的事件路径一致
- 不得绕过 `Expression.getCleanExpression` 直接调用 `Calculator` —— 否则会丢失智能 `%` 语义

---

## 公共组件或函数识别（可复用清单）

| 组件/函数 | 位置 | 复用建议 |
|----------|------|---------|
| `@Builder BtnOp(l: string)` | CalculatorPage.ets:291 | **直接复用**：传入 `'%'` 即可生成与四则同款蓝色运算符按钮。`width('22%')` 在 5 列布局下需调整为 `'18%'` 或 `'19%'` |
| `this.onOp(op: string)` | CalculatorPage.ets:71 | 直接复用，无需修改 |
| `this.getOp()` | CalculatorPage.ets:149 | 直接调用获取主题感知运算符背景色 |
| `this.getBtnText()` | CalculatorPage.ets:182 | 文本色 |
| `this.isLandscape` | CalculatorPage.ets:25 | 横竖屏分支条件 |

### 复用注意事项

- **`BtnOp` 中的 `width('22%')` 硬编码**会与 5 列布局冲突。两种选择：
  - **方案 A（最小改动）**：复用 `BtnOp`，在首行 5 列布局时由 Row 自身或 Flexbox 自动均分（但 ArkTS 的 `width('22%')` 是显式宽度，5 个加起来 110% 会溢出 / 换行）。**不推荐**。
  - **方案 B（推荐）**：新增一个 `@Builder BtnOp5(l: string)`，参数与 `BtnOp` 一致，仅 width 为 `'18%'`（5×18% = 90%，留 10% margin 缓冲）。或者把 `BtnOp` 参数化（带可选宽度）—— **避免，违反最小改动**。
  - **方案 C（推荐变体）**：保留 `BtnOp`，在首行用 `BtnOp` 的代码内联（不通过 `@Builder`，仅 5 个按钮的一行），显式设宽 18%。
- 决定在 step8 `mod-design` 阶段最终确定。倾向方案 B。

---

## 影响范围分析

### 需要修改的文件

| 文件 | 改动类型 | 行数估计 |
|------|---------|---------|
| `entry/src/main/ets/pages/CalculatorPage.ets` | 修改（+约 15 行） | 1. ButtonGrid 首行布局；2. 新增 `BtnOp5` Builder（如采纳方案 B） |

### **无需修改**的文件（重要）

| 文件 | 说明 |
|------|------|
| `entry/src/main/ets/calculator/Expression.ets` | 智能 `%` 语义已完整实现（包括括号/阶乘/前置运算符识别）|
| `entry/src/main/ets/calculator/Calculator.ets` | 引擎不感知 `%`（`%` 在 Expression 层被替换为 `/100`）|
| `entry/src/main/ets/calculator/NumberFormatter.ets` | 数字格式化不变 |
| `entry/src/main/ets/model/*.ets` | 数据模型不变 |
| `entry/src/main/ets/preferences/PreferencesStore.ets` | 持久化不变 |

### 上下游影响

- **上游（触发者）**：用户点击 `%` 按钮 → 已经被 `onOp` 设计为可扩展
- **下游（被影响）**：仅 `expression` 字符串内容多了 `%` 字符；其余流程无差异

---

## 现有代码分析

### 关键代码定位（带行号）

#### CalculatorPage.ets

```
13   @Entry @Component export struct CalculatorPage
14   @State expression: string = ''           // 表达式状态
17   @State errorMsg: string = ''             // 错误提示状态
71   onOp(op: string): void                   // 复用入口：本次仅传入 '%'
77-99 onEquals(): void                        // 求值入口
149-152 getOp(): string                       // 主题感知运算符背景色
182-185 getBtnText(): string                  // 主题感知按钮文本色
272-285 @Builder ButtonGrid()                 // 按钮网格（核心修改点）
278   Row() { this.BtnAct('AC'); this.BtnOp('('); this.BtnOp(')'); this.BtnOp('÷') }  // 首行 4 按钮
288   @Builder BtnDig(l: string)              // 数字按钮 width('22%')
291   @Builder BtnOp(l: string)               // 运算符按钮 width('22%') — 复用基础
294   @Builder BtnFunc(l: string)             // 科学函数 width('18%')
297   @Builder BtnConst(l: string)            // 常量 width('18%')
300   @Builder BtnAct(l: string)              // 动作（AC/退格）width('22%')
303   @Builder BtnEq()                        // 等号 width('22%')
```

#### Expression.ets

```
6    export class Expression
8    getCleanExpression(calc, dec, group) — 主流水线
14-17  if (calc.indexOf('%') !== -1) {
            calc = this.getPercentString(calc)
            calc = this.replaceAll(calc, '%', '/100')  // 兜底替换
        }
58-62  addMultiply():
            else if (ch === '!' || ch === '%') {
                if (next is digit/π/() insert '*'
            }
169-255 getPercentString(calc):                // 智能 % 语义
        遍历表达式：
          - 遇 '(' / ')' → 跟踪嵌套
          - 遇 '%':
            - 若 % 前为 '!' → ((expr!)/100)
            - 若 % 前为 ')' → 找匹配 '('，包成 ((subExpr)/100)
            - 否则（普通数字）：
              - 找前置运算符 opPos
              - 无前置运算符 → 直接 (num/100)
              - 前为 * 或 / → 跟在 op 后 (num/100)
              - 前为 + 或 - → 重写为 base op base*(num/100)  ← 这就是 50+10% → 55 的核心
```

### 关键变量

- `expression`（`@State` string）：当前用户输入的表达式
- `result`（`@State` string）：求值结果显示
- `errorMsg`（`@State` string）：错误信息显示
- `themeIdx`（`@State` number）：0=浅色 / 1=AMOLED / 2=暗色
- `isLandscape`（`@State` boolean）：横竖屏

### 边界条件（已由 Expression 层处理）

| 输入 | 期望 | 已支持 |
|------|------|-------|
| `50+10%` | 55 | ✓ |
| `50-10%` | 45 | ✓ |
| `50*10%` | 5 | ✓ |
| `50/10%` | 500 | ✓ |
| `10%` | 0.1 | ✓ |
| `(20+30)%` | 0.5 | ✓ |
| `5!%` | 阶乘后除 100 | ✓ |
| `+%` 或 `%` 空 | syntax_error | ✓ |

---

## 风险识别

| 风险编号 | 描述 | 等级 | 缓解 |
|---------|------|------|------|
| R-01 | 改 ButtonGrid 首行时不小心破坏 4 列其他行（例如把所有行都改成 5 列）| 中 | 仅修改 `Row() { this.BtnAct('AC'); ...; this.BtnOp('÷') }` 这**一行代码**；其他 Row 不动 |
| R-02 | 复用 `BtnOp` 时未调整宽度，导致首行溢出 / 换行 | 中 | 采纳方案 B：新增 `BtnOp5`，宽度 18% |
| R-03 | 主题切换时 `%` 按钮配色不响应（如硬编码 `'#B4D2E4'`）| 低 | 严格使用 `this.getOp()` 表达式 |
| R-04 | 横屏布局 5 列后按钮过窄（fontSize 在横屏分支下 14，按钮高 36）| 低 | 视觉走查；如果过窄可在横屏分支下 fontSize 略调（但能不动尽量不动）|
| R-05 | 误以为需要修改 Expression.ets — 过度改动 | 中 | step8 设计 + step9 审视明确禁止改动 Expression.ets |

---

## 测试验证策略

### 单元测试场景（关键）

| 用例 | 输入 | 期望结果 |
|------|------|---------|
| UT-PCT-01 | `Expression.getCleanExpression('50+10%','.', ',')` | `"50+50*((10)/100)"` 或等价正确形式 |
| UT-PCT-02 | `CalcEngine.evaluate(clean('50+10%'), true)` | 55 |
| UT-PCT-03 | `CalcEngine.evaluate(clean('50-10%'), true)` | 45 |
| UT-PCT-04 | `CalcEngine.evaluate(clean('50*10%'), true)` | 5 |
| UT-PCT-05 | `CalcEngine.evaluate(clean('25%'), true)` | 0.25 |
| UT-PCT-06 | `CalcEngine.evaluate(clean('%'), true)` | ErrorFlags.syntax_error |

> 注：UT-PCT-01..06 实际验证的是 Expression + Calculator 既有能力，应作为「回归」基线测试。本次需求**不引入新算法**。

### UI 测试场景

| 用例 | 步骤 | 验证 |
|------|------|------|
| UI-PCT-01 | 启动 → 看到 `%` 按钮 | 按钮存在且可见 |
| UI-PCT-02 | 点 5 0 + 1 0 % = | result = "55" |
| UI-PCT-03 | 切换暗色 → 点 % | 按钮背景色 = `#0070BC` |
| UI-PCT-04 | 切换横屏 → 看到 5 列首行 | 按钮无重叠 |
| UI-PCT-05 | 历史回填 `50+10%` → 再次 = | result = "55" |

### 回归测试范围

| 范围 | 用例 |
|------|------|
| 基础运算 | AC、退格、四则、括号、=、`.` |
| 模式切换 | 基础/科学切换 |
| 主题切换 | 三主题切换 |
| 横竖屏 | onAreaChange 触发布局切换 |
| 历史记录 | 新增、点击、滑动删除 |

---

## 监控运维支持

> 本需求不涉及监控/日志/配置变更。

---

## 关键发现

### 可复用组件或函数（再次强调）

- `@Builder BtnOp(l)` — 运算符按钮（width 需调整）
- `onOp(op: string)` — 通用运算符事件
- `getOp() / getBtnText()` — 主题感知颜色
- `Expression.getPercentString()` — 智能百分号语义（**核心复用，零改动**）
- `Expression.getCleanExpression()` — 已自动应用 getPercentString
- `Expression.addMultiply()` — 已处理 `%` 后接数字自动插 `*`

### 风险提示

- 务必**不改 Expression.ets / Calculator.ets**（YAGNI + 最小改动原则）
- 务必使用响应式属性表达式（`this.getOp()`）而非硬编码颜色
- 首行宽度调整必须只影响首行，不影响其他 4 行

### 建议事项

1. **采纳方案 B**：新增 `@Builder BtnOp5(l: string)` 仅宽度 18%，其他与 `BtnOp` 完全一致
2. **首行实现**：`Row() { this.BtnAct5('AC'); this.BtnOp5('('); this.BtnOp5(')'); this.BtnOp5('%'); this.BtnOp5('÷') }`
   - 由于 `BtnAct` 也是 width 22%，可能也需要一个 `BtnAct5`；或者首行直接内联 5 个 Text 组件
3. **测试聚焦**：先做单元测试验证 `%` 语义未受影响（回归），再做 UI 集成测试
4. **不引入新文件**：所有变更在 `CalculatorPage.ets` 一个文件内完成
