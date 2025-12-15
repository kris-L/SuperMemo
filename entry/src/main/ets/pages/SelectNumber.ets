import { router, promptAction, AppStorageV2 } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';

interface OptionStyle {
  bg: string;
  border: string;
}

class SelectNumberStats {
  bestAccuracy: number = 0;
  trainCount: number = 0;
}

/**
 * 看图选数页面
 */
@Entry
@Component
struct SelectNumber {
  @State allPegs: NumberPeg[] = [];
  @State questionOrder: number[] = [];
  @State currentIndex: number = 0;
  @State options: number[] = [];
  @State wrongOption: number | null = null;
  @State selectedOption: number | null = null;
  @State correctCount: number = 0;
  @State errorCount: number = 0;
  @State elapsedTime: number = 0;
  @State isFinished: boolean = false;
  @State bestAccuracy: number = 0; // 百分比整数
  @State trainCount: number = 0;

  private timer: number | null = null;
  private stats?: SelectNumberStats;

  aboutToAppear() {
    this.initStats();
    this.loadStats();
    this.initGame();
  }

  aboutToDisappear() {
    this.stopTimer();
  }

  async initGame() {
    try {
      const service = NumberPegService.getInstance();
      this.allPegs = await service.getAllNumberPegs();
      if (this.allPegs.length === 0) {
        promptAction.showToast({ message: '未找到数字桩数据', duration: 2000 });
        this.options = [];
        return;
      }
      // 创建随机顺序
      this.questionOrder = this.shuffleNumbers(this.allPegs.map(p => p.number));
      this.currentIndex = 0;
      this.correctCount = 0;
      this.errorCount = 0;
      this.elapsedTime = 0;
      this.isFinished = false;
      this.selectedOption = null;
      this.wrongOption = null;
      this.startTimer();
      // 确保加载第一题
      this.loadQuestion();
    } catch (e) {
      console.error('初始化失败', e);
      this.options = [];
    }
  }

  initStats() {
    if (this.stats) {
      return;
    }
    const connected: SelectNumberStats | undefined =
      AppStorageV2.connect(SelectNumberStats, 'selectNumberStats', () => new SelectNumberStats());
    this.stats = connected ? connected : new SelectNumberStats();
  }

  loadStats() {
    this.initStats();
    if (this.stats) {
      this.bestAccuracy = this.stats.bestAccuracy;
      this.trainCount = this.stats.trainCount;
    }
  }

  saveStats() {
    this.initStats();
    if (this.stats) {
      this.stats.bestAccuracy = this.bestAccuracy;
      this.stats.trainCount = this.trainCount;
    }
  }

  shuffleNumbers(list: number[]): number[] {
    const arr = [...list];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = arr[i];
      arr[i] = arr[j];
      arr[j] = tmp;
    }
    return arr;
  }

  getCurrentPeg(): NumberPeg | null {
    if (this.questionOrder.length === 0 || this.allPegs.length === 0) {
      return null;
    }
    const num = this.questionOrder[this.currentIndex];
    const peg = this.allPegs.find(p => p.number === num);
    return peg || null;
  }

  startTimer() {
    this.stopTimer();
    this.timer = setInterval(() => {
      this.elapsedTime++;
    }, 1000);
  }

  stopTimer() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  loadQuestion() {
    // 第一步：先确定当前题目对应的数字桩
    const peg = this.getCurrentPeg();
    if (!peg) {
      // 创建新数组引用以触发UI更新
      this.options = [];
      return;
    }
 
    // 第二步：确定正确答案（当前图片对应的数字）
    const correctNumber = peg.number;

    // 第三步：重置选择状态
    this.selectedOption = null;
    this.wrongOption = null;
    
    // 第四步：生成包含正确答案的选项
    const newOptions = this.generateOptions(correctNumber);
    
    // 第五步：最终验证
    if (newOptions.length !== 4) {
      console.error(`选项数量不正确：${newOptions.length}，应该是4`);
      // 重新生成
      const regenerated = this.generateOptions(correctNumber);
      // 创建新数组引用以触发UI更新
      this.options = [];
      for (let i = 0; i < regenerated.length; i++) {
        this.options.push(regenerated[i]);
      }
      return;
    }
    
    if (!newOptions.includes(correctNumber)) {
      console.error(`选项不包含正确答案 ${correctNumber}，当前选项：`, newOptions);
      // 强制替换第一个位置为正确答案
      newOptions[0] = correctNumber;
    }
    
    // 创建新数组引用以触发UI更新（关键：必须创建新数组）
    // 使用展开运算符创建新数组，确保引用改变
    this.options = [...newOptions];
  }

  generateOptions(correctNumber: number): number[] {
    // 确保有数据
    if (this.allPegs.length === 0) {
      return [correctNumber, correctNumber, correctNumber, correctNumber];
    }
    
    // 第一步：先确定正确答案
    const correctAnswer = correctNumber;
    
    // 第二步：获取所有错误答案的池子（排除正确答案）
    const wrongPool: number[] = [];
    for (let i = 0; i < this.allPegs.length; i++) {
      const num = this.allPegs[i].number;
      if (num !== correctAnswer) {
        wrongPool.push(num);
      }
    }
    
    // 第三步：从错误答案池中随机选择3个不同的数字
    const selectedWrong: number[] = [];
    const usedNumbers: Set<number> = new Set();
    
    // 如果错误答案池不足3个，允许重复
    if (wrongPool.length < 3) {
      while (selectedWrong.length < 3) {
        const idx = Math.floor(Math.random() * wrongPool.length);
        selectedWrong.push(wrongPool[idx]);
      }
    } else {
      // 错误答案池足够，选择3个不同的
      while (selectedWrong.length < 3) {
        const idx = Math.floor(Math.random() * wrongPool.length);
        const num = wrongPool[idx];
        if (!usedNumbers.has(num)) {
          selectedWrong.push(num);
          usedNumbers.add(num);
        }
      }
    }
    
    // 第四步：组合正确答案和3个错误答案
    const allOptions: number[] = [correctAnswer];
    for (let i = 0; i < selectedWrong.length; i++) {
      allOptions.push(selectedWrong[i]);
      console.error(`selectedWrong:`+selectedWrong[i]);
    }
    
    // 确保有4个选项
    while (allOptions.length < 4) {
      allOptions.push(correctAnswer);
    }
    
    // 第五步：打乱顺序（Fisher-Yates shuffle）
    for (let i = allOptions.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const tmp = allOptions[i];
      allOptions[i] = allOptions[j];
      allOptions[j] = tmp;
    }
    
    // 最终验证：确保正确答案在数组中
    if (!allOptions.includes(correctAnswer)) {
      console.error(`严重错误：打乱后丢失正确答案 ${correctAnswer}！强制替换`);
      // 强制替换第一个位置
      allOptions[0] = correctAnswer;
    }
    
    return allOptions;
  }

  onSelect(option: number) {
    if (this.isFinished) {
      return;
    }
    // 确保选项已准备好
    const peg = this.getCurrentPeg();
    if (!peg || this.options.length === 0 || !this.options.includes(peg.number)) {
      this.loadQuestion();
      return;
    }
    if (!peg) {
      return;
    }
    if (this.selectedOption === peg.number) {
      return; // 已经答对，等待切题
    }
    if (option === peg.number) {
      this.selectedOption = option;
      this.correctCount++;
      // 下一题
      setTimeout(() => {
        this.gotoNext();
      }, 200);
    } else {
      this.wrongOption = option;
      this.errorCount++;
    }
  }

  gotoNext() {
    if (this.currentIndex + 1 >= this.questionOrder.length) {
      this.finishGame();
      return;
    }
    this.currentIndex++;
    // 确保切换到下一题时重新加载选项
    this.loadQuestion();
    // 再次验证选项是否正确
    const peg = this.getCurrentPeg();
    if (peg && (!this.options.includes(peg.number) || this.options.length !== 4)) {
      console.error(`切换到第${this.currentIndex + 1}题时选项不正确，重新生成`);
      this.loadQuestion();
    }
  }

  finishGame() {
    this.stopTimer();
    this.isFinished = true;
    // 更新统计
    const accNum = Math.round((this.correctCount / Math.max(1, this.correctCount + this.errorCount)) * 100);
    if (accNum > this.bestAccuracy) {
      this.bestAccuracy = accNum;
    }
    this.trainCount++;
    this.saveStats();
  }

  accuracy(): string {
    const total = this.correctCount + this.errorCount;
    if (total === 0) {
      return '0%';
    }
    return `${Math.round((this.correctCount / total) * 100)}%`;
  }

  formatTime(sec: number): string {
    const m = Math.floor(sec / 60);
    const s = sec % 60;
    return `${m.toString().padStart(2, '0')}:${s.toString().padStart(2, '0')}`;
  }

  imageRes(name: string): Resource {
    const service = NumberPegService.getInstance();
    return service.getImageResourceId(name);
  }

  ensureOptionsReady() {
    const peg = this.getCurrentPeg();
    if (!peg) {
      return;
    }
    if (this.options.length !== 4 || !this.options.includes(peg.number)) {
      this.options = this.generateOptions(peg.number);
    }
  }

  getOptionBg(num: number): string {
    const peg = this.getCurrentPeg();
    if (!peg) {
      return '#FFFFFF';
    }
    if (this.selectedOption === peg.number && num === peg.number) {
      return '#E8F5E9';
    }
    if (this.wrongOption === num && num !== peg.number) {
      return '#FEECEC';
    }
    return '#FFFFFF';
  }

  getOptionBorder(num: number): string {
    const peg = this.getCurrentPeg();
    if (!peg) {
      return '#DDDDDD';
    }
    if (this.selectedOption === peg.number && num === peg.number) {
      return '#4CAF50';
    }
    if (this.wrongOption === num && num !== peg.number) {
      return '#F44336';
    }
    return '#DDDDDD';
  }

  getOptionStyle(option: number): OptionStyle {
    const peg = this.getCurrentPeg();
    if (!peg) {
      return { bg: '#FFFFFF', border: '#DDDDDD' };
    }
    if (this.selectedOption === peg.number && option === peg.number) {
      return { bg: '#E8F5E9', border: '#4CAF50' };
    }
    if (this.wrongOption === option && option !== peg.number) {
      return { bg: '#FEECEC', border: '#F44336' };
    }
    return { bg: '#FFFFFF', border: '#DDDDDD' };
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
          .onClick(() => {
            router.back();
          })

          Text('看图选数')
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

        // 进度
        Text(`${this.questionOrder.length === 0 ? 0 : this.currentIndex + 1}/${this.questionOrder.length || 110}`)
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 12 })

        // 图片
        if (this.getCurrentPeg()) {
          Image(this.imageRes(this.getCurrentPeg()!.imageName))
            .width('80%')
            .height(240)
            .objectFit(ImageFit.Contain)
            .borderRadius(8)
            .backgroundColor(Color.White)
            .margin({ bottom: 16 })
        } else {
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 16 })
        }

        // 选项
        if (this.options.length >= 4) {
          Grid() {
            ForEach(this.options, (option: number, index: number) => {
              GridItem() {
                this.optionButton(option);
              }
            }, (option: number, index: number) => `${option}-${index}-${this.currentIndex}`)
          }
          .columnsTemplate('1fr 1fr')
          .rowsTemplate('1fr 1fr')
          .columnsGap(15)
          .rowsGap(15)
          .width('90%')
          .height(180)
          .margin({ bottom: 20 })
        } else {
          Text('加载选项...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ bottom: 20 })
        }

        // 底部统计
        Row() {
          Column() {
            Text('正确')
              .fontSize(12)
              .fontColor('#666666')
            Text(this.correctCount.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
              .margin({ top: 4 })
          }
          .flexGrow(1)

          Column() {
            Text('错误')
              .fontSize(12)
              .fontColor('#666666')
            Text(this.errorCount.toString())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F44336')
              .margin({ top: 4 })
          }
          .flexGrow(1)

          Column() {
            Text('正确率')
              .fontSize(12)
              .fontColor('#666666')
            Text(this.accuracy())
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#2196F3')
              .margin({ top: 4 })
          }
          .flexGrow(1)
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F5F5F5')
      .padding({ top: 10 })

      // 完成报告
      if (this.isFinished) {
        Column() {
          Column() {
            Text('完成！')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 12 })
            Text(`用时：${this.formatTime(this.elapsedTime)}`)
              .fontSize(16)
              .margin({ bottom: 8 })
            Text(`正确：${this.correctCount}  错误：${this.errorCount}`)
              .fontSize(16)
              .margin({ bottom: 8 })
            Text(`准确率：${this.accuracy()}`)
              .fontSize(16)
              .margin({ bottom: 16 })

            Row() {
              Button('再来一次')
                .width('45%')
                .height(44)
                .backgroundColor('#4CAF50')
                .onClick(() => {
                  this.initGame();
                })

              Button('回到首页')
                .width('45%')
                .height(44)
                .backgroundColor('#9E9E9E')
                .onClick(() => {
                  router.clear();
                  router.replaceUrl({ url: 'pages/Index' });
                })
            }
            .justifyContent(FlexAlign.SpaceBetween)
          }
          .width('80%')
          .padding(20)
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 10, color: '#00000020', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
        .position({ x: 0, y: 0 })
      }
    }
  }

  @Builder
  optionButton(num: number) {
    Button(num.toString())
      .width('100%')
      .height('100%')
      .fontSize(24)
      .fontWeight(FontWeight.Bold)
      .fontColor('#000000')
      .backgroundColor(this.getOptionBg(num))
      .border({ width: 2, color: this.getOptionBorder(num) })
      .borderRadius(12)
      .onClick(() => {
        this.onSelect(num);
      })
  }
}


