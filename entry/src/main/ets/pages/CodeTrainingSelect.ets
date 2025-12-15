import { router, AppStorageV2 } from '@kit.ArkUI';

class SelectNumberStats {
  bestAccuracy: number = 0;
  trainCount: number = 0;
}

/**
 * 编码训练选择页面
 */
@Entry
@Component
struct CodeTrainingSelect {
  @State selectedCodeLibrary: string = '谐音桩编码'; // 选中的图片库
  @State bestAccuracy: number = 0;
  @State trainCount: number = 0;
  private stats?: SelectNumberStats;

  // 图片库选项
  private readonly codeLibraries: string[] = ['谐音桩编码'];

  aboutToAppear() {
    const connected: SelectNumberStats | undefined =
      AppStorageV2.connect(SelectNumberStats, 'selectNumberStats', () => new SelectNumberStats());
    this.stats = connected ? connected : new SelectNumberStats();
    this.bestAccuracy = this.stats.bestAccuracy;
    this.trainCount = this.stats.trainCount;
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_back'))
            .width(24)
            .height(24)
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.back();
        })

        Text('编码训练')
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
      .margin({ bottom: 10 })

      // 图片库选择
      Text('图片库选择：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })

      Column() {
        Image($r('app.media.ic_code'))
          .width(40)
          .height(40)
          .margin({ bottom: 10 })
        Text(this.selectedCodeLibrary)
          .fontSize(16)
      }
      .width('90%')
      .height(100)
      .justifyContent(FlexAlign.Center)
      .padding({ top: 15, bottom: 15 })
      .backgroundColor(Color.White)
      .borderRadius(8)
      .margin({ bottom: 30 })

      // 训练模式选择
      Text('训练模式：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })

      Row() {
        // 编码学习
        Column() {
          Image($r('app.media.ic_study'))
            .width(50)
            .height(50)
            .margin({ bottom: 8 })
          Text('编码学习')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 5 })
          Text('自动播放110的编码，系统学习')
            .fontSize(12)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
          // 占位空间，确保与看图选数对齐
          Row()
            .width('100%')
            .height(20)
        }
        .width('48%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .padding(15)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .border({ width: 2, color: '#2196F3' })
        .onClick(() => {
          // TODO: 跳转到编码学习页面
          router.pushUrl({ url: 'pages/CodeStudy' });
        })

        // 看图选数
        Column() {
          Image($r('app.media.ic_select_number'))
            .width(50)
            .height(50)
            .margin({ bottom: 8 })
          Text('看图选数')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .margin({ bottom: 5 })
          Text('看桩图片，选择对应的数字')
            .fontSize(12)
            .fontColor('#666666')
            .textAlign(TextAlign.Center)
            .margin({ bottom: 5 })
          
          // 记录信息（仅看图选数显示，水平显示）
          Row() {
            Text('最佳：')
              .fontSize(11)
              .fontColor('#666666')
            Text(`${this.bestAccuracy}%`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
            
            Text('  训练：')
              .fontSize(11)
              .fontColor('#666666')
              .margin({ left: 8 })
            Text(`${this.trainCount}次`)
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
          }
          .width('100%')
          .height(20)
          .justifyContent(FlexAlign.Center)
        }
        .width('48%')
        .aspectRatio(1)
        .justifyContent(FlexAlign.Center)
        .padding(15)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .border({ width: 2, color: '#2196F3' })
        .onClick(() => {
          // TODO: 跳转到看图选数页面
          router.pushUrl({ url: 'pages/SelectNumber' });
        })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 30 })

      // 返回按钮
      Button('返回')
        .width('80%')
        .height(50)
        .fontSize(18)
        .backgroundColor('#9E9E9E')
        .onClick(() => {
          router.back();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 20 })
    .backgroundColor('#F5F5F5')
  }
}

