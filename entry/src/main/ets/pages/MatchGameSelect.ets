import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

/**
 * 连连看选择页面
 * 选择数据类型和配对数据
 */
@Entry
@Component
struct MatchGameSelect {
  @State selectedDataType: string = '110数字桩'; // 选中的数据类型
  @State selectedMatchTypes: string[] = ['桩序号', '桩图像']; // 选中的配对数据类型（必须选择两个）

  // 数据类型选项
  private readonly dataTypes: string[] = ['110数字桩', '34省', '36计', '三字经'];
  
  // 配对数据类型选项（110数字桩）
  private readonly matchTypes110: string[] = ['桩序号', '桩图像', '桩名称'];

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
                  // 如果不是110数字桩，重置配对类型
                  if (item !== '110数字桩') {
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

      // 选择配对数据类型（仅110数字桩显示）
      if (this.selectedDataType === '110数字桩') {
        Text('选择配对数据：')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 15 })
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20 })

        Column() {
          ForEach(this.matchTypes110, (item: string) => {
            Row() {
              Checkbox({ name: item })
                .select(this.selectedMatchTypes.includes(item))
                .onChange((isChecked: boolean) => {
                  const isCurrentlySelected = this.selectedMatchTypes.includes(item);
                  
                  if (isChecked && !isCurrentlySelected) {
                    // 尝试选中
                    if (this.selectedMatchTypes.length >= 2) {
                      // 已经选择了两个，提示用户并拒绝操作
                      promptAction.showToast({
                        message: '最多只能选择两个配对类型，请先取消一个',
                        duration: 2000
                      });
                      // 强制触发状态更新，确保checkbox保持未选中状态
                      // 通过创建新数组（即使内容相同）来触发UI刷新
                      const newSelectedTypes: string[] = [];
                      for (let i = 0; i < this.selectedMatchTypes.length; i++) {
                        newSelectedTypes.push(this.selectedMatchTypes[i]);
                      }
                      this.selectedMatchTypes = newSelectedTypes;
                      return;
                    }
                    // 添加到选中列表（创建新数组以触发UI更新）
                    const newSelectedTypes: string[] = [];
                    for (let i = 0; i < this.selectedMatchTypes.length; i++) {
                      newSelectedTypes.push(this.selectedMatchTypes[i]);
                    }
                    newSelectedTypes.push(item);
                    this.selectedMatchTypes = newSelectedTypes;
                  } else if (!isChecked && isCurrentlySelected) {
                    // 取消选中（创建新数组以触发UI更新）
                    const newSelectedTypes: string[] = [];
                    for (let i = 0; i < this.selectedMatchTypes.length; i++) {
                      if (this.selectedMatchTypes[i] !== item) {
                        newSelectedTypes.push(this.selectedMatchTypes[i]);
                      }
                    }
                    this.selectedMatchTypes = newSelectedTypes;
                  } else if (isChecked && isCurrentlySelected) {
                    // 如果已经是选中状态，但onChange被触发（可能是用户重复点击），不做任何操作
                    return;
                  } else if (!isChecked && !isCurrentlySelected) {
                    // 如果已经是未选中状态，但onChange被触发，不做任何操作
                    return;
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
      if (this.selectedDataType === '110数字桩') {
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
        .onClick(() => {
          if (this.selectedDataType !== '110数字桩') {
            promptAction.showToast({
              message: '请选择110数字桩',
              duration: 2000
            });
            return;
          }
          if (this.selectedMatchTypes.length !== 2) {
            promptAction.showToast({
              message: '请选择两个配对类型',
              duration: 2000
            });
            return;
          }
          router.pushUrl({
            url: 'pages/MatchGame',
            params: {
              dataType: this.selectedDataType,
              matchType1: this.selectedMatchTypes[0],
              matchType2: this.selectedMatchTypes[1]
            }
          });
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

