import { router, promptAction } from '@kit.ArkUI';
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
  groupIndex: number; // 所属组索引（0, 1, 2, 3）
  dataType: string; // 数据类型：'110数字桩'、'34省'、'36计'、'三字经'
  peg?: NumberPeg; // 数字桩数据
  province?: Province; // 省份数据
  simpleItem?: SimpleItem; // 简单数据项
  displayType: string; // 显示类型
  displayValue: number; // 显示值（用于判断连续性）
  isCorrect: boolean; // 是否是正确答案
  selectedOrder: number; // 选中的顺序（0表示未选中，1、2、3...表示选中顺序）
}

/**
 * 路由参数类型
 */
interface RouteParams {
  dataType?: string;
  groupCount?: number;
  groupSelections?: string[];
}

/**
 * 路线宫殿游戏页面
 */
@Entry
@Component
struct RoutePalace {
  @State cards: GameCard[] = []; // 12张卡片
  @State elapsedTime: number = 0; // 训练时间（秒）
  @State correctCount: number = 0; // 正确连接数
  @State errorCount: number = 0; // 错误连接数
  @State selectedCount: number = 0; // 已选中的卡片数量
  @State isGameOver: boolean = false;
  
  private timer: number | null = null;
  private dataType: string = '';
  private groupCount: number = 3; // 组数：3或4
  private groupSelections: string[] = []; // 每组的数据类型选择
  private allPegs: NumberPeg[] = [];
  private allProvinces: Province[] = [];
  private allSimpleItems: SimpleItem[] = [];
  private correctSequence: number[] = []; // 正确答案序列
  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as RouteParams;
    this.dataType = params.dataType || '110数字桩';
    this.groupCount = params.groupCount || 3;
    this.groupSelections = params.groupSelections || [];
    
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
      // 加载数据
      if (this.dataType === '110数字桩') {
        const service = NumberPegService.getInstance();
        this.allPegs = await service.getAllNumberPegs();
      } else if (this.dataType === '34省') {
        const service = ProvinceService.getInstance();
        this.allProvinces = service.getAllProvinces();
      } else if (this.dataType === '36计') {
        const service = SimpleItemService.getInstance();
        this.allSimpleItems = service.getAllStratagems();
      } else if (this.dataType === '三字经') {
        const service = SimpleItemService.getInstance();
        this.allSimpleItems = service.getAllSanZiJing();
      }

      // 开始计时
      this.startTimer();
      
      // 生成卡片
      this.generateCards();
    } catch (error) {
      console.error('初始化游戏失败:', error);
      promptAction.showToast({
        message: '初始化游戏失败',
        duration: 2000
      });
    }
  }

  /**
   * 生成卡片
   */
  generateCards() {
    // 生成正确答案序列（连续的数据）
    this.generateCorrectSequence();
    
    // 创建12张卡片
    this.cards = [];
    let cardId = 0;

    if (this.groupCount === 3) {
      // 3组：每列4个卡片
      for (let groupIndex = 0; groupIndex < 3; groupIndex++) {
        const displayType = this.groupSelections[groupIndex];
        const correctValue = this.correctSequence[groupIndex];
        
        // 生成4个卡片，其中一个是正确答案
        const groupCards = this.generateGroupCards(cardId, groupIndex, displayType, correctValue, 4);
        this.cards.push(...groupCards);
        cardId += 4;
      }
    } else {
      // 4组：每行3个卡片
      for (let groupIndex = 0; groupIndex < 4; groupIndex++) {
        const displayType = this.groupSelections[groupIndex];
        const correctValue = this.correctSequence[groupIndex];
        
        // 生成3个卡片，其中一个是正确答案
        const groupCards = this.generateGroupCards(cardId, groupIndex, displayType, correctValue, 3);
        this.cards.push(...groupCards);
        cardId += 3;
      }
    }

    // 重置选中状态
    this.selectedCount = 0;
  }

  /**
   * 生成正确答案序列（连续的数据）
   */
  generateCorrectSequence() {
    this.correctSequence = [];
    
    if (this.dataType === '110数字桩') {
      // 随机选择一个起始数字（0-107，确保有足够的连续数字）
      const startNumber = Math.floor(Math.random() * (110 - this.groupCount));
      for (let i = 0; i < this.groupCount; i++) {
        this.correctSequence.push(startNumber + i);
      }
    } else if (this.dataType === '34省') {
      // 随机选择一个起始省份编号（1-34-groupCount+1）
      const startNumber = Math.floor(Math.random() * (34 - this.groupCount + 1)) + 1;
      for (let i = 0; i < this.groupCount; i++) {
        this.correctSequence.push(startNumber + i);
      }
    } else if (this.dataType === '36计' || this.dataType === '三字经') {
      // 随机选择一个起始编号（1-总数-groupCount+1）
      const maxNumber = this.dataType === '36计' ? 36 : this.allSimpleItems.length;
      const startNumber = Math.floor(Math.random() * (maxNumber - this.groupCount + 1)) + 1;
      for (let i = 0; i < this.groupCount; i++) {
        this.correctSequence.push(startNumber + i);
      }
    }
  }

  /**
   * 生成一组卡片
   */
  generateGroupCards(startId: number, groupIndex: number, displayType: string, correctValue: number, count: number): GameCard[] {
    const cards: GameCard[] = [];
    const usedValues: Set<number> = new Set();
    
    // 添加正确答案
    usedValues.add(correctValue);
    
    // 生成其他随机值
    while (usedValues.size < count) {
      let randomValue: number;
      if (this.dataType === '110数字桩') {
        randomValue = Math.floor(Math.random() * 110);
      } else if (this.dataType === '34省') {
        randomValue = Math.floor(Math.random() * 34) + 1;
      } else {
        const maxNumber = this.dataType === '36计' ? 36 : this.allSimpleItems.length;
        randomValue = Math.floor(Math.random() * maxNumber) + 1;
      }
      
      // 确保不是正确答案且不重复
      if (!usedValues.has(randomValue) && randomValue !== correctValue) {
        usedValues.add(randomValue);
      }
    }
    
    // 将值转换为数组并打乱
    const values = Array.from(usedValues);
    for (let i = values.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = values[i];
      values[i] = values[j];
      values[j] = temp;
    }
    
    // 创建卡片
    for (let i = 0; i < count; i++) {
      const value = values[i];
      const isCorrect = value === correctValue;
      
      const card: GameCard = {
        id: startId + i,
        groupIndex: groupIndex,
        dataType: this.dataType,
        displayType: displayType,
        displayValue: value,
        isCorrect: isCorrect,
        selectedOrder: 0
      };
      
      // 根据数据类型填充数据
      if (this.dataType === '110数字桩') {
        const peg = this.allPegs.find(p => p.number === value);
        if (peg) {
          card.peg = peg;
        }
      } else if (this.dataType === '34省') {
        const province = this.allProvinces.find(p => p.number === value);
        if (province) {
          card.province = province;
        }
      } else {
        const item = this.allSimpleItems.find(i => i.number === value);
        if (item) {
          card.simpleItem = item;
        }
      }
      
      cards.push(card);
    }
    
    return cards;
  }

  /**
   * 点击卡片
   */
  onCardClick(cardId: number) {
    if (this.isGameOver) {
      return;
    }

    const cardIndex = this.cards.findIndex(c => c.id === cardId);
    if (cardIndex === -1) {
      return;
    }

    const card = this.cards[cardIndex];
    const clickedGroupIndex = card.groupIndex;

    // 检查是否按顺序选择（不能跳过前面的组）
    if (clickedGroupIndex > this.selectedCount) {
      promptAction.showToast({
        message: `请先选择第${this.selectedCount + 1}组的数据`,
        duration: 2000
      });
      return;
    }

    // 如果点击的是已经选中的组或之前的组，需要清除后续所有组的选中状态
    let newSelectedCount = clickedGroupIndex;
    
    // 更新卡片状态
    const newCards: GameCard[] = [];
    for (let i = 0; i < this.cards.length; i++) {
      const oldCard = this.cards[i];
      
      if (i === cardIndex) {
        // 点击的卡片：设置为当前组的选中状态
        const newCard: GameCard = {
          id: oldCard.id,
          groupIndex: oldCard.groupIndex,
          dataType: oldCard.dataType,
          peg: oldCard.peg,
          province: oldCard.province,
          simpleItem: oldCard.simpleItem,
          displayType: oldCard.displayType,
          displayValue: oldCard.displayValue,
          isCorrect: oldCard.isCorrect,
          selectedOrder: clickedGroupIndex + 1
        };
        newCards.push(newCard);
      } else if (oldCard.groupIndex === clickedGroupIndex) {
        // 同一组的其他卡片：清除选中状态
        const newCard: GameCard = {
          id: oldCard.id,
          groupIndex: oldCard.groupIndex,
          dataType: oldCard.dataType,
          peg: oldCard.peg,
          province: oldCard.province,
          simpleItem: oldCard.simpleItem,
          displayType: oldCard.displayType,
          displayValue: oldCard.displayValue,
          isCorrect: oldCard.isCorrect,
          selectedOrder: 0
        };
        newCards.push(newCard);
      } else if (oldCard.groupIndex > clickedGroupIndex) {
        // 后续组的卡片：清除选中状态
        const newCard: GameCard = {
          id: oldCard.id,
          groupIndex: oldCard.groupIndex,
          dataType: oldCard.dataType,
          peg: oldCard.peg,
          province: oldCard.province,
          simpleItem: oldCard.simpleItem,
          displayType: oldCard.displayType,
          displayValue: oldCard.displayValue,
          isCorrect: oldCard.isCorrect,
          selectedOrder: 0
        };
        newCards.push(newCard);
      } else {
        // 前面组的卡片：保持原样
        newCards.push(oldCard);
      }
    }
    
    this.cards = newCards;
    this.selectedCount = newSelectedCount + 1;

    // 如果选择了所有组，检查答案
    if (this.selectedCount === this.groupCount) {
      this.checkAnswer();
    }
  }

  /**
   * 检查答案
   */
  checkAnswer() {
    // 获取选中的卡片（按选中顺序）
    const selectedCards: GameCard[] = [];
    for (let order = 1; order <= this.groupCount; order++) {
      const card = this.cards.find(c => c.selectedOrder === order);
      if (card) {
        selectedCards.push(card);
      }
    }

    // 检查是否所有选中的卡片都是正确答案
    let allCorrect = true;
    for (let i = 0; i < selectedCards.length; i++) {
      if (!selectedCards[i].isCorrect) {
        allCorrect = false;
        break;
      }
    }

    // 检查是否连续
    if (allCorrect) {
      const values = selectedCards.map(c => c.displayValue);
      let isContinuous = true;
      for (let i = 1; i < values.length; i++) {
        if (values[i] !== values[i - 1] + 1) {
          isContinuous = false;
          break;
        }
      }
      allCorrect = isContinuous;
    }

    if (allCorrect) {
      // 答案正确
      this.correctCount++;
      promptAction.showToast({
        message: '连接正确！',
        duration: 2000
      });
      
      // 延迟后生成新的卡片
      setTimeout(() => {
        this.generateCards();
      }, 2000);
    } else {
      // 答案错误
      this.errorCount++;
      promptAction.showToast({
        message: '连接错误，请重试',
        duration: 2000
      });
      
      // 重置选中状态
      const newCards: GameCard[] = [];
      for (let i = 0; i < this.cards.length; i++) {
        const oldCard = this.cards[i];
        const newCard: GameCard = {
          id: oldCard.id,
          groupIndex: oldCard.groupIndex,
          dataType: oldCard.dataType,
          peg: oldCard.peg,
          province: oldCard.province,
          simpleItem: oldCard.simpleItem,
          displayType: oldCard.displayType,
          displayValue: oldCard.displayValue,
          isCorrect: oldCard.isCorrect,
          selectedOrder: 0
        };
        newCards.push(newCard);
      }
      this.cards = newCards;
      this.selectedCount = 0;
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
   * 格式化时间显示
   */
  formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
  }

  /**
   * 记录训练数据
   */
  async recordTrainingData() {
    try {
      await this.dbManager.insertTrainingRecord({
        gameType: '路线宫殿',
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

          Text('路线宫殿')
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
            Text('训练时间')
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
            Text('正确连接')
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
            Text('错误连接')
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
      Scroll() {
        if (this.groupCount === 3) {
          // 3组：3列，每列4个卡片
          Row() {
            ForEach([0, 1, 2], (groupIndex: number) => {
              Column() {
                ForEach(
                  this.cards.filter(c => c.groupIndex === groupIndex),
                  (card: GameCard) => {
                    Column() {
                      this.createCard(card)
                    }
                    .width('100%')
                    .height(120)
                    .margin({ bottom: 10 })
                  }
                )
              }
              .layoutWeight(1)
              .width('100%')
              .padding({ left: 5, right: 5 })
            })
          }
          .width('100%')
          .padding({ left: 10, right: 10, top: 0 })
        } else {
          // 4组：4行，每行3个卡片
          Column() {
            ForEach([0, 1, 2, 3], (groupIndex: number) => {
              Row() {
                ForEach(
                  this.cards.filter(c => c.groupIndex === groupIndex),
                  (card: GameCard) => {
                    Column() {
                      this.createCard(card)
                    }
                    .layoutWeight(1)
                    .height(120)
                    .margin({ left: 5, right: 5 })
                  }
                )
              }
              .width('100%')
              .margin({ bottom: 10 })
              .padding({ 
                left: 10, 
                right: 10, 
                top: groupIndex === 0 ? 0 : undefined 
              })
            })
          }
          .width('100%')
        }
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ top: 0 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Start)
    .padding({ top: 20 })
    .backgroundColor('#F5F5F5')
  }

  @Builder
  createCard(card: GameCard) {
    Stack() {
      // 卡片内容
      Column() {
        if (card.dataType === '110数字桩' && card.peg) {
          if (card.displayType === '桩序号' || card.displayType === '序号') {
            Text(card.peg.number.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          } else if (card.displayType === '桩名称' || card.displayType === '名称') {
            Text(card.peg.code)
              .fontSize(22)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 8, right: 8 })
              .textAlign(TextAlign.Center)
          } else if (card.displayType === '桩图像' || card.displayType === '图像') {
            Image($r(`app.media.${card.peg.imageName.replace('.jpg', '')}`))
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
          }
        } else if (card.dataType === '34省' && card.province) {
          if (card.displayType === '省序号' || card.displayType === '序号') {
            Text(card.province.number.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          } else if (card.displayType === '省全称' || card.displayType === '全称') {
            Text(card.province.fullName)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 8, right: 8 })
              .textAlign(TextAlign.Center)
          } else if (card.displayType === '省会') {
            Text(card.province.capital)
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 8, right: 8 })
              .textAlign(TextAlign.Center)
          } else if (card.displayType === '省简称' || card.displayType === '简称') {
            Text(card.province.shortName)
              .fontSize(28)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          }
        } else if ((card.dataType === '36计' || card.dataType === '三字经') && card.simpleItem) {
          if (card.displayType === '序号') {
            Text(card.simpleItem.number.toString())
              .fontSize(36)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.text_primary'))
          } else if (card.displayType === '内容') {
            Text(card.simpleItem.content)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_primary'))
              .padding({ left: 8, right: 8 })
              .textAlign(TextAlign.Center)
              .maxLines(3)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.White)
      .borderRadius(8)
      .border({ width: 1, color: '#CCCCCC' })
      .onClick(() => {
        this.onCardClick(card.id);
      })

      // 选中遮罩层
      if (card.selectedOrder > 0) {
        Column() {
          Text(card.selectedOrder.toString())
            .fontSize(48)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')
        .borderRadius(8)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
  }
}

