import { StrArrayData } from '../database/StrArrayData';
import { Province } from '../model/Province';

/**
 * 34省服务类
 * 提供34省数据的业务逻辑封装
 */
export class ProvinceService {
  private static instance: ProvinceService;

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): ProvinceService {
    if (!ProvinceService.instance) {
      ProvinceService.instance = new ProvinceService();
    }
    return ProvinceService.instance;
  }

  /**
   * 获取所有34省数据
   */
  public getAllProvinces(): Province[] {
    return StrArrayData.getAllProvinces();
  }

  /**
   * 根据序号获取省份数据
   * @param number 序号（1-34）
   */
  public getProvinceByNumber(number: number): Province | null {
    return StrArrayData.getProvinceByNumber(number);
  }
}

