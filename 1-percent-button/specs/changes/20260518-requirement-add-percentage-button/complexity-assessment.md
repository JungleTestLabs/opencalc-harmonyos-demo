# 需求复杂度评估

> 变更：20260518-requirement-add-percentage-button
> 评估日期：2026-05-18
> 评估依据：proposal.md、delta-spec.md、info.md

## 评估维度

| 维度 | 取值 | 标准 |
|------|------|------|
| 功能范围 | 单个功能点（添加按钮 + 复用语义） | 简单 |
| 代码改动 | 预计 < 30 行（CalculatorPage.ets 仅）| 简单 |
| 数据模型 | 无新增 / 无修改 | 简单 |
| 架构影响 | 无 | 简单 |
| 接口变更 | 复用现有 `onOp(op: string)` | 简单 |
| 依赖关系 | 单模块（CalculatorPage）依赖现有公共组件 | 简单 |
| 影响模块数 | 1 个 | 简单 |

## 评估结果

- **复杂度等级**：**简单**（S）
- **影响模块数**：1
- **架构变更**：否
- **数据模型变更**：否
- **依据**：所有 7 个评估维度均落在"简单需求"区间

## 跳过策略

根据复杂度评估结果，确定需要产出的制品：

| 制品 | 是否产出 | 备注 |
|------|---------|------|
| `proposal.md` | ✅ 已产出 | step2-3 |
| `delta-spec.md` | ✅ 已产出 | step4 |
| `info.md` | ✅ 已产出 | step5 |
| `new-arch.md` | ❌ **跳过** | 架构无变更（仅在 CalculatorPage.ets 内的 ButtonGrid 局部修改） |
| `delta-design.md` | ✅ 必须产出 | step8 |
| `design-review.md` | ✅ 必须产出 | step9 |
| `tasks.md` | ✅ 必须产出 | IMPLEMENTING 阶段 |
| `apply-report.md` | ✅ 必须产出 | APPLYING 阶段 |

## 设计指导原则（基于评估）

1. **最小改动**：仅修改 `CalculatorPage.ets`，不触碰 `calculator/` 与 `model/` 下任何文件
2. **YAGNI**：不引入新数据模型、新接口、新文件
3. **复用优先**：复用 `BtnOp` 样式、`onOp` 事件、`getOp()` 颜色
4. **可测试**：保留 UT/UI 测试用例覆盖（详见 delta-spec.md§3 验收准则）

## 决策

→ 进入 step7 架构设计，但因复杂度简单，step7 仅做"无架构变更"声明，不产出 `new-arch.md`，直接进入 step8 组件设计。
