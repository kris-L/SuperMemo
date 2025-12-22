import { router } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';

/**
 * 首页 - 每日训练
 */
@Component
export struct Home {
  @State todayCompletedRounds: number = 0;
  @State todayTotalRounds: number = 10;
  @State refreshKey: number = 0; // 用于触发刷新的key
  @Prop @Watch('onRefreshTriggerChange') refreshTrigger: number = 0; // 接收外部刷新信号

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    // 页面每次显示时刷新今日训练进度（包括从今日训练页面返回时）
    await this.loadTodayTrainingProgress();
  }

  /**
   * 监听刷新触发器的变化，当从其他页面返回时会触发
   * 这是解决组件生命周期问题的关键方法
   */
  onRefreshTriggerChange(propName: string) {
    // 当刷新触发器变化时，重新加载数据
    this.loadTodayTrainingProgress();
  }

  /**
   * 页面显示时触发（包括从其他页面返回时）
   * 注意：对于组件来说，这个方法可能不会被调用
   */
  onPageShow() {
    // 刷新今日训练进度
    this.loadTodayTrainingProgress();
  }

  build() {
    Column() {
      // 使用 Scroll 包裹主体内容，避免小屏设备内容被挤到屏幕外
      Scroll() {
        Column() {
          // 顶部标题
          Text('每日训练')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.text_primary'))
            .margin({ top: 20, bottom: 20 })
            .padding({ left: 20, right: 20 })
            .width('100%')

          // 四个功能卡片（2x2）
      Grid() {
            // 编码练习（主色卡片）
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_coding_train'),
                '编码练习',
                '通过编码规则，快速强化数字与图像联想',
                true,
                () => {
                  router.pushUrl({ url: 'pages/CodeTrainingSelect' });
                }
              )
        }

            // 连连看
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_link_game'),
                '连连看',
                '趣味连线记忆，锻炼专注力和短时记忆',
                false,
                () => {
                  router.pushUrl({ url: 'pages/MatchGameSelect' });
                }
              )
        }

            // 数字记忆
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_number_memory'),
                '数字记忆',
                '记住更多数字，提升工作与学习效率',
                false,
                () => {
                  router.pushUrl({ url: 'pages/NumberMemorySelect' });
                }
              )
        }

        // 骨肉相连
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_bone_match'),
                '骨肉相连',
                '通过联想配对，训练图像与关系记忆',
                false,
                () => {
            router.pushUrl({ url: 'pages/BoneMatchSelect' });
                }
              )
            }

        // 翻翻看
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_link_game'),
                '翻翻看',
                '翻转卡片配对记忆，提升记忆能力',
                false,
                () => {
                  router.pushUrl({ url: 'pages/FlipCardSelect' });
                }
              )
            }

        // 路线宫殿
        GridItem() {
              this.buildFeatureCard(
                $r('app.media.ic_route'),
                '路线宫殿',
                '通过路线记忆，构建记忆宫殿',
                false,
                () => {
                  router.pushUrl({ url: 'pages/RoutePalaceSelect' });
                }
              )
            }
          }
          .columnsTemplate('1fr 1fr')
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
          .padding({ left: 16, right: 16, bottom: 20 })

          // 今日训练卡片
          Column() {
            Text('今日训练')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
              .margin({ bottom: 8 })

            // 进度条
            Column() {
              // 背景条
              Column() {
              }
              .width('100%')
              .height(10)
              .backgroundColor('#5B96FF')
              .borderRadius(5)

              // 前景进度（当前先写死 0，用于样式预览）
              Column() {
              }
              .width(this.todayTotalRounds > 0 ? `${Math.min(this.todayCompletedRounds * 100 / this.todayTotalRounds, 100)}%` : '0%')
              .height(10)
              .backgroundColor('#FF9B45')
              .borderRadius(5)
              .position({ x: 0, y: 0 })
            }
            .width('100%')
            .margin({ bottom: 6 })

            // 进度数字
            Text(`${this.todayCompletedRounds} / ${this.todayTotalRounds}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
              .margin({ bottom: 8 })

            // 训练说明
            Text('需要完成10个轮次的数字桩记忆，才算做一次完整训练，并获取的20积分，未完成不计分和不计时。当天保存进度。')
              .fontSize(12)
              .fontColor('#E3F2FF')
              .textAlign(TextAlign.Center)
              .margin({ bottom: 12 })

            // 开始训练按钮（后续实现具体逻辑）
            Button('开始训练')
              .width('100%')
              .height(40)
              .backgroundColor('#FF9800')
              .fontColor(Color.White)
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .borderRadius(20)
              .onClick(() => {
                router.pushUrl({ url: 'pages/TodayTraining' });
              })
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 16 })
          .backgroundColor('#4485fd')
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 16, right: 16, bottom: 16 })

          // 通关考试卡片
          // Row() {
          //   // 左侧图标
          //   Image($r('app.media.ic_poker'))
          //     .width(48)
          //     .height(48)
          //     .margin({ right: 12 })
          //
          //   // 右侧文字
          //   Column() {
          //     Text('通关考试')
          //       .fontSize(18)
          //       .fontWeight(FontWeight.Medium)
          //       .fontColor($r('app.color.text_primary'))
          //       .margin({ bottom: 4 })
          //
          //     Text('挑战各类记忆考试，检验你的记忆能力')
          //       .fontSize(14)
          //       .fontColor($r('app.color.text_secondary'))
          //       .maxLines(2)
          //       .textOverflow({ overflow: TextOverflow.Ellipsis })
          //   }
          //   .layoutWeight(1)
          //   .alignItems(HorizontalAlign.Start)
          // }
          // .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          // .backgroundColor(Color.White)
          // .borderRadius(12)
          // .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          // .margin({ left: 16, right: 16, bottom: 16 })
          // .onClick(() => {
          //   router.pushUrl({ url: 'pages/ExamList' });
          // })

          // 扑克记忆卡片
          Row() {
            // 左侧图标
            Image($r('app.media.ic_poker'))
              .width(48)
              .height(48)
              .margin({ right: 12 })

            // 右侧文字
            Column() {
              Text('扑克记忆')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.text_primary'))
                .margin({ bottom: 4 })

              Text('通过快速记忆整副扑克牌，挑战极限记忆力')
                .fontSize(14)
                .fontColor($r('app.color.text_secondary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)
          }
          .padding({ left: 16, right: 16, top: 12, bottom: 12 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 16, right: 16, bottom: 24 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/PokerMemory' });
          })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#92c9e9')
  }

  private async loadTodayTrainingProgress() {
    try {
      const now = new Date();
      const dateKey = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
      const progress = await this.dbManager.getDailyTrainingProgress(dateKey);
      this.todayCompletedRounds = progress.roundsCompleted;
      this.todayTotalRounds = progress.totalRounds || 10;
    } catch (err) {
      console.error('加载今日训练进度失败', err);
    }
  }

  @Builder
  buildFeatureCard(iconRes: Resource, title: string, desc: string, isPrimary: boolean, onClick: () => void) {
    Column() {
      // 图片
      Image(iconRes)
        .width(40)
        .height(40)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 8 })

      // 功能标题
      Text(title)
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(isPrimary ? Color.White : $r('app.color.text_primary'))
        .margin({ bottom: 4 })

      // 功能说明
      Text(desc)
        .fontSize(12)
        .fontColor(isPrimary ? '#E3F2FF' : '#777777')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
      .width('100%')
    .padding({ top: 12, bottom: 12, left: 12, right: 12 })
    .backgroundColor(isPrimary ? '#518dfd' : '#fdeadc')
      .borderRadius(12)
    .shadow({ radius: 4, color: '#19000000', offsetX: 0, offsetY: 2 })
    .onClick(() => {
      onClick();
    })
  }
}

@Preview
@Component
struct TodayTrainingPreview {
  build() {
    // 预览首页整体布局（包含“今日训练”卡片）
    Home()
  }
}
