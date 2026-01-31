import { router, promptAction } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';
import { DatabaseManager } from '../database/DatabaseManager';

/**
 * 骨肉相连考试页单个数据项
 */
interface BoneMatchExamItem {
  id: number; // 唯一ID
  originalPosition: number; // 原始位置（1-12，用于判定）
  currentPosition: number; // 当前显示位置（打乱后）
  peg: NumberPeg; // 数字桩数据
  displayType: 'image' | 'number' | 'code'; // 展示类型：图片/数字/名称
  selectedOrder: number | null; // 用户选择的序号（1-12，null表示未选择）
}

/**
 * 骨肉相连考试页面
 * 顶部显示计时与轮次进度（0/6），中间为 3x4 共 12 图的骨肉相连玩法
 */
@Entry
@Component
export struct BoneMatchExam {
  @State items: BoneMatchExamItem[] = []; // 当前轮次数据
  @State isMemorized: boolean = false; // 是否已点击"记完"
  @State currentSelectOrder: number = 1; // 当前应该选择的序号
  @State selectedHistory: number[] = []; // 选择历史（用于撤销）

  @State elapsedTime: number = 0; // 累计考试时间（秒）
  @State completedRounds: number = 0; // 已完成轮次

  @State totalCorrect: number = 0; // 累计正确数量
  @State totalError: number = 0; // 累计错误数量
  @State showExamResult: boolean = false; // 是否显示考试结果
  @State isExamFailed: boolean = false; // 考试是否失败

  private readonly totalRounds: number = 6; // 共 6 轮

  private shuffleSeq: number = 0; // 打乱序列，保证卡片 id 唯一
  private allPegs: NumberPeg[] = []; // 所有数字桩数据
  private pegService: NumberPegService = NumberPegService.getInstance();
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private timer: number | null = null; // 计时器
  private difficulty: number = 12; // 每轮 12 图

  aboutToAppear() {
    this.startTimer();
    this.initRound();
  }

  aboutToDisappear() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * 开始计时
   */
  startTimer() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.timer = setInterval(() => {
      if (!this.showExamResult) {
        this.elapsedTime++;
      }
    }, 1000);
  }

  /**
   * 初始化/开始一轮
   */
  async initRound() {
    try {
      // 首次加载读取所有数字桩
      if (this.allPegs.length === 0) {
        this.allPegs = await this.pegService.getAllNumberPegs();
      }
      if (this.allPegs.length === 0) {
        promptAction.showToast({ message: '未找到数字桩数据', duration: 2000 });
        return;
      }

      // 随机选取 difficulty 个数字桩，仅使用图像展示
      const shuffled = this.shuffleArray(this.allPegs);
      const selectedPegs = shuffled.slice(0, this.difficulty);

      const newItems: BoneMatchExamItem[] = [];
      let uid = 0;
      selectedPegs.forEach((peg, index) => {
        const item: BoneMatchExamItem = {
          id: uid++,
          originalPosition: index + 1,
          currentPosition: index + 1,
          peg: peg,
          displayType: 'image',
          selectedOrder: null
        };
        newItems.push(item);
      });

      this.items = newItems;
      this.isMemorized = false;
      this.currentSelectOrder = 1;
      this.selectedHistory = [];
    } catch (e) {
      console.error('初始化骨肉相连考试失败', e);
      promptAction.showToast({ message: '初始化失败', duration: 2000 });
    }
  }

  /**
   * 点击"记完"按钮，打乱顺序，进入答题阶段
   */
  onMemorizeComplete() {
    if (this.isMemorized) {
      return;
    }

    this.shuffleSeq++;
    const source = [...this.items];
    const randomized: BoneMatchExamItem[] = [];
    const shuffledSource = this.shuffleArray(source);
    for (let i = 0; i < shuffledSource.length; i++) {
      const item = shuffledSource[i];
      const newItem: BoneMatchExamItem = {
        id: this.shuffleSeq * 1000 + i, // 换新 id，确保 ForEach 重新渲染
        originalPosition: item.originalPosition,
        currentPosition: i + 1,
        peg: item.peg,
        displayType: item.displayType,
        selectedOrder: item.selectedOrder
      };
      randomized.push(newItem);
    }

      this.items = randomized;
      this.isMemorized = true;
      this.currentSelectOrder = 1;
      this.selectedHistory = [];
  }

  /**
   * 点击卡片
   */
  onItemClick(item: BoneMatchExamItem) {
    if (!this.isMemorized || this.showExamResult) {
      return;
    }
    if (item.selectedOrder !== null) {
      return;
    }

    const index = this.items.findIndex(i => i.id === item.id);
    if (index === -1) {
      return;
    }

    const updatedItem: BoneMatchExamItem = {
      id: item.id,
      originalPosition: item.originalPosition,
      currentPosition: item.currentPosition,
      peg: item.peg,
      displayType: item.displayType,
      selectedOrder: this.currentSelectOrder
    };

    const newItems = [...this.items];
    newItems[index] = updatedItem;
    this.items = newItems;

    this.selectedHistory.push(item.id);
    this.currentSelectOrder++;

    // 12 个序号都选完，结算本轮
    if (this.currentSelectOrder > this.difficulty) {
      this.checkRoundResult();
    }
  }

  /**
   * 撤销最后的选择
   */
  onUndo() {
    if (this.selectedHistory.length === 0) {
      return;
    }

    // 获取最后选择的ID
    const lastId = this.selectedHistory.pop();
    if (lastId === undefined) {
      return;
    }

    // 找到对应的数据项并清除选择
    const index = this.items.findIndex(i => i.id === lastId);
    if (index === -1) {
      return;
    }

    const item = this.items[index];
    // 创建新对象更新状态
    const updatedItem: BoneMatchExamItem = {
      id: item.id,
      originalPosition: item.originalPosition,
      currentPosition: item.currentPosition,
      peg: item.peg,
      displayType: item.displayType,
      selectedOrder: null
    };

    this.items[index] = updatedItem;
    this.currentSelectOrder--;
    // 触发界面刷新
    this.items = [...this.items];
  }

  /**
   * 结算当前轮结果
   */
  async checkRoundResult() {
    let correct = 0;
    let error = 0;

    this.items.forEach(item => {
      if (item.selectedOrder === item.originalPosition) {
        correct++;
      } else {
        error++;
      }
    });

    this.totalCorrect += correct;
    this.totalError += error;
    this.completedRounds++;

    // 如果已到最后一轮，记录考试记录并显示结果
    if (this.completedRounds >= this.totalRounds) {
      // 停止计时器
      if (this.timer !== null) {
        clearInterval(this.timer);
        this.timer = null;
      }
      
      // 记录考试记录
      try {
        await this.dbManager.insertTrainingRecord({
          gameType: '骨肉相连考试',
          duration: this.elapsedTime,
          createTime: Date.now()
        });
        console.info(`骨肉相连考试记录已保存: 总用时=${this.elapsedTime}秒`);
      } catch (err) {
        console.error('保存骨肉相连考试记录失败:', err);
      }
      
      // 显示考试结果
      this.showExamResult = true;
    } else {
      // 如果全对，立即进入下一轮（不显示提示，不延迟）
      if (error === 0) {
        // 全对，立即进入下一轮
        await this.initRound();
      } else {
        // 有错误，考试失败，停止计时并显示失败弹框
        // 停止计时器
        if (this.timer !== null) {
          clearInterval(this.timer);
          this.timer = null;
        }
        
        // 记录考试失败记录
        try {
          await this.dbManager.insertTrainingRecord({
            gameType: '骨肉相连考试',
            duration: this.elapsedTime,
            createTime: Date.now()
          });
          console.info(`骨肉相连考试失败记录已保存: 总用时=${this.elapsedTime}秒, 完成轮次=${this.completedRounds}/${this.totalRounds}`);
        } catch (err) {
          console.error('保存骨肉相连考试失败记录失败:', err);
        }
        
        // 显示考试失败弹框
        this.isExamFailed = true;
        this.showExamResult = true;
      }
    }
  }


  /**
   * 打乱数组
   */
  shuffleArray<T>(array: T[]): T[] {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    return arr;
  }

  /**
   * 获取图片资源
   */
  getItemImage(item: BoneMatchExamItem): Resource {
    return this.pegService.getImageResourceId(item.peg.imageName);
  }

  /**
   * 时间格式化
   */
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
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

          Text('骨肉相连考试')
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
        .height(44)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 6 })

        // 计时 + 进度
        Row() {
          Column() {
            Text('时间')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text(this.formatTime(this.elapsedTime))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 4 })
          }
          .flexGrow(1)

          Column() {
            Text('进度')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.completedRounds}/${this.totalRounds}`)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 4 })
          }
          .flexGrow(1)
        }
        .width('100%')
        .height(50)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: 4 })

        // 中间 12 图区域（3x4）
        Grid() {
          ForEach(this.items, (item: BoneMatchExamItem) => {
            GridItem() {
              this.buildItem(item);
            }
          }, (item: BoneMatchExamItem) => `${item.id}_${item.selectedOrder ?? 'null'}`)
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 6, right: 6, top: 0, bottom: 6 })

        // 底部按钮（仅在考试未完成时显示）
        if (!this.showExamResult) {
          Row() {
            if (!this.isMemorized) {
              Button('记完')
                .width('45%')
                .height(50)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#2196F3')
                .onClick(() => {
                  this.onMemorizeComplete();
                })
            } else {
              Button('撤销')
                .width('45%')
                .height(50)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#FF9800')
                .onClick(() => {
                  this.onUndo();
                })
            }
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 12, right: 12, bottom: 20 })
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F5F5F5')

      // 考试结果层
      if (this.showExamResult) {
        Column() {
          Column() {
            Text(this.isExamFailed ? '考试失败' : '考试完成')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.isExamFailed ? '#F44336' : $r('app.color.text_primary'))
              .margin({ bottom: 16 })

            Text(`总用时：${this.formatTime(this.elapsedTime)}`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 8 })

            Text(`完成轮次：${this.completedRounds}/${this.totalRounds}`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 8 })

            Text(`总正确：${this.totalCorrect}`)
              .fontSize(18)
              .fontColor('#4CAF50')
              .margin({ bottom: 8 })

            Text(`总错误：${this.totalError}`)
              .fontSize(18)
              .fontColor('#F44336')
              .margin({ bottom: 24 })

            Button('返回')
              .width('60%')
              .height(45)
              .backgroundColor('#9E9E9E')
              .onClick(() => {
                router.back();
              })
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
        .position({ x: 0, y: 0 })
        .backgroundColor('#80000000')
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildItem(item: BoneMatchExamItem) {
    Stack() {
      // 卡片内容
      Column() {
        if (item.displayType === 'image') {
          Image(this.getItemImage(item))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

      // 透明遮罩层显示序号
      if (item.selectedOrder !== null) {
        // 中间显示用户选择的序号
        Column() {
          Text(item.selectedOrder.toString())
            .fontSize(42)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
        .borderRadius(8)
      }
    }
    .width('100%')
    .height(140)
    .backgroundColor(Color.White)
    .borderRadius(8)
    .border({ width: 2, color: item.selectedOrder !== null ? '#2196F3' : '#DDDDDD' })
    .onClick(() => {
      this.onItemClick(item);
    })
    .layoutWeight(1)
    .margin({ left: 4, right: 4 })
  }
}

@Preview
@Component
struct BoneMatchExamPreview {
  build() {
    BoneMatchExam()
  }
}


