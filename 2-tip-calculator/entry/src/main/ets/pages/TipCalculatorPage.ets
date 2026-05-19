// OpenCalc - 小费计算器页面
// 设计文档: specs/changes/20260519-requirement-add-tip-calculator/delta-design.md §3.6
import { router } from '@kit.ArkUI'
import { hilog } from '@kit.PerformanceAnalysisKit'
import { TipCalculator } from '../calculator/TipCalculator'

@Entry
@Component
struct TipCalculatorPage {
  @State amountText: string = ''
  @State peopleText: string = ''
  @State tipPercent: number = 15
  @State isCustomMode: boolean = false
  @State customTipText: string = ''

  private static readonly TIERS: number[] = [10, 15, 18, 20]

  private computePerPerson(): string {
    const amount: number = parseFloat(this.amountText)
    const people: number = parseInt(this.peopleText, 10)
    const tip: number = this.isCustomMode ? parseFloat(this.customTipText) : this.tipPercent
    return TipCalculator.calcPerPerson(amount, people, tip)
  }

  private goBack(): void {
    router.back()
  }

  build() {
    Column() {
      this.Header()
      Scroll() {
        Column() {
          this.AmountInput()
          this.PeopleInput()
          this.TipTierRow()
          if (this.isCustomMode) {
            this.CustomTipInput()
          }
          this.ResultPanel()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 16 })
      }
      .layoutWeight(1)
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }

  @Builder Header() {
    Row() {
      Text('← 返回')
        .fontSize(14)
        .fontColor('#595959')
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .onClick((): void => { this.goBack() })
      Blank()
      Text('小费计算器')
        .fontSize(20)
        .fontColor('#000000')
        .fontWeight(FontWeight.Medium)
      Blank()
      Text('  ')
        .fontSize(14)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .border({ width: { bottom: 1 }, color: '#E8E8E8' })
  }

  @Builder AmountInput() {
    Column() {
      Text('账单金额')
        .fontSize(14)
        .fontColor('#595959')
        .margin({ top: 12, bottom: 6 })
        .alignSelf(ItemAlign.Start)
      TextInput({ placeholder: '请输入金额', text: this.amountText })
        .type(InputType.NUMBER_DECIMAL)
        .inputFilter('^\\d*\\.?\\d{0,2}$', (err: string): void => {
          hilog.warn(0x0000, 'TipCalc', `amount filter rejected: %{public}s`, err)
        })
        .maxLength(15)
        .fontSize(20)
        .height(48)
        .backgroundColor('#EFEFEF')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((value: string): void => { this.amountText = value })
    }
    .width('100%')
  }

  @Builder PeopleInput() {
    Column() {
      Text('就餐人数')
        .fontSize(14)
        .fontColor('#595959')
        .margin({ top: 12, bottom: 6 })
        .alignSelf(ItemAlign.Start)
      TextInput({ placeholder: '请输入人数', text: this.peopleText })
        .type(InputType.Number)
        .inputFilter('^\\d*$', (err: string): void => {
          hilog.warn(0x0000, 'TipCalc', `people filter rejected: %{public}s`, err)
        })
        .maxLength(3)
        .fontSize(20)
        .height(48)
        .backgroundColor('#EFEFEF')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((value: string): void => { this.peopleText = value })
    }
    .width('100%')
  }

  @Builder TipTierRow() {
    Column() {
      Text('小费率')
        .fontSize(14)
        .fontColor('#595959')
        .margin({ top: 12, bottom: 6 })
        .alignSelf(ItemAlign.Start)
      Row() {
        ForEach(TipCalculatorPage.TIERS, (tier: number): void => {
          this.TierButton(tier)
        }, (tier: number): string => `${tier}`)
        this.CustomButton()
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width('100%')
  }

  @Builder TierButton(tier: number) {
    Text(`${tier}%`)
      .fontSize(14)
      .fontColor(!this.isCustomMode && this.tipPercent === tier ? '#FFFFFF' : '#000000')
      .height(40)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(!this.isCustomMode && this.tipPercent === tier ? '#B4D2E4' : '#EFEFEF')
      .borderRadius(12)
      .margin({ right: 8 })
      .onClick((): void => {
        this.tipPercent = tier
        this.isCustomMode = false
      })
  }

  @Builder CustomButton() {
    Text('自定义')
      .fontSize(14)
      .fontColor(this.isCustomMode ? '#FFFFFF' : '#000000')
      .height(40)
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .backgroundColor(this.isCustomMode ? '#B4D2E4' : '#EFEFEF')
      .borderRadius(12)
      .onClick((): void => {
        this.isCustomMode = true
      })
  }

  @Builder CustomTipInput() {
    Column() {
      Text('自定义小费率 (%)')
        .fontSize(14)
        .fontColor('#595959')
        .margin({ top: 12, bottom: 6 })
        .alignSelf(ItemAlign.Start)
      TextInput({ placeholder: '0 - 100', text: this.customTipText })
        .type(InputType.NUMBER_DECIMAL)
        .inputFilter('^\\d{0,3}(\\.\\d{0,2})?$', (err: string): void => {
          hilog.warn(0x0000, 'TipCalc', `customTip filter rejected: %{public}s`, err)
        })
        .maxLength(6)
        .fontSize(20)
        .height(48)
        .backgroundColor('#EFEFEF')
        .borderRadius(12)
        .padding({ left: 12, right: 12 })
        .onChange((value: string): void => { this.customTipText = value })
    }
    .width('100%')
  }

  @Builder ResultPanel() {
    Column() {
      Text('每人应付')
        .fontSize(14)
        .fontColor('#595959')
        .margin({ top: 24, bottom: 8 })
      Text(this.computePerPerson())
        .fontSize(36)
        .fontColor('#000000')
        .fontWeight(FontWeight.Bold)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
  }
}
