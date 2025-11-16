import { router } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';

/**
 * 游戏卡片数据
 */
interface GameCard {
  id: number;
  peg: NumberPeg;
  displayType: string; // 显示类型：matchType1 或 matchType2
  isFlipped: boolean; // 是否翻转
  isMatched: boolean; // 是否已匹配
}

/**
 * 连连看游戏页面
 */
@Entry
@Component
struct MatchGame {
  @State cards: GameCard[] = [];
  @State selectedCards: number[] = []; // 选中的卡片ID
  @State elapsedTime: number = 0; // 消耗时间（秒）
  @State correctCount: number = 0; // 正确消除数
  @State errorCount: number = 0; // 错误消除数
  @State isGameOver: boolean = false;
  @State isRoundComplete: boolean = false; // 当前轮次是否完成
  @State usedPegCount: number = 0; // 已使用过的数字桩数量（用于UI更新）
  
  private timer: number | null = null;
  private dataType: string = '';
  private matchType1: string = '';
  private matchType2: string = '';
  private usedPegNumbers: Set<number> = new Set(); // 已使用过的数字桩编号
  private allPegs: NumberPeg[] = []; // 所有数字桩数据

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, string>;
    this.dataType = params['dataType'] || '101数字桩';
    this.matchType1 = params['matchType1'] || '桩序号';
    this.matchType2 = params['matchType2'] || '桩图像';
    
    this.initGame();
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * 初始化游戏
   */
  async initGame() {
    try {
      const service = NumberPegService.getInstance();
      this.allPegs = await service.getAllNumberPegs();
      
      // 重置已使用列表（首次游戏）
      if (this.usedPegNumbers.size === 0) {
        this.elapsedTime = 0;
        this.correctCount = 0;
        this.errorCount = 0;
        this.startTimer();
      }
      
      // 加载新一轮卡片
      this.loadNextRound();
    } catch (error) {
      console.error('初始化游戏失败:', error);
    }
  }

  /**
   * 加载下一轮卡片
   */
  loadNextRound() {
    // 获取未使用过的数字桩
    const availablePegs = this.allPegs.filter(peg => !this.usedPegNumbers.has(peg.number));
    
    // 如果所有数字桩都已使用，游戏结束
    if (availablePegs.length === 0) {
      this.isGameOver = true;
      if (this.timer !== null) {
        clearInterval(this.timer);
        this.timer = null;
      }
      return;
    }
    
    // 随机抽取6个数据（12张卡片）
    const selectedPegs: NumberPeg[] = [];
    const usedIndices: Set<number> = new Set();
    
    const maxCount = Math.min(6, availablePegs.length);
    while (selectedPegs.length < maxCount) {
      const randomIndex = Math.floor(Math.random() * availablePegs.length);
      if (!usedIndices.has(randomIndex)) {
        usedIndices.add(randomIndex);
        selectedPegs.push(availablePegs[randomIndex]);
        // 标记为已使用
        this.usedPegNumbers.add(availablePegs[randomIndex].number);
        // 更新UI状态
        this.usedPegCount = this.usedPegNumbers.size;
      }
    }
    
    // 创建卡片（每对数据创建2张卡片，一张显示matchType1，一张显示matchType2）
    // 传统连连看：开局所有卡片都正面显示
    this.cards = [];
    let cardId = 0;
    for (const peg of selectedPegs) {
      // 第一张卡片（显示 matchType1）
      this.cards.push({
        id: cardId++,
        peg: peg,
        displayType: this.matchType1,
        isFlipped: true, // 开局就显示内容
        isMatched: false
      });
      // 第二张卡片（显示 matchType2，配对）
      this.cards.push({
        id: cardId++,
        peg: peg,
        displayType: this.matchType2,
        isFlipped: true, // 开局就显示内容
        isMatched: false
      });
    }
    
    // 打乱卡片顺序
    this.shuffleCards();
    
    this.isRoundComplete = false;
    this.selectedCards = [];
  }

  /**
   * 打乱卡片顺序
   */
  shuffleCards() {
    for (let i = this.cards.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      let GeneratedDestructArray_1 = [this.cards[j], this.cards[i]];
      this.cards[i] = GeneratedDestructArray_1[0];
      this.cards[j] = GeneratedDestructArray_1[1];
    }
  }

  /**
   * 开始计时
   */
  startTimer() {
    this.timer = setInterval(() => {
      this.elapsedTime++;
    }, 1000);
  }

  /**
   * 点击卡片（传统连连看：直接点击配对）
   */
  onCardClick(cardId: number) {
    const cardIndex = this.cards.findIndex(c => c.id === cardId);
    if (cardIndex === -1) {
      return;
    }
    
    const card = this.cards[cardIndex];
    // 已匹配的卡片不能点击
    if (!card || card.isMatched || this.isGameOver) {
      return;
    }

    // 如果已经选中了这张卡片，取消选中
    const selectedIndex = this.selectedCards.indexOf(cardId);
    if (selectedIndex !== -1) {
      this.selectedCards.splice(selectedIndex, 1);
      return;
    }

    // 添加到选中列表
    this.selectedCards.push(cardId);

    // 如果选中了两张卡片，立即检查是否匹配
    if (this.selectedCards.length === 2) {
      this.checkMatch();
    }
  }

  /**
   * 检查匹配
   */
  checkMatch() {
    if (this.selectedCards.length !== 2) {
      return;
    }

    const card1Index = this.cards.findIndex(c => c.id === this.selectedCards[0]);
    const card2Index = this.cards.findIndex(c => c.id === this.selectedCards[1]);

    if (card1Index === -1 || card2Index === -1) {
      return;
    }

    const card1 = this.cards[card1Index];
    const card2 = this.cards[card2Index];

    // 两两配对：必须一个是 matchType1，一个是 matchType2，且对应同一个 NumberPeg
    const isMatch = card1.peg.number === card2.peg.number && 
                    card1.displayType !== card2.displayType;

    // 重新创建数组以触发状态更新
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      if (i === card1Index || i === card2Index) {
        // 更新卡片状态
        if (isMatch) {
          // 匹配成功：标记为已匹配（会消失）
          newCards.push({
            id: this.cards[i].id,
            peg: this.cards[i].peg,
            displayType: this.cards[i].displayType,
            isFlipped: true,
            isMatched: true
          });
        } else {
          // 匹配失败：保持原状（不匹配的卡片保持显示）
          newCards.push(this.cards[i]);
        }
      } else {
        newCards.push(this.cards[i]);
      }
    }
    this.cards = newCards;

    if (isMatch) {
      // 匹配成功
      this.correctCount++;
      
      // 检查当前轮次是否完成
      if (this.cards.every(c => c.isMatched)) {
        this.isRoundComplete = true;
        // 快速加载下一轮
        this.loadNextRound();
      }
    } else {
      // 匹配失败：清空选中，让用户重新选择
      this.errorCount++;
    }

    // 清空选中列表
    this.selectedCards = [];
  }

  /**
   * 格式化时间显示
   */
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 顶部统计信息
      Row() {
        Column() {
          Text('时间')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.formatTime(this.elapsedTime))
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 5 })
        }
        .flexGrow(1)

        Column() {
          Text('正确')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.correctCount.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#4CAF50')
            .margin({ top: 5 })
        }
        .flexGrow(1)

        Column() {
          Text('错误')
            .fontSize(12)
            .fontColor('#666666')
          Text(this.errorCount.toString())
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
            .fontColor('#F44336')
            .margin({ top: 5 })
        }
        .flexGrow(1)
      }
      .width('100%')
      .height(60)
      .padding({ left: 20, right: 20 })
      .backgroundColor(Color.White)
      .justifyContent(FlexAlign.SpaceAround)

      // 游戏区域
      Grid() {
        ForEach(this.cards, (card: GameCard) => {
          GridItem() {
            this.createCard(card, this.selectedCards.includes(card.id));
          }
        })
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr 1fr')
      .columnsGap(10)
      .rowsGap(10)
      .width('95%')
      .height('70%')
      .margin({ top: 20 })

      // 进度提示
      if (!this.isGameOver) {
        Text(`进度: ${this.usedPegCount}/101`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ top: 10 })
      }

      // 游戏结束提示
      if (this.isGameOver) {
        Column() {
          Text('恭喜完成！')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .margin({ bottom: 20 })
          
          Text('所有101个数字桩已完成！')
            .fontSize(16)
            .fontColor('#666666')
            .margin({ bottom: 20 })
          
          Text(`总用时: ${this.formatTime(this.elapsedTime)}`)
            .fontSize(18)
            .margin({ bottom: 10 })
          
          Text(`正确: ${this.correctCount} 次`)
            .fontSize(18)
            .margin({ bottom: 10 })
          
          Text(`错误: ${this.errorCount} 次`)
            .fontSize(18)
            .margin({ bottom: 30 })
          
          Row() {
            Button('再来一局')
              .width('40%')
              .height(45)
              .backgroundColor('#4CAF50')
              .onClick(() => {
                this.usedPegNumbers.clear();
                this.usedPegCount = 0;
                this.elapsedTime = 0;
                this.correctCount = 0;
                this.errorCount = 0;
                this.isGameOver = false;
                this.initGame();
              })
            
            Button('返回')
              .width('40%')
              .height(45)
              .backgroundColor('#9E9E9E')
              .onClick(() => {
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
        .margin({ top: 20 })
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 20 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  createCard(card: GameCard, isSelected: boolean) {
    if (card.isMatched) {
      // 已匹配的卡片消失（不显示）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#F5F5F5')
    } else {
      // 传统连连看：所有卡片都正面显示内容
      Stack() {
        // 卡片内容层（底层）
        Column() {
          if (card.displayType === '桩序号') {
            // 显示数字序号
            Text(card.peg.number.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
          } else if (card.displayType === '桩名称') {
            // 显示编码（桩名称）
            Text(card.peg.code)
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
          } else if (card.displayType === '桩图像') {
            // 显示图片，填满整个卡片
            Image($r(`app.media.${card.peg.imageName.replace('.jpg', '')}`))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
          }
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .border({ 
          width: isSelected ? 3 : 1, 
          color: isSelected ? '#FF5722' : '#CCCCCC' 
        })
        
        // 选中状态：右上角红色背景的勾图标（最上层，最后声明）
        if (isSelected) {
          Row() {
            Text('✓')
              .fontSize(30)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(48)
          .height(48)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FF0000')
          .borderRadius(24)
          .margin({ top: 8, right: 8 })
          .position({ x: 'auto', y: 4 }) // 绝对定位：y轴距离顶部4px
          .align(Alignment.TopEnd)
        }
      }
      .width('100%')
      .height('100%')
      .alignContent(Alignment.TopEnd)
      .onClick(() => {
        this.onCardClick(card.id);
      })
    }
  }
}

