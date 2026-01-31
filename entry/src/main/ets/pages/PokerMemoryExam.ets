import { router, promptAction } from '@kit.ArkUI';
import { DatabaseManager, PokerExamRecord } from '../database/DatabaseManager';

/**
 * 扑克牌花色
 */
type Suit = 'spade' | 'heart' | 'club' | 'diamond';

/**
 * 扑克牌点数
 */
type Rank = 'A' | '2' | '3' | '4' | '5' | '6' | '7' | '8' | '9' | '10' | 'J' | 'Q' | 'K';

/**
 * 输入的扑克牌
 */
interface InputCard {
  suit: Suit;
  rank: Rank;
}

/**
 * 扑克牌信息
 */
interface CardInfo {
  suit: Suit;
  rank: Rank;
}

/**
 * 扑克记忆考试页面
 */
@Entry
@Component
struct PokerMemoryExam {
  @State pokerCards: number[] = []; // 扑克牌编号数组（1-52）
  @State currentIndex: number = 0; // 当前显示的起始索引
  @State isPlaying: boolean = false; // 是否正在播放
  @State intervalSeconds: number = 0.5; // 时间间隔（秒）
  @State cardCount: number = 1; // 每次显示的扑克牌张数（1-4）
  @State isReviewMode: boolean = false; // 是否在复盘模式
  @State inputCards: InputCard[] = []; // 输入的扑克牌列表
  @State selectedSuit: Suit = 'spade'; // 当前选中的花色
  @State elapsedTime: number = 0; // 消耗时间（秒）
  @State showResultDialog: boolean = false; // 是否显示结果对话框
  @State resultMessage: string = ''; // 结果消息
  @State isExamPassed: boolean = false; // 是否通过考试

  private timer: number | null = null;
  private reviewScroller: Scroller = new Scroller(); // 复盘阶段的滚动控制器
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private startTime: number = 0; // 考试开始时间戳（毫秒）

  aboutToAppear() {
    this.initPokerCards();
    this.startTimer();
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * 开始计时
   */
  startTimer() {
    this.startTime = Date.now();
    this.elapsedTime = 0;
    if (this.timer !== null) {
      clearInterval(this.timer);
    }
    this.timer = setInterval(() => {
      this.elapsedTime++;
    }, 1000);
  }

  /**
   * 停止计时
   */
  stopTimer() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * 格式化时间显示
   */
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * 初始化扑克牌数组（1-52，随机打乱）
   */
  initPokerCards() {
    // 生成1-52的数组
    const cards: number[] = [];
    for (let i = 1; i <= 52; i++) {
      cards.push(i);
    }
    // 随机打乱
    this.pokerCards = this.shuffleArray(cards);
    this.currentIndex = 0;
    this.isReviewMode = false;
    this.inputCards = [];
    this.selectedSuit = 'spade';
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
   * 获取当前显示的扑克牌编号数组
   */
  getCurrentCards(): number[] {
    const cards: number[] = [];
    for (let i = 0; i < this.cardCount; i++) {
      const index = (this.currentIndex + i) % this.pokerCards.length;
      cards.push(this.pokerCards[index]);
    }
    return cards;
  }

  /**
   * 下一组
   */
  next() {
    if (this.pokerCards.length === 0) {
      return;
    }
    // 每次前进cardCount张
    this.currentIndex = (this.currentIndex + this.cardCount) % this.pokerCards.length;
  }

  /**
   * 上一组
   */
  prev() {
    if (this.pokerCards.length === 0) {
      return;
    }
    // 每次后退cardCount张
    this.currentIndex = (this.currentIndex - this.cardCount + this.pokerCards.length) % this.pokerCards.length;
  }

  /**
   * 获取时间间隔标签
   */
  getIntervalLabel(): string {
    if (this.intervalSeconds === 0.5) {
      return '0.5秒';
    }
    return `${this.intervalSeconds}秒`;
  }

  /**
   * 获取扑克牌图片资源
   */
  getPokerImageResource(cardNumber: number): Resource {
    // 确保编号在1-52范围内
    const num = Math.max(1, Math.min(52, cardNumber));
    // 格式化为两位数字符串
    const numStr = num.toString().padStart(2, '0');
    return $r(`app.media.poker_${numStr}`);
  }

  /**
   * 根据扑克牌编号获取花色和点数
   */
  getCardInfo(cardNumber: number): CardInfo {
    // 假设编号规则：1-13黑桃，14-26红桃，27-39梅花，40-52方块
    const num = cardNumber - 1; // 转换为0-51
    const suitIndex = Math.floor(num / 13); // 0=黑桃，1=红桃，2=梅花，3=方块
    const rankIndex = num % 13; // 0=A, 1=2, ..., 12=K
    
    const suits: Suit[] = ['spade', 'heart', 'club', 'diamond'];
    const ranks: Rank[] = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    
    const cardInfo: CardInfo = {
      suit: suits[suitIndex],
      rank: ranks[rankIndex]
    };
    return cardInfo;
  }

  /**
   * 根据花色和点数获取扑克牌编号
   */
  getCardNumber(suit: Suit, rank: Rank): number {
    const suits: Suit[] = ['spade', 'heart', 'club', 'diamond'];
    const ranks: Rank[] = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
    
    const suitIndex = suits.indexOf(suit); // 0=黑桃，1=红桃，2=梅花，3=方块
    const rankIndex = ranks.indexOf(rank); // 0=A, 1=2, ..., 12=K
    
    // 计算编号：suitIndex * 13 + rankIndex + 1
    // 黑桃: 0*13 + rankIndex + 1 = 1-13
    // 红桃: 1*13 + rankIndex + 1 = 14-26
    // 梅花: 2*13 + rankIndex + 1 = 27-39
    // 方块: 3*13 + rankIndex + 1 = 40-52
    return suitIndex * 13 + rankIndex + 1;
  }

  /**
   * 进入复盘模式
   */
  enterReviewMode() {
    this.isReviewMode = true;
    this.inputCards = [];
    this.selectedSuit = 'spade';
    // 计时继续，不停止
  }

  /**
   * 选择花色
   */
  selectSuit(suit: Suit) {
    this.selectedSuit = suit;
  }

  /**
   * 输入点数
   */
  inputRank(rank: Rank) {
    // 限制输入不超过52张
    if (this.inputCards.length >= 52) {
      promptAction.showToast({
        message: '已输入52张牌，无法继续输入',
        duration: 2000
      });
      return;
    }

    this.inputCards.push({
      suit: this.selectedSuit,
      rank: rank
    });
    // 当输入超过7张牌时，自动滚动到最右边
    if (this.inputCards.length > 7) {
      // 延迟滚动，确保UI更新完成
      setTimeout(() => {
        // 计算总宽度：第一张228px + 后续每张偏移60px + 占位100px
        const totalWidth = 228 + (this.inputCards.length - 1) * 60 + 100;
        // 滚动到最右边（减去一个屏幕宽度，确保最后一张牌可见）
        // 假设屏幕宽度约为400px，计算需要滚动的距离
        const scrollOffset = Math.max(0, totalWidth - 400);
        try {
          this.reviewScroller.scrollTo({ xOffset: scrollOffset, yOffset: 0, animation: false });
        } catch (err) {
          console.error('滚动失败', err);
        }
      }, 100);
    }
  }

  /**
   * 撤销最后一张
   */
  undoLastCard() {
    if (this.inputCards.length > 0) {
      this.inputCards.pop();
    }
  }

  /**
   * 提交答案
   */
  async submitAnswer() {
    if (this.inputCards.length !== 52) {
      promptAction.showToast({
        message: `请输入52张牌，当前输入${this.inputCards.length}张`,
        duration: 2000
      });
      return;
    }

    // 停止计时
    this.stopTimer();

    // 验证答案
    let correctCount = 0;
    for (let i = 0; i < 52; i++) {
      const correctCard = this.getCardInfo(this.pokerCards[i]);
      const inputCard = this.inputCards[i];
      if (correctCard.suit === inputCard.suit && correctCard.rank === inputCard.rank) {
        correctCount++;
      }
    }

    const accuracy = ((correctCount / 52) * 100).toFixed(1);
    this.isExamPassed = correctCount === 52;
    
    // 如果全部正确，记录到数据库
    if (this.isExamPassed) {
      await this.recordExamData();
    }

    // 显示结果对话框
    this.resultMessage = `答题完成！\n正确：${correctCount}/52\n准确率：${accuracy}%\n用时：${this.formatTime(this.elapsedTime)}`;
    this.showResultDialog = true;
  }

  /**
   * 记录考试数据
   */
  async recordExamData() {
    try {
      const now = new Date();
      const examDate = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
      const examTime = Date.now();
      
      const record: PokerExamRecord = {
        examDate: examDate,
        examTime: examTime,
        duration: this.elapsedTime
      };
      
      await this.dbManager.insertPokerExamRecord(record);
      console.info('扑克记忆考试记录成功');
    } catch (err) {
      console.error('记录考试数据失败:', err);
    }
  }

  /**
   * 获取花色图片资源
   */
  getSuitImageResource(suit: Suit): Resource {
    const suitMap: Record<Suit, string> = {
      'spade': 'app.media.ic_spade',
      'heart': 'app.media.ic_heart',
      'club': 'app.media.ic_club',
      'diamond': 'app.media.ic_diamond'
    };
    return $r(suitMap[suit]);
  }

  /**
   * 获取花色中文名称
   */
  getSuitName(suit: Suit): string {
    const suitMap: Record<Suit, string> = {
      'spade': '黑桃',
      'heart': '红桃',
      'club': '梅花',
      'diamond': '方块'
    };
    return suitMap[suit];
  }

  build() {
    if (this.isReviewMode) {
      // 复盘模式
      this.buildReviewMode();
    } else {
      // 记忆模式
      this.buildMemoryMode();
    }
  }

  @Builder
  buildMemoryMode() {
    Stack() {
      // 主内容
      Column() {
        // 标题栏（固定，不滚动）
        Row() {
          Button() {
            Image($r('sys.media.ohos_ic_back'))
              .width(20)
              .height(20)
          }
          .width(36)
          .height(36)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })

          Text('扑克记忆考试')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.text_primary'))

          Blank()
            .width(36)
            .height(36)
        }
        .width('100%')
        .height(48)
        .padding({ left: 12, right: 12, top: 8, bottom: 8 })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 10 })

        // 计时显示（参考110数字桩考试页面）
        Row() {
          Column() {
            Text('时间')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text(this.formatTime(this.elapsedTime))
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 5 })
          }
          .flexGrow(1)
        }
        .width('100%')
        .height(60)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)
        .margin({ bottom: 10 })

        // 可滚动内容区域
        Column() {
          // 扑克牌显示区域（显示所有52张牌，叠加显示，水平滚动）
          Scroll() {
            Stack() {
              // 从前往后渲染，后面的牌在上层
              ForEach(this.pokerCards, (cardNumber: number, index: number) => {
                Image(this.getPokerImageResource(cardNumber))
                  .width(300)
                  .height(420)
                  .objectFit(ImageFit.Fill)
                  .borderRadius(8)
                  .position({ 
                    x: index * 60 // 每张牌向右偏移60px，在前一张的1/5位置开始显示，形成覆盖效果
                  })
                  .zIndex(index) // 后面的牌在上层
              }, (cardNumber: number, index: number) => `card_${cardNumber}_${index}`)
            }
            .width(300 + (this.pokerCards.length - 1) * 60) // 动态计算宽度：第一张300px + 后续每张偏移60px
            .height(420)
            .alignContent(Alignment.Start) // 左对齐，第一张牌从左边开始
          }
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Auto)
          .width('100%')
          .height(420)
          .margin({ bottom: 20 })

          // 记完按钮
          Button('记完')
            .width('80%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#4CAF50')
            .fontColor(Color.White)
            .borderRadius(25)
            .onClick(() => {
              this.enterReviewMode();
            })
            .margin({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .alignItems(HorizontalAlign.Center)
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 12 })
      .backgroundColor('#F5F5F5')
    }
  }

  @Builder
  buildReviewMode() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_back'))
            .width(20)
            .height(20)
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.isReviewMode = false;
        })

        Text('复盘')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.text_primary'))

        Blank()
          .width(36)
          .height(36)
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 10 })

      // 计时和输入统计显示（参考110数字桩考试页面）
      Row() {
        Column() {
          Text('时间')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(this.formatTime(this.elapsedTime))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 5 })
        }
        .flexGrow(1)

        Column() {
          Text('已输入')
            .fontSize(12)
            .fontColor($r('app.color.text_secondary'))
          Text(`${this.inputCards.length}/52`)
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 5 })
        }
        .flexGrow(1)
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceAround)
      .margin({ bottom: 10 })
      .width('100%')
      .backgroundColor(Color.White)
      .margin({ bottom: 0 })

      // 输入的牌显示区域（覆盖效果，类似记忆阶段）
      Scroll(this.reviewScroller) {
        Stack() {
          // 从前往后渲染，后面的牌在上层
          ForEach(this.inputCards, (card: InputCard, index: number) => {
            Image(this.getPokerImageResource(this.getCardNumber(card.suit, card.rank)))
              .width(228)
              .height(320)
              .objectFit(ImageFit.Fill)
              .borderRadius(8)
              .position({ 
                x: index * 60 // 每张牌向右偏移60px，形成覆盖效果
              })
              .zIndex(index) // 后面的牌在上层
          }, (card: InputCard, index: number) => `input_${index}_${card.suit}_${card.rank}`)
          
          // 添加一个小的透明占位元素，确保最后一张牌可见（只添加很小的边距）
          if (this.inputCards.length > 0) {
            Image($r('app.media.poker_01'))
              .width(100)
              .height(320)
              .opacity(0) // 完全透明
              .position({ 
                x: this.inputCards.length * 60 + 228 // 放在最后一张牌后面
              })
              .zIndex(this.inputCards.length)
          }
        }
        .width(this.inputCards.length > 0 ? 228 + (this.inputCards.length - 1) * 60 + 100 : 228) // 总宽度：第一张228px + 后续每张偏移60px + 占位100px（只保留很小的边距）
        .height(320)
        .alignContent(Alignment.Start) // 左对齐，第一张牌从左边开始
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Auto)
      .width('100%')
      .height(320)
      .margin({ bottom: 10 })
      .edgeEffect(EdgeEffect.Spring) // 添加边缘效果，可能有助于滚动

      // 自定义键盘
      Column() {
        // 第一行：花色选择
        Row() {
          ForEach(['spade', 'heart', 'club', 'diamond'] as Suit[], (suit: Suit) => {
            Column() {
              Image(this.getSuitImageResource(suit))
                .width(42)
                .height(42)
                .opacity(this.selectedSuit === suit ? 1 : 0.5)
            }
            .layoutWeight(1)
            .height(65)
            .margin({ left:2 ,right: 2 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.selectedSuit === suit ? '#2196F3' : Color.White)
            .borderRadius(6)
            .border({ 
              width: this.selectedSuit === suit ? 2 : 1, 
              color: this.selectedSuit === suit ? '#2196F3' : '#CCCCCC' 
            })
            .onClick(() => {
              this.selectSuit(suit);
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 4 })

        // 第二行：A、2、3、4、5
        Row() {
          ForEach(['A', '2', '3', '4', '5'] as Rank[], (rank: Rank) => {
            Column() {
              Text(rank)
                .fontSize(25)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .layoutWeight(1)
            .height(65)
            .margin({ left:2 ,right: 2})
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(6)
            .border({ width: 1, color: '#CCCCCC' })
            .onClick(() => {
              this.inputRank(rank);
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 4 })

        // 第三行：6、7、8、9、10
        Row() {
          ForEach(['6', '7', '8', '9', '10'] as Rank[], (rank: Rank) => {
            Column() {
              Text(rank)
                .fontSize(25)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .layoutWeight(1)
            .height(65)
            .margin({ left:2 ,right: 2 })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(6)
            .border({ width: 1, color: '#CCCCCC' })
            .onClick(() => {
              this.inputRank(rank);
            })
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 4 })

        // 第四行：撤销、J、Q、K、提交
        Row() {
          Column() {
            Text('撤销')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
          .height(65)
          .margin({ left:2 ,right: 2 })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FF9800')
          .borderRadius(6)
          .onClick(() => {
            this.undoLastCard();
          })

          ForEach(['J', 'Q', 'K'] as Rank[], (rank: Rank) => {
            Column() {
              Text(rank)
                .fontSize(25)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
            }
            .layoutWeight(1)
            .height(65)
            .margin({ left:2 ,right: 2})
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(Color.White)
            .borderRadius(6)
            .border({ width: 1, color: '#CCCCCC' })
            .onClick(() => {
              this.inputRank(rank);
            })
          })

          Column() {
            Text('提交')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
          }
          .layoutWeight(1)
          .margin({ left:2 ,right: 2})
          .height(65)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#4CAF50')
          .borderRadius(6)
          .onClick(() => {
            this.submitAnswer();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('100%')
      .padding(10)
      .backgroundColor('#F5F5F5')
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')

    // 结果对话框
    if (this.showResultDialog) {
      Column() {
        Column() {
          if (this.isExamPassed) {
            Text('考试通过')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#4CAF50')
              .margin({ bottom: 20 })
            
            Text('恭喜！你已成功完成所有52张牌的回忆')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })
          } else {
            Text('考试失败')
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor('#F44336')
              .margin({ bottom: 20 })
            
            Text('很遗憾，未能全部答对')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .textAlign(TextAlign.Center)
              .margin({ bottom: 20 })
          }
          
          Text(this.resultMessage)
            .fontSize(16)
            .fontColor($r('app.color.text_primary'))
            .textAlign(TextAlign.Center)
            .margin({ bottom: 30 })
          
          Row() {
            Button('重新开始')
              .width('40%')
              .height(45)
              .backgroundColor('#2196F3')
              .fontColor(Color.White)
              .onClick(() => {
                this.showResultDialog = false;
                this.isReviewMode = false;
                this.initPokerCards();
                this.startTimer();
              })
            
            Button('返回')
              .width('40%')
              .height(45)
              .backgroundColor('#999999')
              .fontColor(Color.White)
              .onClick(() => {
                this.showResultDialog = false;
                router.back();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceAround)
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
}

