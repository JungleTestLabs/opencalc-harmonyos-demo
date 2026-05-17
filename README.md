# OpenCalc HarmonyOS Demo

> 客户实验手册 · 三个增量需求的完整 Demo  
> 仓库：https://github.com/JungleTestLabs/opencalc-harmonyos-demo

---

## 目录结构

```
0-basic/              ← 原始 OpenCalc 计算器（基线版本）
1-percent-button/     ← 需求 1：百分号按钮
2-tip-calculator/     ← 需求 2：小费计算器
3-draw-func/          ← 需求 3：函数图像绘制
```

## 三个需求一览

| # | 需求 | 复杂度 | 改动量 | 编译 | 详细手册 |
|---|------|:--:|--------|:--:|------|
| 1 | 百分号按钮 | S | CalculatorPage.ets +3行 | ✅ | [DEMO_GUIDE.md](1-percent-button/DEMO_GUIDE.md) |
| 2 | 小费计算器 | S | TipCalculatorPage.ets +410行, Index.ets +102行 | ✅ | [DEMO_GUIDE.md](2-tip-calculator/DEMO_GUIDE.md) |
| 3 | 函数图像绘制 | M | DrawFuncPage.ets +491行, Index.ets +82行 | ✅ | [DEMO_GUIDE.md](3-draw-func/DEMO_GUIDE.md) |

## 快速开始

每个需求都是独立的 HarmonyOS 应用。编译任一：

```bash
cd <目录>
export DEVECO_SDK_HOME=/path/to/sdk
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

## 开发流程

三个需求均使用标准化 AID 工作流开发：

1. **狗助** 使用 `requirement-development` skill 完成代码开发 + AID 制品
2. **爹助** 使用 `requirement-verification` skill 完成编译验证 + 代码审查
3. 每个需求文件夹内包含完整的 SPEC 文件、验证报告、DEMO 手册

## AID 制品位置

- 需求 1：`1-percent-button/specs/changes/20260517-requirement-add-percent/`
- 需求 2：`2-tip-calculator/specs/changes/20260517-requirement-add-tip/`
- 需求 3：`3-draw-func/specs/changes/20260517-requirement-add-drawfunc/`

## SDK 兼容性

- 开发 SDK：API 14 (6.0.0)
- 验证 SDK：API 22 (6.0.2)
- 如需在不同 SDK 版本编译，修改 `build-profile.json5` 中的 `compatibleSdkVersion`
- 需求 3 在 SDK 6.0.2 下有 8 个 ArkTS 严格类型错误，已修复（见验证报告）

## 问题排查

每个需求的 DEMO_GUIDE.md 包含：
- 编译运行指南
- 演示操作步骤
- 常见问题排查
- 基准版本对比方法

---

*开发：狗助 (JungleAssistant) · 验证：爹助 (IntelliJungle) · 2026-05-17*
