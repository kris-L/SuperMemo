import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { DataInitializer } from '../database/DataInitializer';
import { MemoryPalaceInitializer } from '../database/MemoryPalaceInitializer';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  async onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): Promise<void> {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    // 初始化数据库
    try {
      const dbManager = DatabaseManager.getInstance();
      await dbManager.init(this.context);
      
      // 初始化默认数据
      await DataInitializer.initializeDefaultData();
      await MemoryPalaceInitializer.initializeDefaultData();
      
      // 清理非当天的训练进度数据，确保日期变化时进度重置
      await dbManager.cleanupOldTrainingProgress();
      
      hilog.info(DOMAIN, 'testTag', '数据库初始化完成');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '数据库初始化失败: %{public}s', JSON.stringify(err));
    }
  }

  async onDestroy(): Promise<void> {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
    
    // 关闭数据库连接
    try {
      const dbManager = DatabaseManager.getInstance();
      await dbManager.close();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', '关闭数据库失败: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/MainFrame', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}