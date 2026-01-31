/**
 * 导航项接口
 */
interface TabItem {
  icon: string;
  label: string;
}

/**
 * 底部导航栏组件
 */
@ComponentV2
export struct BottomNavigation {
  @Param currentIndex: number = 0; // 当前选中的索引
  @Param onTabChange: (index: number) => void = () => {}; // 切换回调

  // 导航项配置
  private readonly tabs: TabItem[] = [
    { icon: '练', label: '每日训练' },
    { icon: '宫', label: '记忆宫殿' },
    { icon: '我', label: '我的' }
  ];

  build() {
    Row() {
      ForEach(this.tabs, (item: TabItem, index: number) => {
        Column() {
          // 圆形卡片
          Stack() {
            Text(item.icon)
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.currentIndex === index ? Color.White : '#666666')
          }
          .width(50)
          .height(50)
          .borderRadius(28)
          .backgroundColor(this.currentIndex === index ? '#2196F3' : '#E0E0E0')
          .margin({ bottom: 4 })

          // 菜单文字
          Text(item.label)
            .fontSize(12)
            .fontColor(this.currentIndex === index ? '#2196F3' : '#999999')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          if (this.currentIndex !== index) {
            this.onTabChange(index);
          }
        })
      }, (item: TabItem, index: number) => `tab_${index}`)
    }
    .width('100%')
    .height(80)
    .padding({ top: 5, bottom: 8, left: 12, right: 12 })
    .backgroundColor(Color.White)
    .shadow({ radius: 8, color: '#20000000', offsetX: 0, offsetY: -2 })
  }
}

