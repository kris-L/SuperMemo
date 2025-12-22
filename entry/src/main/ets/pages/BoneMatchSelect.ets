import { router, promptAction } from '@kit.ArkUI';

/**
 * 骨肉相连 设置页面
 */
@Entry
@Component
struct BoneMatchSelect {
  @State selectedRangeTypes: string[] = ['图像']; // 图像 / 桩序号 / 桩名称（多选）
  @State difficulty: number = 3; // 3-12 图
  @State startNumberText: string = '0';
  @State endNumberText: string = '109';
  private readonly rangeTypes: string[] = ['图像', '桩序号', '桩名称'];
  private readonly difficulties: number[] = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  validateNumber(value: string, isStart: boolean): boolean {
    let num = parseInt(value);
    if (isNaN(num) || value === '') {
      return false;
    }
    if (num < 0 || num > 109) {
      promptAction.showToast({ 
        message: `${isStart ? '起始' : '结束'}范围应在0-109之间`, 
        duration: 2000 
      });
      return false;
    }
    return true;
  }

  validateAndStart() {
    let startNum = parseInt(this.startNumberText);
    let endNum = parseInt(this.endNumberText);
    if (isNaN(startNum) || this.startNumberText === '') {
      promptAction.showToast({ message: '请输入起始范围', duration: 2000 });
      return;
    }
    if (isNaN(endNum) || this.endNumberText === '') {
      promptAction.showToast({ message: '请输入结束范围', duration: 2000 });
      return;
    }
    if (startNum < 0 || startNum > 109) {
      promptAction.showToast({ message: '起始范围应在0-109之间', duration: 2000 });
      return;
    }
    if (endNum < 0 || endNum > 109) {
      promptAction.showToast({ message: '结束范围应在0-109之间', duration: 2000 });
      return;
    }
    if (startNum > endNum) {
      promptAction.showToast({ message: '起始不能大于结束', duration: 2000 });
      return;
    }
    if (this.selectedRangeTypes.length === 0) {
      promptAction.showToast({ message: '请至少选择一个范围类型', duration: 2000 });
      return;
    }
    // 打印rangeTypes的信息
    console.info('选择的数据范围selectedRangeTypes:', this.selectedRangeTypes);
    // 跳转到骨肉相连训练页面
    router.pushUrl({
      url: 'pages/BoneMatch',
      params: {
        rangeTypes: this.selectedRangeTypes,
        difficulty: this.difficulty,
        startNumber: startNum,
        endNumber: endNum
      }
    });
  }

  toggleRangeType(item: string) {
    console.info('选择的数据范围1:', this.selectedRangeTypes);
    const index = this.selectedRangeTypes.indexOf(item);
    if (index >= 0) {
      this.selectedRangeTypes.splice(index, 1);
    } else {
      this.selectedRangeTypes.push(item);
    }
    console.info('选择的数据范围2:', this.selectedRangeTypes);
    // 触发状态更新
    this.selectedRangeTypes = [...this.selectedRangeTypes];
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

        Text('骨肉相连设置')
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
      .margin({ bottom: 10 })

      // 范围
      Column() {
        Text('范围')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })
          .alignSelf(ItemAlign.Start)
          .width('90%')
          .padding({ left: 12 })

        Column() {
          ForEach(this.rangeTypes, (item: string) => {
            Row() {
              Checkbox({ name: item })
                .select(this.selectedRangeTypes.indexOf(item) >= 0)
                .onClick(() => {
                  // 勾选/取消勾选时直接切换选项，补足 Checkbox 不冒泡到 Row 的情况
                  this.toggleRangeType(item);
                })
              Text(item)
                .fontSize(16)
                .fontColor($r('app.color.text_primary'))
                .margin({ left: 8 })
            }
            .width('100%')
            .height(40)
            .justifyContent(FlexAlign.Start)
            .onClick(() => {
              this.toggleRangeType(item);
            })
          })
        }
        .width('90%')
        .alignItems(HorizontalAlign.Start)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 20 })

      // 难度
      Column() {
        Text('难度（图数）')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })
          .alignSelf(ItemAlign.Start)
          .width('90%')
          .padding({ left: 12 })

        Grid() {
          ForEach(this.difficulties, (num: number) => {
            GridItem() {
              Button(`${num}图`)
                .width('100%')
                .height(40)
                .padding(0)
                .backgroundColor(this.difficulty === num ? '#2196F3' : '#FFFFFF')
                .fontColor(this.difficulty === num ? '#FFFFFF' : $r('app.color.text_primary'))
                .fontSize(14)
                .border({ width: 1, color: this.difficulty === num ? '#2196F3' : '#DDDDDD' })
                .borderRadius(12)
                .onClick(() => {
                  this.difficulty = num;
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
        .rowsTemplate('1fr 1fr')
        .columnsGap(10)
        .rowsGap(10)
        .width('90%')
        .height(100)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 20 })

      // 数据区间
      Column() {
        Text('数据区间（0 - 109）')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 10 })
          .alignSelf(ItemAlign.Start)
          .width('90%')
          .padding({ left: 12 })

        Row() {
          Column() {
            Text('起始')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            TextInput({ placeholder: '0', text: this.startNumberText })
              .type(InputType.Number)
              .maxLength(3)
              .width('100%')
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_tertiary'))
              .onChange((val: string) => {
                this.startNumberText = val;
                if (val !== '' && !this.validateNumber(val, true)) {
                  // 验证失败时，如果超出范围，重置为边界值
                  let num = parseInt(val);
                  if (!isNaN(num)) {
                    if (num < 0) {
                      this.startNumberText = '0';
                    } else if (num > 109) {
                      this.startNumberText = '109';
                    }
                  }
                }
              })
          }
          .width('45%')

          Column() {
            Text('结束')
              .fontSize(14)
              .fontColor($r('app.color.text_secondary'))
            TextInput({ placeholder: '109', text: this.endNumberText })
              .type(InputType.Number)
              .maxLength(3)
              .width('100%')
              .fontColor($r('app.color.text_primary'))
              .placeholderColor($r('app.color.text_tertiary'))
              .onChange((val: string) => {
                this.endNumberText = val;
                if (val !== '' && !this.validateNumber(val, false)) {
                  // 验证失败时，如果超出范围，重置为边界值
                  let num = parseInt(val);
                  if (!isNaN(num)) {
                    if (num < 0) {
                      this.endNumberText = '0';
                    } else if (num > 109) {
                      this.endNumberText = '109';
                    }
                  }
                }
              })
          }
          .width('45%')
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .backgroundColor(Color.White)
        .borderRadius(8)
        .padding({ left: 12, right: 12, top: 10, bottom: 10 })
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
      .margin({ bottom: 30 })

      // 开始按钮
      Button('开始')
        .width('90%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#2196F3')
        .onClick(() => {
          this.validateAndStart();
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Center)
    .padding({ top: 10, bottom: 20 })
    .backgroundColor('#F5F5F5')
  }
}


