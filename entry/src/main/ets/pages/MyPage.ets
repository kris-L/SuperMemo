import { router } from '@kit.ArkUI';

/**
 * 我的页面
 */
@Component
export struct MyPage {
  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('我的')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)

        Blank()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 20 })

      // 内容区域
      Column() {
        Text('我的功能开发中...')
          .fontSize(16)
          .fontColor('#666666')
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

