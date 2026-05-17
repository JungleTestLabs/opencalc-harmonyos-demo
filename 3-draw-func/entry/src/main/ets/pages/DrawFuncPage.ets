// OpenCalc — 函数图像绘制页面
// 增量需求：3-draw-func
// 输入数学表达式（如 sin(x)），Canvas 实时绘制函数曲线
import { router } from '@kit.ArkUI'
import { CalcEngine } from '../calculator/Calculator'

interface Point {
  x: number
  y: number
}

@Entry
@Component
export struct DrawFuncPage {
  // ==================== 状态 ====================
  @State expression: string = 'sin(x)'
  @State errorMsg: string = ''
  @State canvasReady: boolean = false

  // ==================== 引擎 ====================
  private engine: CalcEngine = new CalcEngine()

  // ==================== 预设函数 ====================
  private presets: string[] = ['sin(x)', 'cos(x)', 'tan(x)', 'x^2', 'x^3', 'sqrt(x)']

  // ==================== 绘图参数 ====================
  private xMin: number = -6.28   // -2π
  private xMax: number = 6.28    // 2π
  private sampleCount: number = 300

  // ==================== 颜色定义 ====================
  private colorBg: string = '#0f0f1a'
  private colorCard: string = '#1a1a2e'
  private colorPrimary: string = '#e94560'
  private colorText: string = '#ffffff'
  private colorTextDim: string = '#a0a0b0'
  private colorInput: string = '#252540'
  private colorBtn: string = '#2a2a45'
  private colorBtnActive: string = '#e94560'
  private colorGrid: string = '#2a2a40'
  private colorAxis: string = '#555570'
  private colorCurve: string = '#00e676'
  private settings: RenderingContextSettings = new RenderingContextSettings(true)
  private context: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings)

  // ==================== 辅助方法 ====================
  private replaceX(expr: string, value: number): string {
    let result: string = ''
    let i: number = 0
    while (i < expr.length) {
      if (expr[i] === 'x') {
        const prevIsLetter: boolean = i > 0 && /[a-zA-Z]/.test(expr[i - 1])
        const nextIsLetter: boolean = i + 1 < expr.length && /[a-zA-Z]/.test(expr[i + 1])
        if (!prevIsLetter && !nextIsLetter) {
          result += `(${value})`
        } else {
          result += 'x'
        }
      } else {
        result += expr[i]
      }
      i++
    }
    return result
  }

  private isFiniteNum(v: number): boolean {
    return !isNaN(v) && v !== Infinity && v !== -Infinity
  }

  // ==================== 函数采样 ====================
  private sampleFunction(expr: string): Point[] {
    const points: Point[] = []
    this.errorMsg = ''

    if (expr.trim().length === 0) {
      this.errorMsg = '请输入函数表达式'
      return points
    }

    let hasValidPoint: boolean = false

    for (let i: number = 0; i < this.sampleCount; i++) {
      const x: number = this.xMin + (this.xMax - this.xMin) * i / (this.sampleCount - 1)
      try {
        const exprWithX: string = this.replaceX(expr, x)
        const y: number = this.engine.evaluate(exprWithX, false)

        if (this.isFiniteNum(y)) {
          points.push({ x: x, y: y })
          hasValidPoint = true
        } else {
          // NaN → 断点标记
          points.push({ x: x, y: Number.NaN })
        }
      } catch (_e) {
        points.push({ x: x, y: Number.NaN })
      }
    }

    if (!hasValidPoint) {
      this.errorMsg = '无法计算该函数（检查表达式或定义域）'
    }

    return points
  }

  // ==================== Canvas 绘制 ====================
  private drawGraph(): void {
    if (!this.canvasReady) return

    const points: Point[] = this.sampleFunction(this.expression)

    const ctx: CanvasRenderingContext2D = this.context
    const w: number = ctx.width
    const h: number = ctx.height
    const margin: number = 40

    // 清除画布
    ctx.clearRect(0, 0, w, h)

    // 背景
    ctx.fillStyle = this.colorBg
    ctx.fillRect(0, 0, w, h)

    if (points.length === 0) {
      // 显示错误信息在 Canvas 中央
      ctx.fillStyle = '#ff5252'
      ctx.font = '14px sans-serif'
      ctx.textAlign = 'center'
      ctx.fillText(this.errorMsg, w / 2, h / 2)
      return
    }

    // 计算 y 轴范围
    let yMin: number = Number.MAX_VALUE
    let yMax: number = -Number.MAX_VALUE
    for (let i: number = 0; i < points.length; i++) {
      if (this.isFiniteNum(points[i].y)) {
        if (points[i].y < yMin) yMin = points[i].y
        if (points[i].y > yMax) yMax = points[i].y
      }
    }

    if (yMin === Number.MAX_VALUE) {
      yMin = -5; yMax = 5
    }

    // 添加 10% margin
    const yRange: number = yMax - yMin
    if (yRange < 0.1) {
      yMin = yMin - 1; yMax = yMax + 1
    } else {
      yMin = yMin - yRange * 0.1
      yMax = yMax + yRange * 0.1
    }

    const plotW: number = w - 2 * margin
    const plotH: number = h - 2 * margin

    // 坐标转换函数
    const toX = (mathX: number): number => margin + (mathX - this.xMin) / (this.xMax - this.xMin) * plotW
    const toY = (mathY: number): number => h - margin - (mathY - yMin) / (yMax - yMin) * plotH

    // 绘制网格
    ctx.strokeStyle = this.colorGrid
    ctx.lineWidth = 0.5
    this.drawGrid(ctx, w, h, margin, this.xMin, this.xMax, yMin, yMax, toX, toY)

    // 绘制坐标轴
    ctx.strokeStyle = this.colorAxis
    ctx.lineWidth = 1.5
    ctx.setLineDash([])

    // Y 轴（x=0 处）
    const axisX: number = toX(0)
    if (axisX >= margin && axisX <= w - margin) {
      ctx.beginPath()
      ctx.moveTo(axisX, h - margin)
      ctx.lineTo(axisX, margin)
      ctx.stroke()
      // Y 轴箭头
      ctx.beginPath()
      ctx.moveTo(axisX, margin)
      ctx.lineTo(axisX - 4, margin + 8)
      ctx.lineTo(axisX + 4, margin + 8)
      ctx.closePath()
      ctx.fillStyle = this.colorAxis
      ctx.fill()
    }

    // X 轴（y=0 处）
    const axisY: number = toY(0)
    if (axisY >= margin && axisY <= h - margin) {
      ctx.beginPath()
      ctx.moveTo(margin, axisY)
      ctx.lineTo(w - margin, axisY)
      ctx.stroke()
      // X 轴箭头
      ctx.beginPath()
      ctx.moveTo(w - margin, axisY)
      ctx.lineTo(w - margin - 8, axisY - 4)
      ctx.lineTo(w - margin - 8, axisY + 4)
      ctx.closePath()
      ctx.fillStyle = this.colorAxis
      ctx.fill()
    }

    // 绘制刻度标签
    ctx.fillStyle = this.colorTextDim
    ctx.font = '10px sans-serif'
    ctx.textAlign = 'center'
    this.drawTicks(ctx, w, h, margin, this.xMin, this.xMax, yMin, yMax, toX, toY)

    // 绘制函数曲线
    ctx.strokeStyle = this.colorCurve
    ctx.lineWidth = 2.5
    ctx.setLineDash([])

    let drawing: boolean = false
    ctx.beginPath()

    for (let i: number = 0; i < points.length; i++) {
      const pt = points[i]
      if (this.isFiniteNum(pt.y)) {
        const sx: number = toX(pt.x)
        const sy: number = toY(pt.y)

        if (sx >= margin && sx <= w - margin && sy >= margin && sy <= h - margin) {
          if (!drawing) {
            ctx.moveTo(sx, sy)
            drawing = true
          } else {
            ctx.lineTo(sx, sy)
          }
        } else if (drawing) {
          // 点超出画布 → 连线到边界但不中断
          ctx.lineTo(
            sx < margin ? margin : (sx > w - margin ? w - margin : sx),
            sy < margin ? margin : (sy > h - margin ? h - margin : sy)
          )
        }
      } else {
        // NaN → 断线
        if (drawing) {
          ctx.stroke()
          drawing = false
        }
      }
    }
    if (drawing) {
      ctx.stroke()
    }

    // 函数表达式标签（左上角）
    ctx.fillStyle = this.colorPrimary
    ctx.font = 'bold 14px sans-serif'
    ctx.textAlign = 'left'
    ctx.fillText(`y = ${this.expression}`, margin + 4, margin + 18)
  }

  // 绘制网格
  private drawGrid(
    ctx: CanvasRenderingContext2D, w: number, h: number, m: number,
    xMin: number, xMax: number, yMin: number, yMax: number,
    toX: (v: number) => number, toY: (v: number) => number
  ): void {
    ctx.setLineDash([3, 5])

    // 垂直网格线（每 π/2 或 1 单位）
    const xStep: number = (xMax - xMin) > 10 ? 2 : (xMax - xMin) > 5 ? 1 : 0.5
    for (let x: number = Math.ceil(xMin / xStep) * xStep; x <= xMax; x += xStep) {
      const sx: number = toX(x)
      if (sx > m && sx < w - m) {
        ctx.beginPath()
        ctx.moveTo(sx, m)
        ctx.lineTo(sx, h - m)
        ctx.stroke()
      }
    }

    // 水平网格线
    const yRange: number = yMax - yMin
    const yStep: number = yRange > 10 ? 2 : yRange > 5 ? 1 : 0.5
    for (let y: number = Math.ceil(yMin / yStep) * yStep; y <= yMax; y += yStep) {
      const sy: number = toY(y)
      if (sy > m && sy < h - m) {
        ctx.beginPath()
        ctx.moveTo(m, sy)
        ctx.lineTo(w - m, sy)
        ctx.stroke()
      }
    }

    ctx.setLineDash([])
  }

  // 绘制刻度标签
  private drawTicks(
    ctx: CanvasRenderingContext2D, w: number, h: number, m: number,
    xMin: number, xMax: number, yMin: number, yMax: number,
    toX: (v: number) => number, toY: (v: number) => number
  ): void {
    // X 轴刻度
    const xRange: number = xMax - xMin
    const xStep: number = xRange > 10 ? 2 : xRange > 5 ? 1 : 0.5
    const axisY: number = toY(0)
    const labelY: number = axisY >= m && axisY <= h - m ? axisY + 16 : h - m + 16

    for (let x: number = Math.ceil(xMin / xStep) * xStep; x <= xMax; x += xStep) {
      const sx: number = toX(x)
      if (sx > m && sx < w - m) {
        // 小刻度线
        ctx.beginPath()
        ctx.moveTo(sx, axisY >= m ? axisY - 3 : h - m - 3)
        ctx.lineTo(sx, axisY >= m ? axisY + 3 : h - m + 3)
        ctx.strokeStyle = this.colorAxis
        ctx.lineWidth = 1
        ctx.stroke()

        // 标签
        let label: string = x.toFixed(1)
        if (Math.abs(x) < 0.001) label = '0'
        ctx.fillText(label, sx, labelY)
      }
    }

    // Y 轴刻度
    const yStep: number = (yMax - yMin) > 10 ? 2 : (yMax - yMin) > 5 ? 1 : 0.5
    const axisX: number = toX(0)
    ctx.textAlign = 'right'

    for (let y: number = Math.ceil(yMin / yStep) * yStep; y <= yMax; y += yStep) {
      const sy: number = toY(y)
      if (sy > m && sy < h - m) {
        ctx.beginPath()
        ctx.moveTo(axisX >= m ? axisX - 3 : m, sy)
        ctx.lineTo(axisX >= m ? axisX + 3 : m + 3, sy)
        ctx.strokeStyle = this.colorAxis
        ctx.lineWidth = 1
        ctx.stroke()

        let label: string = y.toFixed(1)
        if (Math.abs(y) < 0.001) label = '0'
        const labelX: number = axisX >= m ? axisX - 8 : m + 36
        ctx.fillText(label, labelX, sy + 4)
      }
    }
  }

  // ==================== 事件处理 ====================
  private onBack(): void {
    router.back()
  }

  private onPreset(expr: string): void {
    this.expression = expr
    this.errorMsg = ''
    this.drawGraph()
  }

  private onExpressionChange(value: string): void {
    // 过滤危险字符
    const filtered: string = value.replace(/[^a-zA-Z0-9+\-*/().^% x]/g, '')
    this.expression = filtered
  }

  private onRedraw(): void {
    this.drawGraph()
  }

  // ==================== UI 构建器 ====================
  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(this.colorText)
        .width(40).height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colorBtn)
        .onClick(() => { this.onBack() })

      Text('📈 函数图像')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colorText)
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 4 })
  }

  @Builder
  InputArea() {
    Column() {
      Row() {
        Text('y =')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colorPrimary)
          .margin({ right: 8 })

        TextInput({ text: this.expression, placeholder: 'sin(x)' })
          .fontSize(18)
          .fontColor(this.colorText)
          .placeholderColor(this.colorTextDim)
          .backgroundColor(Color.Transparent)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => { this.onExpressionChange(value) })
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.colorInput)
      .borderRadius(10)
      .padding({ left: 12, right: 12 })

      // 预设按钮行
      Row() {
        ForEach(this.presets, (preset: string) => {
          Text(preset)
            .fontSize(12)
            .fontColor(this.expression === preset ? '#ffffff' : this.colorTextDim)
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(8)
            .backgroundColor(this.expression === preset ? this.colorBtnActive : this.colorBtn)
            .margin({ right: 6, top: 8 })
            .onClick(() => { this.onPreset(preset) })
        })
      }
      .width('100%')

      // 绘制按钮 + 错误信息
      Row() {
        Text('绘制')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor('#ffffff')
          .padding({ left: 16, right: 16, top: 6, bottom: 6 })
          .borderRadius(8)
          .backgroundColor(this.colorPrimary)
          .onClick(() => { this.onRedraw() })

        if (this.errorMsg.length > 0) {
          Text(this.errorMsg)
            .fontSize(12)
            .fontColor('#ff5252')
            .margin({ left: 12 })
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }

        Blank()

        Text(`x: [${this.xMin.toFixed(1)}, ${this.xMax.toFixed(1)}]`)
          .fontSize(10)
          .fontColor(this.colorTextDim)
      }
      .width('100%')
      .margin({ top: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
  }

  // ==================== 主构建 ====================
  build() {
    Column() {
      this.Header()
      this.InputArea()

      // Canvas 绘图区
      Canvas(this.context)
        .width('100%')
        .layoutWeight(1)
        .backgroundColor(this.colorBg)
        .onReady(() => {
          this.canvasReady = true
          this.drawGraph()
        })
        .onAreaChange(() => {
          if (this.canvasReady) {
            this.drawGraph()
          }
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colorBg)
  }
}
