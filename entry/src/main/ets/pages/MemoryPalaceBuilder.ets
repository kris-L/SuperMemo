import { router, promptAction } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { MemoryPalaceData, MemoryPalaceStructure, MemoryPalaceCategory } from '../model/MemoryPalace';

/**
 * 树节点接口
 */
interface TreeNode {
  id: string; // 唯一ID
  type: 'palace' | 'category' | 'peg'; // 节点类型
  name: string; // 显示名称
  parentId?: string; // 父节点ID
  children: TreeNode[]; // 子节点
  color?: string; // 颜色（用于分类和桩）
}

/**
 * 记忆宫殿构建器页面
 */
@Entry
@Component
struct MemoryPalaceBuilder {
  @State treeData: TreeNode | null = null; // 树形数据
  @State refreshKey: number = 0; // 用于强制刷新的key
  @State selectedNodeId: string | null = null; // 选中的节点ID
  @State showEditDialog: boolean = false; // 是否显示编辑对话框
  @State editNodeId: string | null = null; // 正在编辑的节点ID
  @State editText: string = ''; // 编辑文本
  @State showDeleteConfirmDialog: boolean = false; // 是否显示删除确认对话框
  @State scaleValue: number = 1.0; // 缩放比例
  @State offsetX: number = 0; // X轴偏移
  @State offsetY: number = 0; // Y轴偏移
  @State initialScale: number = 1.0; // 初始缩放比例
  @State initialOffsetX: number = 0; // 初始X偏移
  @State initialOffsetY: number = 0; // 初始Y偏移
  @State showTipDialog: boolean = false; // 是否显示提示弹窗

  private palaceId: number | null = null; // 记忆宫殿ID
  private dbManager: DatabaseManager = DatabaseManager.getInstance();
  private tipTimer: number | null = null; // 提示弹窗自动关闭定时器
  
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
    // 显示提示弹窗
    this.showTipDialog = true;
    // 10秒后自动关闭
    this.tipTimer = setTimeout(() => {
      this.showTipDialog = false;
      this.tipTimer = null;
    }, 10 * 1000) as number;
  }

  aboutToDisappear() {
    // 页面消失时清除定时器
    if (this.tipTimer !== null) {
      clearTimeout(this.tipTimer);
      this.tipTimer = null;
    }
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
   * 将数据结构转换为树节点
   */
  convertToTreeNode(palaceName: string, structure: MemoryPalaceStructure): TreeNode {
    const palaceNode: TreeNode = {
      id: 'palace_root',
      type: 'palace',
      name: palaceName,
      children: []
    };

    structure.categories.forEach((category, categoryIndex) => {
      const categoryColor = this.mainColors[categoryIndex % this.mainColors.length];
      const categoryNode: TreeNode = {
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
        const pegNode: TreeNode = {
          id: `peg_${categoryIndex}_${pegIndex}`,
          type: 'peg',
          name: peg,
          parentId: categoryNode.id,
          color: pegColor, // 同一个分类的桩使用相同的分类颜色
          children: []
        };
        categoryNode.children.push(pegNode);
      });

      palaceNode.children.push(categoryNode);
    });

    return palaceNode;
  }

  /**
   * 获取渐变颜色（从主颜色浅到深）
   */
  getGradientColor(baseColor: string, index: number, total: number): string {
    // 简单的颜色渐变实现
    const colors = [
      this.lightenColor(baseColor, 0.6),
      this.lightenColor(baseColor, 0.4),
      this.lightenColor(baseColor, 0.2),
      baseColor,
      this.darkenColor(baseColor, 0.2)
    ];
    const colorIndex = Math.floor((index / total) * colors.length);
    return colors[Math.min(colorIndex, colors.length - 1)];
  }

  /**
   * 获取颜色的中间值（浅色和深色的中间）
   */
  getMiddleColor(baseColor: string): string {
    // 返回浅色和深色的中间值
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
   * 颜色变深
   */
  darkenColor(color: string, amount: number): string {
    const num = parseInt(color.replace('#', ''), 16);
    const r = Math.max(0, (num >> 16) - Math.floor(255 * amount));
    const g = Math.max(0, ((num >> 8) & 0x00FF) - Math.floor(255 * amount));
    const b = Math.max(0, (num & 0x0000FF) - Math.floor(255 * amount));
    return `#${((r << 16) | (g << 8) | b).toString(16).padStart(6, '0')}`;
  }

  /**
   * 深拷贝树节点
   */
  deepCopyTreeNode(node: TreeNode): TreeNode {
    const copied: TreeNode = {
      id: node.id,
      type: node.type,
      name: node.name,
      parentId: node.parentId,
      color: node.color,
      children: []
    };
    
    if (node.children && node.children.length > 0) {
      copied.children = node.children.map(child => this.deepCopyTreeNode(child));
    }
    
    return copied;
  }

  /**
   * 选中节点
   */
  selectNode(nodeId: string) {
    this.selectedNodeId = nodeId;
  }

  /**
   * 长按节点（显示编辑对话框）
   */
  onLongPressNode(node: TreeNode) {
    this.editNodeId = node.id;
    this.editText = node.name;
    this.showEditDialog = true;
  }

  /**
   * 保存编辑
   */
  async onSaveEdit() {
    if (!this.editNodeId || !this.treeData) {
      return;
    }

    // 先深拷贝，避免直接修改原对象
    const newTreeData = this.deepCopyTreeNode(this.treeData);
    const node = this.findNodeById(newTreeData, this.editNodeId);
    if (node) {
      node.name = this.editText.trim();
      // 触发更新：先设置为null再赋值，确保UI刷新
      const finalTreeData = this.deepCopyTreeNode(newTreeData);
      this.treeData = null;
      await this.savePalaceData(finalTreeData);
      // 使用setTimeout确保状态更新
      setTimeout(() => {
        this.treeData = finalTreeData;
        this.refreshKey++;
      }, 50);
      this.showEditDialog = false;
      promptAction.showToast({ message: '修改成功', duration: 1000 });
    }
  }

  /**
   * 查找节点
   */
  findNodeById(root: TreeNode, id: string): TreeNode | null {
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

  /**
   * 添加子节点
   */
  async onAddChild() {
    console.info("MYTEST","添加子节点")
    if (!this.selectedNodeId || !this.treeData) {
      promptAction.showToast({ message: '请先选择一个节点', duration: 2000 });
      return;
    }

    // 先深拷贝，避免直接修改原对象
    const newTreeData = this.deepCopyTreeNode(this.treeData);
    const parentNode = this.findNodeById(newTreeData, this.selectedNodeId);
    if (!parentNode) {
      return;
    }

    let newNode: TreeNode;
    if (parentNode.type === 'palace') {
      // 在宫殿下添加分类
      const colorIndex = parentNode.children.length % this.mainColors.length;
      newNode = {
        id: `category_${Date.now()}`,
        type: 'category',
        name: '新分类',
        parentId: parentNode.id,
        color: this.mainColors[colorIndex],
        children: []
      };
    } else if (parentNode.type === 'category') {
      // 在分类下添加桩
      const pegColor = parentNode.color || '#F44336'; // 直接使用分类节点的颜色
      newNode = {
        id: `peg_${Date.now()}`,
        type: 'peg',
        name: '新桩',
        parentId: parentNode.id,
        color: pegColor,
        children: []
      };
    } else {
      promptAction.showToast({ message: '桩下不能再添加子节点', duration: 2000 });
      return;
    }

    parentNode.children.push(newNode);
    // 触发更新：先设置为null再赋值，确保UI刷新
    const finalTreeData = this.deepCopyTreeNode(newTreeData);
    // 先保存数据（传入 finalTreeData，因为此时 this.treeData 会被设置为 null）
    await this.savePalaceData(finalTreeData);
    this.treeData = null;
    // 使用setTimeout确保状态更新
    setTimeout(() => {
      this.treeData = finalTreeData;
      this.refreshKey++;
    }, 50);
    promptAction.showToast({ message: '添加成功', duration: 1000 });
  }

  /**
   * 显示删除确认对话框
   */
  onDeleteNode() {
    if (!this.selectedNodeId || !this.treeData) {
      promptAction.showToast({ message: '请先选择一个节点', duration: 2000 });
      return;
    }

    if (this.selectedNodeId === 'palace_root') {
      promptAction.showToast({ message: '不能删除宫殿根节点', duration: 2000 });
      return;
    }

    this.showDeleteConfirmDialog = true;
  }

  /**
   * 确认删除节点
   */
  async onConfirmDelete() {
    console.info("MYTEST","确认删除节点")
    if (!this.selectedNodeId || !this.treeData) {
      return;
    }

    // 先深拷贝，避免直接修改原对象
    const newTreeData = this.deepCopyTreeNode(this.treeData);
    const node = this.findNodeById(newTreeData, this.selectedNodeId);
    if (!node || !node.parentId) {
      return;
    }

    const parentNode = this.findNodeById(newTreeData, node.parentId);
    if (parentNode) {
      parentNode.children = parentNode.children.filter(child => child.id !== this.selectedNodeId);
      // 触发更新：先设置为null再赋值，确保UI刷新
      const finalTreeData = this.deepCopyTreeNode(newTreeData);
      // 先保存数据（传入 finalTreeData，因为此时 this.treeData 会被设置为 null）
      await this.savePalaceData(finalTreeData);
      this.treeData = null;
      this.selectedNodeId = null;
      this.showDeleteConfirmDialog = false;
      // 使用setTimeout确保状态更新
      setTimeout(() => {
        this.treeData = finalTreeData;
        this.refreshKey++;
      }, 50);
      promptAction.showToast({ message: '删除成功', duration: 2000 });
    }
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
   * 保存数据到数据库
   * @param treeData 可选的树数据，如果不提供则使用 this.treeData
   */
  async savePalaceData(treeData?: TreeNode | null) {
    const dataToSave = treeData !== undefined ? treeData : this.treeData;
    if (!this.palaceId || !dataToSave) {
      return;
    }

    try {
      const palaces = await this.dbManager.getAllMemoryPalaces();
      const palace = palaces.find(p => p.id === this.palaceId);
      if (palace) {
        const structure = this.convertToStructure(dataToSave);
        palace.name = dataToSave.name;
        palace.data = JSON.stringify(structure);
        palace.updateTime = Date.now();
        await this.dbManager.updateMemoryPalace(palace);
        console.info('MYTEST', '保存数据成功', JSON.stringify(structure));
      }
    } catch (err) {
      console.error('保存数据失败', err);
      promptAction.showToast({ message: '保存失败', duration: 2000 });
    }
  }

  /**
   * 将树节点转换为数据结构
   */
  convertToStructure(root: TreeNode): MemoryPalaceStructure {
    const categories: MemoryPalaceCategory[] = [];
    root.children.forEach(categoryNode => {
      categories.push({
        name: categoryNode.name,
        pegs: categoryNode.children.map(pegNode => pegNode.name)
      });
    });
    return { categories };
  }

  /**
   * 缩放视图
   */
  onScale(delta: number) {
    this.scaleValue = Math.max(0.5, Math.min(2.0, this.scaleValue + delta));
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

          Text('记忆宫殿构建器')
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
              })
              .onActionEnd(() => {
                // 缩放结束
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
              .onActionEnd(() => {
                // 拖动结束
              })
          )
        )
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#E3F2FD') // 浅蓝色背景

      // 顶部提示弹窗
      if (this.showTipDialog) {
        this.buildTipDialog()
      }

      // 底部操作按钮（添加和删除）
      Row() {
        Button('添加')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(100)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#4CAF50')
          .onClick(() => {
            this.onAddChild();
          })
          .margin({ right: 12 })

        Button('删除')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
          .width(100)
          .height(44)
          .borderRadius(22)
          .backgroundColor('#F44336')
          .onClick(() => {
            this.onDeleteNode();
          })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .position({ x: '50%', y: '100%' })
      .margin({ bottom: 16 })
      .translate({ x: -106, y: -44 })
      .zIndex(200)

      // 右下角操作按钮
      Column() {
        // 复位按钮
        Button() {
          Text('↺')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#2196F3')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.onResetView();
        })

        // 放大按钮
        Button() {
          Text('+')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#FF9800')
        .margin({ bottom: 8 })
        .onClick(() => {
          this.scaleValue = Math.min(3.0, this.scaleValue + 0.2);
        })

        // 缩小按钮
        Button() {
          Text('−')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
        }
        .width(40)
        .height(40)
        .borderRadius(20)
        .backgroundColor('#FF9800')
        .onClick(() => {
          this.scaleValue = Math.max(0.5, this.scaleValue - 0.2);
        })
      }
      .position({ x: '100%', y: '100%' })
      .margin({ right: 8, bottom: 16 })
      .translate({ x: -48, y: -200 })
      .zIndex(200)
      // 编辑对话框
      if (this.showEditDialog) {
        this.buildEditDialog()
      }

      // 删除确认对话框
      if (this.showDeleteConfirmDialog) {
        this.buildDeleteConfirmDialog()
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTreeView(node: TreeNode, level: number, index: number) {
    Row() {
      // 节点按钮
      Stack() {
        Button() {
          Text(node.name)
            .fontSize(node.type === 'palace' ? 20 : node.type === 'category' ? 18 : 16)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .textAlign(TextAlign.Center)
        }
        .width(node.type === 'palace' ? 120 : node.type === 'category' ? 100 : 80)
        .height(node.type === 'palace' ? 60 : node.type === 'category' ? 50 : 40)
        .backgroundColor(node.color || '#2196F3')
        .borderRadius(8)
        .border({
          width: this.selectedNodeId === node.id ? 3 : 0,
          color: '#FFD700'
        })
        .onClick(() => {
          this.selectNode(node.id);
        })
        .gesture(
          LongPressGesture({ duration: 500 })
            .onAction(() => {
              this.onLongPressNode(node);
            })
        )
      }
      .width(node.type === 'palace' ? 120 : node.type === 'category' ? 100 : 80)
      .height(node.type === 'palace' ? 60 : node.type === 'category' ? 50 : 40)

      // 连接线和子节点
      if (node.children.length > 0) {
        Row() {
          // 连接线（竖线）
          Column() {
            Blank()
          }
          .width(2)
          .backgroundColor('#999999')
          .margin({ left: level === 0 ? 5 : 5, right: 5 }) // 减少左右边距，更紧凑

          // 子节点（垂直排列，整体居中）
          Column() {
            ForEach(node.children, (child: TreeNode, childIndex: number) => {
              // 子节点（去掉横线，直接显示）
              Column() {
                this.buildTreeView(child, level + 1, childIndex)
              }
              .margin({ bottom: childIndex < node.children.length - 1 ? (level >= 1 ? 4 : 15) : 0 }) // 紧凑间距
            }, (child: TreeNode) => child.id)
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
    .margin({ right: 15 }) // 减少右边距，更紧凑
  }

  @Builder
  @Builder
  buildEditDialog() {
    Column() {
      Column() {
        Text('编辑名称')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 16 })

        TextInput({ placeholder: '请输入名称', text: this.editText })
          .width('100%')
          .height(40)
          .onChange((val: string) => {
            this.editText = val;
          })
          .margin({ bottom: 16 })

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .backgroundColor('#9E9E9E')
            .onClick(() => {
              this.showEditDialog = false;
            })
            .margin({ right: 10 })

          Button('确定')
            .width('45%')
            .height(40)
            .backgroundColor('#2196F3')
            .onClick(() => {
              this.onSaveEdit();
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
      this.showEditDialog = false;
    })
  }

  /**
   * 构建顶部提示弹窗
   */
  @Builder
  buildTipDialog() {
    Row() {
      Text('点击选中项目,长按编辑文字,滑动查看内容,双指缩放')
        .fontSize(14)
        .fontColor('#FF6B35')
        .textAlign(TextAlign.Center)
    }
    .width('90%')
    .height(40)
    .padding({ left: 6, right: 6 })
    .backgroundColor('#FFF3E0')
    .borderRadius(20) // 椭圆形
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .position({ x: '50%', y: 56 }) // 标题栏高度56，放在标题栏下方
    .margin({ top: 8 })
    .translate({ x: '-45%', y: 0 })
    .zIndex(300)
    .shadow({ radius: 8, color: '#40000000', offsetX: 0, offsetY: 2 })
  }

  /**
   * 构建删除确认对话框
   */
  @Builder
  buildDeleteConfirmDialog() {
    Column() {
      Column() {
        Text('确认删除')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 8 })

        Text('确定要删除该节点吗？删除后无法恢复。')
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 20 })
          .textAlign(TextAlign.Center)

        Row() {
          Button('取消')
            .width('45%')
            .height(40)
            .fontSize(16)
            .backgroundColor('#9E9E9E')
            .fontColor(Color.White)
            .onClick(() => {
              this.showDeleteConfirmDialog = false;
            })
            .margin({ right: 10 })

          Button('删除')
            .width('45%')
            .height(40)
            .fontSize(16)
            .backgroundColor('#F44336')
            .fontColor(Color.White)
            .onClick(() => {
              this.onConfirmDelete();
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
      this.showDeleteConfirmDialog = false;
    })
  }
}

