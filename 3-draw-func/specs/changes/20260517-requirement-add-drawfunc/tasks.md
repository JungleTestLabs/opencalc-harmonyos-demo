# Tasks — 函数图像绘制

## 复杂度: M 级（Canvas 绘图新领域）

## 任务列表

| # | 任务 | 文件 | 预估 | 依赖 |
|---|------|------|------|------|
| T1 | 创建 DrawFuncPage.ets | `pages/DrawFuncPage.ets`（新建） | 45min | 无 |
| T2 | 注册新页面路由 | `main_pages.json`（修改） | 5min | T1 |
| T3 | 修改 Index.ets 添加导航 | `pages/Index.ets`（修改） | 10min | T1 |

## 详细说明

### T1: 创建 DrawFuncPage.ets

**描述**: 创建函数图像绘制页面，包含：
- TextInput 输入函数表达式
- 预设函数快捷按钮（sin/cos/x^2 等）
- Canvas 绘制图像（坐标轴+网格+曲线）
- 使用 CalcEngine 采样计算 y 值
- 错误处理

**验收标准**:
- [ ] sin(x) 显示正弦曲线
- [ ] x^2 显示抛物线
- [ ] cos(x) 显示余弦曲线
- [ ] 坐标轴+网格+刻度正确显示
- [ ] 空输入不崩溃

**涉及文件**: `entry/src/main/ets/pages/DrawFuncPage.ets`（新建）
