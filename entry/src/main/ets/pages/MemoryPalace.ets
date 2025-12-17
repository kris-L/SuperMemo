import { router } from '@kit.ArkUI';

/**
 * 功能菜单项接口
 */
interface MenuItem {
  icon: Resource;
  title: string;
  description: string;
  onClick: () => void;
}

/**
 * 记忆宫殿页面
 */
@Component
export struct MemoryPalace {
  // 功能菜单列表
  private readonly menuItems: MenuItem[] = [
    {
      icon: $r('app.media.ic_palace'),
      title: '搭建记忆宫殿',
      description: '创建和管理你的记忆宫殿',
      onClick: () => {
        router.pushUrl({ url: 'pages/MemoryPalaceList' });
      }
    },
    {
      icon: $r('app.media.ic_exercise'),
      title: '记忆宫殿练习',
      description: '通过练习巩固记忆宫殿',
      onClick: () => {
        router.pushUrl({ url: 'pages/MemoryPalacePracticeSelect' });
      }
    },
    // {
    //   icon: $r('app.media.ic_book'),
    //   title: '记忆宫殿文章记忆',
    //   description: '使用记忆宫殿记忆文章内容',
    //   onClick: () => {
    //     console.info('跳转到文章记忆');
    //   }
    // },
    {
      icon: $r('app.media.ic_everyday_memory'),
      title: '记忆宫殿日常记忆',
      description: '将记忆宫殿应用到日常记忆',
      onClick: () => {
        router.pushUrl({ url: 'pages/MemoryPalaceDaily' });
      }
    }
  ];

  build() {
    Column() {
      // 顶部栏
      Row() {
        Blank()
          .width(44)
          .height(44)

        Text('记忆宫殿')
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
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 20 })

      // 功能菜单列表
      Column() {
        ForEach(this.menuItems, (item: MenuItem, index: number) => {
          this.buildMenuCard(item, index)
        }, (item: MenuItem, index: number) => `menu_${index}`)
      }
      .width('100%')
      .layoutWeight(1)
      .padding({ left: 16, right: 16 })
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildMenuCard(item: MenuItem, index: number) {
    Row() {
      // 左边圆形图片
      Stack() {
        Image(item.icon)
          .width(40)
          .height(40)
          .objectFit(ImageFit.Contain)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#E3F2FD')
      .margin({ right: 16 })
      .alignContent(Alignment.Center)

      // 右边文字区域
      Column() {
        // 功能标题
        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#333333')
          .margin({ bottom: 4 })
          .alignSelf(ItemAlign.Start)

        // 功能说明
        Text(item.description)
          .fontSize(12)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(80)
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .backgroundColor(Color.White)
    .borderRadius(12)
    .margin({ bottom: 12 })
    .onClick(() => {
      item.onClick();
    })
  }
}

