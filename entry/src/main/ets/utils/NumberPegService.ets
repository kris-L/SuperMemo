import { DatabaseManager } from '../database/DatabaseManager';
import { NumberPeg } from '../model/NumberPeg';

/**
 * 数字桩服务类
 * 提供数字桩数据的业务逻辑封装
 */
export class NumberPegService {
  private static instance: NumberPegService;
  private dbManager: DatabaseManager;

  private constructor() {
    this.dbManager = DatabaseManager.getInstance();
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): NumberPegService {
    if (!NumberPegService.instance) {
      NumberPegService.instance = new NumberPegService();
    }
    return NumberPegService.instance;
  }

  /**
   * 根据数字获取数字桩数据
   */
  public async getNumberPeg(number: number): Promise<NumberPeg | null> {
    return await this.dbManager.getNumberPegByNumber(number);
  }

  /**
   * 获取所有数字桩数据
   */
  public async getAllNumberPegs(): Promise<NumberPeg[]> {
    return await this.dbManager.getAllNumberPegs();
  }

  /**
   * 更新数字桩数据（用于用户自定义修改）
   */
  public async updateNumberPeg(peg: NumberPeg): Promise<number> {
    peg.isCustom = true; // 标记为用户自定义数据
    return await this.dbManager.updateNumberPeg(peg);
  }

  /**
   * 批量更新数字桩数据（用于批量导入）
   */
  public async batchUpdateNumberPegs(pegs: NumberPeg[]): Promise<void> {
    for (const peg of pegs) {
      peg.isCustom = true; // 标记为用户自定义数据
      await this.dbManager.updateNumberPeg(peg);
    }
  }

  /**
   * 根据图片资源名称获取资源ID
   * @param imageName 图片名称，如 "images0.jpg"
   * @returns 资源ID，可用于 $r() 函数
   */
  public getImageResourceId(imageName: string) {
    // 移除文件扩展名
    const resourceName = imageName.replace('.jpg', '').replace('.png', '');
    return $r(`app.media.${resourceName}`);
  }
}

