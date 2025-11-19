import { router } from '@kit.ArkUI';

/**
 * 首页 - 9宫格布局
 */
@Entry
@Component
struct Index {
  build() {
    Column() {
      // 标题
      Text('记忆法训练')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 20, bottom: 30 })

      // 9宫格布局
      Grid() {
        // 连连看按钮
        GridItem() {
          this.createGameButton('连连看', '#4CAF50', () => {
            router.pushUrl({ url: 'pages/MatchGameSelect' });
          });
        }

        // 数字记忆按钮
        GridItem() {
          this.createGameButton('数字记忆', '#2196F3', () => {
            router.pushUrl({ url: 'pages/NumberMemorySelect' });
          });
        }

        // 预留位置（其他功能按钮）
        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }

        GridItem() {
          this.createGameButton('待开发', '#9E9E9E', () => {
            // 预留
          });
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .rowsTemplate('1fr 1fr 1fr')
      .columnsGap(15)
      .rowsGap(15)
      .width('90%')
      .height('60%')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('#F5F5F5')
  }

  @Builder
  createGameButton(text: string, color: string, onClick: () => void) {
    Button(text)
      .width('100%')
      .height('100%')
      .fontSize(18)
      .fontWeight(FontWeight.Medium)
      .backgroundColor(color)
      .borderRadius(12)
      .onClick(onClick)
  }
}
