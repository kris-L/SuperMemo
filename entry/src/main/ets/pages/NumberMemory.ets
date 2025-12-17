import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { PiGenerator } from '../utils/PiGenerator';
import { DatabaseManager } from '../database/DatabaseManager';

/**
 * 数字行数据
 */
interface NumberRow {
  rowIndex: number; // 行号（从1开始）
  originalDigits: string; // 原始数字（记忆阶段显示）
  userInput: string; // 用户输入的数字（回忆阶段显示）
  isRecalling: boolean; // 是否处于回忆阶段
}

/**
 * 数字记忆训练页面
 */
@Entry
@Component
struct NumberMemory {
  @State rows: NumberRow[] = [];
  @State isRecalling: boolean = false; // 是否处于回忆阶段
  @State currentInputRow: number = 1; // 当前输入的行号
  @State currentInputPosition: number = 0; // 当前输入位置（在当前行的位置）
  @State memoryTime: number = 0; // 记忆时间（秒）
  @State recallTime: number = 0; // 回忆时间（秒）
  @State totalTime: number = 0; // 总时间（秒）
  @State showResult: boolean = false; // 是否显示结果报告
  @State showReview: boolean = false; // 是否显示复盘视图
  @State correctCount: number = 0; // 正确数字数
  @State totalDigits: number = 0; // 总数字数
  @State accuracy: number = 0; // 准确率（百分比）
  
  private rangeType: string = '随机数字'; // 范围类型：随机数字、圆周率
  private rowCount: number = 10; // 行数（随机数字用）
  private digitsPerRow: number = 5; // 每行个数
  private trainingCount: number = 1; // 训练次数
  private piStartDigit: number = 1; // 圆周率开始位数
  private piEndDigit: number = 100; // 圆周率结束位数
  private memoryTimer: number | null = null; // 记忆计时器
  private recallTimer: number | null = null; // 回忆计时器
  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  aboutToAppear() {
    // 获取路由参数
    const params = router.getParams() as Record<string, string>;
    this.rangeType = params['rangeType'] || '随机数字';
    if (this.rangeType === '圆周率') {
      this.piStartDigit = parseInt(params['piStartDigit'] || '1');
      this.piEndDigit = parseInt(params['piEndDigit'] || '100');
      this.digitsPerRow = parseInt(params['digitsPerRow'] || '10');
      this.trainingCount = parseInt(params['trainingCount'] || '1');
    } else {
      this.rowCount = parseInt(params['rowCount'] || '10');
      this.digitsPerRow = parseInt(params['digitsPerRow'] || '5');
      this.trainingCount = parseInt(params['trainingCount'] || '1');
    }
    
    // 初始化数据
    this.initData();
  }

  aboutToDisappear() {
    // 清理定时器
    this.stopMemoryTimer();
    this.stopRecallTimer();
  }

  /**
   * 初始化数据
   */
  initData() {
    this.rows = [];
    this.isRecalling = false;
    this.currentInputRow = 1;
    this.currentInputPosition = 0;
    this.memoryTime = 0;
    this.recallTime = 0;
    this.totalTime = 0;
    this.showResult = false;
    this.correctCount = 0;
    this.totalDigits = 0;
    this.accuracy = 0;
    
    // 开始记忆计时
    this.startMemoryTimer();
    
    if (this.rangeType === '圆周率') {
      // 圆周率模式：从开始位数到结束位数，每行10个数字
      // 注意：piStartDigit和piEndDigit是从1开始的（即第1位是3.14...中的1）
      // PiGenerator.getPiDigits的索引是从0开始的（即索引0对应小数点后第1位）
      const startIndex = this.piStartDigit - 1; // 转换为从0开始的索引
      const totalDigits = this.piEndDigit - this.piStartDigit + 1;
      const rowCount = Math.ceil(totalDigits / this.digitsPerRow);
      
      for (let i = 1; i <= rowCount; i++) {
        const rowStartIndex = startIndex + (i - 1) * this.digitsPerRow;
        const remainingDigits = totalDigits - (i - 1) * this.digitsPerRow;
        const digitsInThisRow = Math.min(this.digitsPerRow, remainingDigits);
        
        // 从圆周率获取数字（从索引0开始，即1415...）
        const digits = PiGenerator.getPiDigits(rowStartIndex, digitsInThisRow);
        
        this.rows.push({
          rowIndex: i,
          originalDigits: digits,
          userInput: '',
          isRecalling: false
        });
      }
    } else {
      // 随机数字模式
      for (let i = 1; i <= this.rowCount; i++) {
        const digits = PiGenerator.generateRandomDigits(this.digitsPerRow);
        this.rows.push({
          rowIndex: i,
          originalDigits: digits,
          userInput: '',
          isRecalling: false
        });
      }
    }
  }

  /**
   * 开始记忆计时
   */
  startMemoryTimer() {
    this.memoryTimer = setInterval(() => {
      this.memoryTime++;
    }, 1000);
  }

  /**
   * 停止记忆计时
   */
  stopMemoryTimer() {
    if (this.memoryTimer !== null) {
      clearInterval(this.memoryTimer);
      this.memoryTimer = null;
    }
  }

  /**
   * 开始回忆计时
   */
  startRecallTimer() {
    this.recallTimer = setInterval(() => {
      this.recallTime++;
      this.totalTime = this.memoryTime + this.recallTime;
    }, 1000);
  }

  /**
   * 停止回忆计时
   */
  stopRecallTimer() {
    if (this.recallTimer !== null) {
      clearInterval(this.recallTimer);
      this.recallTimer = null;
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
   * 点击"搞定"按钮，进入回忆阶段
   */
  onStartRecalling() {
    // 停止记忆计时，开始回忆计时
    this.stopMemoryTimer();
    this.startRecallTimer();
    
    // 清空原始数字显示，进入回忆阶段
    const newRows: NumberRow[] = [];
    for (let i = 0; i < this.rows.length; i++) {
      newRows.push({
        rowIndex: this.rows[i].rowIndex,
        originalDigits: this.rows[i].originalDigits,
        userInput: this.rows[i].userInput,
        isRecalling: true
      });
    }
    this.rows = newRows;
    this.isRecalling = true;
    this.currentInputRow = 1;
    this.currentInputPosition = 0;
  }

  /**
   * 处理数字输入
   */
  onNumberInput(digit: string) {
    if (!this.isRecalling) {
      return;
    }
    
    // 找到当前行
    const rowIndex = this.currentInputRow - 1;
    if (rowIndex < 0 || rowIndex >= this.rows.length) {
      return;
    }
    
    const row = this.rows[rowIndex];
    
    // 如果当前行已满，自动填充到下一行
    if (row.userInput.length >= this.digitsPerRow) {
      if (this.currentInputRow < this.rows.length) {
        this.currentInputRow++;
        this.currentInputPosition = 0;
        this.onNumberInput(digit);
        return;
      } else {
        // 所有行都已满
        return;
      }
    }
    
    // 更新当前行的输入
    const newRows: NumberRow[] = [];
    for (let i = 0; i < this.rows.length; i++) {
      if (i === rowIndex) {
        const newInput = row.userInput + digit;
        newRows.push({
          rowIndex: row.rowIndex,
          originalDigits: row.originalDigits,
          userInput: newInput,
          isRecalling: row.isRecalling
        });
        this.currentInputPosition = newInput.length;
      } else {
        newRows.push(this.rows[i]);
      }
    }
    this.rows = newRows;
    
    // 如果当前行已满，自动移动到下一行
    const updatedRow = newRows[rowIndex];
    if (updatedRow.userInput.length >= this.digitsPerRow) {
      if (this.currentInputRow < this.rows.length) {
        this.currentInputRow++;
        this.currentInputPosition = 0;
      }
    }
  }

  /**
   * 撤销最后一个输入
   */
  onUndo() {
    if (!this.isRecalling) {
      return;
    }
    
    // 找到当前行
    const rowIndex = this.currentInputRow - 1;
    if (rowIndex < 0 || rowIndex >= this.rows.length) {
      return;
    }
    
    const row = this.rows[rowIndex];
    
    // 如果当前行有输入，删除最后一个字符
    if (row.userInput.length > 0) {
      const newRows: NumberRow[] = [];
      for (let i = 0; i < this.rows.length; i++) {
        if (i === rowIndex) {
          const newInput = row.userInput.substring(0, row.userInput.length - 1);
          newRows.push({
            rowIndex: row.rowIndex,
            originalDigits: row.originalDigits,
            userInput: newInput,
            isRecalling: row.isRecalling
          });
          this.currentInputPosition = Math.max(0, this.currentInputPosition - 1);
        } else {
          newRows.push(this.rows[i]);
        }
      }
      this.rows = newRows;
    } else if (this.currentInputRow > 1) {
      // 如果当前行没有输入，移动到上一行
      this.currentInputRow--;
      const prevRow = this.rows[this.currentInputRow - 1];
      this.currentInputPosition = prevRow.userInput.length;
      this.onUndo();
    }
  }

  /**
   * 计算统计信息
   */
  calculateStatistics() {
    let correct = 0;
    let total = 0;
    
    for (let i = 0; i < this.rows.length; i++) {
      const row = this.rows[i];
      const original = row.originalDigits;
      const userInput = row.userInput;
      
      total += original.length;
      
      // 逐位比较
      for (let j = 0; j < Math.min(original.length, userInput.length); j++) {
        if (original[j] === userInput[j]) {
          correct++;
        }
      }
    }
    
    this.correctCount = correct;
    this.totalDigits = total;
    this.accuracy = total > 0 ? Math.round((correct / total) * 100 * 100) / 100 : 0;
  }

  /**
   * 提交答案
   */
  async onSubmit() {
    // 停止回忆计时
    this.stopRecallTimer();
    this.totalTime = this.memoryTime + this.recallTime;
    
    // 计算统计信息
    this.calculateStatistics();
    
    // 记录训练数据
    try {
      await this.dbManager.insertTrainingRecord({
        gameType: '数字记忆',
        duration: this.totalTime,
        createTime: Date.now()
      });
    } catch (err) {
      console.error('记录训练数据失败', err);
    }
    
    // 显示结果报告
    this.showResult = true;
  }

  /**
   * 关闭结果报告
   */
  closeResult() {
    this.showResult = false;
    this.showReview = false;
    router.back();
  }

  /**
   * 打开复盘视图
   */
  openReview() {
    this.showReview = true;
  }

  /**
   * 关闭复盘视图
   */
  closeReview() {
    this.showReview = false;
  }

  /**
   * 获取复盘显示的行数据（每5个数字一行）
   */
  getReviewLines(row: NumberRow): number[][] {
    const digitsPerLine = 5;
    const totalLines = Math.ceil(row.originalDigits.length / digitsPerLine);
    const lines: number[][] = [];
    
    for (let i = 0; i < totalLines; i++) {
      const startIndex = i * digitsPerLine;
      const endIndex = Math.min(startIndex + digitsPerLine, row.originalDigits.length);
      const line: number[] = [];
      for (let j = startIndex; j < endIndex; j++) {
        line.push(j);
      }
      lines.push(line);
    }
    
    return lines;
  }

  build() {
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
        Text('数字记忆')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
        Blank()
          .width(44)
          .height(44)
      }
      .padding({ left: 12, right: 12, top: 12 })
      .width('100%')
      .height(56)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      // 顶部时间显示
      if (!this.showResult) {
        Row() {
          if (!this.isRecalling) {
            Column() {
              Text('记忆时间')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.formatTime(this.memoryTime))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .margin({ top: 5 })
            }
            .flexGrow(1)
          } else {
            Column() {
              Text('记忆时间')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.formatTime(this.memoryTime))
                .fontSize(14)
                .fontColor('#666666')
                .margin({ top: 2 })
            }
            .flexGrow(1)
            
            Column() {
              Text('回忆时间')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.formatTime(this.recallTime))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#4CAF50')
                .margin({ top: 5 })
            }
            .flexGrow(1)
            
            Column() {
              Text('总时间')
                .fontSize(12)
                .fontColor('#666666')
              Text(this.formatTime(this.totalTime))
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FF9800')
                .margin({ top: 5 })
            }
            .flexGrow(1)
          }
        }
        .width('100%')
        .height(60)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
        .justifyContent(FlexAlign.SpaceAround)
      }

      // 内容区域（可滚动）
      Scroll() {
        Column() {
          ForEach(this.rows, (row: NumberRow) => {
            Row() {
              // 行号
              Text(`${row.rowIndex}：`)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .width(60)
              
              // 数字显示
              if (this.isRecalling) {
                // 回忆阶段：显示用户输入
                Text(row.userInput || '')
                  .fontSize(36)
                  .fontColor('#2196F3')
                  .fontWeight(FontWeight.Bold)
                  .letterSpacing(2)
              } else {
                // 记忆阶段：显示原始数字
                Text(row.originalDigits)
                  .fontSize(36)
                  .fontColor('#333333')
                  .fontWeight(FontWeight.Bold)
                  .letterSpacing(2)
              }
            }
            .width('100%')
            .height(50)
            .padding({ left: 20, right: 20 })
            .justifyContent(FlexAlign.Start)
            .margin({ bottom: 5 })
          })
        }
        .width('100%')
        .padding({ top: 20, bottom: 20 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)

      // 底部按钮区域
      if (!this.isRecalling) {
        // 记忆阶段：显示"搞定"和"返回"按钮
        Row() {
          Button('返回')
            .width('40%')
            .height(50)
            .fontSize(18)
            .backgroundColor('#9E9E9E')
            .onClick(() => {
              router.back();
            })
          
          Button('搞定')
            .width('40%')
            .height(50)
            .fontSize(18)
            .fontWeight(FontWeight.Medium)
            .backgroundColor('#4CAF50')
            .onClick(() => {
              this.onStartRecalling();
            })
        }
        .width('100%')
        .height(70)
        .justifyContent(FlexAlign.SpaceAround)
        .padding({ left: 20, right: 20 })
        .backgroundColor(Color.White)
      } else {
        // 回忆阶段：显示数字键盘
        Column() {
          // 数字键盘
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
          
          // 返回按钮
          Button('返回')
            .width('90%')
            .height(50)
            .fontSize(18)
            .backgroundColor('#9E9E9E')
            .margin({ top: 10, bottom: 10 })
            .onClick(() => {
              router.back();
            })
        }
        .width('100%')
        .backgroundColor(Color.White)
      }

      // 结果报告弹窗
      if (this.showResult) {
        Column() {
          Column() {
            Text('训练结果报告')
              .fontSize(24)
              .fontWeight(FontWeight.Bold)
              .margin({ bottom: 30 })
            
            // 时间统计
            Column() {
              Text('时间统计')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 15 })
                .alignSelf(ItemAlign.Start)
              
              Row() {
                Text('记忆时间：')
                  .fontSize(16)
                  .width('50%')
                Text(this.formatTime(this.memoryTime))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2196F3')
                  .width('50%')
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('回忆时间：')
                  .fontSize(16)
                  .width('50%')
                Text(this.formatTime(this.recallTime))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4CAF50')
                  .width('50%')
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('总时间：')
                  .fontSize(16)
                  .width('50%')
                Text(this.formatTime(this.totalTime))
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF9800')
                  .width('50%')
              }
              .width('100%')
            }
            .width('100%')
            .padding({ bottom: 20 })
            .border({ width: 1, color: '#E0E0E0' })
            .borderRadius(8)
            .padding({ top: 15, left: 15, right: 15, bottom: 15 })
            .margin({ bottom: 20 })
            
            // 准确率统计
            Column() {
              Text('准确率统计')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .margin({ bottom: 15 })
                .alignSelf(ItemAlign.Start)
              
              Row() {
                Text('正确数字：')
                  .fontSize(16)
                  .width('50%')
                Text(`${this.correctCount} / ${this.totalDigits}`)
                  .fontSize(16)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4CAF50')
                  .width('50%')
              }
              .width('100%')
              .margin({ bottom: 10 })
              
              Row() {
                Text('准确率：')
                  .fontSize(16)
                  .width('50%')
                Text(`${this.accuracy}%`)
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor(this.accuracy >= 80 ? '#4CAF50' : (this.accuracy >= 60 ? '#FF9800' : '#F44336'))
                  .width('50%')
              }
              .width('100%')
            }
            .width('100%')
            .padding({ bottom: 20 })
            .border({ width: 1, color: '#E0E0E0' })
            .borderRadius(8)
            .padding({ top: 15, left: 15, right: 15, bottom: 15 })
            .margin({ bottom: 30 })
            
            // 按钮
            Row() {
              Button('复盘')
                .width('38%')
                .height(50)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#FF9800')
                .onClick(() => {
                  this.openReview();
                })
              
              Button('确定')
                .width('38%')
                .height(50)
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .backgroundColor('#2196F3')
                .onClick(() => {
                  this.closeResult();
                })
            }
            .width('100%')
            .justifyContent(FlexAlign.SpaceAround)
          }
          .width('85%')
          .padding(25)
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

      // 复盘视图
      if (this.showReview) {
        Column() {
          Column() {
            // 标题栏
            Row() {
              Text('复盘')
                .fontSize(24)
                .fontWeight(FontWeight.Bold)
                .flexGrow(1)
              
              Text('✕')
                .fontSize(28)
                .fontColor('#666666')
                .fontWeight(FontWeight.Bold)
                .onClick(() => {
                  this.closeReview();
                })
            }
            .width('100%')
            .margin({ bottom: 20 })
            
            // 复盘内容（可滚动）
            Scroll() {
              Column() {
                ForEach(this.rows, (row: NumberRow) => {
                  Column() {
                    // 行号
                    Text(`${row.rowIndex}：`)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#666666')
                      .alignSelf(ItemAlign.Start)
                      .margin({ bottom: 8 })
                    
                    // 对比显示（每5个数字一行）
                    Column() {
                      ForEach(this.getReviewLines(row), (line: number[]) => {
                        Row() {
                          ForEach(line, (index: number) => {
                            Row() {
                              // 用户输入的数字
                              if (index < row.userInput.length) {
                                Text(row.userInput[index])
                                  .fontSize(28)
                                  .fontWeight(FontWeight.Bold)
                                  .fontColor(row.userInput[index] === row.originalDigits[index] ? '#4CAF50' : '#F44336')
                              } else {
                                // 未输入的位置显示占位符
                                Text('_')
                                  .fontSize(28)
                                  .fontColor('#CCCCCC')
                              }
                              
                              // 如果错误，在旁边显示正确答案
                              if (index < row.userInput.length && row.userInput[index] !== row.originalDigits[index]) {
                                Text(`(${row.originalDigits[index]})`)
                                  .fontSize(20)
                                  .fontColor('#2196F3')
                                  .fontWeight(FontWeight.Medium)
                                  .margin({ left: 2 })
                              } else if (index >= row.userInput.length) {
                                // 未输入的位置显示正确答案
                                Text(`(${row.originalDigits[index]})`)
                                  .fontSize(20)
                                  .fontColor('#999999')
                                  .fontWeight(FontWeight.Medium)
                                  .margin({ left: 2 })
                              }
                            }
                            .margin({ right: 8 })
                          })
                        }
                        .width('100%')
                        .justifyContent(FlexAlign.Start)
                        .margin({ bottom: 8 })
                      })
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Start)
                  }
                  .width('100%')
                  .padding({ top: 15, bottom: 15, left: 15, right: 15 })
                  .margin({ bottom: 15 })
                  .backgroundColor('#F9F9F9')
                  .borderRadius(8)
                })
              }
              .width('100%')
              .padding({ top: 10, bottom: 10 })
            }
            .layoutWeight(1)
            .scrollBar(BarState.Auto)
            
            // 底部按钮
            Button('返回')
              .width('80%')
              .height(50)
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .backgroundColor('#2196F3')
              .margin({ top: 20 })
              .onClick(() => {
                this.closeReview();
              })
          }
          .width('90%')
          .height('85%')
          .padding(25)
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
    .backgroundColor('#F5F5F5')
  }

  @Builder
  createKeyButton(text: string, onClick: () => void, color: string = '#2196F3') {
    Button(text)
      .width('28%')
      .height(70)
      .fontSize(28)
      .fontWeight(FontWeight.Bold)
      .backgroundColor(color)
      .borderRadius(10)
      .onClick(onClick)
  }
}

