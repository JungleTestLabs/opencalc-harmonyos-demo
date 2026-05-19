# 小费计算器 - 代码仓理解 (info.md)

## 基本信息

- **需求类别**: 新增功能(New Requirement)
- **需求名称**: 小费计算器(Tip Calculator)
- **分析时间**: 2026-05-19
- **分析范围**: `entry/src/main/ets/pages/`、`entry/src/main/ets/calculator/`、`entry/src/main/resources/`、应用工程配置

## 重点分析类别(按 rq-codebase 匹配表)

- 架构分析 ✓✓
- 公共组件或函数识别 ✓✓
- 接口/契约识别 ✓✓
- 影响范围分析 ✓(次要)
- 现有代码分析 ○(简化)
- 风险识别 ✓
- 测试验证策略 ○
- 监控运维支持 △(本地工具,无需监控)

---

## 1. 架构分析

### 1.1 模块结构

```
entry/src/main/ets/
├── entryability/          # 应用入口 EntryAbility
├── pages/                 # ArkUI 页面层
│   ├── Index.ets          # 启动占位页 → router.replaceUrl 到 CalculatorPage
│   └── CalculatorPage.ets # 实际主交互页(基础/科学计算器 + 设置 + 关于 + 历史)
├── calculator/            # 计算逻辑层(纯 ArkTS,无 UI 依赖)
│   ├── Calculator.ets       # CalcEngine: 表达式求值
│   ├── Expression.ets       # Expression: 表达式归一化
│   └── NumberFormatter.ets  # NumberFormatter.format: 千分位/小数分隔符
├── model/                 # 数据模型
│   ├── Models.ets           # NumberingSystem、HistoryItem 等枚举/类型
│   └── ErrorFlags.ets       # 计算错误标志位(全局静态)
└── preferences/           # 持久化层
    └── PreferencesStore    # 偏好/历史的持久化封装
```

### 1.2 模块关系

```
EntryAbility(系统入口)
   ↓ 启动 pages/Index
Index.ets ──aboutToAppear──> router.replaceUrl('pages/CalculatorPage')
   ↓
CalculatorPage.ets  ←── 用户实际看到的"主页"
   ├── 依赖 calculator/* (纯计算)
   ├── 依赖 model/*       (数据类型)
   └── 依赖 preferences/* (持久化)
```

**关键发现**:`Index.ets` 仅是占位启动页,**真正承载用户首屏的页面是 `CalculatorPage`**。用户原话"主页新增按钮"需对应到 `CalculatorPage` 的某个区域,而非 `Index.ets`。

### 1.3 扩展机制

- 页面注册:`entry/src/main/resources/base/profile/main_pages.json` 列出所有可路由的页面路径。
- 新增页面必须更新该文件。
- 不存在插件机制/抽象路由,新增小费计算器即向 `main_pages.json` 追加 `"pages/TipCalculatorPage"`。

### 1.4 SDK / 工程配置

| 项 | 值 |
| --- | --- |
| compatibleSdkVersion | 6.0.0(14) |
| targetSdkVersion | 6.0.0(14) |
| runtimeOS | HarmonyOS |
| modelVersion (oh-package) | 6.0.2 |
| 测试框架 | `@ohos/hypium` 1.0.15、`@ohos/hamock` 1.0.0 |
| 第三方依赖 | 无生产依赖(`dependencies: {}`) |
| 设备类型 | phone、tablet |
| 权限 | `ohos.permission.VIBRATE`(振动反馈) |

---

## 2. 接口/契约识别

### 2.1 路由 API
- 现有用法:`import { router } from '@kit.ArkUI'`,调用 `router.replaceUrl({ url: 'pages/CalculatorPage' })`(见 Index.ets:1, 7)。
- 新页面跳转推荐:`router.pushUrl({ url: 'pages/TipCalculatorPage' })`(保留返回栈)。
- 失败处理:返回的 Promise 可能 reject;现有 Index.ets 未捕获(占位逻辑),新入口处需 catch 以满足 FM-NAV-01。

### 2.2 ArkUI 内置组件(本变更将使用)
- `Column`、`Row`、`Stack`、`Blank`(布局)
- `Text`、`Button`、`TextInput`(输入与展示)
- 事件:`.onClick`、`.onChange`、`.onAreaChange`(响应布局变化,已在 CalculatorPage 使用)

### 2.3 现有 NumberFormatter 接口
```ts
class NumberFormatter {
  static format(text, decimalSep, groupingSep, numberingSystem): string
}
```
- 功能:数字加千分位,处理国际制/印度制。
- **不提供**四舍五入到 N 位小数。本变更需要的 `.toFixed(2)` 必须由 TipCalculator 自行实现或直接调用 JS `Number.prototype.toFixed`。
- 复用情景有限:本变更的人均结果是小数点保留 2 位,不强制千分位;可选用 `NumberFormatter.format` 在 toFixed 之后,以兼顾大金额可读性,但用户已明确"仅显示人均",可保持最简,**默认不复用**。

### 2.4 字符串资源
- `resources/base/element/string.json` 仅有 4 条字符串(app_name / module_desc / EntryAbility_desc / EntryAbility_label),**没有 UI 文案条目**。
- 现有 CalculatorPage 的所有文案("设置"、"关于 OpenCalc"、"暂无计算记录"、"已复制"等)**全部硬编码中文**。
- 本变更对应澄清决策 #8 的"跟随项目现有语言配置" → **决定:硬编码中文,与现有风格保持一致**。

---

## 3. 公共组件或函数识别

| 候选 | 路径 | 复用建议 |
| --- | --- | --- |
| `NumberFormatter.format` | `calculator/NumberFormatter.ets` | 不强制复用;若想给大金额加千分位可在 toFixed 后调用,本期暂不引入 |
| `router` (@kit.ArkUI) | 系统 API | 复用,用于主页 → 小费页跳转 |
| `Toast`(promptAction.showToast) | CalculatorPage 现有用法 | 可选;非法输入采用 `--` 占位,无需 Toast |
| CalculatorPage 的主题方法(getBg/getOp/...) | CalculatorPage 内部私有 | **不可直接复用**(在结构体内部);本期 TipCalculatorPage 简化为单一浅色样式即可,不引入主题切换 |
| PreferencesStore | `preferences/PreferencesStore` | 不复用(澄清决策 #7:不保存历史) |

**复用注意事项**:
- CalculatorPage 的样式工具函数都是 struct 私有方法,无法直接 import。如果未来需要主题统一,可考虑将其抽出为独立 utils。本期不做。
- 计算逻辑通过新文件 `calculator/TipCalculator.ets` 提供纯函数,保持与现有 calculator 子目录风格一致。

---

## 4. 影响范围分析

### 4.1 需要新增的文件

| 文件 | 类型 | 说明 |
| --- | --- | --- |
| `entry/src/main/ets/pages/TipCalculatorPage.ets` | 新增 | 小费计算器页面(@Entry @Component) |
| `entry/src/main/ets/calculator/TipCalculator.ets` | 新增 | 纯函数计算工具:`calcPerPerson(amount, peopleCount, tipPercent): string` |

### 4.2 需要修改的文件

| 文件 | 修改类型 | 说明 |
| --- | --- | --- |
| `entry/src/main/resources/base/profile/main_pages.json` | 追加一行 | 注册 `"pages/TipCalculatorPage"` |
| `entry/src/main/ets/pages/CalculatorPage.ets` | 局部插入 | 在 ToggleRow 或 SettingsPanel 内增加"小费计算器"入口按钮 + `router.pushUrl` 调用 |

### 4.3 不修改的文件
- `Index.ets`(保持占位跳转逻辑,不引入入口按钮)
- `entryability/EntryAbility.ets`
- `oh-package.json5`(无新依赖)
- `module.json5`(无新权限)
- `build-profile.json5`(无 SDK 变化)
- `string.json`(本期硬编码中文)

### 4.4 调用链

```
用户点击 CalculatorPage 内"小费计算器"按钮
   → router.pushUrl({ url: 'pages/TipCalculatorPage' })
   → 加载 TipCalculatorPage
   → 输入 amount/peopleCount/tipPercent
   → 调用 TipCalculator.calcPerPerson(amount, peopleCount, tipPercent)
   → 返回 string(已 toFixed(2) 或 "--")
   → 绑定到 @State perPerson, UI 自动重渲染
   → 系统返回手势 / router.back() → 回到 CalculatorPage
```

---

## 5. 现有代码分析(简化)

- `CalculatorPage.ets` 使用 `@Entry @Component struct + @State + @Builder` 的标准 ArkUI 范式,UI 与状态强绑定。
- 大量 inline 样式(无样式表),颜色通过实例方法返回字符串。
- 入口控件常见模式:`ToggleRow` 内的 `Text` 上挂 `.onClick`(见 `CalculatorPage.ets:263-265` 的"⚙"按钮)。
- 没有现存的"页面入口卡片"组件,需要新增。可参考 `BtnAct` `BtnDig` 的构建方式自定义一个轻量入口控件。

---

## 6. 风险识别

| 风险编号 | 描述 | 级别 | 缓解建议 |
| --- | --- | --- | --- |
| R-01 | "主页"理解差异:用户意图的"主页"是 CalculatorPage,而非 Index.ets。如果按字面在 Index.ets 加按钮,因 Index.ets 自动跳转,按钮永远不会被看到 | 高 | step8 设计阶段明确入口加在 CalculatorPage,可在 ToggleRow 旁或 SettingsPanel 中 |
| R-02 | 浮点精度:`(amount * (1 + tipPercent/100)) / peopleCount` 可能出现 0.1 + 0.2 ≠ 0.3 的累积误差 | 中 | 使用 `.toFixed(2)` 在最末环节舍入,DT 覆盖典型值 |
| R-03 | 横屏布局:CalculatorPage 已做横竖屏适配,小费计算器需考虑横屏被键盘遮挡问题 | 中 | 使用 Column + 安全区(`expandSafeArea`)或滚动容器 |
| R-04 | 主题不一致:TipCalculatorPage 不接入 CalculatorPage 的多主题切换(浅/暗/AMOLED),用户从暗色主进入小费页突然变浅色会突兀 | 低 | 本期固定浅色,作为已知偏差记录;或选取最常用的浅色一组与基础页协调 |
| R-05 | 测试缺口:目前 entry/src/ohosTest 在仓中尚未确认存在(本次未读取);若不存在则 DT 用例无法运行 | 中 | 在 IMPLEMENTING 阶段前确认测试目录;若不存在,新增最小骨架 |
| R-06 | 数字键盘:TextInput 的 `type=Number` 在 ArkUI 中存在,但小数点输入行为与系统输入法相关;真机表现需要验证 | 低 | 用 `InputType.NUMBER_DECIMAL` 并增加输入过滤;真机验证 |

---

## 7. 测试验证策略

### 7.1 单元测试(纯函数,使用 hypium)
- `calcPerPerson(100, 3, 15)` === "38.33"
- `calcPerPerson(0, 3, 15)` === "--"
- `calcPerPerson(100, 0, 15)` === "--"
- `calcPerPerson(NaN, 3, 15)` === "--"
- `calcPerPerson(-100, 3, 15)` === "--" 或 "0.00"(实现决定)
- `calcPerPerson(100, 3, 0)` === "33.33"
- `calcPerPerson(100, 3, 100)` === "66.67"

### 7.2 UI / 集成测试
- 启动应用 → CalculatorPage 可见"小费计算器"入口按钮
- 点击入口 → 成功跳转 TipCalculatorPage
- 输入金额 200 / 人数 4 / 18% → 显示 59.00
- 切换"自定义"输入 12.5% → 实时刷新
- 输入框输入字母被过滤 / 长度超限制被截断
- 返回手势 → 回到 CalculatorPage

### 7.3 回归范围
- CalculatorPage 的所有现有功能(基础/科学计算、设置、关于、历史)需保持原行为。
- 横竖屏切换无异常。

---

## 8. 监控运维支持(本期不涉及)
- 无监控指标。
- 无配置项。
- 日志:仅在 router.pushUrl 失败的 catch 中打一条 hilog warn(FM-NAV-01)。

---

## 9. 关键发现汇总

### 9.1 可复用内容
- `@kit.ArkUI` 的 `router` API
- ArkUI 内置组件(Text/Button/TextInput/Column/Row)
- `calculator/` 目录约定(本变更新增 `TipCalculator.ets` 遵循此约定)

### 9.2 待澄清/确认(step8 设计阶段处理)
- 入口按钮在 CalculatorPage 内的具体位置:
  - 候选 A:`ToggleRow` 旁(基础/科学切换、历史、设置按钮所在行,加一个"小费"图标/文字)
  - 候选 B:`SettingsPanel` 内作为列表项(类似"关于 OpenCalc")
  - 候选 C:在 `DisplayPanel` 顶部增加一个小图标
  - 推荐:**A**,与现有同级工具按钮在视觉上一致

### 9.3 重要提示
- 用户原话"主页"在工程层面实际是 `CalculatorPage`,需在 step8 设计与 step9 审视中以正确路径落地。
- 项目无国际化资源,本变更硬编码中文,符合现有风格。
- `NumberFormatter` 不能直接用于"保留两位小数",需自行 toFixed(2)。
