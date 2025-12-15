import { router, promptAction } from '@kit.ArkUI';
import { preferences } from '@kit.ArkData';
import { Context } from '@kit.AbilityKit';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';

/**
 * 骨肉相连游戏数据项
 */
interface BoneMatchItem {
  id: number; // 唯一ID
  originalPosition: number; // 原始位置（1-12，用于判定）
  currentPosition: number; // 当前显示位置（打乱后）
  peg: NumberPeg; // 数字桩数据
  displayType: 'image' | 'number' | 'code'; // 展示类型：图片/数字/名称
  selectedOrder: number | null; // 用户选择的序号（1-12，null表示未选择）
}

/**
 * 骨肉相连游戏页面
 */
@Entry
@Component
struct BoneMatch {
  @State items: BoneMatchItem[] = []; // 游戏数据项
  @State isMemorized: boolean = false; // 是否已点击"记完"
  @State currentSelectOrder: number = 1; // 当前应该选择的序号
  @State correctConnections: number = 0; // 正确连接数
  @State errorConnections: number = 0; // 错误连接数
  @State selectedHistory: number[] = []; // 选择历史（用于撤销）
  @State showResult: boolean = false; // 是否显示结果（有错误时显示）
  @State showGameRuleDialog: boolean = false; // 是否显示游戏说明弹框
  private shuffleSeq: number = 0; // 每次打乱的序列号，保证卡片 id 唯一
  private autoCloseTimer: number | null = null; // 自动关闭定时器
  private preferencesStore: preferences.Preferences | null = null; // Preferences 存储

  // 时间统计变量
  private startTime: number = 0; // 开始时间戳（毫秒）
  private memorizeCompleteTime: number = 0; // 记完时间戳（毫秒）
  private memoryTime: number = 0; // 记忆时间（毫秒）：从开始到记完
  private reviewTime: number = 0; // 复盘时间（毫秒）：从记完到所有序号选择完
  private totalTime: number = 0; // 总时间（毫秒）：记忆时间 + 复盘时间

  private rangeTypes: string[] = []; // 范围类型：图像、桩序号、桩名称
  private difficulty: number = 3; // 难度（图数）
  private startNumber: number = 0; // 起始数字
  private endNumber: number = 109; // 结束数字
  private allPegs: NumberPeg[] = []; // 所有数字桩数据
  private pegService: NumberPegService = NumberPegService.getInstance();

  async aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, Object>;
    if (params) {
      this.rangeTypes = (params['rangeTypes'] as string[]) || ['图像'];
      this.difficulty = (params['difficulty'] as number) || 3;
      this.startNumber = (params['startNumber'] as number) || 0;
      this.endNumber = (params['endNumber'] as number) || 109;
    }
    // 打印rangeTypes的信息
    console.info('选择的数据范围rangeTypes:', this.rangeTypes);

    // 初始化 Preferences 并检查是否显示游戏说明
    await this.initPreferences();
    await this.checkShouldShowRuleDialog();

    this.initGame();
  }

  aboutToDisappear() {
    // 清理定时器
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
      this.autoCloseTimer = null;
    }
  }

  /**
   * 初始化 Preferences
   */
  async initPreferences() {
    try {
      const context = getContext(this) as Context;
      this.preferencesStore = await preferences.getPreferences(context, 'BoneMatchSettings');
    } catch (e) {
      console.error('初始化 Preferences 失败', e);
    }
  }

  /**
   * 检查是否应该显示游戏说明弹框
   */
  async checkShouldShowRuleDialog() {
    if (!this.preferencesStore) {
      await this.initPreferences();
    }
    if (!this.preferencesStore) {
      return;
    }
    try {
      const hideRuleDialog = await this.preferencesStore.get('hideGameRuleDialog', false) as boolean;
      if (!hideRuleDialog) {
        this.showGameRuleDialog = true;
        // 定时器在弹框 onAppear 时启动，避免重复启动
      }
    } catch (e) {
      console.error('读取 Preferences 失败', e);
      // 如果读取失败，默认显示
      this.showGameRuleDialog = true;
      // 定时器在弹框 onAppear 时启动，避免重复启动
    }
  }

  /**
   * 启动自动关闭定时器（60秒）
   */
  startAutoCloseTimer() {
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
    }
    console.info('启动自动关闭定时器，30秒后关闭');
    const timerId = setTimeout(() => {
      console.info('定时器触发，关闭弹框');
      this.closeGameRuleDialog();
    }, 30 * 1000); // 60秒
    this.autoCloseTimer = timerId as number;
  }

  /**
   * 关闭游戏说明弹框
   */
  closeGameRuleDialog() {
    this.showGameRuleDialog = false;
    // 关闭定时器
    if (this.autoCloseTimer !== null) {
      clearTimeout(this.autoCloseTimer);
      this.autoCloseTimer = null;
      console.info('定时器已关闭');
    }
  }

  /**
   * 点击"知道了"按钮
   */
  onKnowButtonClick() {
    // 关闭定时器并关闭弹框
    this.closeGameRuleDialog();
  }

  /**
   * 点击"以后不再显示"按钮
   */
  async onNeverShowButtonClick() {
    if (!this.preferencesStore) {
      await this.initPreferences();
    }
    if (this.preferencesStore) {
      try {
        await this.preferencesStore.put('hideGameRuleDialog', true);
        await this.preferencesStore.flush();
      } catch (e) {
        console.error('保存 Preferences 失败', e);
      }
    }
    // 关闭定时器并关闭弹框
    this.closeGameRuleDialog();
  }

  async initGame() {
    try {
      // 加载所有数字桩数据
      this.allPegs = await this.pegService.getAllNumberPegs();
      if (this.allPegs.length === 0) {
        promptAction.showToast({ message: '未找到数字桩数据', duration: 2000 });
        return;
      }

      // 过滤数据范围
      const filteredPegs = this.allPegs.filter(
        peg => peg.number >= this.startNumber && peg.number <= this.endNumber
      );

      if (filteredPegs.length < this.difficulty) {
        promptAction.showToast({ 
          message: `数据范围不足，需要至少${this.difficulty}个数据`, 
          duration: 2000 
        });
        return;
      }

      // 根据选择的范围类型构造候选数据池
      const candidateItems: BoneMatchItem[] = [];
      let uid = 0;
      filteredPegs.forEach((peg) => {
        if (this.rangeTypes.includes('图像')) {
          candidateItems.push(this.createItem(peg, uid++, 'image'));
        }
        if (this.rangeTypes.includes('桩序号')) {
          candidateItems.push(this.createItem(peg, uid++, 'number'));
        }
        if (this.rangeTypes.includes('桩名称')) {
          candidateItems.push(this.createItem(peg, uid++, 'code'));
        }
      });

      if (candidateItems.length < this.difficulty) {
        promptAction.showToast({
          message: `数据范围不足，需要至少${this.difficulty}个数据`,
          duration: 2000
        });
        return;
      }

      // 随机选择 difficulty 个数据
      const selectedItems = this.shuffleArray(candidateItems).slice(0, this.difficulty);

      // 重新标记位置
      this.items = selectedItems.map((item, index) => {
        const newItem: BoneMatchItem = {
          id: item.id,
          originalPosition: index + 1,
          currentPosition: index + 1,
          peg: item.peg,
          displayType: item.displayType,
          selectedOrder: null
        };
        return newItem;
      });

      // 重置游戏状态
      this.isMemorized = false;
      this.currentSelectOrder = 1;
      this.selectedHistory = [];
      this.showResult = false;
      
      // 记录开始时间
      this.startTime = Date.now();
      this.memorizeCompleteTime = 0;
      this.memoryTime = 0;
      this.reviewTime = 0;
      this.totalTime = 0;
    } catch (e) {
      console.error('初始化失败', e);
      promptAction.showToast({ message: '初始化失败', duration: 2000 });
    }
  }

  /**
   * 点击"记完"按钮，打乱顺序
   */
  onMemorizeComplete() {
    if (this.isMemorized) {
      return;
    }

    // 重新构造新对象并打乱，避免引用复用导致未刷新
    this.shuffleSeq++;
    const source = [...this.items];
    const randomized: BoneMatchItem[] = [];
    const shuffledSource = this.shuffleArray(source);
    for (let i = 0; i < shuffledSource.length; i++) {
      const item = shuffledSource[i];
      const newItem: BoneMatchItem = {
        id: this.shuffleSeq * 1000 + i, // 换新 id，确保 ForEach 重新渲染
        originalPosition: item.originalPosition,
        currentPosition: i + 1,
        peg: item.peg,
        displayType: item.displayType,
        selectedOrder: item.selectedOrder
      };
      randomized.push(newItem);
    }

    // 直接替换为新数组
    this.items = randomized;
    this.isMemorized = true;
    
    // 记录记完时间并计算记忆时间
    this.memorizeCompleteTime = Date.now();
    this.memoryTime = this.memorizeCompleteTime - this.startTime;
    console.info('记忆时间:', this.memoryTime, 'ms');
  }

  /**
   * 点击数据项
   */
  onItemClick(item: BoneMatchItem) {
    if (this.showResult) {
      return; // 显示结果时不能点击
    }
    if (!this.isMemorized) {
      return; // 未点击"记完"前不能选择
    }

    if (item.selectedOrder !== null) {
      return; // 已选择过，不能重复选择
    }

    // 找到对应的数据项并更新
    const index = this.items.findIndex(i => i.id === item.id);
    if (index === -1) {
      return;
    }

    // 创建新对象更新状态
    const updatedItem: BoneMatchItem = {
      id: item.id,
      originalPosition: item.originalPosition,
      currentPosition: item.currentPosition,
      peg: item.peg,
      displayType: item.displayType,
      selectedOrder: this.currentSelectOrder
    };
    
    // 创建新数组，确保触发状态更新
    const newItems = [...this.items];
    newItems[index] = updatedItem;
    this.items = newItems;
    
    this.selectedHistory.push(item.id);
    this.currentSelectOrder++;

    // 检查是否全部选择完成
    if (this.currentSelectOrder > this.difficulty) {
      this.checkResult();
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
    const updatedItem: BoneMatchItem = {
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
   * 检查结果
   */
  checkResult() {
    let correct = 0;
    let error = 0;

    // 检查每个数据项：用户选择的序号是否等于原始位置
    this.items.forEach(item => {
      if (item.selectedOrder === item.originalPosition) {
        correct++;
      } else {
        error++;
      }
    });

    this.correctConnections += correct;
    this.errorConnections += error;

    // 记录完成时间并计算复盘时间和总时间
    const completeTime = Date.now();
    this.reviewTime = completeTime - this.memorizeCompleteTime;
    this.totalTime = this.memoryTime + this.reviewTime;
    console.info('复盘时间:', this.reviewTime, 'ms');
    console.info('总时间:', this.totalTime, 'ms (记忆:', this.memoryTime, 'ms + 复盘:', this.reviewTime, 'ms)');

    // 显示结果提示
    const message = `本轮完成！正确：${correct}，错误：${error}`;
    promptAction.showToast({ message: message, duration: 2000 });

    // 如果有错误，显示结果界面，否则自动进入下一轮
    if (error > 0) {
      this.showResult = true;
    } else {
      // 全部正确，延迟后生成下一轮
      setTimeout(() => {
        this.initGame();
      }, 2000);
    }
  }

  /**
   * 再来一次
   */
  onRetry() {
    this.initGame();
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
   * 克隆数据项并更新 currentPosition
   */
  cloneItemWithPosition(item: BoneMatchItem, newPosition: number): BoneMatchItem {
    const cloned: BoneMatchItem = {
      id: item.id,
      originalPosition: item.originalPosition,
      currentPosition: newPosition,
      peg: item.peg,
      displayType: item.displayType,
      selectedOrder: item.selectedOrder
    };
    return cloned;
  }

  /**
   * 创建带类型的数据项
   */
  createItem(peg: NumberPeg, index: number, displayType: 'image' | 'number' | 'code'): BoneMatchItem {
    const item: BoneMatchItem = {
      id: index,
      originalPosition: index + 1,
      currentPosition: index + 1,
      peg: peg,
      displayType: displayType,
      selectedOrder: null
    };
    return item;
  }

  /**
   * 获取数据项的显示内容
   */
  getItemDisplayContent(item: BoneMatchItem): string {
    switch (item.displayType) {
      case 'number':
        return item.peg.number.toString();
      case 'code':
        return item.peg.code;
      default:
        return '';
    }
  }

  /**
   * 获取数据项的图片资源
   */
  getItemImage(item: BoneMatchItem): Resource {
    return this.pegService.getImageResourceId(item.peg.imageName);
  }

  /**
   * 计算列数（固定3列）
   */
  getColumns(): number {
    return 3;
  }

  /**
   * 计算行数
   */
  getRows(): number {
    return Math.ceil(this.difficulty / 3);
  }

  /**
   * 行索引数组（避免使用未声明类型的对象字面量）
   */
  getRowIndexes(): number[] {
    return new Array<number>(this.getRows()).fill(0).map((_, i) => i);
  }

  /**
   * 列索引数组（避免使用未声明类型的对象字面量）
   */
  getColIndexes(): number[] {
    return new Array<number>(this.getColumns()).fill(0).map((_, i) => i);
  }

  /**
   * 是否存在对应网格位置的数据
   */
  hasItemAt(rowIndex: number, colIndex: number): boolean {
    const index = rowIndex * this.getColumns() + colIndex;
    const result = index < this.getSortedItems().length;
    return result;
  }


  /**
   * 获取按 currentPosition 排序的数据项（用于显示）
   */
  getSortedItems(): BoneMatchItem[] {
    // items 已按 currentPosition 排序存储，直接返回
    return [...this.items];
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

        Text('骨肉相连')
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
      .margin({ bottom: 10 })

      // 统计信息
      Row() {
        Text(`正确连接：${this.correctConnections}`)
          .fontSize(14)
          .fontColor('#4CAF50')
          .margin({ right: 20 })
        Text(`错误连接：${this.errorConnections}`)
          .fontSize(14)
          .fontColor('#F44336')
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 10 })

      // 游戏区域（直接按 items 渲染，使用 Grid 保持 3 列）
      Grid() {
        ForEach(this.getSortedItems(), (item: BoneMatchItem) => {
          GridItem() {
            this.buildItem(item);
          }
        }, (item: BoneMatchItem) => `${item.id}_${item.selectedOrder ?? 'null'}`)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsGap(8)
      .columnsGap(8)
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 6, right: 6 })

      // 底部按钮
      Row() {
        if (this.showResult) {
          // 显示结果时，显示"再来一次"按钮
          Button('再来一次')
            .width('45%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#2196F3')
            .onClick(() => {
              this.onRetry();
            })
        } else if (!this.isMemorized) {
          Button('记完')
            .width('45%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#4CAF50')
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
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#F5F5F5')

      // 游戏说明弹框
      if (this.showGameRuleDialog) {
        this.buildGameRuleDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildGameRuleDialog() {
    Stack() {
      // 背景遮罩
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000') // 半透明黑色背景
        .onClick(() => {
          // 点击背景关闭弹框
          this.closeGameRuleDialog();
        })
        .onAppear(() => {
          // 弹框显示时启动定时器
          console.info('弹框显示，启动60秒自动关闭定时器');
          this.startAutoCloseTimer();
        })

      // 弹框内容
      Column() {
        Column() {
          Text('游戏玩法')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FF6B35')
            .margin({ bottom: 12 })

          Text('1. 根据选择的数据范围随机生成对应难度张数的卡片')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          Text('2. 从左到右、从上到下依次记忆并标号（1、2、3...）')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          Text('3. 记完后点击"记完"按钮进入回忆阶段')
            .fontSize(14)
            .fontColor('#FF6B35')
            .alignSelf(ItemAlign.Start)
            .margin({ bottom: 8 })
          Text('4. 依次点击卡片，按记忆顺序选择，直到全部点击完')
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
            Button('以后不再显示')
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
  buildItem(item: BoneMatchItem) {
    Stack() {
      // 卡片内容
      Column() {
        // 显示内容
        if (item.displayType === 'image') {
          Image(this.getItemImage(item))
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
        }
        if (item.displayType === 'number') {
          Text(this.getItemDisplayContent(item))
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .textAlign(TextAlign.Center)
        }
        if (item.displayType === 'code') {
          Text(this.getItemDisplayContent(item))
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .textAlign(TextAlign.Center)
        }
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      // 透明遮罩层显示序号
      if (item.selectedOrder !== null) {
        Stack() {
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

          // 右上角显示正确的序号（仅在显示结果时）
          if (this.showResult) {
            Column() {
              Text(item.originalPosition.toString())
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor(item.selectedOrder === item.originalPosition ? '#4CAF50' : '#F44336')
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.Start)
            .alignItems(HorizontalAlign.End)
            .padding({ top: 8, right: 8 })
          }
        }
        .width('100%')
        .height('100%')
        .backgroundColor('#80000000') // 半透明黑色遮罩
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

