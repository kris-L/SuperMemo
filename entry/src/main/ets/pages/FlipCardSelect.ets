import { router, promptAction } from '@kit.ArkUI';

/**
 * 翻翻看设置页面
 * 选择数据类型和配对项
 */
@Entry
@Component
struct FlipCardSelect {
  @State selectedDataType: string = '110数字桩'; // 选中的数据类型
  @State selectedPairType1: string = '桩序号'; // 选中的配对项一
  @State selectedPairType2: string = '桩图像'; // 选中的配对项二

  // 数据类型选项
  private readonly dataTypes: string[] = ['110数字桩', '34省', '36计', '三字经'];

  // 配对数据类型选项（110数字桩）
  private readonly matchTypes110: string[] = ['桩序号', '桩图像', '桩名称'];

  // 配对数据类型选项（34省）
  private readonly matchTypes34: string[] = ['省序号', '省全称', '省会', '省简称'];

  // 获取当前数据类型的配对选项
  private getCurrentMatchTypes(): string[] {
    if (this.selectedDataType === '110数字桩') {
      return this.matchTypes110;
    } else if (this.selectedDataType === '34省') {
      return this.matchTypes34;
    } else if (this.selectedDataType === '36计' || this.selectedDataType === '三字经') {
      return ['序号', '内容'];
    }
    return [];
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

        Text('翻翻看设置')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()
          .width(44)
          .height(44)
      }
      .width('100%')
      .height(56)
      .padding({ left: 12, right: 12 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 8 })

      // 选择数据类型
      Text('选择数据类型：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })

      Column() {
        ForEach(this.dataTypes, (item: string) => {
          Row() {
            Radio({ value: item, group: 'dataType' })
              .checked(this.selectedDataType === item)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedDataType = item;
                  // 根据数据类型设置默认配对类型
                  const matchTypes = this.getCurrentMatchTypes();
                  if (matchTypes.length >= 2) {
                    this.selectedPairType1 = matchTypes[0];
                    this.selectedPairType2 = matchTypes[1];
                  } else if (matchTypes.length >= 1) {
                    this.selectedPairType1 = matchTypes[0];
                    this.selectedPairType2 = matchTypes[0];
                  }
                }
              })
            Text(item)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .margin({ left: 10 })
          }
          .width('100%')
          .height(42)
          .justifyContent(FlexAlign.Start)
          .padding({ left: 20 })
        })
      }
      .width('90%')
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding({ top: 8, bottom: 8 })
      .margin({ bottom: 16 })

      // 选择配对项（水平布局）
      Text('选择配对项：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.text_primary'))
        .margin({ bottom: 10 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })

      Row() {
        // 配对项一
        Column() {
          Text('配对项一')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 8 })
          
          Column() {
            ForEach(this.getCurrentMatchTypes(), (item: string) => {
              Row() {
                Radio({ value: item, group: 'pairType1' })
                  .checked(this.selectedPairType1 === item)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedPairType1 = item;
                    }
                  })
                Text(item)
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ left: 10 })
              }
              .width('100%')
              .height(42)
              .justifyContent(FlexAlign.Start)
              .padding({ left: 12 })
            })
          }
          .width('100%')
        }
        .width('48%')
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ top: 12, bottom: 12, left: 8, right: 8 })

        // 配对项二
        Column() {
          Text('配对项二')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 8 })
          
          Column() {
            ForEach(this.getCurrentMatchTypes(), (item: string) => {
              Row() {
                Radio({ value: item, group: 'pairType2' })
                  .checked(this.selectedPairType2 === item)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedPairType2 = item;
                    }
                  })
                Text(item)
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ left: 10 })
              }
              .width('100%')
              .height(42)
              .justifyContent(FlexAlign.Start)
              .padding({ left: 12 })
            })
          }
          .width('100%')
        }
        .width('48%')
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ top: 12, bottom: 12, left: 8, right: 8 })
      }
      .width('90%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({ bottom: 16 })

      // 提示信息
      Text(`已选择配对类型：${this.selectedPairType1} ↔ ${this.selectedPairType2}`)
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      // 开始按钮
      Button('开始游戏')
        .width('80%')
        .height(45)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#2196F3')
        .onClick(() => {
          // 验证数据类型
          if (this.selectedDataType !== '110数字桩' &&
            this.selectedDataType !== '34省' &&
            this.selectedDataType !== '36计' &&
            this.selectedDataType !== '三字经') {
            promptAction.showToast({
              message: '请选择有效的数据类型',
              duration: 2000
            });
            return;
          }

          router.pushUrl({
            url: 'pages/FlipCard',
            params: {
              dataType: this.selectedDataType,
              pairType1: this.selectedPairType1,
              pairType2: this.selectedPairType2
            }
          });
        })
        .margin({ bottom: 20 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 16 })
    .backgroundColor('#F5F5F5')
  }
}

