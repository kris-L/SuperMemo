import { router } from '@kit.ArkUI';

/**
 * 考试项目接口
 */
interface ExamItem {
  id: number;
  title: string;
  description: string;
  icon?: Resource;
  onClick: () => void;
}

/**
 * 通关考试列表页面
 */
@Entry
@Component
export struct ExamList {
  // 考试项目列表
  private readonly examItems: ExamItem[] = [
    {
      id: 1,
      title: '110数字桩',
      description: '记忆110个数字桩编码，掌握基础记忆法',
      onClick: () => {
        router.pushUrl({ url: 'pages/NumberPegExam' });
      }
    },
    {
      id: 2,
      title: '三十六计',
      description: '记忆三十六计内容，提升策略记忆能力',
      onClick: () => {
        router.pushUrl({ url: 'pages/StratagemExam' });
      }
    },
    {
      id: 3,
      title: '骨肉相连',
      description: '通过配对记忆，训练关联记忆能力',
      onClick: () => {
        router.pushUrl({ url: 'pages/BoneMatchExam' });
      }
    },
    {
      id: 4,
      title: '34省路线桩',
      description: '记忆中国34个省级行政区，掌握地理记忆',
      onClick: () => {
        router.pushUrl({ url: 'pages/ProvinceExam' });
      }
    },
    {
      id: 5,
      title: '扑克记忆',
      description: '快速记忆整副扑克牌，挑战极限记忆力',
      onClick: () => {
        router.pushUrl({ url: 'pages/PokerMemoryExam' });
      }
    },
    // {
    //   id: 6,
    //   title: '手机号速记',
    //   description: '快速记忆手机号码，提升数字记忆能力',
    //   onClick: () => {
    //     // TODO: 跳转到手机号速记考试页面
    //     console.info('跳转到手机号速记考试');
    //   }
    // },
    // {
    //   id: 7,
    //   title: '三字经',
    //   description: '记忆三字经内容，传承经典文化记忆',
    //   onClick: () => {
    //     // TODO: 跳转到三字经考试页面
    //     console.info('跳转到三字经考试');
    //   }
    // }
  ];

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

        Text('通关考试')
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
      .margin({ bottom: 0 })

      // 考试列表
      Scroll() {
        Column() {
          ForEach(this.examItems, (item: ExamItem) => {
            Row() {
              // 左侧图标区域
              Column() {
                Text(item.id.toString())
                  .fontSize(20)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#2196F3')
              }
              .width(48)
              .height(48)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .backgroundColor('#E3F2FD')
              .borderRadius(24)
              .margin({ right: 12 })

              // 中间文字区域
              Column() {
                Text(item.title)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor($r('app.color.text_primary'))
                  .margin({ bottom: 4 })

                Text(item.description)
                  .fontSize(14)
                  .fontColor($r('app.color.text_secondary'))
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)

              // 右侧箭头
              Image($r('app.media.ic_right_arrow'))
                .width(24)
                .height(24)
                .margin({ left: 8 })
            }
            .width('100%')
            .padding({ left: 16, right: 16, top: 16, bottom: 16 })
            .backgroundColor(Color.White)
            .borderRadius(12)
            .shadow({ radius: 6, color: '#1F000000', offsetX: 0, offsetY: 2 })
            .margin({ left: 16, right: 16, bottom: 12 })
            .onClick(() => {
              item.onClick();
            })
          }, (item: ExamItem) => item.id.toString())
        }
        .width('100%')
        .padding({ top: 8, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

@Preview
@Component
struct ExamListPreview {
  build() {
    ExamList()
  }
}

