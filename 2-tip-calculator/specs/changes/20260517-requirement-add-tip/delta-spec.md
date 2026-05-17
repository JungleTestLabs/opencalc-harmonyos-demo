# Delta Spec — 小费计算器

## 变更摘要

为 OpenCalc 增加小费计算器页面。纯增量变更，不修改任何现有代码逻辑。

## 新增文件

### 1. `entry/src/main/ets/pages/TipCalculatorPage.ets`

独立的小费计算器页面组件。包含：

**状态变量**：
- `@State amount: string` — 账单金额输入
- `@State tipPercent: number` — 小费比例（默认 15）
- `@State customTip: string` — 自定义小费比例
- `@State people: string` — 人数输入
- `@State tipAmount: string` — 小费金额（计算结果）
- `@State totalAmount: string` — 总金额（含小费）
- `@State perPerson: string` — 每人应付（计算结果）
- `@State useCustomTip: boolean` — 是否使用自定义比例
- `@State errorMsg: string` — 错误信息

**预设比例按钮**: [10%, 15%, 18%, 20%, 自定义]

**计算逻辑**：
```
if (amount <= 0) → error "金额必须大于0"
if (people <= 0) → error "人数必须大于0"
tipAmount = amount × tipPercent / 100
totalAmount = amount + tipAmount
perPerson = totalAmount / people
```

**UI 布局**：
- 深色主题背景（与计算器一致）
- 顶部：标题 + 返回按钮
- 金额输入区：TextInput + 货币符号
- 小费比例选择：4 个预设按钮 + 自定义输入
- 人数输入：TextInput + 人图标
- 结果展示区：小费 / 总计 / 每人

### 2. `entry/src/main/ets/pages/Index.ets`（修改）

将 Index 从自动跳转到 CalculatorPage 改为显示导航菜单：
- "🔢 计算器" 按钮 → 跳转 CalculatorPage
- "💰 小费计算" 按钮 → 跳转 TipCalculatorPage

## 验收标准对照

| AC# | 条件 | 预期结果 |
|-----|------|---------|
| AC1 | amount=100, tip=15%, people=2 | perPerson="57.50" |
| AC2 | amount=200, tip=18%, people=4 | perPerson="59.00" |
| AC3 | 自定义 tip=12% | 结果正确 |
| AC4 | people=0 | 显示错误提示 |
| AC5 | amount≤0 | 显示错误提示 |
| AC6 | 点击导航"小费计算" | 进入 TipCalculatorPage |
| AC7 | 点击返回按钮 | 回到 Index 导航页 |
| AC8 | 使用原计算器功能 | 无回归 |
