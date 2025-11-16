import { router } from '@kit.ArkUI';

/**
 * 连连看选择页面
 * 选择数据类型和配对数据
 */
@Entry
@Component
struct MatchGameSelect {
  @State selectedDataType: string = '101数字桩'; // 选中的数据类型
  @State selectedMatchTypes: string[] = ['桩序号', '桩图像']; // 选中的配对数据类型（必须选择两个）

  // 数据类型选项
  private readonly dataTypes: string[] = ['101数字桩', '34省', '36计', '三字经'];
  
  // 配对数据类型选项（101数字桩）
  private readonly matchTypes101: string[] = ['桩序号', '桩图像', '桩名称'];

  build() {
    Column() {
      // 标题
      Text('连连看设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })

      // 选择数据类型
      Text('选择数据类型：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 })
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
                  // 如果不是101数字桩，重置配对类型
                  if (item !== '101数字桩') {
                    this.selectedMatchTypes = [];
                  } else {
                    // 默认选择前两个
                    this.selectedMatchTypes = ['桩序号', '桩图像'];
                  }
                }
              })
            Text(item)
              .fontSize(16)
              .margin({ left: 10 })
          }
          .width('100%')
          .height(50)
          .justifyContent(FlexAlign.Start)
          .padding({ left: 20 })
        })
      }
      .width('90%')
      .backgroundColor(Color.White)
      .borderRadius(8)
      .padding({ top: 10, bottom: 10 })
      .margin({ bottom: 30 })

      // 选择配对数据类型（仅101数字桩显示）
      if (this.selectedDataType === '101数字桩') {
        Text('选择配对数据：')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 15 })
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20 })

        Column() {
          ForEach(this.matchTypes101, (item: string) => {
            Row() {
              Checkbox({ name: item })
                .select(this.selectedMatchTypes.includes(item))
                .onChange((isChecked: boolean) => {
                  if (isChecked) {
                    // 如果已选择两个，需要先取消第一个，再选择新的
                    if (this.selectedMatchTypes.length >= 2) {
                      // 移除第一个选中的
                      this.selectedMatchTypes.shift();
                    }
                    // 添加到选中列表
                    if (!this.selectedMatchTypes.includes(item)) {
                      this.selectedMatchTypes.push(item);
                    }
                  } else {
                    // 如果只有两个，不允许取消（必须保持两个）
                    if (this.selectedMatchTypes.length <= 2) {
                      // 不允许取消，自动选择第一个未选中的来替代
                      for (const type of this.matchTypes101) {
                        if (!this.selectedMatchTypes.includes(type) && type !== item) {
                          const index = this.selectedMatchTypes.indexOf(item);
                          if (index > -1) {
                            this.selectedMatchTypes[index] = type;
                          }
                          break;
                        }
                      }
                    }
                  }
                })
              Text(item)
                .fontSize(16)
                .margin({ left: 10 })
              
              // 显示选中状态提示
              if (this.selectedMatchTypes.includes(item)) {
                Text('✓')
                  .fontSize(16)
                  .fontColor('#4CAF50')
                  .margin({ left: 10 })
              }
            }
            .width('100%')
            .height(50)
            .justifyContent(FlexAlign.Start)
            .padding({ left: 20 })
          })
        }
        .width('90%')
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ top: 10, bottom: 10 })
        .margin({ bottom: 30 })
      } else {
        // 其他数据类型提示
        Text('该数据类型功能开发中...')
          .fontSize(16)
          .fontColor('#999999')
          .margin({ bottom: 30 })
      }

      // 提示信息
      if (this.selectedDataType === '101数字桩') {
        Text(`已选择配对类型：${this.selectedMatchTypes.join(' ↔ ')}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 10 })
      }

      // 开始按钮
      Button('开始游戏')
        .width('80%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#4CAF50')
        .enabled(this.selectedDataType === '101数字桩' && this.selectedMatchTypes.length === 2)
        .onClick(() => {
          if (this.selectedDataType === '101数字桩' && this.selectedMatchTypes.length === 2) {
            router.pushUrl({
              url: 'pages/MatchGame',
              params: {
                dataType: this.selectedDataType,
                matchType1: this.selectedMatchTypes[0],
                matchType2: this.selectedMatchTypes[1]
              }
            });
          }
        })
        .margin({ bottom: 20 })

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

