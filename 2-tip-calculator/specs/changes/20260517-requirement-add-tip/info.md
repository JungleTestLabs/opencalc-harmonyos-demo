# Info — 代码仓理解（小费计算器）

## 项目概览

- **项目**: OpenCalc HarmonyOS（Android 移植版）
- **代码量**: 9 个 .ets 文件，~1,800 行 ArkTS
- **架构**: MVVM-like（Engine → Page，无中间层）
- **SDK**: HarmonyOS SDK 6.0.2 / API 12

## 文件结构

```
entry/src/main/ets/
├── entryability/EntryAbility.ets     # 应用入口
├── calculator/
│   ├── Calculator.ets                # 递归下降解析器（核心引擎）
│   ├── Expression.ets                # 表达式预处理（百分号等）
│   └── NumberFormatter.ets           # 数字格式化
├── model/
│   ├── ErrorFlags.ets                # 错误标志位
│   └── Models.ets                    # 数据模型/枚举
├── preferences/PreferencesStore.ets  # 偏好存储
└── pages/
    ├── Index.ets                     # 入口页（当前自动跳转 CalculatorPage）
    └── CalculatorPage.ets            # 主计算器页面（~500行）
```

## 新增文件位置

TipCalculatorPage.ets 放在 `pages/` 目录下，与 CalculatorPage.ets 同级。

## 路由系统

- HarmonyOS 使用 `@ohos.router` 进行页面导航
- 所有页面需在 `entry/src/main/resources/base/profile/main_pages.json` 注册
- 当前注册页面: `pages/Index`, `pages/CalculatorPage`

## 无依赖追加

TipCalculatorPage 不依赖 Calculator.ets / Expression.ets / PreferencesStore / History。纯独立组件，仅使用 ArkUI 基础组件。

## 需要注册的新页面

需在 `main_pages.json` 中添加 `"pages/TipCalculatorPage"`。
