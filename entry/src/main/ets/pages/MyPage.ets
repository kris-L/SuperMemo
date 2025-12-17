import { promptAction, router } from '@kit.ArkUI';
import { DatabaseManager, UserStats } from '../database/DatabaseManager';

/**
 * 我的页面
 */
@Component
export struct MyPage {
  @State username: string = '';
  @State points: number = 0;
  @State trainCount: number = 0;
  @State trainDuration: number = 0; // 单位：分钟
  @State hasSignedToday: boolean = false;
  @State avatarKey: string = ''; // 头像标识
  @State showEditUserDialog: boolean = false;
  @State editUsername: string = '';
  @State editAvatarKey: string = '';

  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private userStats: UserStats | null = null;

  async aboutToAppear() {
    await this.loadUserStats();
  }

  /**
   * 加载用户统计数据
   */
  private async loadUserStats() {
    try {
      const stats = await this.dbManager.getUserStats();
      this.userStats = stats;
      this.username = stats.username;
      this.avatarKey = stats.avatar || '';
      this.points = stats.points;
      this.trainCount = stats.trainCount;
      // trainDuration在数据库中存储为0.01分钟单位，需要转换为实际分钟数
      // 例如：33表示0.33分钟，100表示1.00分钟
      this.trainDuration = (stats.trainDuration || 0) / 100;
      this.hasSignedToday = this.isToday(stats.lastSignInDate);
    } catch (err) {
      console.error('加载用户统计数据失败', err);
      promptAction.showToast({ message: '加载用户信息失败', duration: 2000 });
    }
  }

  /**
   * 判断给定日期是否为今天（格式：yyyyMMdd）
   */
  private isToday(dateValue?: number): boolean {
    if (!dateValue) {
      return false;
    }
    const now = new Date();
    const todayKey = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
    return dateValue === todayKey;
  }

  /**
   * 格式化训练时长显示（保留2位小数）
   */
  private formatDuration(minutes: number): string {
    // 如果小于0.01，显示0.00
    if (minutes < 0.01) {
      return '0.00';
    }
    // 保留2位小数
    return minutes.toFixed(2);
  }

  /**
   * 处理每日签到
   */
  async onSignIn() {
    if (!this.userStats) {
      await this.loadUserStats();
      if (!this.userStats) {
        return;
      }
    }

    const now = new Date();
    const todayKey = now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();

    // 检查今天是否已经签到（通过积分记录表检查，更可靠）
    const hasSignedToday = await this.dbManager.hasPointsRecordByDateAndSource(todayKey, '每日签到');
    if (hasSignedToday || this.isToday(this.userStats.lastSignInDate)) {
      promptAction.showToast({ message: '今天已签到，明天再来哦~', duration: 2000 });
      this.hasSignedToday = true;
      return;
    }

    // 未签到，增加积分并记录
    const pointsToAdd = 10;
    this.userStats.points = (this.userStats.points || 0) + pointsToAdd;
    this.userStats.lastSignInDate = todayKey;

    try {
      // 更新用户统计
      await this.dbManager.updateUserStats(this.userStats);
      
      // 记录积分记录
      await this.dbManager.insertPointsRecord({
        dateKey: todayKey,
        source: '每日签到',
        points: pointsToAdd,
        createTime: Date.now()
      });
      
      this.points = this.userStats.points;
      this.hasSignedToday = true;
      promptAction.showToast({ message: '签到成功，获得10积分！', duration: 2000 });
    } catch (err) {
      console.error('签到失败', err);
      promptAction.showToast({ message: '签到失败，请稍后重试', duration: 2000 });
    }
  }

  /**
   * 打开编辑用户信息对话框
   */
  async openEditUserDialog() {
    if (!this.userStats) {
      await this.loadUserStats();
      if (!this.userStats) {
        return;
      }
    }
    this.editUsername = this.username || '';
    this.editAvatarKey = this.avatarKey || '';
    this.showEditUserDialog = true;
  }

  /**
   * 保存用户信息修改
   */
  async onSaveUserInfo() {
    const finalName = this.editUsername.trim();
    if (!finalName) {
      promptAction.showToast({ message: '用户名不能为空', duration: 2000 });
      return;
    }

    if (!this.userStats) {
      return;
    }

    this.userStats.username = finalName;

    try {
      await this.dbManager.updateUserStats(this.userStats);
      this.username = finalName;
      this.showEditUserDialog = false;
      promptAction.showToast({ message: '资料已更新', duration: 2000 });
    } catch (err) {
      console.error('更新用户资料失败', err);
      promptAction.showToast({ message: '更新失败，请稍后重试', duration: 2000 });
    }
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Text('我的')
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
      .margin({ bottom: 20 })

      // 内容区域
      Scroll() {
        Column() {
          // 用户信息卡片
          Row() {
            // 头像
            Column() {
              // 使用应用内已有图标作为占位头像
              Image(
                this.avatarKey === 'palace' ? $r('app.media.ic_palace') :
                  this.avatarKey === 'exercise' ? $r('app.media.ic_exercise') :
                    this.avatarKey === 'everyday' ? $r('app.media.ic_everyday_memory') :
                      $r('app.media.ic_mind_map2')
              )
                .width(64)
                .height(64)
                .borderRadius(32)
                .objectFit(ImageFit.Cover)
            }
            .margin({ right: 16 })

            // 中间：用户名 + 提示语，占据剩余空间
            Column() {
              Text(this.username || '最强大脑')
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor('#333333')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .margin({ bottom: 6 })

              Text('坚持训练，打造你的最强大脑')
                .fontSize(12)
                .fontColor('#999999')
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            // 右侧：独立的“编辑资料”按钮，始终靠近卡片右边
            Text('编辑资料')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor(Color.White)
              .padding({ left: 10, right: 10, top: 6, bottom: 6 })
              .backgroundColor('#2196F3')
              .borderRadius(12)
              .onClick(() => {
                this.openEditUserDialog();
              })
          }
          .width('100%')
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 16, right: 16, bottom: 16 })

          // 每日签到卡片
          Row() {
            Column() {
              Text('每日签到')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .margin({ bottom: 6 })

              Text('每天签到可获得 10 积分')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)

              Text(this.hasSignedToday ? '今天已签到' : '坚持打卡，积分可用于更多训练解锁')
                .fontSize(12)
                .fontColor(this.hasSignedToday ? '#4CAF50' : '#999999')
                .margin({ top: 4 })
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Button(this.hasSignedToday ? '已签到' : '签到')
              .height(40)
              .padding({ left: 16, right: 16 })
              .borderRadius(20)
              .backgroundColor(this.hasSignedToday ? '#BDBDBD' : '#2196F3')
              .fontColor(Color.White)
              .onClick(() => {
                if (!this.hasSignedToday) {
                  this.onSignIn();
                }
              })
          }
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 10, right: 10, bottom: 16 })

          // 训练数据统计
          Column() {
            Text('训练数据统计')
              .fontSize(18)
              .fontWeight(FontWeight.Medium)
              .fontColor('#333333')
              .margin({ bottom: 12 })

            Row() {
              // 积分
              Column() {
                Text(`${this.points}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2196F3')
                  .margin({ bottom: 4 })

                Text('总积分')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('30%')
              .padding({ top: 10, bottom: 10 })
              .backgroundColor('#F5FAFF')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/PointsRecord' });
              })

              // 训练次数
              Column() {
                Text(`${this.trainCount}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FF9800')
                  .margin({ bottom: 4 })

                Text('训练次数')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('30%')
              .padding({ top: 10, bottom: 10 })
              .backgroundColor('#FFF7E6')
              .borderRadius(10)
              .margin({ left: 10, right: 10 })
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/TrainingRecord' });
              })

              // 训练时长
              Column() {
                Text(`${this.formatDuration(this.trainDuration)}`)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#4CAF50')
                  .margin({ bottom: 4 })

                Text('训练时长(分钟)')
                  .fontSize(12)
                  .fontColor('#666666')
              }
              .width('30%')
              .padding({ top: 10, bottom: 10 })
              .backgroundColor('#E8F5E9')
              .borderRadius(10)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                router.pushUrl({ url: 'pages/TrainingRecord' });
              })
            }
            .width('100%')
          }
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 10, right: 10, bottom: 16 })

          // 学习指南卡片
          Row() {
            Column() {
              Text('学习指南')
                .fontSize(18)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .margin({ bottom: 6 })

              Text('掌握记忆技巧，提升学习效率')
                .fontSize(14)
                .fontColor('#666666')
                .width('100%')
                .textAlign(TextAlign.Start)
            }
            .layoutWeight(1)
            .alignItems(HorizontalAlign.Start)

            Image($r('app.media.ic_right_arrow'))
              .width(24)
              .height(24)
          }
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 10, right: 10, bottom: 24 })
          .onClick(() => {
            router.pushUrl({ url: 'pages/GuideList' });
          })

          // 联系我们/问题反馈卡片
          Column() {
            Row() {
              Column() {
                Text('问题反馈')
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .margin({ bottom: 6 })

                Text('遇到问题或有建议？欢迎联系我们')
                  .fontSize(14)
                  .fontColor('#666666')
                  .width('100%')
                  .textAlign(TextAlign.Start)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
            .margin({ bottom: 12 })

            // 邮箱信息
            Row() {
              Text('📧')
                .fontSize(16)
                .margin({ right: 8 })

              Text('445000968@qq.com')
                .fontSize(14)
                .fontColor('#2196F3')
                .decoration({ type: TextDecorationType.Underline })
            }
            .width('100%')
            .justifyContent(FlexAlign.Start)
            .alignItems(VerticalAlign.Center)
          }
          .padding({ top: 16, bottom: 16, left: 16, right: 16 })
          .backgroundColor(Color.White)
          .borderRadius(12)
          .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
          .margin({ left: 10, right: 10, bottom: 24 })
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)

      // 编辑用户信息对话框
      if (this.showEditUserDialog) {
        this.buildEditUserDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundImage($r('app.media.bg_my_page'), ImageRepeat.NoRepeat)
  }

  @Builder
  buildEditUserDialog() {
    Column() {
      Column() {
        Text('编辑个人资料')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        // 用户名输入（只修改名字）
        Text('用户名')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 6 })

        TextInput({ placeholder: '请输入用户名', text: this.editUsername })
          .width('100%')
          .height(40)
          .onChange((val: string) => {
            this.editUsername = val;
          })
          .margin({ bottom: 20 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#9E9E9E')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.showEditUserDialog = false;
            })
            .margin({ right: 10 })

          Button('保存')
            .width('45%')
            .height(40)
            .backgroundColor('#2196F3')
            .fontColor(Color.White)
            .borderRadius(8)
            .onClick(() => {
              this.onSaveUserInfo();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .width('80%')
      .padding(20)
      .backgroundColor(Color.White)
      .borderRadius(12)
      .shadow({ radius: 10, color: '#40000000', offsetX: 0, offsetY: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('#80000000')
    .onClick(() => {
      this.showEditUserDialog = false;
    })
  }
}

@Preview
@Component
struct MyPagePreview {
  build() {
    // 预览实际 MyPage 布局
    MyPage()
  }
}

