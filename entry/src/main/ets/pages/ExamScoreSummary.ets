import { router } from '@kit.ArkUI';
import { DatabaseManager, NumberPegExamRecord, StratagemExamRecord, ProvinceExamRecord, PokerExamRecord } from '../database/DatabaseManager';

/**
 * 考试统计信息
 */
interface ExamStats {
  examType: string; // 考试类型
  count: number; // 考试次数
  bestTime: number | null; // 最好成绩（最短时间，秒）
}

/**
 * 考试成绩汇总页面
 */
@Entry
@Component
struct ExamScoreSummary {
  @State stats: ExamStats[] = [];
  @State isLoading: boolean = true;

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    await this.loadStats();
  }

  /**
   * 加载考试统计信息
   */
  private async loadStats() {
    try {
      this.isLoading = true;
      
      // 加载所有考试记录
      const numberPegRecords = await this.dbManager.getAllNumberPegExamRecords();
      const stratagemRecords = await this.dbManager.getAllStratagemExamRecords();
      const provinceRecords = await this.dbManager.getAllProvinceExamRecords();
      const pokerRecords = await this.dbManager.getAllPokerExamRecords();

      // 计算统计信息
      const statsList: ExamStats[] = [];

      // 110数字桩考试
      if (numberPegRecords.length > 0) {
        const bestTime = Math.min(...numberPegRecords.map(r => r.duration));
        statsList.push({
          examType: '110数字桩考试',
          count: numberPegRecords.length,
          bestTime: bestTime
        });
      } else {
        statsList.push({
          examType: '110数字桩考试',
          count: 0,
          bestTime: null
        });
      }

      // 三十六计考试
      if (stratagemRecords.length > 0) {
        const bestTime = Math.min(...stratagemRecords.map(r => r.duration));
        statsList.push({
          examType: '三十六计考试',
          count: stratagemRecords.length,
          bestTime: bestTime
        });
      } else {
        statsList.push({
          examType: '三十六计考试',
          count: 0,
          bestTime: null
        });
      }

      // 34省路线桩考试
      if (provinceRecords.length > 0) {
        const bestTime = Math.min(...provinceRecords.map(r => r.duration));
        statsList.push({
          examType: '34省路线桩考试',
          count: provinceRecords.length,
          bestTime: bestTime
        });
      } else {
        statsList.push({
          examType: '34省路线桩考试',
          count: 0,
          bestTime: null
        });
      }

      // 扑克记忆考试
      if (pokerRecords.length > 0) {
        const bestTime = Math.min(...pokerRecords.map(r => r.duration));
        statsList.push({
          examType: '扑克记忆考试',
          count: pokerRecords.length,
          bestTime: bestTime
        });
      } else {
        statsList.push({
          examType: '扑克记忆考试',
          count: 0,
          bestTime: null
        });
      }

      this.stats = statsList;
      this.isLoading = false;
    } catch (err) {
      console.error('加载考试统计失败', err);
      this.isLoading = false;
    }
  }

  /**
   * 格式化时间显示
   */
  private formatTime(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
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
        .type(ButtonType.Normal)
        .onClick(() => {
          router.back();
        })

        Text('考试成绩')
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
      .backgroundColor(Color.White)

      // 内容区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#2196F3')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.stats, (stat: ExamStats, index: number) => {
            ListItem() {
              Column() {
                // 考试类型
                Text(stat.examType)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ bottom: 16 })
                  .width('100%')
                  .textAlign(TextAlign.Start)

                // 统计信息
                Row() {
                  Column() {
                    Text('考试次数')
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ bottom: 8 })
                    Text(stat.count.toString())
                      .fontSize(24)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#2196F3')
                  }
                  .flexGrow(1)
                  .alignItems(HorizontalAlign.Center)

                  Column() {
                    Text('最好成绩')
                      .fontSize(14)
                      .fontColor($r('app.color.text_secondary'))
                      .margin({ bottom: 8 })
                    if (stat.bestTime !== null) {
                      Text(this.formatTime(stat.bestTime))
                        .fontSize(24)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#4CAF50')
                    } else {
                      Text('暂无')
                        .fontSize(16)
                        .fontColor($r('app.color.text_tertiary'))
                    }
                  }
                  .flexGrow(1)
                  .alignItems(HorizontalAlign.Center)
                }
                .width('100%')
                .justifyContent(FlexAlign.SpaceAround)
              }
              .width('100%')
              .padding({ top: 20, bottom: 20, left: 20, right: 20 })
              .backgroundColor(Color.White)
              .borderRadius(12)
              .margin({ left: 16, right: 16, bottom: index === this.stats.length - 1 ? 16 : 12 })
              .onClick(() => {
                // 点击跳转到详情页面，传递考试类型
                router.pushUrl({
                  url: 'pages/ExamScoreDetail',
                  params: {
                    examType: stat.examType
                  }
                });
              })
            }
          }, (stat: ExamStats, index: number) => `${stat.examType}_${index}`)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

