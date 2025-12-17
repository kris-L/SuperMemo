import { router } from '@kit.ArkUI';

/**
 * 学习指南条目数据
 */
interface GuideItem {
  id: number;
  title: string;
}

/**
 * 学习指南列表页面
 */
@Entry
@Component
struct GuideListPage {
  @State guideList: GuideItem[] = [
    { id: 1, title: '增加记忆的五个小窍门' },
    { id: 2, title: '简书记忆如何运作' },
    { id: 3, title: '110数字桩' },
    { id: 4, title: '110数字桩之三十六计记忆应用' },
    { id: 5, title: '走遍中国路线桩' },
    { id: 6, title: '扑克牌记忆训练' },
    { id: 7, title: '如何牢记别人的手机号码' },
    { id: 8, title: '数字桩之三字经记忆方法实例' },
    { id: 9, title: '数字桩之圆周率后1000位记忆' }
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
        .type(ButtonType.Normal)
        .onClick(() => {
          router.back();
        })

        Text('学习指南')
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
      List() {
        ForEach(this.guideList, (item: GuideItem, index: number) => {
          ListItem() {
            Row() {
              // 序号
              Text(`${item.id}`)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor('#2196F3')
                .width(32)
                .textAlign(TextAlign.Center)
                .margin({ right: 16 })

              // 标题
              Text(item.title)
                .fontSize(16)
                .fontColor('#333333')
                .layoutWeight(1)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })

              // 右箭头
              Image($r('app.media.ic_right_arrow'))
                .width(20)
                .height(20)
                .margin({ left: 12 })
            }
            .width('100%')
            .height(60)
            .padding({ left: 16, right: 16 })
            .backgroundColor(Color.White)
            .onClick(() => {
              // 点击事件先不做实现
              // TODO: 跳转到详细说明页面
            })
          }
        }, (item: GuideItem) => `${item.id}`)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({ strokeWidth: 1, color: '#E0E0E0', startMargin: 48, endMargin: 0 })
      .backgroundColor('#F5F5F5')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
