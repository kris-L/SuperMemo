import { router, promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { MemoryPalaceData, MemoryPalaceStructure } from '../model/MemoryPalace';

/**
 * 树节点接口（带数字）
 */
interface PracticeTreeNode {
  id: string; // 唯一ID
  type: 'palace' | 'category' | 'peg'; // 节点类型
  name: string; // 显示名称
  parentId?: string; // 父节点ID
  children: PracticeTreeNode[]; // 子节点
  color?: string; // 颜色（用于分类和桩）
  number?: string; // 四位随机数字（仅桩有）
  userInput?: string; // 用户输入的数字（复盘时使用）
}


/**
 * 记忆宫殿练习页面
 */
@Entry
@Component
struct MemoryPalacePractice {
  @State treeData: PracticeTreeNode | null = null; // 树形数据
  @State refreshKey: number = 0; // 用于强制刷新的key
  @State scaleValue: number = 1.0; // 缩放比例
  @State offsetX: number = 0; // X轴偏移
  @State offsetY: number = 0; // Y轴偏移
  @State initialScale: number = 1.0; // 初始缩放比例
  @State initialOffsetX: number = 0; // 初始X偏移
  @State initialOffsetY: number = 0; // 初始Y偏移

  private palaceId: number | null = null; // 记忆宫殿ID
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  
  // 主颜色列表（用于分类）
  private readonly mainColors: string[] = [
    '#F44336', // 红色
    '#2196F3', // 蓝色
    '#4CAF50', // 绿色
    '#FF9800', // 橙色
    '#9C27B0', // 紫色
    '#00BCD4', // 青色
    '#E91E63', // 粉色
    '#795548'  // 棕色
  ];

  aboutToAppear() {
    const params = router.getParams() as Record<string, Object>;
    if (params && params['palaceId']) {
      this.palaceId = params['palaceId'] as number;
      this.loadPalaceData();
    }
  }

  /**
   * 生成四位随机数字
   */
  generateRandomNumber(): string {
    return Math.floor(1000 + Math.random() * 9000).toString();
  }

  /**
   * 加载记忆宫殿数据
   */
  async loadPalaceData() {
    if (!this.palaceId) {
      return;
    }

    try {
      const palaces = await this.dbManager.getAllMemoryPalaces();
      const palace = palaces.find(p => p.id === this.palaceId);
      if (palace) {
        const structure: MemoryPalaceStructure = JSON.parse(palace.data);
        this.treeData = this.convertToTreeNode(palace.name, structure);
      }
      // 保存初始状态用于复位
      this.initialScale = 1.0;
      this.initialOffsetX = 0;
      this.initialOffsetY = 0;
      this.scaleValue = 1.0;
      this.offsetX = 0;
      this.offsetY = 0;
    } catch (err) {
      console.error('加载记忆宫殿数据失败', err);
      promptAction.showToast({ message: '加载失败', duration: 2000 });
    }
  }

  /**
   * 将数据结构转换为树节点（带随机数字）
   */
  convertToTreeNode(palaceName: string, structure: MemoryPalaceStructure): PracticeTreeNode {
    const palaceNode: PracticeTreeNode = {
      id: 'palace_root',
      type: 'palace',
      name: palaceName,
      children: []
    };

    structure.categories.forEach((category, categoryIndex) => {
      const categoryColor = this.mainColors[categoryIndex % this.mainColors.length];
      const categoryNode: PracticeTreeNode = {
        id: `category_${categoryIndex}`,
        type: 'category',
        name: category.name,
        parentId: palaceNode.id,
        color: categoryColor,
        children: []
      };

      // 桩节点直接使用分类节点的颜色值
      const pegColor = categoryColor;
      category.pegs.forEach((peg, pegIndex) => {
        const pegNode: PracticeTreeNode = {
          id: `peg_${categoryIndex}_${pegIndex}`,
          type: 'peg',
          name: peg,
          parentId: categoryNode.id,
          color: pegColor,
          number: this.generateRandomNumber(), // 生成四位随机数字
          children: []
        };
        categoryNode.children.push(pegNode);
      });

      palaceNode.children.push(categoryNode);
    });

    return palaceNode;
  }

  /**
   * 获取颜色的中间值（浅色和深色的中间）
   */
  getMiddleColor(baseColor: string): string {
    return this.lightenColor(baseColor, 0.3);
  }

  /**
   * 颜色变浅
   */
  lightenColor(color: string, amount: number): string {
    const num = parseInt(color.replace('#', ''), 16);
    const r = Math.min(255, (num >> 16) + Math.floor(255 * amount));
    const g = Math.min(255, ((num >> 8) & 0x00FF) + Math.floor(255 * amount));
    const b = Math.min(255, (num & 0x0000FF) + Math.floor(255 * amount));
    return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, '0')}`;
  }

  /**
   * 深拷贝树节点
   */
  deepCopyTreeNode(node: PracticeTreeNode): PracticeTreeNode {
    const copied: PracticeTreeNode = {
      id: node.id,
      type: node.type,
      name: node.name,
      parentId: node.parentId,
      color: node.color,
      number: node.number,
      userInput: node.userInput,
      children: []
    };
    
    if (node.children && node.children.length > 0) {
      copied.children = node.children.map(child => this.deepCopyTreeNode(child));
    }
    
    return copied;
  }

  /**
   * 查找所有桩节点
   */
  findAllPegs(root: PracticeTreeNode): PracticeTreeNode[] {
    const pegs: PracticeTreeNode[] = [];
    if (root.type === 'peg') {
      pegs.push(root);
    }
    root.children.forEach(child => {
      pegs.push(...this.findAllPegs(child));
    });
    return pegs;
  }

  /**
   * 记忆完成 - 跳转到复盘页面
   */
  onCompleteMemory() {
    if (!this.treeData) {
      return;
    }

    // 收集所有桩的数字并按顺序拼接
    const pegs = this.findAllPegs(this.treeData);
    const numbers: string[] = [];
    pegs.forEach(peg => {
      if (peg.number) {
        numbers.push(peg.number);
      }
    });
    const combinedNumbers = numbers.join(''); // 拼接所有数字

    // 跳转到复盘页面
    router.pushUrl({
      url: 'pages/MemoryPalaceReview',
      params: {
        numbers: combinedNumbers,
        totalPegs: pegs.length
      }
    });
  }


  /**
   * 复位视图
   */
  onResetView() {
    this.scaleValue = 1.0;
    this.offsetX = 0;
    this.offsetY = 0;
    this.initialScale = 1.0;
    this.initialOffsetX = 0;
    this.initialOffsetY = 0;
    promptAction.showToast({ message: '已复位', duration: 1000 });
  }


  /**
   * 查找节点
   */
  findNodeById(root: PracticeTreeNode, id: string): PracticeTreeNode | null {
    if (root.id === id) {
      return root;
    }
    for (const child of root.children) {
      const found = this.findNodeById(child, id);
      if (found) {
        return found;
      }
    }
    return null;
  }

  build() {
    Stack() {
      // 主内容区域
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

          Text('记忆宫殿练习')
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

        // 画布区域（可缩放和拖动）
        Scroll() {
          if (this.treeData) {
            Row() {
              this.buildTreeView(this.treeData, 0, 0)
            }
            .justifyContent(FlexAlign.Start)
            .alignItems(VerticalAlign.Center)
            .padding(20)
            .scale({ x: this.scaleValue, y: this.scaleValue })
            .translate({ x: this.offsetX, y: this.offsetY })
            .width('100%')
            .height('100%')
            .id(`tree_row_${this.refreshKey}`)
          }
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .scrollable(ScrollDirection.Horizontal)
        .scrollable(ScrollDirection.Vertical)
        .gesture(
          GestureGroup(GestureMode.Parallel,
            // 双指缩放
            PinchGesture({ fingers: 2 })
              .onActionStart((event?: GestureEvent) => {
                if (event) {
                  this.initialScale = this.scaleValue;
                }
              })
              .onActionUpdate((event?: GestureEvent) => {
                if (event && event.scale !== undefined) {
                  const newScale = this.initialScale * event.scale;
                  this.scaleValue = Math.max(0.5, Math.min(3.0, newScale));
                }
              }),
            // 单指拖动
            PanGesture({ fingers: 1, direction: PanDirection.All, distance: 1 })
              .onActionStart(() => {
                this.initialOffsetX = this.offsetX;
                this.initialOffsetY = this.offsetY;
              })
              .onActionUpdate((event?: GestureEvent) => {
                if (event && event.offsetX !== undefined && event.offsetY !== undefined) {
                  this.offsetX = this.initialOffsetX + event.offsetX;
                  this.offsetY = this.initialOffsetY + event.offsetY;
                }
              })
          )
        )
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#E3F2FD') // 浅蓝色背景

      // 底部操作按钮
      Row() {
        // 记忆完成按钮
        Button('记忆完成')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(120)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.onCompleteMemory();
          })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ x: '50%', y: '100%' })
      .margin({ bottom: 16 })
      .translate({ x: -60, y: -44 })
      .zIndex(200)

      // 右下角复位按钮
      Button() {
        Text('↺')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .textAlign(TextAlign.Center)
      }
      .width(48)
      .height(48)
      .borderRadius(24)
      .backgroundColor('#2196F3')
      .position({ x: '100%', y: '100%' })
      .margin({ right: 16, bottom: 16 })
      .translate({ x: -64, y: -200 })
      .zIndex(200)
      .onClick(() => {
        this.onResetView();
      })

    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTreeView(node: PracticeTreeNode, level: number, index: number) {
    Row() {
      // 节点按钮
      if (node.type === 'peg' && node.number) {
        // 正常模式：桩名 + 数字框（并排显示）
        Row() {
          // 桩名按钮
          Button() {
            Text(node.name)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor(Color.White)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .textAlign(TextAlign.Center)
          }
          .width(60)
          .height(40)
          .backgroundColor(node.color || '#2196F3')
          .borderRadius(8)
          .margin({ right: 8 })

          // 数字框（矩形框）
          Button() {
            Text(node.number)
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
          }
          .width(60)
          .height(40)
          .backgroundColor('#FFE082')
          .borderRadius(8)
        }
        .alignItems(VerticalAlign.Center)
      } else {
        // 宫殿和分类节点
        Button() {
          Text(node.name)
            .fontSize(node.type === 'palace' ? 18 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
        }
        .width(node.type === 'palace' ? 100 : 80)
        .height(node.type === 'palace' ? 50 : 40)
        .backgroundColor(node.color || '#2196F3')
        .borderRadius(8)
      }

      // 连接线和子节点
      if (node.children.length > 0) {
        Row() {
          // 连接线（竖线）
          Column() {
            Blank()
          }
          .width(2)
          .backgroundColor('#999999')
          .margin({ left: level === 0 ? 5 : 8, right: 8 })

          // 子节点（垂直排列）
          Column() {
            ForEach(node.children, (child: PracticeTreeNode, childIndex: number) => {
              // 子节点（去掉横线）
              Column() {
                this.buildTreeView(child, level + 1, childIndex)
              }
              .margin({ bottom: childIndex < node.children.length - 1 ? (level >= 1 ? 4 : 20) : 0 })
            }, (child: PracticeTreeNode) => child.id)
          }
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Start)
          .alignSelf(ItemAlign.Center)
        }
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
      }
    }
    .justifyContent(FlexAlign.Start)
    .alignItems(VerticalAlign.Center)
    .margin({ right: 20 })
  }

}

