import { router, promptAction } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';
import { DatabaseManager, NumberPegExamRecord } from '../database/DatabaseManager';

/**
 * 游戏卡片数据
 */
interface GameCard {
  id: number;
  peg: NumberPeg;
  displayType: string; // 显示类型：'桩序号'、'桩名称'、'桩图像'
  isFlipped: boolean;
  isMatched: boolean;
  isSelected: boolean;
}

/**
 * 配对类型
 */
interface MatchTypes {
  type1: string;
  type2: string;
}

/**
 * 110数字桩考试页面
 */
@Entry
@Component
struct NumberPegExam {
  @State cards: GameCard[] = [];
  @State selectedCards: number[] = []; // 选中的卡片ID
  @State elapsedTime: number = 0; // 消耗时间（秒）
  @State correctCount: number = 0; // 正确消除数
  @State isExamOver: boolean = false; // 考试是否结束
  @State isExamPassed: boolean = false; // 是否通过考试
  @State showErrorDialog: boolean = false; // 是否显示错误提示对话框
  @State errorMessage: string = ''; // 错误提示信息
  @State isRoundComplete: boolean = false; // 当前轮次是否完成
  @State usedPegCount: number = 0; // 已配对成功的数字桩数量（进度）
  
  private timer: number | null = null;
  private usedPegNumbers: Set<number> = new Set(); // 已抽取过的数字桩编号（用于避免重复抽取）
  private completedPegNumbers: Set<number> = new Set(); // 已配对成功的数字桩编号（用于进度显示）
  private allPegs: NumberPeg[] = []; // 所有数字桩数据
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private startTime: number = 0; // 考试开始时间戳（毫秒）

  /**
   * 根据数字桩编号获取配对类型
   * 前36个（0-35）：桩图 ↔ 桩名称
   * 中间36个（36-71）：桩名称 ↔ 桩序号
   * 剩余（72-109）：序号 ↔ 桩图
   */
  private getMatchTypesForPeg(pegNumber: number): MatchTypes {
    if (pegNumber >= 0 && pegNumber <= 35) {
      // 前36个：桩图 ↔ 桩名称
      return { type1: '桩图像', type2: '桩名称' };
    } else if (pegNumber >= 36 && pegNumber <= 71) {
      // 中间36个：桩名称 ↔ 桩序号
      return { type1: '桩名称', type2: '桩序号' };
    } else {
      // 剩余：序号 ↔ 桩图
      return { type1: '桩序号', type2: '桩图像' };
    }
  }

  aboutToAppear() {
    this.initExam();
  }

  /**
   * 页面显示时触发（包括从其他页面返回时）
   */
  onPageShow() {
    // 每次显示页面时都重新初始化，确保状态清空
    this.initExam();
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * 初始化考试
   */
  async initExam() {
    try {
      // 先清理定时器
      if (this.timer !== null) {
        clearInterval(this.timer);
        this.timer = null;
      }
      
      const service = NumberPegService.getInstance();
      this.allPegs = await service.getAllNumberPegs();
      
      // 重置所有状态
      this.cards = [];
      this.selectedCards = [];
      this.elapsedTime = 0;
      this.correctCount = 0;
      this.isExamOver = false;
      this.isExamPassed = false;
      this.showErrorDialog = false;
      this.errorMessage = '';
      this.isRoundComplete = false;
      this.usedPegNumbers.clear();
      this.completedPegNumbers.clear();
      this.usedPegCount = 0;
      this.startTime = Date.now();
      
      // 开始计时
      this.startTimer();
      
      // 加载第一轮卡片
      this.loadNextRound();
    } catch (error) {
      console.error('初始化考试失败:', error);
    }
  }

  /**
   * 加载下一轮卡片
   */
  loadNextRound() {
    // 获取未配对成功的数字桩（排除已完成的）
    const availablePegs = this.allPegs.filter(peg => !this.completedPegNumbers.has(peg.number));
    
    // 如果所有数字桩都已配对成功，考试通过
    if (availablePegs.length === 0) {
      this.isExamOver = true;
      this.isExamPassed = true;
      if (this.timer !== null) {
        clearInterval(this.timer);
        this.timer = null;
      }
      // 记录考试数据
      this.recordExamData();
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
        // 标记为已抽取（用于避免重复抽取）
        this.usedPegNumbers.add(availablePegs[randomIndex].number);
      }
    }
    
    // 创建卡片（每对数据创建2张卡片，根据数字桩编号决定配对类型）
    this.cards = [];
    let cardId = 0;
    for (const peg of selectedPegs) {
      const matchTypes = this.getMatchTypesForPeg(peg.number);
      // 第一张卡片（显示 type1）
      this.cards.push({
        id: cardId++,
        peg: peg,
        displayType: matchTypes.type1,
        isFlipped: true,
        isMatched: false,
        isSelected: false
      });
      // 第二张卡片（显示 type2，配对）
      this.cards.push({
        id: cardId++,
        peg: peg,
        displayType: matchTypes.type2,
        isFlipped: true,
        isMatched: false,
        isSelected: false
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
   * 点击卡片
   */
  onCardClick(cardId: number) {
    if (this.isExamOver) {
      return;
    }

    const cardIndex = this.cards.findIndex(c => c.id === cardId);
    if (cardIndex === -1) {
      return;
    }
    
    const card = this.cards[cardIndex];
    // 已匹配的卡片不能点击
    if (!card || card.isMatched) {
      return;
    }

    // 创建新数组以触发UI更新
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      if (i === cardIndex) {
        // 切换选中状态
        const card = this.cards[i];
        newCards.push({
          id: card.id,
          peg: card.peg,
          displayType: card.displayType,
          isFlipped: card.isFlipped,
          isMatched: card.isMatched,
          isSelected: !card.isSelected
        });
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

    // 检查是否匹配：必须是同一个数字桩，且显示类型不同，且符合配对规则
    const matchTypes = this.getMatchTypesForPeg(card1.peg.number);
    const isMatch = card1.peg.number === card2.peg.number && 
                    card1.displayType !== card2.displayType &&
                    ((card1.displayType === matchTypes.type1 && card2.displayType === matchTypes.type2) ||
                     (card1.displayType === matchTypes.type2 && card2.displayType === matchTypes.type1));

    // 重新创建数组以触发状态更新
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      if (i === card1Index || i === card2Index) {
        // 更新卡片状态
        const card = this.cards[i];
        if (isMatch) {
          // 匹配成功：标记为已匹配（会消失）
          newCards.push({
            id: card.id,
            peg: card.peg,
            displayType: card.displayType,
            isFlipped: true,
            isMatched: true,
            isSelected: false
          });
        } else {
          // 匹配失败：取消选中状态
          newCards.push({
            id: card.id,
            peg: card.peg,
            displayType: card.displayType,
            isFlipped: card.isFlipped,
            isMatched: card.isMatched,
            isSelected: false
          });
        }
      } else {
        newCards.push(this.cards[i]);
      }
    }
    this.cards = newCards;

    if (isMatch) {
      // 匹配成功
      this.correctCount++;
      
      // 标记该数字桩为已完成，并更新进度
      if (!this.completedPegNumbers.has(card1.peg.number)) {
        this.completedPegNumbers.add(card1.peg.number);
        this.usedPegCount = this.completedPegNumbers.size;
      }
      
      // 检查当前轮次是否完成
      if (this.cards.every(c => c.isMatched)) {
        this.isRoundComplete = true;
        // 检查是否所有数字桩都已配对成功
        if (this.completedPegNumbers.size >= 110) {
          // 所有数字桩都已完成，考试通过
          this.isExamOver = true;
          this.isExamPassed = true;
          if (this.timer !== null) {
            clearInterval(this.timer);
            this.timer = null;
          }
          // 记录考试数据
          this.recordExamData();
        } else {
          // 快速加载下一轮
          this.loadNextRound();
        }
      }
    } else {
      // 匹配失败：考试结束，显示错误提示
      this.isExamOver = true;
      if (this.timer !== null) {
        clearInterval(this.timer);
        this.timer = null;
      }
      
      // 构建错误提示信息，显示具体的配对内容
      const peg = card1.peg;
      const matchTypes = this.getMatchTypesForPeg(peg.number);
      let correctPairInfo = '';
      
      // 根据配对类型显示具体内容
      if (peg.number >= 0 && peg.number <= 35) {
        // 前36个：桩图 ↔ 桩名称
        // 显示：桩序号和桩名称
        correctPairInfo = `桩序号：${peg.number}\n桩名称：${peg.code}`;
      } else if (peg.number >= 36 && peg.number <= 71) {
        // 中间36个：桩名称 ↔ 桩序号
        // 显示：桩名称和桩序号
        correctPairInfo = `桩名称：${peg.code}\n桩序号：${peg.number}`;
      } else {
        // 剩余：序号 ↔ 桩图
        // 显示：桩序号和桩名称（桩图对应的名称）
        correctPairInfo = `桩序号：${peg.number}\n桩名称：${peg.code}`;
      }
      
      // 显示用户选错的内容
      let userSelectedInfo = '';
      if (card1.displayType === '桩序号') {
        userSelectedInfo = `你选择了：桩序号 ${card1.peg.number}`;
      } else if (card1.displayType === '桩名称') {
        userSelectedInfo = `你选择了：桩名称 ${card1.peg.code}`;
      } else if (card1.displayType === '桩图像') {
        userSelectedInfo = `你选择了：桩图像（桩序号 ${card1.peg.number}）`;
      }
      
      if (card2.displayType === '桩序号') {
        userSelectedInfo += ` 与 桩序号 ${card2.peg.number}`;
      } else if (card2.displayType === '桩名称') {
        userSelectedInfo += ` 与 桩名称 ${card2.peg.code}`;
      } else if (card2.displayType === '桩图像') {
        userSelectedInfo += ` 与 桩图像（桩序号 ${card2.peg.number}）`;
      }
      
      this.errorMessage = `配对错误！\n\n${userSelectedInfo}\n\n正确配对应该是：\n${correctPairInfo}`;
      this.showErrorDialog = true;
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
   * 记录考试数据
   */
  async recordExamData() {
    try {
      const now = new Date();
      const examDate = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
      const examTime = Date.now();
      
      const record: NumberPegExamRecord = {
        examDate: examDate,
        examTime: examTime,
        duration: this.elapsedTime
      };
      
      await this.dbManager.insertNumberPegExamRecord(record);
      console.info('110数字桩考试记录成功');
    } catch (err) {
      console.error('记录110数字桩考试数据失败', err);
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

          Text('110数字桩考试')
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
            Text('进度')
              .fontSize(12)
              .fontColor($r('app.color.text_secondary'))
            Text(`${this.usedPegCount}/110`)
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

      // 考试通过提示
      if (this.isExamOver && this.isExamPassed) {
        Column() {
          Column() {
            Text('恭喜通过考试！')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 20 })
            
            Text('你已成功完成所有110个数字桩的配对')
              .fontSize(16)
              .fontColor($r('app.color.text_secondary'))
              .margin({ bottom: 20 })
            
            Text(`总用时: ${this.formatTime(this.elapsedTime)}`)
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 30 })
            
            Row() {
              Button('返回')
                .width('40%')
                .height(45)
                .backgroundColor('#2196F3')
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
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .position({ x: 0, y: 0 })
        .backgroundColor('#80000000')
      }

      // 错误提示对话框
      if (this.showErrorDialog) {
        Column() {
          Column() {
            Text('考试失败')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
              .margin({ bottom: 16 })
            
            Text(this.errorMessage)
              .fontSize(16)
              .fontColor($r('app.color.text_primary'))
              .textAlign(TextAlign.Center)
              .margin({ bottom: 24 })
            
            Button('确定')
              .width('60%')
              .height(45)
              .backgroundColor('#2196F3')
              .onClick(() => {
                this.showErrorDialog = false;
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
      // 所有卡片都正面显示内容
      Stack() {
        // 卡片内容层（底层）
        Column() {
          if (card.displayType === '桩序号') {
            // 显示数字序号
            Text(card.peg.number.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          } else if (card.displayType === '桩名称') {
            // 显示编码（桩名称）
            Text(card.peg.code)
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
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

