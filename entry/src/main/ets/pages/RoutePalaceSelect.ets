import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

/**
 * 路线宫殿选择页面
 * 选择数据类型、组数和每组的数据类型
 */
@Entry
@Component
struct RoutePalaceSelect {
  @State selectedDataType: string = '110数字桩'; // 选中的数据类型
  @State selectedGroupCount: number = 3; // 选中的组数：3组或4组
  @State groupSelections: string[] = ['桩图像', '桩名称', '桩序号']; // 每组的数据类型选择

  // 数据类型选项
  private readonly dataTypes: string[] = ['110数字桩', '34省', '36计', '三字经'];
  
  // 组数选项
  private readonly groupCounts: number[] = [3, 4];

  /**
   * 根据数据类型获取可选的显示类型
   */
  getDisplayTypesForDataType(dataType: string): string[] {
    if (dataType === '110数字桩') {
      return ['桩图像', '桩名称', '桩序号'];
    } else if (dataType === '34省') {
      return ['省序号', '省全称', '省会', '省简称'];
    } else if (dataType === '36计' || dataType === '三字经') {
      return ['序号', '内容'];
    }
    return [];
  }

  /**
   * 初始化组选择（根据数据类型设置默认值）
   */
  initGroupSelections() {
    const displayTypes = this.getDisplayTypesForDataType(this.selectedDataType);
    this.groupSelections = [];
    for (let i = 0; i < this.selectedGroupCount; i++) {
      // 循环使用显示类型
      this.groupSelections.push(displayTypes[i % displayTypes.length]);
    }
  }

  aboutToAppear() {
    // 初始化组选择
    this.initGroupSelections();
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

        Text('路线宫殿设置')
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

      Scroll() {
        Column() {
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
                      // 重新初始化组选择
                      this.initGroupSelections();
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

          // 选择组数
          Text('设置组数：')
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: 10 })
            .alignSelf(ItemAlign.Start)
            .margin({ left: 20 })

          Row() {
            ForEach(this.groupCounts, (count: number) => {
              Row() {
                Radio({ value: count.toString(), group: 'groupCount' })
                  .checked(this.selectedGroupCount === count)
                  .onChange((isChecked: boolean) => {
                    if (isChecked) {
                      this.selectedGroupCount = count;
                      // 重新初始化组选择
                      this.initGroupSelections();
                    }
                  })
                Text(`${count}组`)
                  .fontSize(16)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ left: 10 })
              }
              .layoutWeight(1)
              .justifyContent(FlexAlign.Center)
            })
          }
          .width('90%')
          .height(50)
          .backgroundColor(Color.White)
          .borderRadius(8)
          .padding({ left: 20, right: 20 })
          .margin({ bottom: 16 })

          // 根据组数显示每组的数据类型选择
          ForEach(this.groupSelections, (selection: string, index: number) => {
            Column() {
              Text(`${index + 1}组数据：`)
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 8 })
                .alignSelf(ItemAlign.Start)

              Row() {
                ForEach(this.getDisplayTypesForDataType(this.selectedDataType), (type: string) => {
                  Row() {
                    Radio({ value: type, group: `group${index}` })
                      .checked(this.groupSelections[index] === type)
                      .onChange((isChecked: boolean) => {
                        if (isChecked) {
                          const newSelections: string[] = [];
                          for (let i = 0; i < this.groupSelections.length; i++) {
                            if (i === index) {
                              newSelections.push(type);
                            } else {
                              newSelections.push(this.groupSelections[i]);
                            }
                          }
                          this.groupSelections = newSelections;
                        }
                      })
                    Text(type)
                      .fontSize(14)
                      .fontColor($r('app.color.text_primary'))
                      .margin({ left: 8 })
                  }
                  .layoutWeight(1)
                  .justifyContent(FlexAlign.Center)
                })
              }
              .width('100%')
              .height(40)
            }
            .width('90%')
            .backgroundColor(Color.White)
            .borderRadius(8)
            .padding({ top: 12, bottom: 12, left: 16, right: 16 })
            .margin({ bottom: 12 })
          })
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .layoutWeight(1)
      .width('100%')

      // 开始按钮
      Button('开始')
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
          
          // 验证组数
          if (this.selectedGroupCount !== 3 && this.selectedGroupCount !== 4) {
            promptAction.showToast({
              message: '请选择有效的组数',
              duration: 2000
            });
            return;
          }

          // 验证每组选择
          if (this.groupSelections.length !== this.selectedGroupCount) {
            promptAction.showToast({
              message: '请为每组选择数据类型',
              duration: 2000
            });
            return;
          }

          // 跳转到路线宫殿游戏页面
          router.pushUrl({
            url: 'pages/RoutePalace',
            params: {
              dataType: this.selectedDataType,
              groupCount: this.selectedGroupCount,
              groupSelections: this.groupSelections
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

