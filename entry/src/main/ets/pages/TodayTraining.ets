import { router, promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';
import { DatabaseManager } from '../database/DatabaseManager';

/**
 * 游戏卡片数据
 */
interface GameCard {
  id: number;
  dataType: string; // 数据类型：仅使用 '110数字桩'
  peg?: NumberPeg; // 数字桩数据（当dataType为'110数字桩'时使用）
  displayType: string; // 显示类型：matchType1 或 matchType2
  isFlipped: boolean; // 是否翻转
  isMatched: boolean; // 是否已匹配
  isSelected: boolean; // 是否选中（用于UI更新）
}

/**
 * 今日训练页面（基于连连看）
 */
@Entry
@Component
struct TodayTrain {
  @State cards: GameCard[] = [];
  @State selectedCards: number[] = []; // 选中的卡片ID
  @State elapsedTime: number = 0; // 消耗时间（秒）
  @State correctCount: number = 0; // 正确消除数
  @State errorCount: number = 0; // 错误消除数
  @State isGameOver: boolean = false;
  @State isRoundComplete: boolean = false; // 当前轮次是否完成
  @State usedPegCount: number = 0; // 已使用过的数据数量（用于UI更新）
  @State completedRounds: number = 0; // 当日已完成轮次
  @State totalRounds: number = 10; // 当日总轮次
  @State showTrainingRuleDialog: boolean = false; // 是否显示训练说明弹框
  
  private timer: number | null = null;
  private dataType: string = '110数字桩';
  private matchType1: string = ''; // 每轮动态决定
  private matchType2: string = ''; // 每轮动态决定
  private usedPegNumbers: Set<number> = new Set(); // 已使用过的数字桩编号
  private allPegs: NumberPeg[] = []; // 所有数字桩数据
  private todayKey: number = 0; // 例如 20250101
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private startTime: number = 0; // 训练开始时间戳（毫秒）
  private isTimerRunning: boolean = false; // 计时器是否正在运行
  private autoCloseTimer: number | null = null; // 说明弹框自动关闭定时器
  private preferencesStore: preferences.Preferences | null = null; // Preferences 存储

  async aboutToAppear() {
    // 仅使用 110 数字桩，matchType 根据轮次自动切换
    const now = new Date();
    this.todayKey = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
    await this.initPreferences();
    await this.checkShouldShowRuleDialog();
    await this.initTodayProgress();
  }

  aboutToDisappear() {
    // 停止计时器
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
      this.isTimerRunning = false;
    }
    // 清理弹框定时器
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
      this.autoCloseTimer = null;
    }
    
    // 保存当前训练时间（已用时间和离开时间戳）
    // 如果训练未完成，保存已用时间和离开时间戳，以便下次继续
    if (!this.isGameOver && this.completedRounds < this.totalRounds) {
      this.saveTrainingTime();
    }
  }

  /**
   * 初始化 Preferences
   */
  async initPreferences() {
    try {
      const context = getContext(this) as Context;
      this.preferencesStore = await preferences.getPreferences(context, 'TodayTrainingSettings');
    } catch (e) {
      console.error('初始化 Preferences 失败', e);
    }
  }

  /**
   * 检查是否显示训练说明弹框
   */
  async checkShouldShowRuleDialog() {
    if (!this.preferencesStore) {
      await this.initPreferences();
    }
    if (!this.preferencesStore) {
      return;
    }
    try {
      const hideDialog = await this.preferencesStore.get('hideTrainingRuleDialog', false) as boolean;
      if (!hideDialog) {
        this.showTrainingRuleDialog = true;
      }
    } catch (e) {
      console.error('读取 Preferences 失败', e);
      this.showTrainingRuleDialog = true;
    }
  }

  /**
   * 启动自动关闭定时器
   */
  startAutoCloseTimer() {
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
    }
    const timerId = setTimeout(() => {
      this.closeTrainingRuleDialog();
    }, 30 * 1000);
    this.autoCloseTimer = timerId as number;
  }

  /**
   * 关闭训练说明弹框
   */
  closeTrainingRuleDialog() {
    this.showTrainingRuleDialog = false;
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
      this.autoCloseTimer = null;
    }
  }

  /**
   * 点击“知道了”
   */
  onKnowButtonClick() {
    this.closeTrainingRuleDialog();
  }

  /**
   * 点击“不再提示”
   */
  async onNeverShowButtonClick() {
    if (!this.preferencesStore) {
      await this.initPreferences();
    }
    if (this.preferencesStore) {
      try {
        await this.preferencesStore.put('hideTrainingRuleDialog', true);
        await this.preferencesStore.flush();
      } catch (e) {
        console.error('保存 Preferences 失败', e);
      }
    }
    this.closeTrainingRuleDialog();
  }

  /**
   * 初始化当日进度并开始游戏
   */
  async initTodayProgress() {
    try {
      const progress = await this.dbManager.getDailyTrainingProgress(this.todayKey);
      this.completedRounds = progress.roundsCompleted;
      this.totalRounds = progress.totalRounds || 10;

      if (this.completedRounds >= this.totalRounds) {
        this.isGameOver = true;
        promptAction.showToast({ message: '今日训练已全部完成，明天再来~', duration: 2000 });
        return;
      }

      // 恢复训练时间
      const now = Date.now();
      if (progress.elapsedTime !== undefined && progress.elapsedTime > 0) {
        // 从保存的已用时间继续计时（不累加离开期间的时间）
        this.elapsedTime = progress.elapsedTime;
        // 记录当前时间作为新的开始时间（用于下次离开时保存）
        this.startTime = now;
        console.info(`恢复训练时间: elapsedTime=${this.elapsedTime}, startTime=${this.startTime}`);
      } else {
        // 首次开始训练，记录开始时间
        this.startTime = now;
        this.elapsedTime = 0;
        await this.dbManager.saveTrainingTime(this.todayKey, this.startTime, 0);
        console.info(`首次开始训练: startTime=${this.startTime}, elapsedTime=0`);
      }

      // 确保计时器启动（如果训练未完成）
      if (!this.isGameOver && !this.isTimerRunning) {
        this.startTimer();
      }

      await this.initGame();
    } catch (err) {
      console.error('初始化今日训练进度失败:', err);
      promptAction.showToast({ message: '初始化今日训练失败', duration: 2000 });
    }
  }

  /**
   * 初始化游戏（单轮）
   */
  async initGame() {
    try {
      const service = NumberPegService.getInstance();
      this.allPegs = await service.getAllNumberPegs();

      // 根据轮次设置匹配类型
      this.setupMatchTypes();

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
    }
    
    // 打乱卡片顺序
    this.shuffleCards();
    
    this.isRoundComplete = false;
    this.selectedCards = [];
  }

  /**
   * 根据已完成轮次设置匹配类型：
   * 前 5 轮：图片 + 桩名称；后 5 轮：图片 + 桩序号
   */
  setupMatchTypes() {
    if (this.completedRounds < 5) {
      this.matchType1 = '桩图像';
      this.matchType2 = '桩名称';
    } else {
      this.matchType1 = '桩图像';
      this.matchType2 = '桩序号';
    }
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
    // 如果计时器已在运行，先停止
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.isTimerRunning = true;
    this.timer = setInterval(() => {
      this.elapsedTime++;
    }, 1000);
    console.info('计时器已启动');
  }

  /**
   * 保存训练时间到数据库
   * 保存已用时间和离开时间戳，以便下次进入时从保存的时间继续计时
   */
  async saveTrainingTime() {
    try {
      // 保存已用时间和离开时间戳（作为startTime，下次进入时用于恢复）
      const leaveTime = Date.now();
      await this.dbManager.saveTrainingTime(this.todayKey, leaveTime, this.elapsedTime);
      console.info(`保存训练时间: elapsedTime=${this.elapsedTime}秒, leaveTime=${leaveTime}`);
    } catch (err) {
      console.error('保存训练时间失败:', err);
    }
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
  async checkMatch() {
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
        this.completedRounds++;

        // 更新数据库中的今日训练进度（同时保存时间）
        try {
          await this.dbManager.updateDailyTrainingProgress(this.todayKey, this.completedRounds, this.totalRounds, 0, this.elapsedTime);
          // 同时保存训练时间，以便中途离开时能正确恢复
          await this.dbManager.saveTrainingTime(this.todayKey, Date.now(), this.elapsedTime);
        } catch (err) {
          console.error('更新今日训练进度失败:', err);
        }

        if (this.completedRounds >= this.totalRounds) {
          this.isGameOver = true;
          if (this.timer !== null) {
            clearInterval(this.timer);
            this.timer = null;
            this.isTimerRunning = false;
          }
          
          // 保存训练记录（包含总计时）
          await this.saveTrainingRecord();
          
          // 完成今日训练，奖励积分
          await this.rewardPointsForTodayTraining();
          
          // 清除训练时间记录（已完成）
          try {
            await this.dbManager.saveTrainingTime(this.todayKey, 0, 0);
          } catch (err) {
            console.error('清除训练时间失败:', err);
          }
          
          promptAction.showToast({ message: '今日训练已全部完成！获得20积分！', duration: 2000 });
        } else {
          // 进入下一轮
          this.setupMatchTypes();
          this.loadNextRound();
        }
      }
    } else {
      // 匹配失败：清空选中，让用户重新选择
      this.errorCount++;
    }

    // 清空选中列表
    this.selectedCards = [];
  }

  /**
   * 保存训练记录
   */
  private async saveTrainingRecord() {
    try {
      await this.dbManager.insertTrainingRecord({
        gameType: '今日训练',
        duration: this.elapsedTime,
        createTime: Date.now()
      });
      console.info(`保存训练记录: 今日训练, 时长=${this.elapsedTime}秒`);
    } catch (err) {
      console.error('保存训练记录失败:', err);
    }
  }

  /**
   * 完成今日训练后奖励积分
   */
  private async rewardPointsForTodayTraining() {
    try {
      // 检查今天是否已经完成过训练（防止重复奖励）
      const hasRewarded = await this.dbManager.hasPointsRecordByDateAndSource(this.todayKey, '完成今日训练');
      if (hasRewarded) {
        console.info('今日训练已完成，已获得过积分奖励');
        return;
      }

      // 获取用户统计数据
      const userStats = await this.dbManager.getUserStats();
      
      // 增加积分
      const pointsToAdd = 20;
      userStats.points = (userStats.points || 0) + pointsToAdd;
      
      // 更新用户统计
      await this.dbManager.updateUserStats(userStats);
      
      // 记录积分记录
      await this.dbManager.insertPointsRecord({
        dateKey: this.todayKey,
        source: '完成今日训练',
        points: pointsToAdd,
        createTime: Date.now()
      });
      
      console.info(`完成今日训练，获得${pointsToAdd}积分`);
    } catch (err) {
      console.error('奖励积分失败:', err);
      // 不显示错误提示，避免影响用户体验
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
    }
    return 110;
  }

  build() {
    Stack() {
      Column() {
        // 顶部栏 + 统计（固定，不滚动）
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

            Text('今日训练')
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

        // 可滚动内容区域
        Scroll() {
          Column() {
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
            .height(400)
            .margin({ top: 20 })

            // 今日训练轮次进度提示（10 轮制）
            if (!this.isGameOver) {
              Text(`今日训练进度：${this.completedRounds}/${this.totalRounds}`)
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 10, bottom: 20 })
            }
            
            // 底部填充，确保内容从顶部开始
            Blank()
              .height(1)
              .layoutWeight(1)
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .justifyContent(FlexAlign.Start)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)

        // 游戏结束提示（居中显示）
        if (this.isGameOver) {
          Column() {
            Column() {
              Text('恭喜完成！')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
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
              
              // 如果完成了10次，只显示返回按钮；否则显示再来一局和返回按钮
              if (this.completedRounds >= this.totalRounds) {
                // 完成今日训练，只显示返回按钮
                Button('返回')
                  .width('60%')
                  .height(45)
                  .backgroundColor('#9E9E9E')
                  .onClick(() => {
                    // 直接返回到上一个页面（首页的每日训练页）
                    router.back();
                  })
              } else {
                // 未完成今日训练，显示再来一局和返回按钮
                Row() {
                  Button('再来一局')
                    .width('40%')
                    .height(45)
                    .backgroundColor('#2196F3')
                    .onClick(() => {
                      if (this.dataType === '110数字桩') {
                        this.usedPegNumbers.clear();
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
                      // 直接返回到上一个页面（首页的每日训练页）
                      router.back();
                    })
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
              }
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
      .justifyContent(FlexAlign.Center)
      .padding({ top: 20 })

      if (this.showTrainingRuleDialog) {
        this.buildTrainingRuleDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildTrainingRuleDialog() {
    Stack() {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000')
        .onClick(() => {
          this.closeTrainingRuleDialog();
        })
        .onAppear(() => {
          this.startAutoCloseTimer();
        })

      Column() {
        Column() {
          Text('训练说明')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')
            .margin({ bottom: 12 })

          Text('1. 完成10个轮次的数字桩匹配才算做一次完整训练。')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          Text('2. 每轮完成卡片配对计为1轮，进度当天保存。')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          Text('3. 完成全部轮次后可获得20积分，未完成不计分。')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 16 })

          Row() {
            Button('知道了')
              .width('45%')
              .height(40)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#4CAF50')
              .fontColor(Color.White)
              .onClick(() => {
                this.onKnowButtonClick();
              })
            Button('不再提示')
              .width('45%')
              .height(40)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#FF9800')
              .fontColor(Color.White)
              .onClick(() => {
                this.onNeverShowButtonClick();
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('90%')
        .padding({ left: 20, right: 20, top: 20, bottom: 20 })
        .backgroundColor(Color.White)
        .borderRadius(12)
        .shadow({ radius: 20, color: '#80000000', offsetX: 0, offsetY: 4 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .padding({ top: 60 })
    }
    .width('100%')
    .height('100%')
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

