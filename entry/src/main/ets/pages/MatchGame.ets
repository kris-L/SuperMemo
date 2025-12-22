import { router } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';
import { ProvinceService } from '../utils/ProvinceService';
import { Province } from '../model/Province';
import { SimpleItemService } from '../utils/SimpleItemService';
import { SimpleItem } from '../model/SimpleItem';
import { DatabaseManager } from '../database/DatabaseManager';

/**
 * 游戏卡片数据
 */
interface GameCard {
  id: number;
  dataType: string; // 数据类型：'110数字桩'、'34省'、'36计'、'三字经'
  peg?: NumberPeg; // 数字桩数据（当dataType为'110数字桩'时使用）
  province?: Province; // 省份数据（当dataType为'34省'时使用）
  simpleItem?: SimpleItem; // 简单数据项（当dataType为'36计'或'三字经'时使用）
  displayType: string; // 显示类型：matchType1 或 matchType2
  isFlipped: boolean; // 是否翻转
  isMatched: boolean; // 是否已匹配
  isSelected: boolean; // 是否选中（用于UI更新）
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
  @State usedPegCount: number = 0; // 已使用过的数据数量（用于UI更新）
  
  private timer: number | null = null;
  private dataType: string = '';
  private matchType1: string = '';
  private matchType2: string = '';
  private usedPegNumbers: Set<number> = new Set(); // 已使用过的数字桩编号
  private usedProvinceNumbers: Set<number> = new Set(); // 已使用过的省份编号
  private usedSimpleItemNumbers: Set<number> = new Set(); // 已使用过的简单数据项编号
  private allPegs: NumberPeg[] = []; // 所有数字桩数据
  private allProvinces: Province[] = []; // 所有省份数据
  private allSimpleItems: SimpleItem[] = []; // 所有简单数据项（36计或三字经）
  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, string>;
    this.dataType = params['dataType'] || '110数字桩';
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
      if (this.dataType === '110数字桩') {
        const service = NumberPegService.getInstance();
        this.allPegs = await service.getAllNumberPegs();
        
        // 重置已使用列表（首次游戏）
        if (this.usedPegNumbers.size === 0) {
          this.elapsedTime = 0;
          this.correctCount = 0;
          this.errorCount = 0;
          this.startTimer();
        }
      } else if (this.dataType === '34省') {
        const service = ProvinceService.getInstance();
        this.allProvinces = service.getAllProvinces();
        
        // 重置已使用列表（首次游戏）
        if (this.usedProvinceNumbers.size === 0) {
          this.elapsedTime = 0;
          this.correctCount = 0;
          this.errorCount = 0;
          this.startTimer();
        }
      } else if (this.dataType === '36计') {
        const service = SimpleItemService.getInstance();
        this.allSimpleItems = service.getAllStratagems();
        
        // 重置已使用列表（首次游戏）
        if (this.usedSimpleItemNumbers.size === 0) {
          this.elapsedTime = 0;
          this.correctCount = 0;
          this.errorCount = 0;
          this.startTimer();
        }
      } else if (this.dataType === '三字经') {
        const service = SimpleItemService.getInstance();
        this.allSimpleItems = service.getAllSanZiJing();
        
        // 重置已使用列表（首次游戏）
        if (this.usedSimpleItemNumbers.size === 0) {
          this.elapsedTime = 0;
          this.correctCount = 0;
          this.errorCount = 0;
          this.startTimer();
        }
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
    if (this.dataType === '110数字桩') {
      // 获取未使用过的数字桩
      const availablePegs = this.allPegs.filter(peg => !this.usedPegNumbers.has(peg.number));
      
      // 如果所有数字桩都已使用，游戏结束
      if (availablePegs.length === 0) {
        this.isGameOver = true;
        if (this.timer !== null) {
          clearInterval(this.timer);
          this.timer = null;
        }
        // 记录训练数据
        this.recordTrainingData();
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
      this.cards = [];
      let cardId = 0;
      for (const peg of selectedPegs) {
        // 第一张卡片（显示 matchType1）
        this.cards.push({
          id: cardId++,
          dataType: '110数字桩',
          peg: peg,
          displayType: this.matchType1,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
        // 第二张卡片（显示 matchType2，配对）
        this.cards.push({
          id: cardId++,
          dataType: '110数字桩',
          peg: peg,
          displayType: this.matchType2,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
      }
    } else if (this.dataType === '34省') {
      // 获取未使用过的省份
      const availableProvinces = this.allProvinces.filter(province => !this.usedProvinceNumbers.has(province.number));
      
      // 如果所有省份都已使用，游戏结束
      if (availableProvinces.length === 0) {
        this.isGameOver = true;
        if (this.timer !== null) {
          clearInterval(this.timer);
          this.timer = null;
        }
        // 记录训练数据
        this.recordTrainingData();
        return;
      }
      
      // 随机抽取6个数据（12张卡片）
      const selectedProvinces: Province[] = [];
      const usedIndices: Set<number> = new Set();
      
      const maxCount = Math.min(6, availableProvinces.length);
      while (selectedProvinces.length < maxCount) {
        const randomIndex = Math.floor(Math.random() * availableProvinces.length);
        if (!usedIndices.has(randomIndex)) {
          usedIndices.add(randomIndex);
          selectedProvinces.push(availableProvinces[randomIndex]);
          // 标记为已使用
          this.usedProvinceNumbers.add(availableProvinces[randomIndex].number);
          // 更新UI状态
          this.usedPegCount = this.usedProvinceNumbers.size;
        }
      }
      
      // 创建卡片（每对数据创建2张卡片，一张显示matchType1，一张显示matchType2）
      this.cards = [];
      let cardId = 0;
      for (const province of selectedProvinces) {
        // 第一张卡片（显示 matchType1）
        this.cards.push({
          id: cardId++,
          dataType: '34省',
          province: province,
          displayType: this.matchType1,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
        // 第二张卡片（显示 matchType2，配对）
        this.cards.push({
          id: cardId++,
          dataType: '34省',
          province: province,
          displayType: this.matchType2,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
      }
    } else if (this.dataType === '36计' || this.dataType === '三字经') {
      // 获取未使用过的简单数据项
      const availableItems = this.allSimpleItems.filter(item => !this.usedSimpleItemNumbers.has(item.number));
      
      // 如果所有数据都已使用，游戏结束
      if (availableItems.length === 0) {
        this.isGameOver = true;
        if (this.timer !== null) {
          clearInterval(this.timer);
          this.timer = null;
        }
        // 记录训练数据
        this.recordTrainingData();
        return;
      }
      
      // 随机抽取6个数据（12张卡片）
      const selectedItems: SimpleItem[] = [];
      const usedIndices: Set<number> = new Set();
      
      const maxCount = Math.min(6, availableItems.length);
      while (selectedItems.length < maxCount) {
        const randomIndex = Math.floor(Math.random() * availableItems.length);
        if (!usedIndices.has(randomIndex)) {
          usedIndices.add(randomIndex);
          selectedItems.push(availableItems[randomIndex]);
          // 标记为已使用
          this.usedSimpleItemNumbers.add(availableItems[randomIndex].number);
          // 更新UI状态
          this.usedPegCount = this.usedSimpleItemNumbers.size;
        }
      }
      
      // 创建卡片（每对数据创建2张卡片，一张显示matchType1，一张显示matchType2）
      this.cards = [];
      let cardId = 0;
      for (const item of selectedItems) {
        // 第一张卡片（显示 matchType1）
        this.cards.push({
          id: cardId++,
          dataType: this.dataType,
          simpleItem: item,
          displayType: this.matchType1,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
        // 第二张卡片（显示 matchType2，配对）
        this.cards.push({
          id: cardId++,
          dataType: this.dataType,
          simpleItem: item,
          displayType: this.matchType2,
          isFlipped: true,
          isMatched: false,
          isSelected: false
        });
      }
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

    // 创建新数组以触发UI更新
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      if (i === cardIndex) {
        // 切换选中状态
        const card = this.cards[i];
        if (card.dataType === '110数字桩') {
          newCards.push({
            id: card.id,
            dataType: card.dataType,
            peg: card.peg,
            displayType: card.displayType,
            isFlipped: card.isFlipped,
            isMatched: card.isMatched,
            isSelected: !card.isSelected
          });
        } else if (card.dataType === '34省') {
          newCards.push({
            id: card.id,
            dataType: card.dataType,
            province: card.province,
            displayType: card.displayType,
            isFlipped: card.isFlipped,
            isMatched: card.isMatched,
            isSelected: !card.isSelected
          });
        } else if (card.dataType === '36计' || card.dataType === '三字经') {
          newCards.push({
            id: card.id,
            dataType: card.dataType,
            simpleItem: card.simpleItem,
            displayType: card.displayType,
            isFlipped: card.isFlipped,
            isMatched: card.isMatched,
            isSelected: !card.isSelected
          });
        }
      } else {
        newCards.push(this.cards[i]);
      }
    }
    this.cards = newCards;

    // 更新选中列表
    const selectedIndex = this.selectedCards.indexOf(cardId);
    if (selectedIndex !== -1) {
      // 取消选中
      const newSelectedCards: number[] = [];
      for (let i = 0; i < this.selectedCards.length; i++) {
        if (i !== selectedIndex) {
          newSelectedCards.push(this.selectedCards[i]);
        }
      }
      this.selectedCards = newSelectedCards;
    } else {
      // 添加到选中列表
      const newSelectedCards: number[] = [];
      for (let i = 0; i < this.selectedCards.length; i++) {
        newSelectedCards.push(this.selectedCards[i]);
      }
      newSelectedCards.push(cardId);
      this.selectedCards = newSelectedCards;

      // 如果选中了两张卡片，立即检查是否匹配
      if (this.selectedCards.length === 2) {
        this.checkMatch();
      }
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

    // 两两配对：必须一个是 matchType1，一个是 matchType2，且对应同一个数据
    let isMatch = false;
    if (card1.dataType === '110数字桩' && card2.dataType === '110数字桩') {
      isMatch = card1.peg !== undefined && card2.peg !== undefined &&
                card1.peg.number === card2.peg.number && 
                card1.displayType !== card2.displayType;
    } else if (card1.dataType === '34省' && card2.dataType === '34省') {
      isMatch = card1.province !== undefined && card2.province !== undefined &&
                card1.province.number === card2.province.number && 
                card1.displayType !== card2.displayType;
    } else if ((card1.dataType === '36计' || card1.dataType === '三字经') && 
               (card2.dataType === '36计' || card2.dataType === '三字经') &&
               card1.dataType === card2.dataType) {
      isMatch = card1.simpleItem !== undefined && card2.simpleItem !== undefined &&
                card1.simpleItem.number === card2.simpleItem.number && 
                card1.displayType !== card2.displayType;
    }

    // 重新创建数组以触发状态更新
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      if (i === card1Index || i === card2Index) {
        // 更新卡片状态
        const card = this.cards[i];
        if (isMatch) {
          // 匹配成功：标记为已匹配（会消失）
          if (card.dataType === '110数字桩') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              peg: card.peg,
              displayType: card.displayType,
              isFlipped: true,
              isMatched: true,
              isSelected: false
            });
          } else if (card.dataType === '34省') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              province: card.province,
              displayType: card.displayType,
              isFlipped: true,
              isMatched: true,
              isSelected: false
            });
          } else if (card.dataType === '36计' || card.dataType === '三字经') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              simpleItem: card.simpleItem,
              displayType: card.displayType,
              isFlipped: true,
              isMatched: true,
              isSelected: false
            });
          }
        } else {
          // 匹配失败：取消选中状态
          if (card.dataType === '110数字桩') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              peg: card.peg,
              displayType: card.displayType,
              isFlipped: card.isFlipped,
              isMatched: card.isMatched,
              isSelected: false
            });
          } else if (card.dataType === '34省') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              province: card.province,
              displayType: card.displayType,
              isFlipped: card.isFlipped,
              isMatched: card.isMatched,
              isSelected: false
            });
          } else if (card.dataType === '36计' || card.dataType === '三字经') {
            newCards.push({
              id: card.id,
              dataType: card.dataType,
              simpleItem: card.simpleItem,
              displayType: card.displayType,
              isFlipped: card.isFlipped,
              isMatched: card.isMatched,
              isSelected: false
            });
          }
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

  /**
   * 获取游戏结束提示信息
   */
  getGameOverMessage(): string {
    if (this.dataType === '110数字桩') {
      return '所有110个数字桩已完成！';
    } else if (this.dataType === '34省') {
      return '所有34个省已完成！';
    } else if (this.dataType === '36计') {
      return '所有36计已完成！';
    } else if (this.dataType === '三字经') {
      return '所有三字经内容已完成！';
    }
    return '游戏完成！';
  }

  /**
   * 获取总数据数量
   */
  getTotalCount(): number {
    if (this.dataType === '110数字桩') {
      return 110;
    } else if (this.dataType === '34省') {
      return 34;
    } else if (this.dataType === '36计') {
      return 36;
    } else if (this.dataType === '三字经') {
      return this.allSimpleItems.length;
    }
    return 110;
  }

  /**
   * 记录训练数据
   */
  async recordTrainingData() {
    try {
      await this.dbManager.insertTrainingRecord({
        gameType: '连连看',
        duration: this.elapsedTime,
        createTime: Date.now()
      });
    } catch (err) {
      console.error('记录训练数据失败', err);
    }
  }

  build() {
    Column() {
      // 顶部栏 + 统计
      Column() {
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

          Text('连连看')
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
            Text('正确')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
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
              .fontColor($r('app.color.text_secondary'))
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
      }

      // 游戏区域
      Grid() {
        ForEach(this.cards, (card: GameCard) => {
          GridItem() {
            this.createCard(card, card.isSelected);
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
        Text(`进度: ${this.usedPegCount}/${this.getTotalCount()}`)
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
          .margin({ top: 10 })
      }

      // 游戏结束提示（居中显示）
      if (this.isGameOver) {
        Column() {
          Column() {
            Text('恭喜完成！')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 20 })
            
            Text(this.getGameOverMessage())
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 20 })
            
            Text(`总用时: ${this.formatTime(this.elapsedTime)}`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 10 })
            
            Text(`正确: ${this.correctCount} 次`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 10 })
            
            Text(`错误: ${this.errorCount} 次`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 30 })
            
            Row() {
              Button('再来一局')
                .width('40%')
                .height(45)
                .backgroundColor('#2196F3')
                .onClick(() => {
                  if (this.dataType === '110数字桩') {
                    this.usedPegNumbers.clear();
                  } else if (this.dataType === '34省') {
                    this.usedProvinceNumbers.clear();
                  } else if (this.dataType === '36计' || this.dataType === '三字经') {
                    this.usedSimpleItemNumbers.clear();
                  }
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
                  // 清空路由栈并返回到首页
                  router.clear();
                  router.replaceUrl({ url: 'pages/Index' });
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
          if (card.dataType === '110数字桩' && card.peg) {
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
          } else if (card.dataType === '34省' && card.province) {
            if (card.displayType === '省序号') {
              // 显示省序号
              Text(card.province.number.toString())
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            } else if (card.displayType === '省全称') {
              // 显示省全称
              Text(card.province.fullName)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            } else if (card.displayType === '省会') {
              // 显示省会
              Text(card.province.capital)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            } else if (card.displayType === '省简称') {
              // 显示省简称
              Text(card.province.shortName)
                .fontSize(28)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            }
          } else if ((card.dataType === '36计' || card.dataType === '三字经') && card.simpleItem) {
            if (card.displayType === '序号') {
              // 显示序号
              Text(card.simpleItem.number.toString())
                .fontSize(36)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
            } else if (card.displayType === '内容') {
              // 显示内容
              Text(card.simpleItem.content)
                .fontSize(22)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
            }
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
              .fontSize(24)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(36)
          .height(36)
          .justifyContent(FlexAlign.Center)
          .backgroundColor('#FF0000')
          .borderRadius(18)
          .margin({ top: 6, right: 6 })
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

