// OpenCalc — 主计算器页面（横竖屏自适应 + Android 配色）
// 移植自：MainActivity.kt（1447行）
import { promptAction } from '@kit.ArkUI'
import { pasteboard } from '@kit.BasicServicesKit'
import { common } from '@kit.AbilityKit'
import { Expression } from '../calculator/Expression'
import { CalcEngine } from '../calculator/Calculator'
import { NumberFormatter } from '../calculator/NumberFormatter'
import { NumberingSystem, HistoryItem } from '../model/Models'
import { ErrorFlags } from '../model/ErrorFlags'
import { PreferencesStore } from '../preferences/PreferencesStore'

@Entry
@Component
export struct CalculatorPage {
  // ==================== 显示状态 ====================
  @State expression: string = ''
  @State result: string = ''
  @State errorMsg: string = ''
  @State scientific: boolean = false
  @State history: HistoryItem[] = []
  @State showHistory: boolean = false
  @State showSettings: boolean = false
  @State showAbout: boolean = false
  @State isLandscape: boolean = false

  // ==================== 偏好设置状态 ====================
  @State vibrateOn: boolean = true
  @State preventSleep: boolean = false
  @State radianMode: boolean = false
  @State themeIdx: number = 0

  // ==================== 内部状态 ====================
  private nextId: number = 0
  private engine: CalcEngine = new CalcEngine()
  private expr: Expression = new Expression()
  private prefs: PreferencesStore | null = null

  aboutToAppear(): void {
    const ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext
    this.prefs = new PreferencesStore(ctx)
    this.prefs.init().then((): void => { this.loadPrefs(); this.loadHistory() })
  }

  async loadPrefs(): Promise<void> {
    if (!this.prefs) return
    this.vibrateOn = await this.prefs.getVibrationEnabled()
    this.preventSleep = await this.prefs.getPreventSleep()
    this.radianMode = await this.prefs.getRadiansDefault()
    this.themeIdx = await this.prefs.getTheme()
    this.scientific = (await this.prefs.getScientificModeDefault()) === 1
  }

  async loadHistory(): Promise<void> {
    if (!this.prefs) return
    this.history = await this.prefs.getHistory()
    if (this.history.length > 0) this.nextId = this.history[0].id + 1
  }

  async savePref(key: string, value: boolean | number): Promise<void> {
    if (!this.prefs) return
    if (key === 'vibrateOn') await this.prefs.setVibrationEnabled(value as boolean)
    else if (key === 'preventSleep') await this.prefs.setPreventSleep(value as boolean)
    else if (key === 'radianMode') await this.prefs.setRadiansDefault(value as boolean)
    else if (key === 'themeIdx') await this.prefs.setTheme(value as number)
    else if (key === 'scientific') await this.prefs.setScientificModeDefault(value as number)
  }

  // ==================== 按钮事件 ====================
  onDigit(d: string): void { this.expression = this.expression + d; this.errorMsg = '' }
  onOp(op: string): void { this.expression = this.expression + op; this.errorMsg = '' }
  onFunc(f: string): void { this.expression = this.expression + f + '('; this.errorMsg = '' }
  onConst(c: string): void { this.expression = this.expression + c; this.errorMsg = '' }
  onBS(): void { if (this.expression.length > 0) this.expression = this.expression.substring(0, this.expression.length - 1) }
  onAC(): void { this.expression = ''; this.result = ''; this.errorMsg = ''; ErrorFlags.reset() }

  onEquals(): void {
    if (this.expression.length === 0) return
    ErrorFlags.reset()
    try {
      const clean: string = this.expr.getCleanExpression(this.expression, '.', ',')
      const raw: number = this.engine.evaluate(clean, !this.radianMode)
      if (ErrorFlags.division_by_0) { this.errorMsg = '除数不能为零'; this.result = '' }
      else if (ErrorFlags.domain_error) { this.errorMsg = '定义域错误'; this.result = '' }
      else if (ErrorFlags.syntax_error) { this.errorMsg = '表达式错误'; this.result = '' }
      else if (ErrorFlags.is_infinity) { this.errorMsg = '结果无穷大'; this.result = '' }
      else if (ErrorFlags.require_real_number) { this.errorMsg = '需要实数'; this.result = '' }
      else {
        const fmt: string = NumberFormatter.format(raw.toString(), '.', ',', NumberingSystem.INTERNATIONAL)
        this.result = fmt; this.errorMsg = ''
        const item: HistoryItem = { id: this.nextId, expression: this.expression, result: fmt, timestamp: Date.now() }
        this.nextId = this.nextId + 1
        const nh: HistoryItem[] = [item]
        for (let i: number = 0; i < this.history.length; i++) nh.push(this.history[i])
        this.history = nh
        if (this.prefs) this.prefs.setHistory(this.history)
      }
    } catch (_e) { this.errorMsg = '计算错误' }
  }

  onCopy(): void {
    if (this.result.length === 0) return
    pasteboard.getSystemPasteboard().setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.result))
    promptAction.showToast({ message: '已复制' })
  }

  onHistoryTap(item: HistoryItem): void { this.expression = item.expression; this.showHistory = false }
  onHistoryDelete(item: HistoryItem): void {
    const keep: HistoryItem[] = []
    for (let i: number = 0; i < this.history.length; i++) { if (this.history[i].id !== item.id) keep.push(this.history[i]) }
    this.history = keep
    if (this.prefs) this.prefs.setHistory(this.history)
  }

  // ==================== 主题颜色（对齐 Android 原版） ====================
  // themeIdx: 0=默认浅色  1=AMOLED纯黑  2=暗色
  // 默认：Android values/colors.xml 浅色主题
  // 暗色：Android values-night/colors.xml 暗色主题

  /** 背景色（默认白 #FFFFFF） */
  getBg(): string {
    if (this.themeIdx === 1) return '#000000'   // AMOLED
    if (this.themeIdx === 2) return '#121212'   // 暗色
    return '#FFFFFF'                              // 默认浅色
  }

  /** 按钮背景色 */
  getBtnBg(): string {
    if (this.themeIdx === 1) return '#1a1a1a'   // AMOLED: 微亮于纯黑背景
    if (this.themeIdx === 2) return '#333333'
    return '#EFEFEF'
  }

  /** 面板背景色 */
  getPanelBg(): string {
    if (this.themeIdx === 1) return '#0a0a0a'   // AMOLED: 稍亮于纯黑
    if (this.themeIdx === 2) return '#323232'
    return '#FFFFFF'
  }

  /** 功能/常量按钮背景（比普通按钮稍暗以区分层级） */
  getFuncBg(): string {
    if (this.themeIdx === 1) return '#111111'
    if (this.themeIdx === 2) return '#333333'
    return '#E8E8E8'
  }

  /** 运算符按钮色（默认浅蓝 #B4D2E4） */
  getOp(): string {
    if (this.themeIdx === 2) return '#0070BC'
    return '#B4D2E4'
  }

  /** 等号按钮色（默认浅粉 #DCB5C5） */
  getEq(): string {
    if (this.themeIdx === 2) return '#B3004D'
    return '#DCB5C5'
  }

  /** 清除按钮色（默认浅绿 #B7DABD） */
  getClr(): string {
    if (this.themeIdx === 2) return '#00BA20'
    return '#B7DABD'
  }

  /** 错误文字色 */
  getErr(): string { return '#F44B3F' }

  /** 主文字色（默认黑 #000000） */
  getT1(): string {
    if (this.themeIdx >= 1) return '#EFEFEF'
    return '#000000'
  }

  /** 次要文字色（默认深灰 #595959） */
  getT2(): string {
    if (this.themeIdx >= 1) return '#BDBDBD'
    return '#595959'
  }

  /** 运算符文字色（白字在有色按钮上） */
  getBtnText(): string {
    if (this.themeIdx >= 1) return '#EFEFEF'
    return '#000000'
  }

  // ==================== 主布局 ====================
  build() {
    Stack() {
      if (this.isLandscape) {
        // 横屏：左边按钮 + 可选右侧历史（有折叠按钮）
        Row() {
          Column() {
            this.DisplayPanel()
            this.ButtonGrid()
          }
          .layoutWeight(this.showHistory ? 3 : 1).height('100%')
          if (this.showHistory) this.HistoryPanel()
        }
        .width('100%').height('100%').backgroundColor(this.getBg())
      } else {
        // 竖屏：原有布局
        Column() {
          this.DisplayPanel()
          this.ToggleRow()
          this.ButtonGrid()
          if (this.showHistory) this.HistoryPanel()
        }
        .width('100%').height('100%').backgroundColor(this.getBg())
      }
      if (this.showSettings) this.SettingsPanel()
      if (this.showAbout) this.AboutPanel()
    }
    .width('100%').height('100%')
    .onAreaChange((_old: Area, newVal: Area): void => {
      const w: number = newVal.width as number
      const h: number = newVal.height as number
      this.isLandscape = w > h
      // 横屏时自动开启科学模式（但不强制显示历史）
      if (this.isLandscape) this.scientific = true
    })
  }

  // ==================== 显示屏 ====================
  @Builder DisplayPanel() {
    Column() {
    // 横屏时在显示屏右侧加历史切换按钮
    if (this.isLandscape) {
      Row() {
        Text(this.expression.length > 0 ? this.expression : ' ')
          .fontSize(14).fontColor(this.getT2()).textAlign(TextAlign.End).maxLines(3).layoutWeight(1)
        Text(this.showHistory ? '◀' : '▶')
          .fontSize(14).fontColor(this.getOp()).padding({ left: 8 })
          .onClick((): void => { this.showHistory = !this.showHistory })
      }
      .width('100%').padding({ right: 8, left: 8 })
    } else {
      Text(this.expression.length > 0 ? this.expression : ' ')
        .fontSize(18).fontColor(this.getT2()).width('100%').textAlign(TextAlign.End)
        .padding({ right: 12, left: 12 }).maxLines(3)
    }
      if (this.errorMsg.length > 0) {
        Text(this.errorMsg).fontSize(this.isLandscape ? 22 : 28).fontColor(this.getErr())
          .width('100%').textAlign(TextAlign.End).padding({ right: 12, left: 12 })
      } else {
        Text(this.result.length > 0 ? this.result : '0')
          .fontSize(this.isLandscape ? 28 : 36).fontWeight(FontWeight.Bold).fontColor(this.getT1())
          .width('100%').textAlign(TextAlign.End).padding({ right: 12, left: 12 })
      }
    }
    .width('100%').padding(this.isLandscape ? { top: 8, bottom: 2 } : { top: 24, bottom: 8 })
    .gesture(LongPressGesture().onAction((): void => { this.onCopy() }))
  }

  // ==================== 模式切换栏（仅竖屏显示） ====================
  @Builder ToggleRow() {
    Row() {
      Text(this.scientific ? '科学' : '基础').fontSize(12).fontColor(this.getOp())
        .padding({ left: 12, right: 12, top: 4, bottom: 4 })
        .border({ width: 1, color: this.getOp(), radius: 8 })
        .onClick((): void => { this.scientific = !this.scientific })
      Blank()
      Text(this.showHistory ? '▲ 历史' : '▼ 历史').fontSize(12).fontColor(this.getT2()).padding(8)
        .onClick((): void => { this.showHistory = !this.showHistory })
      Text('⚙').fontSize(16).fontColor(this.getT2()).padding(8)
        .onClick((): void => { this.showSettings = true })
    }
    .width('100%').padding({ left: 16, right: 16, bottom: 4 })
  }

  // ==================== 按钮网格 ====================
  @Builder ButtonGrid() {
    Column() {
      if (this.scientific) {
        Row() { this.BtnFunc('sin'); this.BtnFunc('cos'); this.BtnFunc('tan'); this.BtnFunc('ln'); this.BtnFunc('log') }
        Row() { this.BtnFunc('arcsi'); this.BtnFunc('arcco'); this.BtnFunc('arcta'); this.BtnConst('π'); this.BtnConst('e') }
      }
      Row() { this.BtnAct5('AC'); this.BtnOp5('('); this.BtnOp5(')'); this.BtnOp5('%'); this.BtnOp5('÷') }
      Row() { this.BtnDig('7'); this.BtnDig('8'); this.BtnDig('9'); this.BtnOp('×') }
      Row() { this.BtnDig('4'); this.BtnDig('5'); this.BtnDig('6'); this.BtnOp('-') }
      Row() { this.BtnDig('1'); this.BtnDig('2'); this.BtnDig('3'); this.BtnOp('+') }
      Row() { this.BtnDig('0'); this.BtnOp('.'); this.BtnAct('⌫'); this.BtnEq() }
    }
    .width('100%').padding({ left: 8, right: 8 }).layoutWeight(this.isLandscape ? 0 : 1)
  }

  /** 数字按钮 */
  @Builder BtnDig(l: string) { Text(l).fontSize(this.isLandscape ? 16 : 22).fontColor(this.getT1()).width('22%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(this.getBtnBg()).borderRadius(50).margin(this.isLandscape ? 1 : 4).onClick((): void => { this.onDigit(l) }) }

  /** 运算符按钮 */
  @Builder BtnOp(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('22%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(this.getOp()).borderRadius(50).margin(this.isLandscape ? 1 : 4).onClick((): void => { this.onOp(l) }) }

  /** 5 列运算符按钮（首行专用：AC ( ) % ÷） */
  @Builder BtnOp5(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(this.getOp()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { this.onOp(l) }) }

  /** 科学函数按钮 */
  @Builder BtnFunc(l: string) { Text(l).fontSize(this.isLandscape ? 11 : 14).fontColor(this.getT1()).width('18%').height(this.isLandscape ? 30 : 46).textAlign(TextAlign.Center).backgroundColor(this.getFuncBg()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { this.onFunc(l) }) }

  /** 常量按钮 */
  @Builder BtnConst(l: string) { Text(l).fontSize(this.isLandscape ? 13 : 18).fontColor(this.getOp() === '#B4D2E4' ? '#4684E3' : this.getOp()).width('18%').height(this.isLandscape ? 30 : 46).textAlign(TextAlign.Center).backgroundColor(this.getFuncBg()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { this.onConst(l) }) }

  /** 动作按钮（AC/退格） */
  @Builder BtnAct(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('22%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(l === 'AC' ? this.getClr() : this.getBtnBg()).borderRadius(50).margin(this.isLandscape ? 1 : 4).onClick((): void => { if (l === 'AC') this.onAC(); else this.onBS() }) }

  /** 5 列动作按钮（首行 AC 专用） */
  @Builder BtnAct5(l: string) { Text(l).fontSize(this.isLandscape ? 14 : 20).fontColor(this.getBtnText()).width('18%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(l === 'AC' ? this.getClr() : this.getBtnBg()).borderRadius(50).margin(this.isLandscape ? 1 : 3).onClick((): void => { if (l === 'AC') this.onAC(); else this.onBS() }) }

  /** 等号按钮 */
  @Builder BtnEq() { Text('=').fontSize(this.isLandscape ? 18 : 24).fontWeight(FontWeight.Bold).fontColor(this.getBtnText()).width('22%').height(this.isLandscape ? 36 : 56).textAlign(TextAlign.Center).backgroundColor(this.getEq()).borderRadius(50).margin(this.isLandscape ? 1 : 4).onClick((): void => { this.onEquals() }) }

  // ==================== 历史面板（仿 Android SlidingUpPanelLayout） ====================

  @Builder HistoryPanel() {
    Column() {
      // 拖拽手柄 / 折叠按钮（始终可见，仿 Android sliding_layout_button）
      Row() {
        // 手柄横条
        Text('').width(40).height(4).backgroundColor(this.getT2()).borderRadius(2)
      }
      .width('100%').height(24).justifyContent(FlexAlign.Center)
      .onClick((): void => { this.showHistory = false })

      if (this.history.length === 0) {
        Text('暂无计算记录').fontSize(13).fontColor(this.getT2()).width('100%').textAlign(TextAlign.Center).padding(20)
      } else {
        List() {
          ForEach(this.history, (item: HistoryItem) => {
            ListItem() {
              Column() {
                Text(item.expression).fontSize(12).fontColor(this.getT2()).maxLines(1)
                Text(item.result).fontSize(15).fontWeight(FontWeight.Bold).fontColor(this.getOp())
              }
              .alignItems(HorizontalAlign.Start).width('100%').padding(this.isLandscape ? 8 : 12)
              .onClick((): void => { this.onHistoryTap(item) })
            }
            .swipeAction({ end: { builder: (): void => { this.DelBtn(item) } } })
          })
        }
        .layoutWeight(1)
      }
    }
    .layoutWeight(this.isLandscape ? 1 : 0)
    .width('100%').height(this.isLandscape ? '100%' : 'auto')
    .backgroundColor(this.getPanelBg())
    .borderRadius(this.isLandscape ? 0 : { topLeft: 16, topRight: 16 })
  }

  @Builder DelBtn(item: HistoryItem) {
    Text('删除').fontSize(14).fontColor(this.getT1()).padding(16).backgroundColor(this.getErr()).height('100%')
      .onClick((): void => { this.onHistoryDelete(item) })
  }

  // ==================== 设置面板 ====================
  @Builder SettingsPanel() {
    Column() {
      Row() {
        Text('设置').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getT1())
        Blank()
        Text('✕').fontSize(20).fontColor(this.getT2()).onClick((): void => { this.showSettings = false })
      }.width('100%').padding(16)
      List() {
        ListItem() { this.ToggleItem('振动反馈', this.vibrateOn, (v: boolean): void => { this.vibrateOn = v; this.savePref('vibrateOn', v) }) }
        ListItem() { this.ToggleItem('防休眠', this.preventSleep, (v: boolean): void => { this.preventSleep = v; this.savePref('preventSleep', v) }) }
        ListItem() { this.ToggleItem('弧度模式', this.radianMode, (v: boolean): void => { this.radianMode = v; this.savePref('radianMode', v) }) }
        ListItem() { this.ThemeItem() }
        ListItem() {
          Row() { Text('关于 OpenCalc').fontSize(15).fontColor(this.getT2()); Blank(); Text('>').fontColor(this.getT2()) }
          .width('100%').padding(12).onClick((): void => { this.showSettings = false; this.showAbout = true })
        }
      }
    }
    .width('85%').backgroundColor(this.getPanelBg()).borderRadius(16)
  }

  @Builder ToggleItem(title: string, val: boolean, cb: (v: boolean) => void) {
    Row() {
      Text(title).fontSize(15).fontColor(this.getT1()).layoutWeight(1)
      Toggle({ type: ToggleType.Switch, isOn: val }).onChange((on: boolean): void => { cb(on) })
    }.width('100%').padding(12)
  }

  @Builder ThemeItem() {
    Row() {
      Text('主题').fontSize(15).fontColor(this.getT1()).layoutWeight(1)
      Row() {
        Text('浅色').fontSize(11).fontColor(this.themeIdx === 0 ? '#000' : this.getT2())
          .backgroundColor(this.themeIdx === 0 ? this.getOp() : (this.themeIdx >= 1 ? '#555' : '#DDD'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8).margin({ left: 2 })
          .onClick((): void => { this.themeIdx = 0; this.savePref('themeIdx', 0) })
        Text('暗色').fontSize(11).fontColor(this.themeIdx === 2 ? '#EFEFEF' : this.getT2())
          .backgroundColor(this.themeIdx === 2 ? '#0070BC' : (this.themeIdx >= 1 ? '#555' : '#DDD'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8).margin({ left: 2 })
          .onClick((): void => { this.themeIdx = 2; this.savePref('themeIdx', 2) })
        Text('AMOLED').fontSize(11).fontColor(this.themeIdx === 1 ? '#EFEFEF' : this.getT2())
          .backgroundColor(this.themeIdx === 1 ? '#B3004D' : (this.themeIdx >= 1 ? '#555' : '#DDD'))
          .padding({ left: 8, right: 8, top: 4, bottom: 4 }).borderRadius(8).margin({ left: 2 })
          .onClick((): void => { this.themeIdx = 1; this.savePref('themeIdx', 1) })
      }
    }.width('100%').padding(12)
  }

  // ==================== 关于面板 ====================
  @Builder AboutPanel() {
    Column() {
      Text('关于 OpenCalc').fontSize(18).fontWeight(FontWeight.Bold).fontColor(this.getT1()).padding({ bottom: 12 })
      Text('OpenCalc HarmonyOS').fontSize(14).fontColor(this.getT2())
      Text('版本 1.0.0').fontSize(14).fontColor(this.getT2()).padding({ top: 4 })
      Text('原项目: github.com/clementwzk/OpenCalc').fontSize(11).fontColor(this.getT2()).padding({ top: 8 })
      Text('Android 3.2.1 → HarmonyOS').fontSize(11).fontColor(this.getT2()).padding({ top: 2 })
      Text('迁移: github.com/JungleTestLabs/opencalc-harmonyos').fontSize(11).fontColor(this.getOp()).padding({ top: 4 })
      Button('关闭').margin({ top: 16 }).onClick((): void => { this.showAbout = false })
    }
    .width('80%').padding(24).backgroundColor(this.getPanelBg()).borderRadius(16)
  }
}
