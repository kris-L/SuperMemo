/**
 * 数字桩数据模型
 * 用于存储数字-编码-图片的关联关系
 */
export class NumberPeg {
  id?: number; // 主键ID
  number: number; // 数字（0-109）
  code: string; // 编码（如：铃、衣、耳等）
  imageName: string; // 图片资源名称（如：images0.jpg）
  remark?: string; // 备注
  isCustom: boolean = false; // 是否为用户自定义数据（false表示默认数据，true表示用户导入/修改的数据）
  createTime?: number; // 创建时间
  updateTime?: number; // 更新时间

  constructor(number: number, code: string, imageName: string, isCustom: boolean = false, remark?: string) {
    this.number = number;
    this.code = code;
    this.imageName = imageName;
    this.isCustom = isCustom;
    this.remark = remark;
  }
}

