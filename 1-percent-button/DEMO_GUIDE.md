# OpenCalc HarmonyOS — 百分号按钮迁移知道文档

> 客户 DEMO 实验手册 · 版本 1.0 · 2026-05-19
> 仓库：https://github.com/JungleTestLabs/opencalc-harmonyos · 分支 `demo1`
> 关联变更：`specs/changes/20260518-requirement-add-percentage-button/`

---

## 1. 需求是什么

在 OpenCalc 计算器基础键盘第一行新增 `%` 百分号按钮，使首行从 `AC ( ) ÷` (4 列) 变为 `AC ( ) % ÷` (5 列)。用户输入 `50+10%` 自动算出 `55`。

> **与早期 demo 仓的差别**：早期 `opencalc-harmonyos-demo/1-percent-button` 把 `%` 插在 AC 之后（顺序 `AC % ( ) ÷`），用 `BtnAct/BtnOp` 加宽度参数。本次迁移把 `%` 放在 `÷` 之前（顺序 `AC ( ) % ÷`），改为新增独立 `BtnAct5/BtnOp5` Builder，**零侵入既有按钮**。

## 2. 怎么分析的（AID 工作流）

使用 `/aid-workflow` 命令一站式跑完 PLANNING → IMPLEMENTING → APPLYING 三阶段：

| 阶段 | 主要产物 | 说明 |
|------|---------|------|
| 意图识别 | `proposal.md` | rq-parse + rq-clarify 三问澄清（按钮顺序 / 显示策略 / 配色） |
| 仓理解 | `info.md` | 定位 `Expression.getPercentString()` 已存在 → 算法层零改动 |
| 复杂度评估 | `complexity-assessment.md` | **S 级**（单文件 / 无算法 / 无新依赖），跳过 new-arch.md |
| 详细规格 | `delta-spec.md` | IR-PCT-01 + SR-PCT-01..08 + FMEA FM-01..06 |
| 组件设计 | `delta-design.md` | D1–D10 含代码草稿 |
| 设计审视 | `design-review.md` | 7 维度通过 |
| 任务拆分 | `tasks.md` + `todo.md` | 7 个任务（2 实现 + 1 修改 + 3 测试 + 1 构建） |
| 实施 | `apply-report.md` | 实际改动 + 静态等价审查 |
| 爹助验证 | `verification-report.md` | 模拟器 5 用例实测 |

## 3. 生成了哪些 SPEC 文件

变更目录：[`specs/changes/20260518-requirement-add-percentage-button/`](./specs/changes/20260518-requirement-add-percentage-button/)

- [`todo.md`](./specs/changes/20260518-requirement-add-percentage-button/todo.md) — 工作流进度追踪
- [`proposal.md`](./specs/changes/20260518-requirement-add-percentage-button/proposal.md) — 需求提案（含三问澄清结果）
- [`info.md`](./specs/changes/20260518-requirement-add-percentage-button/info.md) — 代码仓理解
- [`complexity-assessment.md`](./specs/changes/20260518-requirement-add-percentage-button/complexity-assessment.md) — 复杂度评估（S 级）
- [`delta-spec.md`](./specs/changes/20260518-requirement-add-percentage-button/delta-spec.md) — 详细规格（IR + SR + FMEA）
- [`delta-design.md`](./specs/changes/20260518-requirement-add-percentage-button/delta-design.md) — 组件设计（D1–D10）
- [`design-review.md`](./specs/changes/20260518-requirement-add-percentage-button/design-review.md) — 设计审视报告
- [`tasks.md`](./specs/changes/20260518-requirement-add-percentage-button/tasks.md) — 任务清单
- [`apply-report.md`](./specs/changes/20260518-requirement-add-percentage-button/apply-report.md) — 实施报告
- [`verification-report.md`](./specs/changes/20260518-requirement-add-percentage-button/verification-report.md) — 爹助验证报告（含模拟器实测 5 张截图）

## 4. 改了哪些文件

| 文件 | 改动 | 说明 |
|------|------|------|
| `entry/src/main/ets/pages/CalculatorPage.ets` | +6 / -1 | 新增 `BtnOp5` + `BtnAct5` Builder，首行 Row 改 5 列 |
| `Expression.ets` / `Calculator.ets` / `model/` | **零改动** | 智能 `%` 语义 `getPercentString()` 早已存在 |

**核心代码（独立 Builder，零侵入既有按钮）**：

```typescript
// 5 列运算符按钮（首行专用：AC ( ) % ÷）
@Builder BtnOp5(l: string) {
  Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText())
    .width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center)
    .backgroundColor(this.getOp()).borderRadius(50).margin(this.isLandscape ? 1 : 3)
    .onClick((): void => { this.onOp(l) })
}

// 5 列动作按钮（首行 AC 专用）
@Builder BtnAct5(l: string) {
  Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText())
    .width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center)
    .backgroundColor(l === 'AC' ? this.getClr() : this.getBtnBg()).borderRadius(50)
    .margin(this.isLandscape ? 1 : 3)
    .onClick((): void => { if (l === 'AC') this.onAC(); else this.onBS() })
}
```

**首行宽度**：5 × 18% = **90%**，加上 margin 余量约 95%（不溢出）。其他行仍是 4 × 22% = 88%。

**为什么独立新建 Builder 而不复用**：避免给 `BtnOp/BtnAct` 加可选宽度参数后影响所有调用点，保持其他四行（数字 / 四则 / 等号）零回归风险。代价仅 2 个 @Builder，权衡后是更稳妥的选择。

## 5. 最后结果

### 编译结果

- ⚠️ CLI `hvigorw assembleHap`：**BLOCKED**（`00303168 SDK component missing`，hvigor 6.22.3 期望 SDK 组件扁平化但本机 SDK 是嵌套结构 `HarmonyOS-6.0.2/{toolchains,ets,...}`，与代码无关）
- ✅ DevEco Studio IDE 编译：`entry-default-unsigned.hap` 已就绪（含本次修改）
- ✅ `hdc install`：`install bundle successfully`
- ✅ 静态语法等价审查：`BtnOp5` ↔ `BtnOp` 仅在 `width` / `margin` 两个数值差异，编译器视角等价

### 功能展示

Pura 80 模拟器实测截图（HarmonyOS 6.0.2，1256×2760）：

<img src="./specs/changes/20260518-requirement-add-percentage-button/screenshots/02_50_plus_10_pct.jpeg" alt="计算器主界面" width="280" />

第一行 5 个按钮 `AC | ( | ) | % | ÷` 完整显示，`%` 加入后不溢出右边框。

### 功能验证

| # | 测试 | 输入 | 预期 | 实测 | 截图 |
|---|------|------|:---:|:---:|:---:|
| 1 | 主页布局 | 启动 App | 首行 5 按钮可见 | ✅ | [01](./specs/changes/20260518-requirement-add-percentage-button/screenshots/01_calculator_main.jpeg) |
| 2 | 加法智能百分比 | `50+10%=` | 55 | **55** ✅ | [02](./specs/changes/20260518-requirement-add-percentage-button/screenshots/02_50_plus_10_pct.jpeg) |
| 3 | 减法智能百分比 | `50-10%=` | 45 | **45** ✅ | [03](./specs/changes/20260518-requirement-add-percentage-button/screenshots/03_50_minus_10_pct.jpeg) |
| 4 | 乘法百分比 | `50×10%=` | 5 | **5** ✅ | [04](./specs/changes/20260518-requirement-add-percentage-button/screenshots/04_50_times_10_pct.jpeg) |
| 5 | 独立百分比 | `25%=` | 0.25 | **0.25** ✅ | [05](./specs/changes/20260518-requirement-add-percentage-button/screenshots/05_25_pct.jpeg) |

### 爹助审查

- 代码审查 7 维度全部 [PASS]（正确性 / 鲁棒性 / 安全性 / 可维护性 / 性能 / 主题响应 / 布局合理性）
- 风险与缓解：6 项 FMEA 全部覆盖（孤立 `%` / `%%` 连续 / `%` 后接数字 / 主题切换 / 横屏 5 列 / 历史回填）
- 详见 [`verification-report.md`](./specs/changes/20260518-requirement-add-percentage-button/verification-report.md)

## 6. 客户 DEMO 操作指南

### 6.1 如何编译运行

```bash
# 前提：DevEco Studio 6.0.2+ 已安装，SDK API 22 已下载
# 打开项目（CLI 编译可能受 hvigor 6.22.3 SDK 解析限制，推荐 IDE 内编译）
open -a "DevEco-Studio" /path/to/opencalc-harmonyos

# 在 IDE 内：Build → Make Project → Run 'entry'

# 或者，如果已有 HAP，直接安装到模拟器：
export PATH="/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains:$PATH"
hdc install entry/build/default/outputs/default/entry-default-unsigned.hap
hdc shell aa start -b com.darkempire78.opencalculator -a EntryAbility
```

### 6.2 如何演示

1. 打开计算器，观察第一行按钮：`AC` `(` `)` `%` `÷`（共 5 个，比基础版本多了 `%`）
2. 输入 `50+10%`，按 `=`，显示 `55`
3. 输入 `50-10%`，按 `=`，显示 `45`
4. 输入 `50×10%`，按 `=`，显示 `5`
5. 输入 `25%`，按 `=`，显示 `0.25`
6. 切换主题（设置 → 主题 → 浅色/暗色/AMOLED），验证 `%` 按钮颜色跟随
7. 横屏旋转设备，验证 5 列在横屏下也不溢出

### 6.3 出了问题怎么对比查看

1. **CLI 编译失败 `00303168 SDK component missing`？** → 这是 hvigor 6.22.3 已知限制，与本次代码无关。改在 DevEco Studio IDE 内 Build。
2. **按钮不显示？** → 检查 `CalculatorPage.ets:278` 的首行 `Row()` 是否包含 `this.BtnOp5('%')`
3. **按钮溢出右边框？** → 确认是 `BtnOp5` (width=18%) 而非 `BtnOp` (width=22%)；首行所有 5 个按钮必须用 `*5` 系列
4. **计算结果不对？** → 智能 `%` 在 `entry/src/main/ets/calculator/Expression.ets:169-255` 的 `getPercentString()`；如果是其他用例失败，对照该方法的 7 种分支
5. **主题切换 `%` 颜色没变？** → `BtnOp5` 必须用 `this.getOp()`（响应式表达式），不能写硬编码颜色
6. **对比早期 demo 版本？** → 参考 [`../opencalc-harmonyos-demo/1-percent-button/`](../opencalc-harmonyos-demo/1-percent-button/) 目录中的实现（顺序和 Builder 策略不同）

### 6.4 如果客户没做完

所有 SPEC 文件 + 验证报告 + AID 制品已在 [`specs/changes/20260518-requirement-add-percentage-button/`](./specs/changes/20260518-requirement-add-percentage-button/) 中。直接阅读：

- 需求分析 → [`proposal.md`](./specs/changes/20260518-requirement-add-percentage-button/proposal.md)
- 验收标准 → [`delta-spec.md`](./specs/changes/20260518-requirement-add-percentage-button/delta-spec.md)
- 架构设计 → [`delta-design.md`](./specs/changes/20260518-requirement-add-percentage-button/delta-design.md)
- 实施详情 → [`apply-report.md`](./specs/changes/20260518-requirement-add-percentage-button/apply-report.md)
- 验证结果 → [`verification-report.md`](./specs/changes/20260518-requirement-add-percentage-button/verification-report.md)
