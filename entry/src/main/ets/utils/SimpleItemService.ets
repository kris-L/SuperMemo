import { StrArrayData } from '../database/StrArrayData';
import { SimpleItem } from '../model/SimpleItem';

/**
 * 简单数据项服务类
 * 提供36计和三字经数据的业务逻辑封装
 */
export class SimpleItemService {
  private static instance: SimpleItemService;

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): SimpleItemService {
    if (!SimpleItemService.instance) {
      SimpleItemService.instance = new SimpleItemService();
    }
    return SimpleItemService.instance;
  }

  /**
   * 获取所有36计数据
   */
  public getAllStratagems(): SimpleItem[] {
    return StrArrayData.getAllStratagems();
  }

  /**
   * 根据序号获取36计数据
   * @param number 序号（1-36）
   */
  public getStratagemByNumber(number: number): SimpleItem | null {
    return StrArrayData.getStratagemByNumber(number);
  }

  /**
   * 获取所有三字经数据
   */
  public getAllSanZiJing(): SimpleItem[] {
    return StrArrayData.getAllSanZiJing();
  }

  /**
   * 根据序号获取三字经数据
   * @param number 序号（从1开始）
   */
  public getSanZiJingByNumber(number: number): SimpleItem | null {
    return StrArrayData.getSanZiJingByNumber(number);
  }
}

