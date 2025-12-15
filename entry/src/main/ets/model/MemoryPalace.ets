/**
 * 记忆宫殿数据模型
 */
export class MemoryPalaceData {
  id?: number; // 主键ID
  name: string; // 宫殿名
  data: string; // JSON格式存储：{ categories: [{ name: string, pegs: string[] }] }
  createTime?: number; // 创建时间
  updateTime?: number; // 更新时间

  constructor(name: string, data: string) {
    this.name = name;
    this.data = data;
  }
}

/**
 * 记忆宫殿分类数据
 */
export interface MemoryPalaceCategory {
  name: string; // 分类名
  pegs: string[]; // 桩名列表
}

/**
 * 记忆宫殿完整数据结构
 */
export interface MemoryPalaceStructure {
  categories: MemoryPalaceCategory[];
}

