import { router, promptAction } from '@kit.ArkUI';
import { DatabaseManager, MindMapData } from '../database/DatabaseManager';
import { MemoryPalaceData } from '../model/MemoryPalace';

/**
 * 记忆宫殿日常记忆页面
 */
@Entry
@Component
struct MemoryPalaceDaily {
  @State mindMaps: MindMapData[] = []; // 思维导图列表
  @State showImportDialog: boolean = false; // 是否显示导入对话框
  @State availablePalaces: MemoryPalaceData[] = []; // 可导入的记忆宫殿列表

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    await this.loadMindMaps();
  }

  /**
   * 加载思维导图列表
   */
  async loadMindMaps() {
    try {
      this.mindMaps = await this.dbManager.getAllMindMaps();
    } catch (err) {
      console.error('加载思维导图列表失败', err);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    }
  }

  /**
   * 打开导入对话框
   */
  async onOpenImportDialog() {
    try {
      this.availablePalaces = await this.dbManager.getAllMemoryPalaces();
      if (this.availablePalaces.length === 0) {
        promptAction.showToast({ message: '暂无记忆宫殿可导入', duration: 2000 });
        return;
      }
      this.showImportDialog = true;
    } catch (err) {
      console.error('加载记忆宫殿列表失败', err);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    }
  }

  /**
   * 导入记忆宫殿
   */
  async onImportPalace(palace: MemoryPalaceData) {
    if (!palace.id) {
      return;
    }

    try {
      // 导入记忆宫殿数据到思维导图表（可以重复导入）
      await this.dbManager.insertMindMap(palace.name, palace.data, palace.id);
      this.showImportDialog = false;
      await this.loadMindMaps();
      promptAction.showToast({ message: '导入成功', duration: 2000 });
    } catch (err) {
      console.error('导入记忆宫殿失败', err);
      promptAction.showToast({ message: '导入失败', duration: 2000 });
    }
  }

  /**
   * 删除思维导图
   */
  async onDeleteMindMap(mindMap: MindMapData) {
    if (!mindMap.id) {
      return;
    }

    try {
      await this.dbManager.deleteMindMap(mindMap.id);
      await this.loadMindMaps();
      promptAction.showToast({ message: '删除成功', duration: 2000 });
    } catch (err) {
      console.error('删除思维导图失败', err);
      promptAction.showToast({ message: '删除失败', duration: 2000 });
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

        Text('记忆宫殿日常记忆')
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
      Stack() {
        // 导入按钮和思维导图列表
        Column() {
          // 导入记忆宫殿按钮
          Row() {
            Image($r('app.media.ic_import'))
              .width(40)
              .height(40)
              .objectFit(ImageFit.Contain)
              .margin({ right: 12 })

            Column() {
              Text('导入记忆宫殿')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor('#333333')
                .alignSelf(ItemAlign.Start)

              Text('从已有宫殿中选择导入')
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
          .margin({ left: 20, right: 20, bottom: 12 })
          .onClick(() => {
            this.onOpenImportDialog();
          })

          // 思维导图列表（2列网格）
          if (this.mindMaps.length === 0) {
            Column() {
              Text('暂无思维导图')
                .fontSize(16)
                .fontColor('#999999')
            }
            .width('100%')
            .layoutWeight(1)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
          } else {
            Grid() {
              ForEach(this.mindMaps, (mindMap: MindMapData) => {
                GridItem() {
                  this.buildMindMapCard(mindMap);
                }
              }, (mindMap: MindMapData) => `mindmap_${mindMap.id}`)
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
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 导入对话框
      if (this.showImportDialog) {
        this.buildImportDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildMindMapCard(mindMap: MindMapData) {
    Stack() {
      Column() {
        // 图片
        Image($r('app.media.ic_mind_map2'))
          .width(70)
          .height(70)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 12 })

        // 名称
        Text(mindMap.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
          .padding({ left: 8, right: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .onClick(() => {
        if (mindMap.id) {
          router.pushUrl({
            url: 'pages/MindMapEditor',
            params: { mindMapId: mindMap.id }
          });
        }
      })

      // 删除按钮 - 放在卡片内的右上角
      Button() {
        Text('×')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .width(28)
      .height(28)
      .backgroundColor('#F44336')
      .borderRadius(14)
      .type(ButtonType.Normal)
      .position({ x: '100%', y: 0 })
      .margin({ top: 8, right: 8 })
      .translate({ x: -36, y: 0 })
      .zIndex(100)
      .onClick(() => {
        this.onDeleteMindMap(mindMap);
      })
    }
    .width('100%')
    .height(160)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#20000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  buildImportDialog() {
    Column() {
      Column() {
        Text('选择要导入的记忆宫殿')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        Scroll() {
          Column() {
            ForEach(this.availablePalaces, (palace: MemoryPalaceData) => {
              Row() {
                Image($r('app.media.ic_palace'))
                  .width(32)
                  .height(32)
                  .margin({ right: 16 })

                Text(palace.name)
                  .fontSize(18)
                  .fontWeight(FontWeight.Medium)
                  .fontColor('#333333')
                  .layoutWeight(1)
              }
              .width('100%')
              .height(64)
              .padding({ left: 16, right: 16 })
              .justifyContent(FlexAlign.Start)
              .alignItems(VerticalAlign.Center)
              .backgroundColor(Color.White)
              .borderRadius(8)
              .border({ width: 1, color: '#E0E0E0' })
              .margin({ bottom: 12 })
              .onClick(() => {
                this.onImportPalace(palace);
              })
            }, (palace: MemoryPalaceData) => `import_palace_${palace.id}`)
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 8 })
        }
        .width('100%')
        .height(400)
        .layoutWeight(1)
        .backgroundColor(Color.White)

        // 取消按钮
        Button('取消')
          .width('100%')
          .height(44)
          .fontSize(16)
          .backgroundColor('#9E9E9E')
          .fontColor(Color.White)
          .margin({ top: 16 })
          .onClick(() => {
            this.showImportDialog = false;
          })
      }
      .width('80%')
      .height('70%')
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
      this.showImportDialog = false;
    })
  }
}
