import { router, promptAction } from '@kit.ArkUI';

/**
 * 记忆宫殿复盘页面
 */
@Entry
@Component
struct MemoryPalaceReview {
  @State userInput: string = ''; // 用户输入的数字
  @State refreshKey: number = 0; // 用于强制刷新的key
  @State showResult: boolean = false; // 是否显示结果
  @State correctCount: number = 0; // 正确数字数
  @State totalDigits: number = 0; // 总数字数
  @State accuracy: number = 0; // 准确率（百分比）

  private correctNumbers: string = ''; // 正确答案（拼接后的数字）
  private totalPegs: number = 0; // 总桩数

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['numbers']) {
      this.correctNumbers = params['numbers'] as string;
      this.totalDigits = this.correctNumbers.length;
    }
    if (params && params['totalPegs']) {
      this.totalPegs = params['totalPegs'] as number;
    }
  }

  /**
   * 处理数字输入
   */
  onNumberInput(digit: string) {
    // 限制输入长度不超过正确答案长度
    if (this.userInput.length >= this.totalDigits) {
      console.info('MYTEST', '输入已达上限');
      promptAction.showToast({ message: '输入已达上限', duration: 2000 });
      return;
    }
    // 直接更新状态，不使用 setTimeout
    this.userInput = this.userInput + digit;
    this.refreshKey++;
    console.info('MYTEST', '输入数字:', digit, '当前值:', this.userInput, 'refreshKey:', this.refreshKey);
  }

  /**
   * 撤销最后一个输入
   */
  onUndo() {
    if (this.userInput.length > 0) {
      this.userInput = this.userInput.substring(0, this.userInput.length - 1);
    }
  }

  /**
   * 提交答案
   */
  onSubmit() {
    if (this.userInput.length === 0) {
      promptAction.showToast({ message: '请输入数字', duration: 2000 });
      return;
    }

    // 计算正确数量
    let correct = 0;
    const minLength = Math.min(this.userInput.length, this.correctNumbers.length);
    for (let i = 0; i < minLength; i++) {
      if (this.userInput[i] === this.correctNumbers[i]) {
        correct++;
      }
    }

    this.correctCount = correct;
    this.accuracy = this.totalDigits > 0 ? Math.round((correct / this.totalDigits) * 100) : 0;
    this.showResult = true;
  }

  build() {
    Stack() {
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
          .type(ButtonType.Normal)
          .onClick(() => {
            router.back();
          })

          Text('记忆宫殿复盘')
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

        // 提示文字
        Text('请输入记忆的数字')
          .fontSize(16)
          .fontColor('#666666')
          .width('100%')
          .padding({ left: 20, right: 20, top: 12, bottom: 12 })
          .backgroundColor(Color.White)

        // 数字显示矩形框（占据剩余空间）
        Scroll() {
          Column() {
            Text(this.userInput || '')
              .fontSize(36)
              .fontColor('#2196F3')
              .fontWeight(FontWeight.Bold)
              .letterSpacing(6)
              .textAlign(TextAlign.Start)
              .width('100%')
          }
          .width('100%')
          .padding({ top: 10, bottom: 10,right:20 })
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .margin({ left: 20, right: 20, top: 0, bottom: 0 })
        .padding({ left: 20, right: 20 })
        .backgroundColor('#F5F5F5')
        .borderRadius(8)
        .border({ width: 2, color: '#2196F3' }) // 蓝色边框
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        // 数字键盘（固定在底部）
        Column() {
          // 第一行：1-3
          Row() {
            this.createKeyButton('1', () => { this.onNumberInput('1'); })
            this.createKeyButton('2', () => { this.onNumberInput('2'); })
            this.createKeyButton('3', () => { this.onNumberInput('3'); })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ bottom: 15 })

          // 第二行：4-6
          Row() {
            this.createKeyButton('4', () => { this.onNumberInput('4'); })
            this.createKeyButton('5', () => { this.onNumberInput('5'); })
            this.createKeyButton('6', () => { this.onNumberInput('6'); })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ bottom: 15 })

          // 第三行：7-9
          Row() {
            this.createKeyButton('7', () => { this.onNumberInput('7'); })
            this.createKeyButton('8', () => { this.onNumberInput('8'); })
            this.createKeyButton('9', () => { this.onNumberInput('9'); })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
          .margin({ bottom: 15 })

          // 第四行：撤销、0、提交
          Row() {
            this.createKeyButton('撤销', () => { this.onUndo(); }, '#FF9800')
            this.createKeyButton('0', () => { this.onNumberInput('0'); })
            this.createKeyButton('提交', () => { this.onSubmit(); }, '#4CAF50')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
        }
        .width('100%')
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .backgroundColor('#F5F5F5')
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')

      // 结果对话框
      if (this.showResult) {
        this.buildResultDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  createKeyButton(text: string, onClick: () => void, color: string = '#2196F3') {
    Button(text)
      .width('28%')
      .height(70)
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .fontColor(Color.White)
      .backgroundColor(color)
      .borderRadius(10)
      .onClick(onClick)
  }

  @Builder
  buildResultDialog() {
    Column() {
      Column() {
        Text('复盘结果')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })

        Text(`正确: ${this.correctCount} / ${this.totalDigits}`)
          .fontSize(18)
          .margin({ bottom: 12 })

        Text(`准确率: ${this.accuracy}%`)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.accuracy >= 80 ? '#4CAF50' : '#F44336')
          .margin({ bottom: 24 })

        // 显示正确答案和用户输入对比
        Column() {
          Text('正确答案：')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Text(this.correctNumbers)
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .letterSpacing(1)
            .textAlign(TextAlign.Start)
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#E8F5E9')
            .borderRadius(4)
            .margin({ bottom: 16 })

          Text('你的答案：')
            .fontSize(14)
            .fontColor('#666666')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })

          Text(this.userInput || '未输入')
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .letterSpacing(1)
            .textAlign(TextAlign.Start)
            .width('100%')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('#FFF3E0')
            .borderRadius(4)
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .margin({ bottom: 24 })

        Button('确定')
          .width('100%')
          .height(44)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .backgroundColor('#2196F3')
          .borderRadius(8)
          .onClick(() => {
            this.showResult = false;
            router.back();
          })
      }
      .width('85%')
      .padding(24)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 10, color: '#40000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#80000000')
    .onClick(() => {
      this.showResult = false;
    })
  }
}

