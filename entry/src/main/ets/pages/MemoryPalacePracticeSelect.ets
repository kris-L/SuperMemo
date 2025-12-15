import { router, promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { MemoryPalaceData } from '../model/MemoryPalace';

/**
 * 记忆宫殿练习选择页面
 */
@Entry
@Component
struct MemoryPalacePracticeSelect {
  @State palaces: MemoryPalaceData[] = []; // 记忆宫殿列表

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    await this.loadPalaces();
  }

  /**
   * 加载记忆宫殿列表
   */
  async loadPalaces() {
    try {
      this.palaces = await this.dbManager.getAllMemoryPalaces();
    } catch (err) {
      console.error('加载记忆宫殿列表失败', err);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    }
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

        Text('请选择要练习的宫殿')
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
      .margin({ bottom: 10 })

      // 内容区域
      if (this.palaces.length === 0) {
        Column() {
          Text('暂无记忆宫殿')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Grid() {
          ForEach(this.palaces, (palace: MemoryPalaceData) => {
            GridItem() {
              this.buildPalaceCard(palace);
            }
          }, (palace: MemoryPalaceData) => `palace_${palace.id}`)
        }
        .columnsTemplate('1fr 1fr')
        .columnsGap(12)
        .rowsGap(12)
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildPalaceCard(palace: MemoryPalaceData) {
    Column() {
      // 图片
      Image($r('app.media.ic_palace'))
        .width(70)
        .height(70)
        .objectFit(ImageFit.Contain)
        .margin({ bottom: 12 })

      // 宫殿名称
      Text(palace.name)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#333333')
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Center)
        .padding({ left: 8, right: 8 })
    }
    .width('100%')
    .height(160)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#20000000', offsetX: 0, offsetY: 2 })
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      if (palace.id) {
        router.pushUrl({
          url: 'pages/MemoryPalacePractice',
          params: { palaceId: palace.id }
        });
      }
    })
  }
}

