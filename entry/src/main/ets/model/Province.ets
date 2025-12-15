/**
 * 34省数据模型
 * 用于存储省份序号、全称、简称、省会的关联关系
 */
export class Province {
  number: number; // 序号（1-34）
  fullName: string; // 省全称
  shortName: string; // 省简称
  capital: string; // 省会

  constructor(number: number, fullName: string, shortName: string, capital: string) {
    this.number = number;
    this.fullName = fullName;
    this.shortName = shortName;
    this.capital = capital;
  }
}

