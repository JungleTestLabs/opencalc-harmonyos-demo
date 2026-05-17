# OpenCalc Demo — 需求 1：百分号按钮

> 客户 DEMO 实验手册 · 版本 1.1 · 2026-05-17  
> 仓库：https://github.com/JungleTestLabs/opencalc-harmonyos-demo/tree/main/1-percent-button

---

## 1. 需求是什么

在 OpenCalc 计算器基础键盘第一行（AC 按钮右侧）新增 `%` 百分号按钮。用户输入 `50+10%` 自动算出 `55`。

## 2. 怎么分析的（AID 工作流）

使用 `requirement-development` skill 的标准五步流程：

| 步骤 | 产物 | 说明 |
|------|------|------|
| 意图识别 | `info.md` | 复杂度 S 级，单文件改动 |
| 需求分析 | `proposal.md` | 定义 4 个典型用例 + 验收标准 |
| 详细规格 | `delta-spec.md` | 7 条 AC |
| 任务拆分 | `tasks.md` + `todo.md` | S 级不拆，单任务执行 |
| 实施报告 | `apply-report.md` | 实际改动记录 |

## 3. 生成了哪些 SPEC 文件

变更目录：[`specs/changes/20260517-requirement-add-percent/`](./specs/changes/20260517-requirement-add-percent/)

- [`info.md`](./specs/changes/20260517-requirement-add-percent/info.md) — 复杂度评估（S 级）
- [`proposal.md`](./specs/changes/20260517-requirement-add-percent/proposal.md) — 需求提案（4 个典型用例）
- [`delta-spec.md`](./specs/changes/20260517-requirement-add-percent/delta-spec.md) — 详细规格（7 条 AC）
- [`tasks.md`](./specs/changes/20260517-requirement-add-percent/tasks.md) — 任务清单
- [`todo.md`](./specs/changes/20260517-requirement-add-percent/todo.md) — 待办追踪
- [`apply-report.md`](./specs/changes/20260517-requirement-add-percent/apply-report.md) — 实施报告
- [`verification-report.md`](./specs/changes/20260517-requirement-add-percent/verification-report.md) — 爹助验证报告（含模拟器实测截图）

## 4. 改了哪些文件

| 文件 | 改动 | 说明 |
|------|------|------|
| `entry/src/main/ets/pages/CalculatorPage.ets` | +5 行 | 新增 `BtnPct` Builder + 第一行加 `%`；后续给 `BtnAct`/`BtnOp` 加宽度参数修复第一行 5 按钮溢出 |
| `build-profile.json5` | 版本修正 | SDK `6.0.0(14)` → `6.0.2(22)` |

**核心代码（`BtnPct` Builder）**：
```typescript
@Builder BtnPct() {
  Text('%').fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText())
    .width('14%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center)
    .backgroundColor(this.getOp()).borderRadius(50).margin(this.isLandscape ? 1 : 4)
    .onClick((): void => { this.onOp('%') })
}
```

**第一行宽度收窄（避免 5 按钮溢出右边框）**：第一行用 `BtnAct('AC','18%')` + `BtnPct()`(14%) + `BtnOp('(','18%')` + `BtnOp(')','18%')` + `BtnOp('÷','18%')`，合计 **86%**，留出 margin 空间。其他行仍是 4×22% = 88%。

## 5. 最后结果

### 编译结果
- ✅ BUILD SUCCESSFUL (3.88s)
- 无警告、无错误

### 功能展示

模拟器实测截图（HarmonyOS 模拟器 1256×2760）：

![计算器主界面](./specs/changes/20260517-requirement-add-percent/screenshots/01_calculator_main.jpeg)

第一行 5 个按钮 `AC | % | ( | ) | ÷` 完整显示，`%` 加入后不溢出右边框。

### 功能验证

| 测试 | 输入 | 预期 | 结果 |
|------|------|------|:--:|
| 加法百分比 | `50+10%` | 55 | PASS |
| 减法百分比 | `100-20%` | 80 | PASS |
| 乘法百分比 | `200*15%` | 30 | PASS |
| 裸百分比 | `50%` | 0.5 | PASS |

### 爹助审查
- 代码审查 5 维度全部 [PASS]
- 详见 [`verification-report.md`](./specs/changes/20260517-requirement-add-percent/verification-report.md)

## 6. 客户 DEMO 操作指南

### 6.1 如何编译运行

```bash
# 前提：安装 DevEco Studio 6.0+
cd 1-percent-button
hvigorw assembleHap --mode module -p product=default -p buildMode=debug
```

### 6.2 如何演示

1. 打开计算器，观察第一行按钮：`AC` `%` `(` `)` `÷`
2. 输入 `50+10%`，按 `=`，显示 `55`
3. 输入 `200*15%`，按 `=`，显示 `30`

### 6.3 出了问题怎么对比查看

1. **编译失败？** → 检查 `build-profile.json5` 中 `compatibleSdkVersion` 是否匹配你的 SDK；如果是 SDK_COMPONENT_MISSING，看根目录 `hvigorfile.ts` 里的 `pathVersionMapper` 运行时补丁是否在
2. **按钮不显示？** → 检查 `CalculatorPage.ets` 第一行 `Row()` 是否包含 `this.BtnPct()`
3. **按钮溢出？** → 第一行用了带宽度参数的 `BtnAct/BtnOp`（18%），别忘了传第二个参数
4. **计算结果不对？** → 查看 `entry/.../Expression.ets` 中 `getPercentString()` 方法
5. **对比基准版本？** → 参考 [`../0-basic/`](../0-basic/) 目录中的原始代码

### 6.4 如果客户没做完

所有 SPEC 文件 + 验证报告 + AID 制品已在 [`specs/changes/20260517-requirement-add-percent/`](./specs/changes/20260517-requirement-add-percent/) 中。直接阅读：
- 需求分析 → [`proposal.md`](./specs/changes/20260517-requirement-add-percent/proposal.md)
- 验收标准 → [`delta-spec.md`](./specs/changes/20260517-requirement-add-percent/delta-spec.md)
- 实施详情 → [`apply-report.md`](./specs/changes/20260517-requirement-add-percent/apply-report.md)
- 验证结果 → [`verification-report.md`](./specs/changes/20260517-requirement-add-percent/verification-report.md)
