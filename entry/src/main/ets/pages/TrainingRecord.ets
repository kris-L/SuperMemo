import { router } from '@kit.ArkUI';
import { DatabaseManager, TrainingRecord } from '../database/DatabaseManager';

/**
 * 训练记录列表页面
 */
@Entry
@Component
struct TrainingRecordPage {
  @State records: TrainingRecord[] = [];
  @State isLoading: boolean = true;

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    await this.loadRecords();
  }

  /**
   * 加载训练记录
   */
  private async loadRecords() {
    try {
      this.isLoading = true;
      this.records = await this.dbManager.getAllTrainingRecords();
      this.isLoading = false;
    } catch (err) {
      console.error('加载训练记录失败', err);
      this.isLoading = false;
    }
  }

  /**
   * 格式化时间戳为日期时间字符串
   */
  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day} ${hours}:${minutes}`;
  }

  /**
   * 格式化时长为（+分钟.秒s）格式
   * 例如：20秒 -> +0.20s, 80秒 -> +1.20s, 125秒 -> +2.05s
   */
  private formatDuration(seconds: number): string {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    // 秒数需要格式化为两位数字，不足两位前面补0
    const secsStr = String(secs).padStart(2, '0');
    return `+${mins}.${secsStr}s`;
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

        Text('训练记录')
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
      } else if (this.records.length === 0) {
        Column() {
          Text('暂无训练记录')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.records, (record: TrainingRecord, index: number) => {
            ListItem() {
              Row() {
                Column() {
                  // 训练类型
                  Text(record.gameType)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#333333')
                    .margin({ bottom: 6 })

                  // 时间
                  Text(this.formatDateTime(record.createTime))
                    .fontSize(12)
                    .fontColor('#999999')
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                Column() {
                  // 次数（最新的为第1次）
                  Text(`第${index + 1}次`)
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ bottom: 4 })

                  // 时长
                  Text(this.formatDuration(record.duration))
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#4CAF50')
                }
                .alignItems(HorizontalAlign.End)
                .margin({ right: 10 })
              }
              .width('100%')
              .padding({ top: 16, bottom: 16, left: 16, right: 16 })
              .backgroundColor(Color.White)
              .borderRadius(8)
              .margin({ left: 16, right: 16, bottom: index === this.records.length - 1 ? 16 : 8 })
            }
          }, (record: TrainingRecord) => `${record.id}`)
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
