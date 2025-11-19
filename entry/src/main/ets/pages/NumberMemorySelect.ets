import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';

/**
 * 数字记忆设置页面
 */
@Entry
@Component
struct NumberMemorySelect {
  @State selectedRange: string = '随机数字'; // 选中的范围类型
  @State rowCount: number = 10; // 行数（随机数字用）
  @State digitsPerRow: number = 5; // 每行个数（随机数字用）
  @State trainingCount: number = 1; // 训练次数（随机数字用）
  @State rowCountText: string = '10'; // 行数输入文本
  @State digitsPerRowText: string = '5'; // 每行个数输入文本
  @State trainingCountText: string = '1'; // 训练次数输入文本
  @State piStartDigit: number = 1; // 圆周率开始位数
  @State piEndDigit: number = 100; // 圆周率结束位数
  @State piStartDigitText: string = '1'; // 圆周率开始位数输入文本
  @State piEndDigitText: string = '100'; // 圆周率结束位数输入文本

  // 范围类型选项
  private readonly rangeTypes: string[] = ['随机数字', '圆周率'];

  build() {
    Column() {
      // 标题
      Text('数字记忆设置')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })

      // 选择范围类型
      Text('设置范围：')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .margin({ bottom: 15 })
        .alignSelf(ItemAlign.Start)
        .margin({ left: 20 })

      Column() {
        ForEach(this.rangeTypes, (item: string) => {
          Row() {
            Radio({ value: item, group: 'rangeType' })
              .checked(this.selectedRange === item)
              .onChange((isChecked: boolean) => {
                if (isChecked) {
                  this.selectedRange = item;
                  // 如果切换到圆周率，重置相关值
                  if (item === '圆周率') {
                    this.digitsPerRow = 10;
                    this.digitsPerRowText = '10';
                    this.trainingCount = 1;
                    this.trainingCountText = '1';
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

      // 根据选择类型显示不同的设置项
      if (this.selectedRange === '随机数字') {
        // 随机数字：设置行数
        Row() {
          Text('设置行数：')
            .fontSize(16)
            .width('30%')
          TextInput({ placeholder: '1-1000', text: this.rowCountText })
            .type(InputType.Number)
            .maxLength(4)
            .width('40%')
            .onChange((value: string) => {
              // 限制输入值
              let num = parseInt(value);
              if (isNaN(num) || num < 1) {
                num = 1;
              } else if (num > 1000) {
                num = 1000;
                this.rowCountText = '1000';
              } else {
                this.rowCountText = value;
              }
              this.rowCount = num;
            })
          Text(`当前: ${this.rowCount}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 设置每行个数
        Row() {
          Text('每行个数：')
            .fontSize(16)
            .width('30%')
          TextInput({ placeholder: '1-10', text: this.digitsPerRowText })
            .type(InputType.Number)
            .maxLength(2)
            .width('40%')
            .onChange((value: string) => {
              // 限制输入值
              let num = parseInt(value);
              if (isNaN(num) || num < 1) {
                num = 1;
              } else if (num > 10) {
                num = 10;
                this.digitsPerRowText = '10';
              } else {
                this.digitsPerRowText = value;
              }
              this.digitsPerRow = num;
            })
          Text(`当前: ${this.digitsPerRow}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 设置训练次数
        Row() {
          Text('训练次数：')
            .fontSize(16)
            .width('30%')
          TextInput({ placeholder: '1-1000', text: this.trainingCountText })
            .type(InputType.Number)
            .maxLength(4)
            .width('40%')
            .onChange((value: string) => {
              // 限制输入值
              let num = parseInt(value);
              if (isNaN(num) || num < 1) {
                num = 1;
              } else if (num > 1000) {
                num = 1000;
                this.trainingCountText = '1000';
              } else {
                this.trainingCountText = value;
              }
              this.trainingCount = num;
            })
          Text(`当前: ${this.trainingCount}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 30 })
      } else {
        // 圆周率：开始位数
        Row() {
          Text('开始位数：')
            .fontSize(16)
            .width('30%')
          TextInput({ placeholder: '1-10000', text: this.piStartDigitText })
            .type(InputType.Number)
            .maxLength(5)
            .width('40%')
            .onChange((value: string) => {
              // 限制输入值
              let num = parseInt(value);
              if (isNaN(num) || num < 1) {
                num = 1;
              } else if (num > 10000) {
                num = 10000;
                this.piStartDigitText = '10000';
              } else {
                this.piStartDigitText = value;
              }
              this.piStartDigit = num;
              // 确保结束位数不小于开始位数
              if (this.piEndDigit < this.piStartDigit) {
                this.piEndDigit = this.piStartDigit;
                this.piEndDigitText = this.piStartDigit.toString();
              }
            })
          Text(`当前: ${this.piStartDigit}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 结束位数
        Row() {
          Text('结束位数：')
            .fontSize(16)
            .width('30%')
          TextInput({ placeholder: '1-10000', text: this.piEndDigitText })
            .type(InputType.Number)
            .maxLength(5)
            .width('40%')
            .onChange((value: string) => {
              // 限制输入值
              let num = parseInt(value);
              if (isNaN(num) || num < 1) {
                num = 1;
              } else if (num > 10000) {
                num = 10000;
                this.piEndDigitText = '10000';
              } else {
                this.piEndDigitText = value;
              }
              // 确保结束位数不小于开始位数
              if (num < this.piStartDigit) {
                num = this.piStartDigit;
                this.piEndDigitText = this.piStartDigit.toString();
              }
              this.piEndDigit = num;
            })
          Text(`当前: ${this.piEndDigit}`)
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 每行个数（固定为10，只显示）
        Row() {
          Text('每行个数：')
            .fontSize(16)
            .width('30%')
          Text('10')
            .fontSize(16)
            .fontColor('#333333')
            .width('40%')
          Text('固定')
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 20 })

        // 训练次数（固定为1，只显示）
        Row() {
          Text('训练次数：')
            .fontSize(16)
            .width('30%')
          Text('1')
            .fontSize(16)
            .fontColor('#333333')
            .width('40%')
          Text('固定')
            .fontSize(14)
            .fontColor('#666666')
            .width('30%')
        }
        .width('90%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .borderRadius(8)
        .margin({ bottom: 30 })
      }

      // 开始按钮
      Button('开始')
        .width('80%')
        .height(50)
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .backgroundColor('#2196F3')
        .onClick(() => {
          // 验证输入
          if (this.selectedRange === '随机数字') {
            if (this.rowCount < 1 || this.rowCount > 1000) {
              promptAction.showToast({
                message: '行数范围：1-1000',
                duration: 2000
              });
              return;
            }
            if (this.digitsPerRow < 1 || this.digitsPerRow > 10) {
              promptAction.showToast({
                message: '每行个数范围：1-10',
                duration: 2000
              });
              return;
            }
            if (this.trainingCount < 1 || this.trainingCount > 1000) {
              promptAction.showToast({
                message: '训练次数范围：1-1000',
                duration: 2000
              });
              return;
            }
            
            router.pushUrl({
              url: 'pages/NumberMemory',
              params: {
                rangeType: this.selectedRange,
                rowCount: this.rowCount.toString(),
                digitsPerRow: this.digitsPerRow.toString(),
                trainingCount: this.trainingCount.toString()
              }
            });
          } else {
            // 圆周率
            if (this.piStartDigit < 1 || this.piStartDigit > 10000) {
              promptAction.showToast({
                message: '开始位数范围：1-10000',
                duration: 2000
              });
              return;
            }
            if (this.piEndDigit < 1 || this.piEndDigit > 10000) {
              promptAction.showToast({
                message: '结束位数范围：1-10000',
                duration: 2000
              });
              return;
            }
            if (this.piEndDigit < this.piStartDigit) {
              promptAction.showToast({
                message: '结束位数不能小于开始位数',
                duration: 2000
              });
              return;
            }
            
            router.pushUrl({
              url: 'pages/NumberMemory',
              params: {
                rangeType: this.selectedRange,
                piStartDigit: this.piStartDigit.toString(),
                piEndDigit: this.piEndDigit.toString(),
                digitsPerRow: '10', // 固定为10
                trainingCount: '1' // 固定为1
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

