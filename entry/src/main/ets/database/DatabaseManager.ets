import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { NumberPeg } from '../model/NumberPeg';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'SuperMemo.db', // 数据库名称
  securityLevel: relationalStore.SecurityLevel.S1 // 安全级别
};

const SQL_CREATE_TABLE = `
  CREATE TABLE IF NOT EXISTS number_peg (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    number INTEGER NOT NULL UNIQUE,
    code TEXT NOT NULL,
    image_name TEXT NOT NULL,
    remark TEXT,
    is_custom INTEGER NOT NULL DEFAULT 0,
    create_time INTEGER,
    update_time INTEGER,
    UNIQUE(number)
  )
`;

export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private isInitialized: boolean = false;

  private constructor() {
  }

  /**
   * 获取单例实例
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * 初始化数据库
   */
  public async init(context: Context): Promise<void> {
    if (this.isInitialized && this.rdbStore) {
      return;
    }

    try {
      // 获取关系型数据库
      this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
      
      // 创建表
      await this.rdbStore.executeSql(SQL_CREATE_TABLE);
      
      this.isInitialized = true;
      console.info('[DatabaseManager] 数据库初始化成功');
    } catch (err) {
      console.error('[DatabaseManager] 数据库初始化失败: ' + JSON.stringify(err));
      throw new Error('数据库初始化失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 插入数字桩数据
   */
  public async insertNumberPeg(peg: NumberPeg): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'number': peg.number,
        'code': peg.code,
        'image_name': peg.imageName,
        'remark': peg.remark || '',
        'is_custom': peg.isCustom ? 1 : 0,
        'create_time': Date.now(),
        'update_time': Date.now()
      };

      const insertId: number = await this.rdbStore.insert('number_peg', valuesBucket);
      console.info(`[DatabaseManager] 插入数字桩数据成功: number=${peg.number}, id=${insertId}`);
      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('插入数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 批量插入数字桩数据
   */
  public async insertNumberPegs(pegs: NumberPeg[]): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      await this.rdbStore.beginTransaction();
      
      for (const peg of pegs) {
        const valuesBucket: ValuesBucket = {
          'number': peg.number,
          'code': peg.code,
          'image_name': peg.imageName,
          'is_custom': peg.isCustom ? 1 : 0,
          'create_time': Date.now(),
          'update_time': Date.now()
        };
        await this.rdbStore.insert('number_peg', valuesBucket);
      }
      
      await this.rdbStore.commit();
      console.info(`[DatabaseManager] 批量插入数字桩数据成功: 共${pegs.length}条`);
    } catch (err) {
      await this.rdbStore?.rollBack();
      console.error(`[DatabaseManager] 批量插入数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('批量插入数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 更新数字桩数据
   */
  public async updateNumberPeg(peg: NumberPeg): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'code': peg.code,
        'image_name': peg.imageName,
        'remark': peg.remark || '',
        'is_custom': peg.isCustom ? 1 : 0,
        'update_time': Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('number_peg');
      predicates.equalTo('number', peg.number);
      
      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      console.info(`[DatabaseManager] 更新数字桩数据成功: number=${peg.number}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 更新数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('更新数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 根据数字查询数字桩数据
   */
  public async getNumberPegByNumber(number: number): Promise<NumberPeg | null> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('number_peg');
      predicates.equalTo('number', number);
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id', 'number', 'code', 'image_name', 'remark', 'is_custom', 'create_time', 'update_time']);
      
      if (resultSet.goToFirstRow()) {
        const numberIndex: number = resultSet.getColumnIndex('number');
        const codeIndex: number = resultSet.getColumnIndex('code');
        const imageNameIndex: number = resultSet.getColumnIndex('image_name');
        const remarkIndex: number = resultSet.getColumnIndex('remark');
        const isCustomIndex: number = resultSet.getColumnIndex('is_custom');
        const idIndex: number = resultSet.getColumnIndex('id');
        const createTimeIndex: number = resultSet.getColumnIndex('create_time');
        const updateTimeIndex: number = resultSet.getColumnIndex('update_time');
        
        const peg = new NumberPeg(
          Math.floor(resultSet.getDouble(numberIndex)),
          resultSet.getString(codeIndex),
          resultSet.getString(imageNameIndex),
          resultSet.getLong(isCustomIndex) === 1,
          resultSet.getString(remarkIndex) || undefined
        );
        peg.id = resultSet.getLong(idIndex);
        peg.createTime = resultSet.getLong(createTimeIndex);
        peg.updateTime = resultSet.getLong(updateTimeIndex);
        resultSet.close();
        return peg;
      }
      
      resultSet.close();
      return null;
    } catch (err) {
      console.error(`[DatabaseManager] 查询数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('查询数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有数字桩数据
   */
  public async getAllNumberPegs(): Promise<NumberPeg[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('number_peg');
      predicates.orderByAsc('number');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id', 'number', 'code', 'image_name', 'remark', 'is_custom', 'create_time', 'update_time']);
      
      const pegs: NumberPeg[] = [];
      const numberIndex: number = resultSet.getColumnIndex('number');
      const codeIndex: number = resultSet.getColumnIndex('code');
      const imageNameIndex: number = resultSet.getColumnIndex('image_name');
      const remarkIndex: number = resultSet.getColumnIndex('remark');
      const isCustomIndex: number = resultSet.getColumnIndex('is_custom');
      const idIndex: number = resultSet.getColumnIndex('id');
      const createTimeIndex: number = resultSet.getColumnIndex('create_time');
      const updateTimeIndex: number = resultSet.getColumnIndex('update_time');
      
      while (resultSet.goToNextRow()) {
        const peg = new NumberPeg(
          Math.floor(resultSet.getDouble(numberIndex)),
          resultSet.getString(codeIndex),
          resultSet.getString(imageNameIndex),
          resultSet.getLong(isCustomIndex) === 1,
          resultSet.getString(remarkIndex) || undefined
        );
        peg.id = resultSet.getLong(idIndex);
        peg.createTime = resultSet.getLong(createTimeIndex);
        peg.updateTime = resultSet.getLong(updateTimeIndex);
        pegs.push(peg);
      }
      
      resultSet.close();
      return pegs;
    } catch (err) {
      console.error(`[DatabaseManager] 查询所有数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('查询所有数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 检查数据库是否已有数据
   */
  public async hasData(): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('number_peg');
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id']);
      const hasData: boolean = resultSet.rowCount > 0;
      resultSet.close();
      return hasData;
    } catch (err) {
      console.error(`[DatabaseManager] 检查数据失败: ${JSON.stringify(err)}`);
      throw new Error('检查数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 删除数字桩数据
   */
  public async deleteNumberPeg(number: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('number_peg');
      predicates.equalTo('number', number);
      
      const rowsAffected: number = await this.rdbStore.delete(predicates);
      console.info(`[DatabaseManager] 删除数字桩数据成功: number=${number}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 删除数字桩数据失败: ${JSON.stringify(err)}`);
      throw new Error('删除数字桩数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 关闭数据库连接
   */
  public async close(): Promise<void> {
    if (this.rdbStore) {
      await this.rdbStore.close();
      this.rdbStore = null;
      this.isInitialized = false;
      console.info('[DatabaseManager] 数据库连接已关闭');
    }
  }
}

