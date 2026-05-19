# 小费计算器 开发任务

## 任务概述

- 功能名称:小费计算器(Tip Calculator)
- 变更类型:New Requirement(新增功能)
- 关联特性:本次为首批变更,暂无 feat-* 历史 spec
- 开发阶段:基础设施 → 页面 → 集成 → 验证
- 预计任务数:6 (4 阶段)
- 复杂度:简单(S)

### 关键说明

- **测试目录现状**:`entry/src/ohosTest/` 目录不存在(遗留问题 O-01)。本次变更**不引入** hypium 单元测试脚手架,采用"轻量验证"策略:
  - TipCalculator 纯函数的正确性,通过 `verify_ui` 端到端用例 + 手工真机覆盖核心数值用例
  - 后续若有需要,可在独立变更中补建 ohosTest 骨架
- **不修改的文件**: `Index.ets`、`EntryAbility.ets`、`oh-package.json5`、`module.json5`、`build-profile.json5`、`string.json`
- **横屏限制**: 本期沿用 CalculatorPage 横屏隐藏 ToggleRow 的行为,横屏不提供入口(L-01)

---

## 任务列表

### 阶段 1:基础设施

#### Task 1.1: 实现 TipCalculator 纯函数模块

**描述**:新增 `calculator/TipCalculator.ets`,导出静态类 `TipCalculator`,提供 `calcPerPerson(amount, peopleCount, tipPercent): string`。
- 公式: `total = amount * (1 + tipPercent / 100)`;`perPerson = total / peopleCount`
- 校验三入参合法性(`isFinite` + 范围 + 整数),非法返回常量 `PLACEHOLDER = '--'`
- 合法时调用 `Number.prototype.toFixed(2)` 返回字符串
- 实现要点严格对齐 delta-design §3.5.6 的伪代码

**涉及文件**:
- 实现:`entry/src/main/ets/calculator/TipCalculator.ets` (新增)
- 测试:无(见"关键说明",改由 Task 4.2 端到端验证)

**依赖任务**:无

**验收标准**:
- 文件创建成功,`export class TipCalculator` 可被其它 `.ets` 通过 `import { TipCalculator } from '../calculator/TipCalculator'` 引用
- `arkts-check` 通过(配合 Task 4.1 编译)
- 静态调用 `TipCalculator.calcPerPerson(100, 3, 15)` 返回 `'38.33'`
- 异常分支覆盖 SR-009 + FM-CALC-01..06:人数 0/空/非整、金额 NaN/负数/超大、小费率超范围,均返回 `'--'`
- 无副作用、无依赖 ArkUI

**TDD**:[x] RED 跳过 / [ ] GREEN 实现 / [ ] REFACTOR 检视

---

### 阶段 2:页面层

#### Task 2.1: 实现 TipCalculatorPage 页面

**描述**:新增 `pages/TipCalculatorPage.ets`,`@Entry @Component struct`,承载全部小费计算 UI 与本地状态。包含以下区块(对齐 delta-design §3.6):
- Header:页面标题 + 返回按钮 (`router.back()`)
- AmountInput:`TextInput`(类型 `NUMBER_DECIMAL`),`inputFilter` 正则 `^\d*\.?\d{0,2}$`、`maxLength=15`,绑定 `@State amountText`
- PeopleInput:`TextInput`(类型 `Number`),正则 `^\d*$`、`maxLength=3`,绑定 `@State peopleText`
- TipTierRow:4 个 `Button` 档位(10/15/18/20),互斥选中,默认 15%;额外"自定义"按钮切到 `isCustomMode=true`
- CustomTipInput:仅在 `isCustomMode === true` 显示,`TextInput` 正则 `^\d{0,3}(\.\d{0,2})?$`、`maxLength=6`
- ResultPanel:Text "每人应付" 标签 + 大字号数值,通过 `get perPerson(): string` 调用 `TipCalculator.calcPerPerson(...)` 派生
- 文案硬编码中文,沿用 delta-design §3.4 色彩/排版/尺寸表
- 不接入主题切换,固定浅色

**涉及文件**:
- 实现:`entry/src/main/ets/pages/TipCalculatorPage.ets` (新增)

**依赖任务**:Task 1.1

**验收标准**:
- 页面默认状态:金额空、人数空、小费率 15% 被选中、`isCustomMode=false`、人均显示 `'--'` (SR-011)
- 输入合法的金额 + 人数 → 实时显示两位小数人均 (SR-007/008)
- 切档位 → 实时刷新;切"自定义" + 输入 12.5 → 显示对应人均 (SR-005/006)
- 非法输入(空、0 人、字母被过滤)→ 显示 `'--'`,UI 不崩溃 (SR-009)
- 返回按钮 onClick → `router.back()`,回到 CalculatorPage (SR-012)
- 不引入 `preferences` 调用,不持久化 (C-04)
- `arkts-check` 通过

**TDD**:[x] RED 跳过 / [ ] GREEN 实现 / [ ] REFACTOR 检视

---

### 阶段 3:集成

#### Task 3.1: 注册 TipCalculatorPage 到路由表

**描述**:修改 `entry/src/main/resources/base/profile/main_pages.json`,在 `src` 数组追加 `"pages/TipCalculatorPage"`。保留现有 `"pages/Index"` 与 `"pages/CalculatorPage"` 顺序不变。

**涉及文件**:
- 实现:`entry/src/main/resources/base/profile/main_pages.json` (修改)

**依赖任务**:Task 2.1

**验收标准**:
- 文件含 3 个 `src` 条目
- JSON 合法,可被 hvigor 解析(配合 Task 4.1 编译)

**TDD**:N/A(配置文件)

#### Task 3.2: CalculatorPage ToggleRow 注入「小费」入口按钮

**描述**:**仅**修改 `@Builder ToggleRow()` 方法,在现有 `Text` 控件(基础/科学切换、`▼ 历史`、`⚙`)之间插入新的「💰 小费」Text 按钮(参见 delta-design §3.7.3 片段)。点击调用 `router.pushUrl({ url: 'pages/TipCalculatorPage' })`,失败时通过 hilog 记 warn(FM-NAV-01),不弹错。
- 文件顶部追加 import:`router` from `@kit.ArkUI`、`BusinessError` from `@kit.BasicServicesKit`、`hilog` from `@kit.PerformanceAnalysisKit`(如已有则不重复)
- 不改其它 `@Builder`、`@State`、主题方法、生命周期回调

**涉及文件**:
- 实现:`entry/src/main/ets/pages/CalculatorPage.ets` (修改,仅 ToggleRow + 必要 import)

**依赖任务**:Task 3.1

**验收标准**:
- CalculatorPage 其它功能(基础/科学切换、历史、设置、关于、振动、计算逻辑)行为不变(C-07)
- 竖屏 ToggleRow 显示「💰 小费」入口,样式与同行控件协调(沿用 `this.getOp()`)
- 点击成功跳转 TipCalculatorPage;pushUrl 失败时 hilog 有 warn 日志、主页不崩溃 (FM-NAV-01)
- 横屏不显示 ToggleRow → 横屏无入口(已知偏差 L-01)
- `arkts-check` 通过

**TDD**:[x] RED 跳过 / [ ] GREEN 实现 / [ ] REFACTOR 检视

---

### 阶段 4:验证

#### Task 4.1: 工程编译验证

**描述**:执行项目构建(`build_project`,debug 模式),确保新增/修改的 4 个文件能通过 hvigor + arkts-check + 编译。

**涉及文件**:无

**依赖任务**:Task 3.2

**验收标准**:
- `build_project` 成功,产物 HAP 无 error
- 无 arkts-check 报错
- 无 TS 类型错误,无未解析 import

**TDD**:N/A

#### Task 4.2: 端到端 UI 验证 + 手工真机/模拟器复核

**描述**:通过 `verify_ui` 工具按以下自然语言测试计划在真机/模拟器上跑端到端验证(冷启动 → 主页 → 进入小费页 → 各种输入 → 返回主页),并辅以人工真机手测覆盖键盘表现(R-06)、横屏入口缺失(L-01)。

**测试计划要点**:
1. 启动应用,主页(CalculatorPage)可见「💰 小费」按钮(SR-001)
2. 点击「💰 小费」→ 成功进入 TipCalculatorPage,默认 15% 档位高亮、人均显示 `--` (SR-002/011)
3. 输入金额 `200` → 输入人数 `4` → 人均显示 `59.00`(200×1.15÷4=57.5,等下:200×1.18=236÷4=59.00,18%? 验证用 15% → 期望 57.50;改用 18% 档位 → 59.00)
4. 切换 10% 档位 → 实时刷新人均 (SR-005/007)
5. 点"自定义",输入 `12.5` → 实时刷新人均 (SR-006)
6. 把人数清空 → 人均显示 `--`,UI 不崩溃 (SR-009)
7. 在金额框尝试输入字母 → 被过滤;尝试输入 `999999999999999999` → 被 maxLength 截断 (SR-003/010)
8. 系统返回手势 → 回到 CalculatorPage;再次进入 → 输入框为空 (SR-011/012)

**涉及文件**:无(端到端验证)

**依赖任务**:Task 4.1

**验收标准**:
- `verify_ui` 报告所有步骤 `successPart` 通过
- 真机/模拟器手测:无崩溃,日志无 ERROR 级别异常
- 数值用例至少覆盖:`calcPerPerson(100, 3, 15)='38.33'`、`(200, 4, 18)='59.00'`、`(100, 2, 0)='50.00'`、`(100, 2, 100)='100.00'`、人数=0 / 金额空 → `'--'`
- 现有 CalculatorPage 计算/历史/设置功能回归通过(快速点几个用例)

**TDD**:N/A(端到端)

---

## 开发顺序

```
Task 1.1 (TipCalculator)
   ↓
Task 2.1 (TipCalculatorPage)
   ↓
Task 3.1 (main_pages.json 注册)
   ↓
Task 3.2 (CalculatorPage 注入入口)
   ↓
Task 4.1 (编译)
   ↓
Task 4.2 (端到端 + 真机)
   ↓
完成
```

## 验收计划

| 任务 | 验收方式 | 验收阶段 |
|------|---------|----------|
| Task 1.1 | 代码审查 + Task 4.2 端到端覆盖 | APPLYING |
| Task 2.1 | 代码审查 + Task 4.2 UI 端到端 | APPLYING |
| Task 3.1 | 代码审查 + Task 4.1 编译 | APPLYING |
| Task 3.2 | 代码审查 + Task 4.2 端到端导航 | APPLYING |
| Task 4.1 | `build_project` 命令成功 | APPLYING |
| Task 4.2 | `verify_ui` 报告 + 手工真机 | APPLYING |

## SR ↔ 任务追溯

| SR 编号 | 落地任务 |
| --- | --- |
| SR-001 主页入口可见 | Task 3.2 |
| SR-002 入口导航 | Task 3.2 + Task 4.2 |
| SR-003 金额输入 | Task 2.1 |
| SR-004 人数输入 | Task 2.1 |
| SR-005 小费率档位 | Task 2.1 |
| SR-006 小费率自定义 | Task 2.1 |
| SR-007 实时人均计算 | Task 2.1 + Task 1.1 |
| SR-008 人均显示格式 | Task 1.1 + Task 2.1 |
| SR-009 非法输入容错 | Task 1.1(FM-CALC-01..06) + Task 2.1(输入过滤) |
| SR-010 极端值防护 | Task 2.1(maxLength + 正则) |
| SR-011 不持久化 | Task 2.1(默认 @State 不写 preferences) |
| SR-012 返回交互 | Task 2.1(返回按钮) + 系统返回手势 |
