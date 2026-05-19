// OpenCalc — 函数图像绘制页面
// 由 CalculatorPage 通过 router.pushUrl 跳转进入
// 复用现有 CalcEngine、Expression、PreferencesStore

import { router } from '@kit.ArkUI'
import { CalcEngine } from '../calculator/Calculator'
import { Expression } from '../calculator/Expression'
import { Plotter, ThemeColors } from '../calculator/Plotter'
import { GraphConfig, PlotResult } from '../model/Models'
import { PreferencesStore } from '../preferences/PreferencesStore'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct GraphPage {
  @State expression: string = ''
  @State errorMsg: string = ''
  @State isPlotting: boolean = false
  @State themeIdx: number = 0
  @State canvasReady: boolean = false

  private ctx: CanvasRenderingContext2D = new CanvasRenderingContext2D(
    new RenderingContextSettings(true)
  )
  private engine: CalcEngine = new CalcEngine()
  private expr: Expression = new Expression()
  private debounceTimer: number = -1
  private canvasWidthPx: number = 0
  private canvasHeightPx: number = 0
  private prefs: PreferencesStore | null = null

  async aboutToAppear(): Promise<void> {
    const ctx = getContext(this) as common.UIAbilityContext
    this.prefs = new PreferencesStore(ctx)
    await this.prefs.init()
    this.themeIdx = await this.prefs.getTheme()
  }

  aboutToDisappear(): void {
    if (this.debounceTimer !== -1) {
      clearTimeout(this.debounceTimer)
      this.debounceTimer = -1
    }
  }

  // ==================== 主题颜色（拷贝模式,与 CalculatorPage 同源） ====================
  getBg(): string {
    if (this.themeIdx === 1) return '#000000'
    if (this.themeIdx === 2) return '#121212'
    return '#FFFFFF'
  }

  getBtnBg(): string {
    if (this.themeIdx === 1) return '#1a1a1a'
    if (this.themeIdx === 2) return '#333333'
    return '#EFEFEF'
  }

  getT1(): string {
    if (this.themeIdx >= 1) return '#EFEFEF'
    return '#000000'
  }

  getT2(): string {
    if (this.themeIdx >= 1) return '#BDBDBD'
    return '#595959'
  }

  getErr(): string { return '#F44B3F' }

  getAxis(): string {
    if (this.themeIdx >= 1) return '#666666'
    return '#888888'
  }

  getCurve(): string {
    if (this.themeIdx === 1) return '#00BCD4'
    if (this.themeIdx === 2) return '#A8C7FA'
    return '#1976D2'
  }

  // ==================== 交互逻辑 ====================
  onPlot(): void {
    if (this.expression.trim() === '') {
      this.errorMsg = '请输入表达式'
      this.ctx.clearRect(0, 0, this.canvasWidthPx, this.canvasHeightPx)
      return
    }
    if (!this.canvasReady) return
    this.isPlotting = true
    this.errorMsg = ''

    let prepared: string = ''
    try {
      prepared = this.expr.getCleanExpression(this.expression, '.', ',')
    } catch (e) {
      this.errorMsg = '表达式语法错误'
      this.isPlotting = false
      this.ctx.clearRect(0, 0, this.canvasWidthPx, this.canvasHeightPx)
      return
    }

    const sampleCount: number = Math.max(
      200,
      Math.min(600, Math.floor(this.canvasWidthPx / 2))
    )
    const cfg: GraphConfig = {
      xMin: -10,
      xMax: 10,
      sampleCount: sampleCount,
      canvasWidthPx: this.canvasWidthPx,
      canvasHeightPx: this.canvasHeightPx,
      paddingPx: 16
    }

    const theme: ThemeColors = {
      axis: this.getAxis(),
      curve: this.getCurve(),
      bg: this.getBg()
    }

    try {
      const result: PlotResult = Plotter.sample(prepared, cfg, this.engine, false)
      if (result.validCount === 0) {
        this.errorMsg = '函数在该区间未定义'
      }
      Plotter.drawTo(this.ctx, result, cfg, theme)
    } catch (e) {
      console.error('plot render error', e)
      this.errorMsg = '绘图失败'
    }
    this.isPlotting = false
  }

  onAreaChangeRedraw(w: number, h: number): void {
    this.canvasWidthPx = w
    this.canvasHeightPx = h
    if (!this.canvasReady) return
    if (this.expression.trim() === '') return
    if (this.debounceTimer !== -1) clearTimeout(this.debounceTimer)
    this.debounceTimer = setTimeout((): void => {
      this.debounceTimer = -1
      this.onPlot()
    }, 300)
  }

  // ==================== UI ====================
  build() {
    Column() {
      // 标题栏
      Row() {
        Text('←').fontSize(20).fontColor(this.getT1()).padding(12)
          .onClick((): void => { router.back() })
        Text('函数绘图').fontSize(18).fontColor(this.getT1()).layoutWeight(1)
        Blank().width(44)
      }
      .width('100%').alignItems(VerticalAlign.Center)

      // 表达式输入行
      Row() {
        TextInput({ placeholder: '输入函数,例如 sin(x)', text: this.expression })
          .fontSize(18).fontColor(this.getT1())
          .backgroundColor(this.getBtnBg())
          .placeholderColor(this.getT2())
          .layoutWeight(1).height(48)
          .onChange((v: string): void => { this.expression = v })
        Text('x').fontSize(16).fontColor(this.getT1())
          .width(44).height(48).textAlign(TextAlign.Center)
          .backgroundColor(this.getBtnBg()).borderRadius(8)
          .margin({ left: 8 })
          .onClick((): void => { this.expression = this.expression + 'x' })
      }
      .width('100%').padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 操作行
      Row() {
        Button(this.isPlotting ? '绘图中…' : '绘图')
          .fontSize(16).fontColor(this.getT1())
          .backgroundColor(this.getBtnBg())
          .height(48).layoutWeight(1)
          .enabled(!this.isPlotting)
          .onClick((): void => { this.onPlot() })
      }
      .width('100%').padding({ left: 16, right: 16, bottom: 8 })

      // Canvas
      Canvas(this.ctx)
        .width('100%').layoutWeight(1)
        .backgroundColor(this.getBg())
        .onReady((): void => {
          this.canvasReady = true
        })
        .onAreaChange((_oldArea: Area, newArea: Area): void => {
          const w: number = Number(newArea.width)
          const h: number = Number(newArea.height)
          this.onAreaChangeRedraw(w, h)
        })

      // 错误提示行
      if (this.errorMsg !== '') {
        Text(this.errorMsg).fontSize(14).fontColor(this.getErr())
          .width('100%').padding({ left: 16, right: 16, top: 4, bottom: 8 })
      }
    }
    .width('100%').height('100%').backgroundColor(this.getBg())
  }
}
