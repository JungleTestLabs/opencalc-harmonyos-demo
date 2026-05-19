# 百分号按钮 - 开发任务（tasks.md）

## 任务概述

- **功能名称**：百分号按钮（`%`）
- **变更类型**：New Requirement（新增功能）
- **关联特性**：feat-calculator-buttons（计算器按钮）
- **开发阶段**：UI 层暴露已有计算能力
- **预计任务数**：7 个（4 实现 + 2 测试 + 1 回归）
- **预计总工时**：1-2 小时
- **关键约束**：仅修改 `entry/src/main/ets/pages/CalculatorPage.ets` 一个文件

---

## 任务列表

### 阶段 1：基础设施

> 无 — 本变更不引入新的数据模型、DAO、Service、常量或工具类。

### 阶段 2：UI 层实现

#### Task 2.1：新增 `@Builder BtnOp5(l)` 方法

**描述**：
在 `CalculatorPage.ets` 中新增一个 `@Builder` 方法 `BtnOp5(l: string)`，用于渲染 5 列布局下的运算符按钮（首行专用）。与现有 `BtnOp` 几乎一致，仅 `width` 从 `'22%'` 改为 `'18%'`，竖屏 `margin` 从 `4` 改为 `3`，横屏 `margin` 保持 `1`。

**涉及文件**：
- `entry/src/main/ets/pages/CalculatorPage.ets`（修改，约 +12 行）

**插入位置**：紧邻现有 `@Builder BtnOp(l)` 方法之后（约 CalculatorPage.ets:291 后）

**代码草案**：见 `delta-design.md§A.2`

**依赖任务**：无

**验收标准**：
- ✅ 文件能通过 ArkTS 编译（无类型错误）
- ✅ 方法签名为 `@Builder BtnOp5(l: string)`
- ✅ 调用 `this.onOp(l)` 而非其他事件
- ✅ `backgroundColor` 使用 `this.getOp()` 表达式（响应主题切换）
- ✅ `fontColor` 使用 `this.getBtnText()` 表达式

---

#### Task 2.2：新增 `@Builder BtnAct5(l)` 方法

**描述**：
在 `CalculatorPage.ets` 中新增 `BtnAct5(l: string)`，用于渲染 5 列布局下的动作按钮（首行 `AC` 专用）。与现有 `BtnAct` 几乎一致，仅 `width` 从 `'22%'` 改为 `'18%'`，竖屏 `margin` 从 `4` 改为 `3`。

**涉及文件**：
- `entry/src/main/ets/pages/CalculatorPage.ets`（修改，约 +12 行）

**插入位置**：紧邻 Task 2.1 新增的 `BtnOp5` 之后

**代码草案**：见 `delta-design.md§A.2`

**依赖任务**：无（可与 Task 2.1 并行）

**验收标准**：
- ✅ 文件能通过 ArkTS 编译
- ✅ 方法签名为 `@Builder BtnAct5(l: string)`
- ✅ 点击逻辑：`l === 'AC' ? this.onAC() : this.onBS()`（与 `BtnAct` 一致）
- ✅ 背景色：`l === 'AC' ? this.getClr() : this.getBtnBg()`（与 `BtnAct` 一致）

---

#### Task 2.3：修改 ButtonGrid 首行布局为 5 列

**描述**：
修改 `CalculatorPage.ets` 中 `@Builder ButtonGrid()` 的首行（约第 278 行），从 4 列布局：
```typescript
Row() { this.BtnAct('AC'); this.BtnOp('('); this.BtnOp(')'); this.BtnOp('÷') }
```
改为 5 列布局：
```typescript
Row() { this.BtnAct5('AC'); this.BtnOp5('('); this.BtnOp5(')'); this.BtnOp5('%'); this.BtnOp5('÷') }
```

**涉及文件**：
- `entry/src/main/ets/pages/CalculatorPage.ets`（修改，1 行替换）

**关键约束**：
- ❌ 不修改第 2-5 行（数字行）
- ❌ 不修改科学模式的两行（sin/cos/tan/π/e 等）

**依赖任务**：Task 2.1 + Task 2.2（需要 BtnOp5 / BtnAct5 已存在）

**验收标准**：
- ✅ 仅修改一行代码
- ✅ 应用编译通过
- ✅ 启动应用后主界面首行显示 5 个按钮：`AC ( ) % ÷`
- ✅ 其他 4 行保持 4 列布局（无视觉变化）

---

### 阶段 3：功能验证测试

#### Task 3.1：核心计算验收测试

**描述**：
启动应用，通过 UI 操作验证以下 5 个核心用例的计算结果是否正确：

| 用例 | 操作序列 | 期望结果 |
|------|---------|---------|
| UI-PCT-02-1 | `5` `0` `+` `1` `0` `%` `=` | `55` |
| UI-PCT-02-2 | `5` `0` `-` `1` `0` `%` `=` | `45` |
| UI-PCT-02-3 | `5` `0` `×` `1` `0` `%` `=` | `5` |
| UI-PCT-02-4 | `5` `0` `÷` `1` `0` `%` `=` | `500` |
| UI-PCT-02-5 | `2` `5` `%` `=` | `0.25` |

**涉及文件**：无代码改动（手动 UI 测试）

**依赖任务**：Task 2.3

**验收标准**：
- ✅ 5 个用例全部通过
- ✅ 历史记录正确新增 5 条

---

#### Task 3.2：边界与错误兜底测试

**描述**：
验证 FMEA 中定义的异常场景：

| 用例 | 操作 | 期望 |
|------|------|------|
| UI-PCT-06 | 空表达式点 `%` 后点 `=` | errorMsg = "表达式错误" |
| UI-PCT-05 | 点击历史中的 `50+10%` 回填 → 点 `=` | 结果 `55` |
| FM-03 | 输入 `5%2` 后点 `=` | 不闪退，得到合理结果或错误提示 |

**涉及文件**：无代码改动（手动 UI 测试）

**依赖任务**：Task 3.1

**验收标准**：
- ✅ 应用不闪退
- ✅ 错误提示正确显示
- ✅ 历史回填后再求值正常

---

#### Task 3.3：主题与布局回归测试

**描述**：
验证 `%` 按钮在不同主题与朝向下的视觉一致性，不破坏既有功能。

**测试矩阵**（3 主题 × 2 朝向 = 6 种组合）：

| # | 主题 | 朝向 | 验证点 |
|---|------|------|--------|
| 1 | 浅色 | 竖屏 | `%` 背景 `#B4D2E4`，5 按钮无重叠 |
| 2 | 浅色 | 横屏 | `%` 背景 `#B4D2E4`，首行 5 列正常 |
| 3 | 暗色 | 竖屏 | `%` 背景 `#0070BC`，文字色 `#EFEFEF` |
| 4 | 暗色 | 横屏 | 同上 |
| 5 | AMOLED | 竖屏 | `%` 背景 `#B4D2E4`（AMOLED 沿用浅色 getOp） |
| 6 | AMOLED | 横屏 | 同上 |

**回归覆盖**：
- AC、退格、四则、括号、`=`、`.` 按钮正常
- 模式切换（基础 ↔ 科学）正常
- 历史新增/点击/滑删正常
- 长按显示屏复制结果正常

**涉及文件**：无代码改动（手动 UI 测试 + 可选截图）

**依赖任务**：Task 3.1

**验收标准**：
- ✅ 6 种组合下 `%` 按钮可见、可点、配色一致
- ✅ 既有功能无回归

---

### 阶段 4：构建与最终检查

#### Task 4.1：构建与 lint 检查

**描述**：
通过 Hvigor 构建项目，确保无编译错误、无 lint warning。

**命令**（参考 `oh-package.json5` / `hvigor`）：

```bash
# 在项目根目录
hvigorw assembleHap --mode module -p product=default
```

**涉及文件**：无代码改动

**依赖任务**：Task 2.3 完成（代码层面）；Task 3.* 可并行

**验收标准**：
- ✅ 构建成功（`BUILD SUCCESSFUL`）
- ✅ 无 ArkTS 编译错误
- ✅ 无新增 lint warning（可参考变更前的 baseline）

---

## 任务依赖图

```
Task 2.1 (BtnOp5)  ─┐
                     ├──→ Task 2.3 (修改首行) ──→ Task 3.1 (核心验收)
Task 2.2 (BtnAct5) ─┘                            │
                                                  ├──→ Task 3.2 (边界测试)
                                                  ├──→ Task 3.3 (主题/布局回归)
                                                  └──→ Task 4.1 (构建检查)
```

---

## 开发顺序

```
Task 2.1 + Task 2.2 (并行)
    ↓
Task 2.3 (修改首行)
    ↓
Task 4.1 (构建)         ← 编译验证
    ↓
Task 3.1 (核心验收)
    ↓
Task 3.2 (边界测试) + Task 3.3 (主题/布局回归)
    ↓
完成
```

---

## 验收计划

| 任务 | 验收方式 | 验收时间 |
|------|---------|---------|
| Task 2.1 | 代码审查 + 编译 | 2026-05-18 |
| Task 2.2 | 代码审查 + 编译 | 2026-05-18 |
| Task 2.3 | 代码审查 + 截图（5 按钮可见）| 2026-05-18 |
| Task 3.1 | UI 操作 + 结果断言 | 2026-05-18 |
| Task 3.2 | UI 操作 + 错误断言 | 2026-05-18 |
| Task 3.3 | 6 组合截图比对 | 2026-05-18 |
| Task 4.1 | Hvigor 构建日志 | 2026-05-18 |

---

## TDD 提示（供 tdd-enforcer / aid-applying 阶段参考）

每个 Task 2.x 在 APPLYING 阶段建议遵循 RED → GREEN 节奏：

- **RED**：先编写/识别失败场景
  - Task 2.1/2.2 的 RED：直接复用 BtnOp 而不调整宽度 → 首行溢出 / 5 个按钮 5×22%=110% 越界
  - Task 2.3 的 RED：未新增 % 按钮 → UI-PCT-02-1 失败
- **GREEN**：实现代码使场景通过
  - Task 2.1/2.2 GREEN：新增 width='18%' 的 Builder
  - Task 2.3 GREEN：首行改为 5 列
- **REFACTOR**：本变更体量小，无明显重构空间；不引入参数化（违反最小改动）

---

## 关键约束（再次强调，避免在 APPLYING 阶段被忘记）

- ❌ **不修改** `entry/src/main/ets/calculator/Expression.ets`
- ❌ **不修改** `entry/src/main/ets/calculator/Calculator.ets`
- ❌ **不修改** `entry/src/main/ets/calculator/NumberFormatter.ets`
- ❌ **不修改** `entry/src/main/ets/model/*.ets`
- ❌ **不修改** `entry/src/main/ets/preferences/*.ets`
- ❌ **不修改** `oh-package.json5` / `build-profile.json5` / `module.json5`
- ✅ **仅修改** `entry/src/main/ets/pages/CalculatorPage.ets`
- ✅ 严格遵循 design-review.md 中确认的设计
