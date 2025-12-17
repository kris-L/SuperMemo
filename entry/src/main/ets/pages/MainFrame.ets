import { router } from '@kit.ArkUI';
import { BottomNavigation } from '../components/BottomNavigation';
import { Home } from './Home';
import { MemoryPalace } from './MemoryPalace';
import { MyPage } from './MyPage';

/**
 * 主框架页面 - 包含底部导航栏
 */
@Entry
@Component
struct MainFrame {
  @State currentTabIndex: number = 0; // 当前选中的标签页索引
  @State indexRefreshKey: number = 0; // 用于触发首页刷新的key

  // 标签页内容
  private readonly tabPages: string[] = [
    'pages/Home',           // 每日训练
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
   * 页面显示时触发（从其他页面返回时）
   */
  onPageShow() {
    // 如果当前在首页，强制刷新首页组件以触发数据更新
    if (this.currentTabIndex === 0) {
      this.indexRefreshKey++;
    }
  }

  /**
   * 切换标签页
   */
  onTabChange(index: number) {
    if (this.currentTabIndex !== index) {
      this.currentTabIndex = index;
      // 当切换回首页时，触发刷新
      if (index === 0) {
        this.indexRefreshKey++;
      }
    }
  }

  build() {
    Column() {
      // 内容区域
      Column() {
        if (this.currentTabIndex === 0) {
          // 每日训练 - 显示Index页面内容
          // 使用key来强制刷新组件，同时传递refreshTrigger来触发数据刷新
          Home({ refreshTrigger: this.indexRefreshKey })
            .key(`index_${this.indexRefreshKey}`)
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

