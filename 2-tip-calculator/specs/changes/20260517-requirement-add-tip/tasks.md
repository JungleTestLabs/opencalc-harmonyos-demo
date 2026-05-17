# Tasks — 小费计算器

## 复杂度: S 级（单文件新增 + 导航修改）

## 任务列表

| # | 任务 | 文件 | 预估 | 依赖 |
|---|------|------|------|------|
| T1 | 创建 TipCalculatorPage.ets | `pages/TipCalculatorPage.ets`（新建） | 30min | 无 |
| T2 | 注册新页面路由 | `main_pages.json`（修改） | 5min | T1 |
| T3 | 修改 Index.ets 为导航页 | `pages/Index.ets`（修改） | 15min | T1 |

## 详细说明

### T1: 创建 TipCalculatorPage.ets

**描述**: 创建独立小费计算器页面，包含：
- 账单金额输入框（TextInput）
- 小费比例按钮组（10%/15%/18%/20% + 自定义）
- 人数输入框
- 计算结果显示区（小费/总计/每人）
- 错误提示

**验收标准**:
- [ ] 金额 100 + 15% + 2 人 → 每人 57.50
- [ ] 金额 200 + 18% + 4 人 → 每人 59.00
- [ ] 自定义 12% 正确计算
- [ ] 人数 0 时显示错误
- [ ] 金额 ≤0 时显示错误

**涉及文件**: `entry/src/main/ets/pages/TipCalculatorPage.ets`（新建）

### T2: 注册新页面路由

**描述**: 在 main_pages.json 添加 `"pages/TipCalculatorPage"` 条目

**验收标准**: 构建配置包含新页面声明

**涉及文件**: `entry/src/main/resources/base/profile/main_pages.json`（修改）

### T3: 修改 Index.ets 为导航页

**描述**: 将 Index.ets 从自动跳转到 CalculatorPage 改为显示导航菜单

**验收标准**:
- [ ] 显示"计算器"按钮，点击进入 CalculatorPage
- [ ] 显示"小费计算"按钮，点击进入 TipCalculatorPage
- [ ] 原有 CalculatorPage 功能不受影响

**涉及文件**: `entry/src/main/ets/pages/Index.ets`（修改）
