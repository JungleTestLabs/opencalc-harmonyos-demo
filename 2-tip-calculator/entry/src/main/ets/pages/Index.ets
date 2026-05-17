// OpenCalc — 导航入口页
// 增量需求：2-tip-calculator
// 从自动跳转改为导航菜单，支持计算器和小费计算器
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Index {
  // 颜色定义（与主计算器一致）
  private colorBg: string = '#0f0f1a'
  private colorCard: string = '#1a1a2e'
  private colorPrimary: string = '#e94560'
  private colorText: string = '#ffffff'
  private colorTextDim: string = '#a0a0b0'
  private colorBtn: string = '#2a2a45'

  private openCalculator(): void {
    router.pushUrl({ url: 'pages/CalculatorPage' })
  }

  private openTipCalculator(): void {
    router.pushUrl({ url: 'pages/TipCalculatorPage' })
  }

  build() {
    Column() {
      // Logo 区域
      Column() {
        Text('🔢')
          .fontSize(48)
          .margin({ bottom: 12 })

        Text('OpenCalc')
          .fontSize(28)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.colorText)

        Text('科学计算器 · HarmonyOS 版')
          .fontSize(14)
          .fontColor(this.colorTextDim)
          .margin({ top: 4 })
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // 导航按钮
      Column() {
        // 计算器按钮
        Row() {
          Text('🔢')
            .fontSize(24)
            .margin({ right: 12 })
          Column() {
            Text('标准计算器')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colorText)
            Text('科学计算 · 历史记录 · 多主题')
              .fontSize(12)
              .fontColor(this.colorTextDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Text('→')
            .fontSize(20)
            .fontColor(this.colorTextDim)
        }
        .width('100%')
        .height(64)
        .backgroundColor(this.colorCard)
        .borderRadius(14)
        .padding({ left: 20, right: 20 })
        .onClick(() => { this.openCalculator() })

        Blank().height(12)

        // 小费计算器按钮
        Row() {
          Text('💰')
            .fontSize(24)
            .margin({ right: 12 })
          Column() {
            Text('小费计算器')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.colorText)
            Text('账单分摊 · 多种比例 · 即时计算')
              .fontSize(12)
              .fontColor(this.colorTextDim)
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          // NEW 标签
          Text('NEW')
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#ffffff')
            .backgroundColor(this.colorPrimary)
            .borderRadius(8)
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .margin({ right: 8 })

          Text('→')
            .fontSize(20)
            .fontColor(this.colorTextDim)
        }
        .width('100%')
        .height(64)
        .backgroundColor(this.colorCard)
        .borderRadius(14)
        .padding({ left: 20, right: 20 })
        .onClick(() => { this.openTipCalculator() })
      }
      .width('100%')
      .padding({ left: 24, right: 24, bottom: 40 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.colorBg)
  }
}
