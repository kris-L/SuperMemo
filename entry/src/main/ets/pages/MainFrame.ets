import { router } from '@kit.ArkUI';
import { BottomNavigation } from '../components/BottomNavigation';
import { Index } from './Home';
import { MemoryPalace } from './MemoryPalace';
import { MyPage } from './MyPage';

/**
 * 主框架页面 - 包含底部导航栏
 */
@Entry
@Component
struct MainFrame {
  @State currentTabIndex: number = 0; // 当前选中的标签页索引

  // 标签页内容
  private readonly tabPages: string[] = [
    'pages/Index',           // 每日训练
    'pages/MemoryPalace',   // 记忆宫殿
    'pages/MyPage'          // 我的
  ];

  aboutToAppear() {
    // 可以根据路由参数设置初始标签页
    const params = router.getParams() as Record<string, Object>;
    if (params && params['tabIndex'] !== undefined) {
      this.currentTabIndex = params['tabIndex'] as number;
    }
  }

  /**
   * 切换标签页
   */
  onTabChange(index: number) {
    if (this.currentTabIndex !== index) {
      this.currentTabIndex = index;
      // 可以在这里添加页面切换动画等逻辑
    }
  }

  build() {
    Column() {
      // 内容区域
      Column() {
        if (this.currentTabIndex === 0) {
          // 每日训练 - 显示Index页面内容
          Index()
        } else if (this.currentTabIndex === 1) {
          // 记忆宫殿
          MemoryPalace()
        } else if (this.currentTabIndex === 2) {
          // 我的
          MyPage()
        }
      }
      .width('100%')
      .layoutWeight(1) // 占据剩余空间
      .backgroundColor('#F5F5F5')

      // 底部导航栏
      BottomNavigation({
        currentIndex: this.currentTabIndex,
        onTabChange: (index: number) => {
          this.onTabChange(index);
        }
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}

