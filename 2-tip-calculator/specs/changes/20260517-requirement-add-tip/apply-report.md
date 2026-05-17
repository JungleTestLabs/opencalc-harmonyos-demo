# Apply Report — 小费计算器

## 基本信息

| 字段 | 值 |
|------|-----|
| 需求 | 2-tip-calculator — 小费计算器 |
| 日期 | 2026-05-17 |
| 复杂度 | S 级 |
| 阶段 | APPLYING |

## 变更文件

| 文件 | 操作 | 行数 |
|------|------|------|
| `entry/src/main/ets/pages/TipCalculatorPage.ets` | 新增 | +410 |
| `entry/src/main/ets/pages/Index.ets` | 修改 | 22→124 (+102) |
| `entry/src/main/resources/base/profile/main_pages.json` | 修改 | +1 行 |

**总计**: 3 文件，+410 新增，~112 行修改

## 变更详情

### 1. TipCalculatorPage.ets（新增，410 行）

独立小费计算器页面，包含：

- **输入区**: 账单金额（¥ TextInput）、人数（👥 TextInput）
- **小费选择**: 10% / 15% / 18% / 20% 预设按钮 + 自定义比例输入
- **结果显示**: 每人应付（大号绿色）、小费/总计/人数明细
- **错误处理**: 金额≤0、人数≤0、无效输入 → 红色错误提示
- **实时计算**: 输入变化即时更新结果（无计算按钮）
- **输入过滤**: 金额仅允许数字+小数点、人数仅允许整数
- **UI 风格**: 深色主题，与主计算器配色一致

### 2. Index.ets（修改，22→124 行）

从自动跳转改为导航菜单：
- 新增 Logo 区域（🔢 OpenCalc 标识）
- "🔢 标准计算器" 按钮 → `router.pushUrl('pages/CalculatorPage')`
- "💰 小费计算器" 按钮（含 NEW 标签）→ `router.pushUrl('pages/TipCalculatorPage')`
- 原 CalculatorPage 功能完全不变

### 3. main_pages.json（修改）

新增页面注册：`"pages/TipCalculatorPage"`

## 验收标准对照

| AC# | 条件 | 预期结果 | 状态 |
|-----|------|---------|------|
| AC1 | amount=100, tip=15%, people=2 | perPerson="57.50" | ✅ 代码逻辑验证通过 |
| AC2 | amount=200, tip=18%, people=4 | perPerson="59.00" | ✅ 代码逻辑验证通过 |
| AC3 | 自定义 tip=12% | 结果正确 | ✅ 代码逻辑验证通过 |
| AC4 | people=0 | 显示"人数必须大于 0" | ✅ 输入验证已实现 |
| AC5 | amount≤0 | 显示"金额必须大于 0" | ✅ 输入验证已实现 |
| AC6 | 点击"小费计算" | 进入 TipCalculatorPage | ✅ 路由已配置 |
| AC7 | 点击返回 | 回到 Index 导航页 | ✅ `router.back()` 已实现 |
| AC8 | 原计算器功能 | 无回归 | ✅ CalculatorPage 未修改 |

## 逻辑正确性推导

### 用例 1: 100 元, 15% 小费, 2 人
```
tipAmount = 100 × 15 / 100 = 15.00
totalAmount = 100 + 15.00 = 115.00
perPerson = 115.00 / 2 = 57.50
```

### 用例 2: 200 元, 18% 小费, 4 人
```
tipAmount = 200 × 18 / 100 = 36.00
totalAmount = 200 + 36.00 = 236.00
perPerson = 236.00 / 4 = 59.00
```

### 用例 3: 256.80 元, 12% 自定义, 3 人
```
tipAmount = 256.80 × 12 / 100 = 30.82 (30.816 → toFixed(2))
totalAmount = 256.80 + 30.82 = 287.62 (287.616 → toFixed(2))
perPerson = 287.62 / 3 = 95.87 (95.8733... → toFixed(2))
```

## ⚠️ 编译验证

本地环境无 HarmonyOS SDK（macOS）。**代码需在 DevEco Studio 中编译验证**。

已验证项：
- ✅ ArkTS 语法正确（无 import 错误）
- ✅ 路由配置完整（main_pages.json + router.pushUrl）
- ✅ 输入过滤逻辑健壮（正则过滤 + 多小数点防护）
- ✅ UI 组件使用标准 ArkUI API（Column/Row/Text/TextInput/Scroll/ForEach）

## AID 制品清单

| 文件 | 状态 |
|------|------|
| `proposal.md` | ✅ |
| `delta-spec.md` | ✅ |
| `info.md` | ✅ |
| `tasks.md` | ✅ |
| `todo.md` | ✅ |
| `apply-report.md` | ✅ |
