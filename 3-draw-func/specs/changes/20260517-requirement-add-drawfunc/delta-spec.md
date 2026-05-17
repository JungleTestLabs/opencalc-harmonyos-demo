# Delta Spec — 函数图像绘制

## 变更摘要

为 OpenCalc 增加函数图像绘制页面。纯增量变更，复用 CalcEngine 作为计算后端。

## 新增文件

### 1. `entry/src/main/ets/pages/DrawFuncPage.ets`

函数图像绘制页面，核心组件：

**状态变量**：
- `@State expression: string` — 用户输入的函数表达式
- `@State xMin: number` — x 轴最小值（默认 -6.28 = -2π）
- `@State xMax: number` — x 轴最大值（默认 6.28 = 2π）
- `@State errorMsg: string` — 错误信息

**计算采样**：
1. 将用户输入的 `x` 变量替换为具体数值
2. 对 x 范围均匀采样 200 个点
3. 调用 `CalcEngine.evaluate()` 计算每个点的 y 值
4. 对 y 值做范围裁剪（超出视图范围的点用 NaN 标记断点）

**Canvas 渲染**（onReady 回调）：
1. 绘制深色背景
2. 绘制网格线（灰色虚线）
3. 绘制 x/y 坐标轴（白色实线）
4. 绘制刻度标记和数值标签
5. 使用 `moveTo/lineTo` 绘制函数曲线（红色）
6. NaN 处断线（beginPath 重新开始）

**坐标系转换**：
- 数学坐标 → Canvas 像素坐标
- x: `canvasX = (mathX - xMin) / (xMax - xMin) * canvasWidth`
- y: `canvasY = canvasHeight - (mathY - yMin) / (yMax - yMin) * canvasHeight`
- y 范围自动计算（采样值 min/max 扩展 10% margin）

**预设函数按钮**: sin(x), cos(x), x^2, x^3, sqrt(x), 1/x

### 2. `entry/src/main/ets/pages/Index.ets`（修改）

新增导航按钮："📈 函数图像" → `router.pushUrl('pages/DrawFuncPage')`

### 3. `entry/src/main/resources/base/profile/main_pages.json`（修改）

新增 `"pages/DrawFuncPage"`

## 验收标准对照

| AC# | 条件 | 预期结果 |
|-----|------|---------|
| AC1 | 输入 sin(x) | 正弦曲线，2 个完整周期 |
| AC2 | 输入 x^2 | 抛物线 |
| AC3 | 输入 cos(x) | 余弦曲线 |
| AC4 | 任意函数 | 显示坐标轴+网格+刻度 |
| AC5 | 导航进入/返回 | 正常 |
| AC6 | 空输入 | 不崩溃，显示提示 |
