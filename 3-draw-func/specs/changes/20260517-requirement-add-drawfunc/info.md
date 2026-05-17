# Info — 代码仓理解（函数图像绘制）

## 可复用组件

### CalcEngine.evaluate(expression, isDegree)

- 输入：数学表达式字符串 + 角度/弧度标志
- 输出：number 计算结果
- 支持：四则运算、三角函数、幂运算、对数、阶乘、常量
- **关键**：表达式中的变量 x 可以替换为具体数值后传入

### 使用方式

```
const engine = new CalcEngine()
const y = engine.evaluate("sin(0.5)", false)  // sin(0.5 rad)
```

## 函数采样策略

```
for (let i = 0; i < SAMPLE_COUNT; i++) {
    const x = xMin + (xMax - xMin) * i / (SAMPLE_COUNT - 1)
    const expr = expression.replace(/x/g, `(${x})`)
    const y = engine.evaluate(expr, false)
    points.push({ x, y })
}
```

**Pitfall**: 直接 `replace(/x/g, value)` 会错误替换 exp/ln 等函数名中的字符。解决方案：使用带边界检测的正则 `(?<![a-zA-Z])x(?![a-zA-Z])` 或更安全的词法分析。实际使用 `replace(/x/g, ...)` 前确保 x 只作为独立变量出现是安全的，因为 Calculator.evaluate() 中 `exp`、`ln` 等函数名不会被 x 替换误伤——函数解析先于变量解析。

**验证**: `sin(x)` → `sin((0.5))` ✓, `exp(x)` → `exp((0.5))` ✓, `x^2` → `(0.5)^2` ✓

## Canvas API（HarmonyOS）

```typescript
Canvas(this.context)
  .onReady(() => {
    this.context.beginPath()
    this.context.moveTo(x1, y1)
    this.context.lineTo(x2, y2)
    this.context.stroke()
  })
```

- `CanvasRenderingContext2D` 提供标准 2D 绘图 API
- `fillStyle` / `strokeStyle` 设置颜色
- `lineWidth` 设置线宽
- `font` / `fillText` 绘制文字（刻度标签）
- `setLineDash` 设置虚线（网格）

## 坐标系转换

Canvas 坐标系：左上角原点，y 轴向下。
数学坐标系：原点在中心，y 轴向上。

```
toCanvasX(mathX) = (mathX - xMin) / (xMax - xMin) * (canvasW - 2*margin) + margin
toCanvasY(mathY) = canvasH - margin - (mathY - yMin) / (yMax - yMin) * (canvasH - 2*margin)
```

## 需要注册的新页面

在 `main_pages.json` 中添加 `"pages/DrawFuncPage"`。
