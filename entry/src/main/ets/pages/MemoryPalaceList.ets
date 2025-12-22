import { router, promptAction } from '@kit.ArkUI';
import { Context } from '@kit.AbilityKit';
import { DatabaseManager } from '../database/DatabaseManager';
import { MemoryPalaceData, MemoryPalaceStructure } from '../model/MemoryPalace';

/**
 * 记忆宫殿列表页面
 */
@Entry
@Component
struct MemoryPalaceList {
  @State palaces: MemoryPalaceData[] = []; // 记忆宫殿列表
  @State showCreateDialog: boolean = false; // 是否显示创建对话框
  @State newPalaceName: string = ''; // 新宫殿名称

  private dbManager: DatabaseManager = DatabaseManager.getInstance();

  async aboutToAppear() {
    await this.loadPalaces();
  }

  onPageShow() {
    // 页面显示时刷新列表（包括从其他页面返回时）
    this.loadPalaces();
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

  /**
   * 创建新记忆宫殿
   */
  async onCreatePalace() {
    if (!this.newPalaceName.trim()) {
      promptAction.showToast({ message: '请输入宫殿名称', duration: 2000 });
      return;
    }

    try {
      // 创建空的记忆宫殿数据结构
      const emptyData: MemoryPalaceStructure = {
        categories: []
      };
      
      const palace = new MemoryPalaceData(
        this.newPalaceName.trim(),
        JSON.stringify(emptyData)
      );
      
      const insertedId = await this.dbManager.insertMemoryPalace(palace);
      this.newPalaceName = '';
      this.showCreateDialog = false;
      
      // 创建成功后跳转到构建器页面
      if (insertedId) {
        router.pushUrl({
          url: 'pages/MemoryPalaceBuilder',
          params: { palaceId: insertedId }
        });
      } else {
        await this.loadPalaces();
        promptAction.showToast({ message: '创建成功', duration: 2000 });
      }
    } catch (err) {
      console.error('创建记忆宫殿失败', err);
      promptAction.showToast({ message: '创建失败', duration: 2000 });
    }
  }

  /**
   * 删除记忆宫殿
   */
  async onDeletePalace(palace: MemoryPalaceData) {
    console.info("MYTEST","删除宫殿")
    if (!palace.id) {
      return;
    }

    try {
      await this.dbManager.deleteMemoryPalace(palace.id);
      await this.loadPalaces();
      promptAction.showToast({ message: '删除成功', duration: 2000 });
    } catch (err) {
      console.error('删除记忆宫殿失败', err);
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

        Text('记忆宫殿列表')
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
      .margin({ bottom: 10 })

      // 内容区域
      Stack() {
        // 记忆宫殿列表（2列网格）
        if (this.palaces.length === 0) {
          Column() {
            Text('暂无记忆宫殿')
              .fontSize(16)
              .fontColor($r('app.color.text_tertiary'))
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

        // 悬浮创建按钮
        Button() {
          Text('+')
            .fontSize(32)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width(56)
        .height(56)
        .borderRadius(28)
        .backgroundColor('#2196F3')
        .shadow({ radius: 8, color: '#40000000', offsetX: 0, offsetY: 4 })
        .position({ x: '100%', y: '100%' })
        .margin({ right: 16, bottom: 16 })
        .translate({ x: -72, y: -72 })
        .zIndex(200)
        .onClick(() => {
          this.newPalaceName = '';
          this.showCreateDialog = true;
        })
      }
      .width('100%')
      .layoutWeight(1)
      .backgroundColor('#F5F5F5')

      // 创建对话框
      if (this.showCreateDialog) {
        this.buildCreateDialog()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildPalaceCard(palace: MemoryPalaceData) {
    Stack() {
      Column() {
        // 图片
        Image($r('app.media.ic_mind_map2'))
          .width(70)
          .height(70)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 12 })

        // 宫殿名称
        Text(palace.name)
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
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
        console.info("MYTEST","宫殿卡片点击")
        if (palace.id) {
          router.pushUrl({
            url: 'pages/MemoryPalaceBuilder',
            params: { palaceId: palace.id }
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
        console.info("MYTEST","删除按钮点击")
        this.onDeletePalace(palace);
      })
    }
    .width('100%')
    .height(160)
    .backgroundColor(Color.White)
    .borderRadius(12)
    .shadow({ radius: 4, color: '#20000000', offsetX: 0, offsetY: 2 })
  }

  @Builder
  buildCreateDialog() {
    Column() {
      Column() {
        Text('创建记忆宫殿')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 16 })

        TextInput({ placeholder: '请输入宫殿名称', text: this.newPalaceName })
          .width('100%')
          .height(40)
          .fontColor($r('app.color.text_primary'))
          .placeholderColor($r('app.color.text_tertiary'))
          .onChange((val: string) => {
            this.newPalaceName = val;
          })
          .margin({ bottom: 16 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#9E9E9E')
            .onClick(() => {
              this.showCreateDialog = false;
            })
            .margin({ right: 10 })

          Button('确定')
            .width('45%')
            .height(40)
            .backgroundColor('#2196F3')
            .onClick(() => {
              this.onCreatePalace();
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
      this.showCreateDialog = false;
    })
  }
}

