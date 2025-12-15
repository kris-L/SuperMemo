/**
 * 简单数据项模型
 * 用于存储序号和内容的关联关系（36计、三字经等）
 */
export class SimpleItem {
  number: number; // 序号（从1开始）
  content: string; // 内容

  constructor(number: number, content: string) {
    this.number = number;
    this.content = content;
  }
}

