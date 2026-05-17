# OpenCalc Demo — 需求 1：百分号按钮

> 客户 DEMO 实验手册 · 版本 1.0 · 2026-05-17  
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

```
specs/changes/20260517-requirement-add-percent/
├── proposal.md           # 需求提案
├── delta-spec.md         # 详细规格
├── info.md               # 复杂度评估
├── tasks.md              # 任务清单
├── todo.md               # 待办追踪
├── apply-report.md       # 实施报告
└── verification-report.md # 爹助验证报告
```

## 4. 改了哪些文件

| 文件 | 改动 | 说明 |
|------|------|------|
| `entry/src/main/ets/pages/CalculatorPage.ets` | +3 行 | 新增 BtnPct Builder + 按钮行添加 `%` |
| `build-profile.json5` | 版本修正 | SDK `5.0.0(12)` → `6.0.2(22)` |

**核心代码**：
```typescript
@Builder BtnPct() {
  Text('%').fontSize(20).fontColor(this.getBtnText())
    .width('18%').height(56).textAlign(TextAlign.Center)
    .backgroundColor(this.getOp()).borderRadius(50).margin(4)
    .onClick(() => { this.onOp('%') })
}
```

## 5. 最后结果

### 编译结果
- ✅ BUILD SUCCESSFUL (4.37s)
- 无警告、无错误

### 功能验证

| 测试 | 输入 | 预期 | 结果 |
|------|------|------|:--:|
| 加法百分比 | `50+10%` | 55 | PASS |
| 减法百分比 | `100-20%` | 80 | PASS |
| 乘法百分比 | `200*15%` | 30 | PASS |
| 裸百分比 | `50%` | 0.5 | PASS |

### 爹助审查
- 代码审查 5 维度全部 [PASS]
- 详见 `verification-report.md`

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

1. **编译失败？** → 检查 `build-profile.json5` 中 `compatibleSdkVersion` 是否匹配你的 SDK
2. **按钮不显示？** → 检查 `CalculatorPage.ets` 第 1 行 Row 是否包含 `this.BtnPct()`
3. **计算结果不对？** → 查看 `entry/.../Expression.ets` 中 `getPercentString()` 方法
4. **对比基准版本？** → 参考 `../0-basic/` 目录中的原始代码

### 6.4 如果客户没做完

所有 SPEC 文件 + 验证报告 + AID 制品已在 `specs/changes/20260517-requirement-add-percent/` 中。直接阅读：
- 需求分析 → `proposal.md`
- 验收标准 → `delta-spec.md`
- 实施详情 → `apply-report.md`
- 验证结果 → `verification-report.md`
