import { DatabaseManager } from './DatabaseManager';
import { NumberPeg } from '../model/NumberPeg';

/**
 * 数据初始化工具类
 * 用于导入默认的110数字桩数据
 */
export class DataInitializer {
  /**
   * 默认数字桩编码数据
   * 格式：数字 -> 编码
   */
  private static readonly DEFAULT_CODES: Map<number, string> = new Map([
    [0, '铃'], [1, '衣'], [2, '耳'], [3, '山'], [4, '寺'],
    [5, '舞'], [6, '柳'], [7, '棋'], [8, '发'], [9, '酒'],
    [10, '衣领'], [11, '姨姨'], [12, '婴儿'], [13, '雨伞'], [14, '钥匙'],
    [15, '鹦鹉'], [16, '窑炉'], [17, '仪器'], [18, '腰包'], [19, '药酒'],
    [20, '恶灵'], [21, '鳄鱼'], [22, '鹅鹅'], [23, '耳塞'], [24, '饿死'],
    [25, '二胡'], [26, '二流'], [27, '耳机'], [28, '恶霸'], [29, '爱酒'],
    [30, '三菱'], [31, '山药'], [32, '扇儿'], [33, '闪闪'], [34, '绅士'],
    [35, '山屋'], [36, '山路'], [37, '山鸡'], [38, '伞把'], [39, '散酒'],
    [40, '司令'], [41, '司仪'], [42, '柿儿'], [43, '石山'], [44, '石狮'],
    [45, '饰物'], [46, '死路'], [47, '司机'], [48, '丝帕'], [49, '死狗'],
    [50, '武林'], [51, '五一'], [52, '捂耳'], [53, '午餐'], [54, '武士'],
    [55, '呜呜'], [56, '物流'], [57, '武器'], [58, '五霸'], [59, '午觉'],
    [60, '榴莲'], [61, '六一'], [62, '牛耳'], [63, '流沙'], [64, '流石'],
    [65, '锣鼓'], [66, '溜溜'], [67, '刘淇'], [68, '喇叭'], [69, '鹿角'],
    [70, '麒麟'], [71, '七一'], [72, '企鹅'], [73, '青山'], [74, '骑士'],
    [75, '骑虎'], [76, '气流'], [77, '漆器'], [78, '气泵'], [79, '气球'],
    [80, '巴黎'], [81, '八一'], [82, '靶儿'], [83, '巴萨'], [84, '巴士'],
    [85, '白虎'], [86, '八路'], [87, '白旗'], [88, '爸爸'], [89, '芭蕉'],
    [90, '精灵'], [91, '球衣'], [92, '球儿'], [93, '旧伞'], [94, '教师'],
    [95, '旧屋'], [96, '酒楼'], [97, '酒器'], [98, '酒吧'], [99, '舅舅'],
    [100, '铃铃'], [101, '灵药'], [102, '灵儿'], [103, '灵山'], [104, '零食'],
    [105, '领舞'], [106, '领路'], [107, '令旗'], [108, '篱笆'], [109, '菱角']
  ]);

  /**
   * 初始化默认数据
   * 如果数据库为空，则导入110个数字桩数据
   */
  public static async initializeDefaultData(): Promise<void> {
    try {
      const dbManager = DatabaseManager.getInstance();
      
      // 检查是否已有数据
      const hasData: boolean = await dbManager.hasData();
      if (hasData) {
        console.info('[DataInitializer] 数据库已有数据，跳过初始化');
        return;
      }

      // 生成数字桩数据列表
      const pegs: NumberPeg[] = [];
      for (let i = 0; i <= 109; i++) {
        const code = DataInitializer.DEFAULT_CODES.get(i);
        if (code) {
          // 图片资源名称：images0.jpg, images1.jpg, ..., images109.jpg
          const imageName = `images${i}.jpg`;
          const peg = new NumberPeg(i, code, imageName, false);
          pegs.push(peg);
        }
      }

      // 批量插入数据
      await dbManager.insertNumberPegs(pegs);
      console.info(`[DataInitializer] 成功初始化${pegs.length}条默认数字桩数据`);
    } catch (error) {
      console.error(`[DataInitializer] 初始化默认数据失败: ${JSON.stringify(error)}`);
      throw new Error('初始化默认数据失败: ' + JSON.stringify(error));
    }
  }

  /**
   * 获取默认编码数据（用于后续批量导入功能）
   */
  public static getDefaultCodes(): Map<number, string> {
    return new Map(DataInitializer.DEFAULT_CODES);
  }
}

