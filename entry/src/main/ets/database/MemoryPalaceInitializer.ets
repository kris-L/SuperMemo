import { DatabaseManager } from './DatabaseManager';
import { MemoryPalaceData, MemoryPalaceStructure } from '../model/MemoryPalace';

/**
 * 记忆宫殿数据初始化器
 */
export class MemoryPalaceInitializer {
  /**
   * 初始化默认数据
   * 如果数据库为空，则导入默认的"家"记忆宫殿
   */
  public static async initializeDefaultData(): Promise<void> {
    try {
      const dbManager = DatabaseManager.getInstance();
      
      // 检查是否已有数据
      const hasData: boolean = await dbManager.hasMemoryPalaceData();
      if (hasData) {
        console.info('[MemoryPalaceInitializer] 数据库已有记忆宫殿数据，跳过初始化');
        return;
      }

      // 创建默认的"家"记忆宫殿
      const homePalace: MemoryPalaceStructure = {
        categories: [
          {
            name: '客厅',
            pegs: ['门', '鞋柜', '沙发','坐垫', '茶几', '电视','遥控器']
          },
          {
            name: '卧室',
            pegs: ['床头', '床垫','被子','衣柜', '书桌','台灯']
          },
          {
            name: '厨房',
            pegs: ['冰箱', '炉灶','旋转开关', '水槽','水龙头']
          },
          {
            name: '卫生间',
            pegs: ['马桶盖','水箱','洗手台', '淋浴']
          },
          {
            name: '阳台',
            pegs: ['洗衣机', '晾衣机','议价','花盆','植物', '花架']
          }
        ]
      };

      const palace = new MemoryPalaceData('家', JSON.stringify(homePalace));
      await dbManager.insertMemoryPalace(palace);
      
      console.info('[MemoryPalaceInitializer] 成功初始化默认记忆宫殿数据');
    } catch (error) {
      console.error(`[MemoryPalaceInitializer] 初始化默认数据失败: ${JSON.stringify(error)}`);
      throw new Error('初始化默认数据失败: ' + JSON.stringify(error));
    }
  }
}

