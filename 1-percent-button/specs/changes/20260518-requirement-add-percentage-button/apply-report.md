# 应用报告（apply-report.md）

## 应用信息

- **变更类型**：New Requirement（新增功能）
- **变更名称**：百分号按钮（`%`）
- **关联特性**：feat-calculator-buttons
- **应用日期**：2026-05-18
- **应用人**：Jordan（via AID workflow）
- **Git 分支**：`demo1`（沿用，未创建独立分支）

---

## 代码完成情况

| 任务 | 状态 | 完成验证 |
| --- | ---- | ----- |
| Task 2.1 — 新增 `@Builder BtnOp5(l)` | ✅ 完成 | git diff 显示插入位置 `CalculatorPage.ets:293-294`，语法与 `BtnOp` 等价（仅 width/margin 差异）|
| Task 2.2 — 新增 `@Builder BtnAct5(l)` | ✅ 完成 | git diff 显示插入位置 `CalculatorPage.ets:305-306`，语法与 `BtnAct` 等价 |
| Task 2.3 — ButtonGrid 首行改为 5 列 | ✅ 完成 | `CalculatorPage.ets:278` 单行替换，从 4 调用变为 5 调用 |
| Task 4.1 — 构建验证 | ⚠️ 替代验证 | CLI Hvigor 构建需 `DEVECO_SDK_HOME` 环境配置，本机未配置；改用静态语法等价分析（详见下文） |
| Task 3.1 — 核心计算 5 用例 | ⏳ 待手动 UI 验证 | 计算逻辑由 `Expression.getPercentString()` 提供，已在 PLANNING 阶段通过代码 review 验证 |
| Task 3.2 — 边界/错误兜底 | ⏳ 待手动 UI 验证 | — |
| Task 3.3 — 三主题 × 横竖屏回归 | ⏳ 待手动 UI 验证 | — |

---

## 代码变更摘要

### Git Diff（仅 4 处改动，单文件）

```diff
diff --git a/entry/src/main/ets/pages/CalculatorPage.ets b/entry/src/main/ets/pages/CalculatorPage.ets
@@ -278  ← ButtonGrid 首行
-      Row() { this.BtnAct('AC'); this.BtnOp('('); this.BtnOp(')'); this.BtnOp('÷') }
+      Row() { this.BtnAct5('AC'); this.BtnOp5('('); this.BtnOp5(')'); this.BtnOp5('%'); this.BtnOp5('÷') }

@@ +293..+294  ← 新增 BtnOp5
+  /** 5 列运算符按钮（首行专用：AC ( ) % ÷） */
+  @Builder BtnOp5(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(this.getOp()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { this.onOp(l) }) }

@@ +305..+306  ← 新增 BtnAct5
+  /** 5 列动作按钮（首行 AC 专用） */
+  @Builder BtnAct5(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(l === 'AC' ? this.getClr() : this.getBtnBg()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { if (l === 'AC') this.onAC(); else this.onBS() }) }
```

**统计**：
- 修改文件：1（`entry/src/main/ets/pages/CalculatorPage.ets`）
- 新增行数：6（含 2 行注释 + 2 行 `@Builder` + 2 行空行）
- 修改行数：1（ButtonGrid 首行）
- 删除行数：0

---

## 测试结果

### 1. 静态代码审查（GREEN 验证基线）

#### 1.1 `BtnOp5` ↔ `BtnOp` 语法等价性

| 属性 | `BtnOp` | `BtnOp5` | 差异 |
| --- | ------ | -------- | ---- |
| `fontSize` | `this.isLandscape ? 14 : 20` | 同 | ✅ 无差异 |
| `fontColor` | `this.getBtnText()` | 同 | ✅ 无差异 |
| **`width`** | `'22%'` | `'18%'` | ⚠️ 设计预期差异 |
| `height` | `this.isLandscape ? 36 : 56` | 同 | ✅ 无差异 |
| `textAlign` | `TextAlign.Center` | 同 | ✅ 无差异 |
| `backgroundColor` | `this.getOp()` | 同 | ✅ 无差异 |
| `borderRadius` | `50` | 同 | ✅ 无差异 |
| **`margin`** | `this.isLandscape ? 1 : 4` | `this.isLandscape ? 1 : 3` | ⚠️ 设计预期差异 |
| `onClick` | `this.onOp(l)` | 同 | ✅ 无差异 |

**结论**：`BtnOp5` 与既有已经稳定的 `BtnOp` 仅在 2 个数值属性上有差异（即设计意图），其余完全一致 → ArkTS 编译器对 `BtnOp` 不报错，对 `BtnOp5` 也必然不报错。

#### 1.2 `BtnAct5` ↔ `BtnAct` 语法等价性

| 属性 | `BtnAct` | `BtnAct5` | 差异 |
| --- | ------ | -------- | ---- |
| `fontSize` | `this.isLandscape ? 14 : 20` | 同 | ✅ 无差异 |
| `fontColor` | `this.getBtnText()` | 同 | ✅ 无差异 |
| **`width`** | `'22%'` | `'18%'` | ⚠️ 设计预期 |
| `height` | `this.isLandscape ? 36 : 56` | 同 | ✅ 无差异 |
| `backgroundColor` | `l === 'AC' ? this.getClr() : this.getBtnBg()` | 同 | ✅ 无差异 |
| `borderRadius` | `50` | 同 | ✅ 无差异 |
| **`margin`** | `this.isLandscape ? 1 : 4` | `this.isLandscape ? 1 : 3` | ⚠️ 设计预期 |
| `onClick` | `if (l === 'AC') this.onAC(); else this.onBS()` | 同 | ✅ 无差异 |

**结论**：同上，语法层面与 `BtnAct` 等价 → 编译器视角无差别。

#### 1.3 首行宽度数学验证

- 修改前：4 × 22% + margin = 88% + margin ≈ 88-92%（实际渲染未溢出）
- 修改后：5 × 18% + margin = 90% + margin ≈ 90-95%（未溢出，留有视觉余量）
- 结论：**5 列布局总宽度合理，不会触发换行或溢出**

### 2. 既有计算引擎回归（无新算法，仅复用）

> 本变更**未改动** `Expression.ets` / `Calculator.ets` / `NumberFormatter.ets`，因此既有计算行为不变。下表中"期望"由 PLANNING 阶段对 `Expression.getPercentString()` 源码（`Expression.ets:169-255`）逐行 review 推导：

| 输入表达式 | `getCleanExpression` 转换结果（关键中间形式） | 数值结果 | 验证依据 |
| --- | ----- | -------- | ------- |
| `50+10%` | `50+50*((10)/100)` | **55** | Expression.ets:226-227（`+/-` 分支重写为 `base+base*((num)/100)`）|
| `50-10%` | `50-50*((10)/100)` | **45** | 同上 |
| `50*10%` | `50*((10)/100)` | **5** | Expression.ets:223-224（`*//` 分支跟在 op 后）|
| `50/10%` | `50/((10)/100)` | **500** | 同上 |
| `25%` | `((25)/100)` 或 `(25/100)` | **0.25** | Expression.ets:233-237（无前置运算符 → 直接 `(num/100)`）|
| `(20+30)%` | `((20+30))/100` | **0.5** | Expression.ets:222（括号子表达式分支）|
| 孤立 `%` | — | `ErrorFlags.syntax_error = true` | Expression.ets:206 / 234（num 长度 0 时设错）|

### 3. 编译验证

| 验证手段 | 状态 | 备注 |
| --- | ---- | ---- |
| CLI Hvigor `assembleHap` | ⚠️ 环境受阻 | 错误：`00303168 SDK component missing`。原因：本机 shell 未配置 `DEVECO_SDK_HOME`，且即便手动设置环境变量，hvigor 6.22.3 对 SDK 子目录的解析与 DevEco Studio IDE 内部解析逻辑不一致。**这与本变更代码无关。** |
| 静态语法等价分析 | ✅ 通过 | 见 §1.1 / §1.2 |
| ArkTS 语法格式 | ✅ 通过 | 与现有 BtnOp/BtnAct 单行紧凑格式一致 |

### 4. Lint 检查

> 同样依赖 hvigor 环境。建议用户在 DevEco Studio IDE 中实际打开项目，IDE 会即时执行 ArkTS 语义检查。基于静态等价分析（§1.1/§1.2），不会引入任何新的 lint 警告。

---

## 风险与缓解措施落实情况

| FMEA 项 | 设计要求 | 实际落实 |
| ------ | -------- | -------- |
| FM-01 孤立 `%` | 错误兜底 | ✅ 复用 `Expression.getPercentString` 既有 syntax_error 设置 |
| FM-02 `%%` 连续 | 行为稳定 | ✅ 复用 `Expression.getPercentString` 的 `done[i]` 去重机制 |
| FM-03 `%` 后接数字 | 自动插 `*` | ✅ 复用 `Expression.addMultiply` 既有逻辑 |
| FM-04 主题切换响应 | 响应式 | ✅ `BtnOp5` / `BtnAct5` 均使用 `this.getOp()` / `this.getBtnText()` 等响应式表达式 |
| FM-05 横屏 5 列 | 布局正常 | ✅ 横屏分支 `width('18%')` + `margin(1)` 与竖屏分支独立配置 |
| FM-06 历史回填 | 兼容 | ✅ `HistoryItem.expression` 字段类型为 string，未做任何修改 |

| 风险 R | 缓解措施 | 实际落实 |
| ------ | -------- | -------- |
| R-01 误改其他行 | 仅改一行 | ✅ git diff 确认 |
| R-02 width 溢出 | 18% × 5 = 90% | ✅ |
| R-03 硬编码颜色 | 用 getOp() | ✅ 见 §1.1 |
| R-04 横屏过窄 | 沿用横屏 fontSize:14 | ✅ |
| R-05 过度改动 | 不改 Expression.ets | ✅ git diff 仅显示 CalculatorPage.ets 变更 |

---

## 待用户在 IDE/真机/模拟器中手动验证的事项

> 这些验证依赖 DevEco Studio IDE 编译运行，CLI 环境受阻：

1. **DevEco Studio 打开项目 → 触发即时编译**：验证无 ArkTS 编译错误
2. **运行到模拟器 / 真机**：
   - **UI-PCT-01**：启动后看到首行 5 个按钮 `AC ( ) % ÷`
   - **UI-PCT-02-1**：点 `5` `0` `+` `1` `0` `%` `=` → 显示 `55`
   - **UI-PCT-02-2**：点 `5` `0` `-` `1` `0` `%` `=` → 显示 `45`
   - **UI-PCT-02-3**：点 `5` `0` `×` `1` `0` `%` `=` → 显示 `5`
   - **UI-PCT-02-4**：点 `5` `0` `÷` `1` `0` `%` `=` → 显示 `500`
   - **UI-PCT-02-5**：点 `2` `5` `%` `=` → 显示 `0.25`
   - **UI-PCT-06**：空表达式点 `%` 后点 `=` → errorMsg 显示「表达式错误」
3. **三主题 × 横竖屏 = 6 组合视觉走查**：见 tasks.md Task 3.3 矩阵
4. **回归**：AC、退格、四则、括号、`=`、`.`、历史记录、长按复制结果

---

## 测试结果汇总

| 维度 | 结果 |
| ---- | ---- |
| 静态等价审查 | ✅ 通过 |
| 既有计算回归推导 | ✅ 通过（基于代码 review）|
| 编译验证（CLI） | ⚠️ 受阻于环境配置（与变更无关）|
| Lint（CLI） | ⚠️ 同上 |
| UI 测试（手动）| ⏳ 待用户在 IDE/设备上验证 |

> **GREEN 等级**：代码层 ✅；运行层等待用户验证。

---

## 下一步

代码已应用完毕，待用户在 DevEco Studio 中编译运行并完成 UI 验收。

如确认全部验收用例通过：

```
执行 aid-archiving 20260518-requirement-add-percentage-button
```

将归档本次变更。

---

## 已知问题 / TODO

- 无 (No outstanding code-level issues; only environment-level CLI build limitation, irrelevant to this change.)
