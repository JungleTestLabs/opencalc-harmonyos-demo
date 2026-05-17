# OpenCalc Demo — 需求 2：小费计算器

> 客户 DEMO 实验手册 · 版本 1.1 · 2026-05-17  
> 仓库：https://github.com/JungleTestLabs/opencalc-harmonyos-demo/tree/main/2-tip-calculator

---

## 1. 需求是什么

在 OpenCalc 中新增小费计算器功能。用户输入账单金额、选择/自定义小费比例、输入人数，自动计算每人应付金额（含小费明细）。

## 2. 怎么分析的

| 步骤 | 产物 | 说明 |
|------|------|------|
| 意图识别 | `info.md` | S 级复杂度 |
| 需求分析 | `proposal.md` | 4 个典型用例 |
| 详细规格 | `delta-spec.md` | 7 条 AC |
| 任务拆分 | `tasks.md` + `todo.md` | 单任务 |
| 实施报告 | `apply-report.md` | 实际改动记录 |

## 3. 生成了哪些 SPEC 文件

变更目录：[`specs/changes/20260517-requirement-add-tip/`](./specs/changes/20260517-requirement-add-tip/)

- [`info.md`](./specs/changes/20260517-requirement-add-tip/info.md) — 复杂度评估（S 级）
- [`proposal.md`](./specs/changes/20260517-requirement-add-tip/proposal.md) — 需求提案（4 个典型用例）
- [`delta-spec.md`](./specs/changes/20260517-requirement-add-tip/delta-spec.md) — 详细规格（7 条 AC）
- [`tasks.md`](./specs/changes/20260517-requirement-add-tip/tasks.md) — 任务清单
- [`todo.md`](./specs/changes/20260517-requirement-add-tip/todo.md) — 待办追踪
- [`apply-report.md`](./specs/changes/20260517-requirement-add-tip/apply-report.md) — 实施报告
- [`verification-report.md`](./specs/changes/20260517-requirement-add-tip/verification-report.md) — 爹助验证报告（含模拟器实测截图）

## 4. 改了哪些文件

| 文件 | 改动 | 说明 |
|------|------|------|
| `entry/.../TipCalculatorPage.ets` | **新增** +410 行 | 小费计算器完整页面 |
| `entry/.../Index.ets` | +102 行 | 导航菜单新增「小费计算器」入口 |

**核心架构**：
- 4 个预设比例按钮（10%/15%/18%/20%）+ 自定义比例输入
- 实时计算：金额 + 比例 + 人数 → 小费/总计/每人
- 三重输入校验（金额>0、人数>0、比例有效）

## 5. 最后结果

### 编译
- ✅ BUILD SUCCESSFUL (3.94s)

### 功能展示

模拟器实测截图（HarmonyOS 模拟器 1256×2760）：

![小费计算器页面](./specs/changes/20260517-requirement-add-tip/screenshots/01_tip_calculator.jpeg)

页面包含：账单金额输入框、小费比例预设（10%/15%/18%/20% + 自定义）、用餐人数输入。点击 `15%` 时该按钮高亮（红色背景），其他比例按钮保持暗色。

> 导航首页截图见 [`verification-report.md`](./specs/changes/20260517-requirement-add-tip/verification-report.md) 第四节。

### 功能验证

| 测试 | 输入 | 预期 | 结果 |
|------|------|------|:--:|
| 预设比例 | 100, 2人, 15% | 人均 57.50 | PASS |
| 自定义比例 | 200, 4人, 18% | 人均 59.00 | PASS |
| 金额=0 | 0, 2人 | 错误提示 | PASS |
| 人数=0 | 100, 0人 | 错误提示 | PASS |

### 爹助审查
- 5 维度全部 [PASS]
- 详见 [`verification-report.md`](./specs/changes/20260517-requirement-add-tip/verification-report.md)

## 6. 客户 DEMO 操作指南

### 6.1 编译运行

```bash
cd 2-tip-calculator
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

### 6.2 演示步骤

1. 从主菜单点击「小费计算器」
2. 输入账单金额：`100`
3. 点击预设「15%」或输入自定义比例
4. 输入人数：`2`
5. 查看结果：小费 $15.00 / 总计 $115.00 / 每人 $57.50

### 6.3 出问题怎么对比

1. **编译失败？** → 检查 `build-profile.json5` SDK 版本；如果是 SDK_COMPONENT_MISSING，看根目录 `hvigorfile.ts` 里的 `pathVersionMapper` 运行时补丁是否在
2. **计算结果不对？** → 查看 `TipCalculatorPage.ets` 中 `calculate()` 方法
3. **对比基准？** → [`../0-basic/`](../0-basic/) 不含此功能，`TipCalculatorPage.ets` 为全新文件
4. **UI 不显示？** → 检查 `Index.ets` 导航菜单是否添加了入口
