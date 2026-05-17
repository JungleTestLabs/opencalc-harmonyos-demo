// OpenCalc — 小费计算器页面
// 增量需求：2-tip-calculator
// 输入账单金额 + 小费比例 + 人数 → 自动计算每人应付
import { router } from '@kit.ArkUI'

@Entry
@Component
export struct TipCalculatorPage {
  // ==================== 输入状态 ====================
  @State amount: string = ''
  @State tipPercent: number = 15
  @State customTip: string = ''
  @State people: string = ''
  @State useCustomTip: boolean = false

  // ==================== 计算结果 ====================
  @State tipAmount: string = ''
  @State totalAmount: string = ''
  @State perPerson: string = ''
  @State errorMsg: string = ''

  // ==================== 预设比例 ====================
  private tipPresets: number[] = [10, 15, 18, 20]

  // ==================== 颜色定义（与主计算器一致）====================
  private colorBg: string = '#0f0f1a'
  private colorCard: string = '#1a1a2e'
  private colorPrimary: string = '#e94560'
  private colorPrimaryDim: string = '#b8304f'
  private colorText: string = '#ffffff'
  private colorTextDim: string = '#a0a0b0'
  private colorInput: string = '#252540'
  private colorBtn: string = '#2a2a45'
  private colorBtnActive: string = '#e94560'
  private colorSuccess: string = '#00e676'
  private colorError: string = '#ff5252'

  // ==================== 计算方法 ====================
  private calculate(): void {
    this.errorMsg = ''

    // 输入验证
    const amt: number = parseFloat(this.amount)
    if (isNaN(amt) || this.amount.trim().length === 0) {
      this.errorMsg = '请输入账单金额'
      this.clearResults()
      return
    }
    if (amt <= 0) {
      this.errorMsg = '金额必须大于 0'
      this.clearResults()
      return
    }

    const ppl: number = parseInt(this.people)
    if (isNaN(ppl) || this.people.trim().length === 0) {
      this.errorMsg = '请输入人数'
      this.clearResults()
      return
    }
    if (ppl <= 0) {
      this.errorMsg = '人数必须大于 0'
      this.clearResults()
      return
    }

    // 获取小费比例
    let tip: number = this.tipPercent
    if (this.useCustomTip) {
      const custom: number = parseFloat(this.customTip)
      if (isNaN(custom) || custom < 0) {
        this.errorMsg = '请输入有效的小费比例'
        this.clearResults()
        return
      }
      tip = custom
    }

    // 计算结果
    const tipVal: number = amt * tip / 100
    const totalVal: number = amt + tipVal
    const perVal: number = totalVal / ppl

    this.tipAmount = this.formatCurrency(tipVal)
    this.totalAmount = this.formatCurrency(totalVal)
    this.perPerson = this.formatCurrency(perVal)
  }

  private clearResults(): void {
    this.tipAmount = ''
    this.totalAmount = ''
    this.perPerson = ''
  }

  private formatCurrency(val: number): string {
    return val.toFixed(2)
  }

  // ==================== 事件处理 ====================
  private onTipSelect(pct: number): void {
    this.useCustomTip = false
    this.tipPercent = pct
    this.calculate()
  }

  private onCustomTipInput(): void {
    this.useCustomTip = true
    this.calculate()
  }

  private onAmountChange(value: string): void {
    // 只允许数字和小数点
    const filtered: string = value.replace(/[^0-9.]/g, '')
    // 防止多个小数点
    const parts: string[] = filtered.split('.')
    if (parts.length > 2) {
      this.amount = parts[0] + '.' + parts.slice(1).join('')
    } else {
      this.amount = filtered
    }
    if (this.amount.length > 0) {
      this.calculate()
    }
  }

  private onPeopleChange(value: string): void {
    // 只允许整数
    const filtered: string = value.replace(/[^0-9]/g, '')
    this.people = filtered
    if (this.people.length > 0) {
      this.calculate()
    }
  }

  private onBack(): void {
    router.back()
  }

  // ==================== UI 构建器 ====================
  @Builder
  Header() {
    Row() {
      Text('←')
        .fontSize(24)
        .fontColor(this.colorText)
        .width(40)
        .height(40)
        .textAlign(TextAlign.Center)
        .borderRadius(20)
        .backgroundColor(this.colorBtn)
        .onClick(() => { this.onBack() })

      Text('💰 小费计算器')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.colorText)
        .margin({ left: 12 })

      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 8 })
  }

  @Builder
  AmountInput() {
    Column() {
      Text('账单金额')
        .fontSize(14)
        .fontColor(this.colorTextDim)
        .margin({ bottom: 8 })

      Row() {
        Text('¥')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colorPrimary)
          .margin({ right: 8 })

        TextInput({ text: this.amount, placeholder: '0.00' })
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colorText)
          .placeholderColor(this.colorTextDim)
          .backgroundColor(Color.Transparent)
          .type(InputType.Number)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => { this.onAmountChange(value) })
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.colorInput)
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  TipSelector() {
    Column() {
      Text('小费比例')
        .fontSize(14)
        .fontColor(this.colorTextDim)
        .margin({ bottom: 8 })

      Row() {
        ForEach(this.tipPresets, (pct: number) => {
          Text(`${pct}%`)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(this.tipPercent === pct && !this.useCustomTip ? '#ffffff' : this.colorTextDim)
            .width('22%')
            .height(44)
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor(this.tipPercent === pct && !this.useCustomTip ? this.colorBtnActive : this.colorBtn)
            .margin({ right: 8 })
            .onClick(() => { this.onTipSelect(pct) })
        })

        Text('自定义')
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.useCustomTip ? '#ffffff' : this.colorTextDim)
          .width('22%')
          .height(44)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
          .backgroundColor(this.useCustomTip ? this.colorBtnActive : this.colorBtn)
          .onClick(() => {
            this.useCustomTip = true
            this.calculate()
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)

      if (this.useCustomTip) {
        Row() {
          TextInput({ text: this.customTip, placeholder: '输入比例' })
            .fontSize(16)
            .fontColor(this.colorText)
            .placeholderColor(this.colorTextDim)
            .backgroundColor(Color.Transparent)
            .type(InputType.Number)
            .border({ width: 0 })
            .layoutWeight(1)
            .onChange((value: string) => {
              this.customTip = value
              this.calculate()
            })

          Text('%')
            .fontSize(16)
            .fontColor(this.colorPrimary)
            .margin({ left: 8 })
        }
        .width('100%')
        .height(44)
        .backgroundColor(this.colorInput)
        .borderRadius(10)
        .padding({ left: 16, right: 16 })
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  PeopleInput() {
    Column() {
      Text('用餐人数')
        .fontSize(14)
        .fontColor(this.colorTextDim)
        .margin({ bottom: 8 })

      Row() {
        Text('👥')
          .fontSize(22)
          .margin({ right: 8 })

        TextInput({ text: this.people, placeholder: '1' })
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colorText)
          .placeholderColor(this.colorTextDim)
          .backgroundColor(Color.Transparent)
          .type(InputType.Number)
          .border({ width: 0 })
          .layoutWeight(1)
          .onChange((value: string) => { this.onPeopleChange(value) })
      }
      .width('100%')
      .height(56)
      .backgroundColor(this.colorInput)
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  ResultCard() {
    Column() {
      if (this.errorMsg.length > 0) {
        Text(this.errorMsg)
          .fontSize(14)
          .fontColor(this.colorError)
          .textAlign(TextAlign.Center)
          .width('100%')
          .padding(16)
      } else if (this.perPerson.length > 0) {
        // 每人应付 - 主结果显示
        Column() {
          Text('每人应付')
            .fontSize(13)
            .fontColor(this.colorTextDim)
            .margin({ bottom: 4 })

          Row() {
            Text('¥')
              .fontSize(20)
              .fontColor(this.colorSuccess)
              .margin({ right: 4 })
            Text(this.perPerson)
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.colorSuccess)
          }

          Divider()
            .color('#3a3a55')
            .margin({ top: 12, bottom: 12 })

          // 明细
          Row() {
            Column() {
              Text('小费')
                .fontSize(12)
                .fontColor(this.colorTextDim)
                .margin({ bottom: 2 })
              Text(`¥${this.tipAmount}`)
                .fontSize(16)
                .fontColor(this.colorText)
            }
            .layoutWeight(1)

            Column() {
              Text('总计')
                .fontSize(12)
                .fontColor(this.colorTextDim)
                .margin({ bottom: 2 })
              Text(`¥${this.totalAmount}`)
                .fontSize(16)
                .fontColor(this.colorText)
            }
            .layoutWeight(1)

            Column() {
              Text('人数')
                .fontSize(12)
                .fontColor(this.colorTextDim)
                .margin({ bottom: 2 })
              Text(`${this.people || '1'}`)
                .fontSize(16)
                .fontColor(this.colorText)
            }
            .layoutWeight(1)
          }
          .width('100%')
        }
        .width('100%')
        .padding(20)
      }
    }
    .width('100%')
    .backgroundColor(this.colorCard)
    .borderRadius(16)
    .padding(this.perPerson.length > 0 || this.errorMsg.length > 0 ? 0 : 24)
    .margin({ left: 16, right: 16, top: 16 })
  }

  // ==================== 主构建 ====================
  build() {
    Column() {
      this.Header()

      Scroll() {
        Column() {
          this.AmountInput()
          this.TipSelector()
          this.PeopleInput()
          this.ResultCard()
        }
        .width('100%')
        .padding({ bottom: 32 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colorBg)
  }
}
