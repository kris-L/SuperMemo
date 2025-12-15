import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { NumberPeg } from '../model/NumberPeg';
import { MemoryPalaceData } from '../model/MemoryPalace';

/**
 * 思维导图数据接口
 */
export interface MindMapData {
  id?: number;
  name: string;
  data: string;
  sourcePalaceId?: number;
  createTime?: number;
  updateTime?: number;
}

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

const SQL_CREATE_MEMORY_PALACE_TABLE = `
  CREATE TABLE IF NOT EXISTS memory_palace (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    data TEXT NOT NULL,
    create_time INTEGER,
    update_time INTEGER
  )
`;

const SQL_CREATE_MIND_MAP_TABLE = `
  CREATE TABLE IF NOT EXISTS mind_map (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    data TEXT NOT NULL,
    source_palace_id INTEGER,
    create_time INTEGER,
    update_time INTEGER
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
      await this.rdbStore.executeSql(SQL_CREATE_MEMORY_PALACE_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_MIND_MAP_TABLE);
      
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

  // ==================== 记忆宫殿相关方法 ====================

  /**
   * 插入记忆宫殿数据
   */
  public async insertMemoryPalace(palace: MemoryPalaceData): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'name': palace.name,
        'data': palace.data,
        'create_time': Date.now(),
        'update_time': Date.now()
      };

      const insertId: number = await this.rdbStore.insert('memory_palace', valuesBucket);
      console.info(`[DatabaseManager] 插入记忆宫殿数据成功: name=${palace.name}, id=${insertId}`);
      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入记忆宫殿数据失败: ${JSON.stringify(err)}`);
      throw new Error('插入记忆宫殿数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有记忆宫殿数据
   */
  public async getAllMemoryPalaces(): Promise<MemoryPalaceData[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('memory_palace');
      predicates.orderByAsc('create_time');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id', 'name', 'data', 'create_time', 'update_time']);
      
      const palaces: MemoryPalaceData[] = [];
      const idIndex: number = resultSet.getColumnIndex('id');
      const nameIndex: number = resultSet.getColumnIndex('name');
      const dataIndex: number = resultSet.getColumnIndex('data');
      const createTimeIndex: number = resultSet.getColumnIndex('create_time');
      const updateTimeIndex: number = resultSet.getColumnIndex('update_time');
      
      while (resultSet.goToNextRow()) {
        const palace = new MemoryPalaceData(
          resultSet.getString(nameIndex),
          resultSet.getString(dataIndex)
        );
        palace.id = resultSet.getLong(idIndex);
        palace.createTime = resultSet.getLong(createTimeIndex);
        palace.updateTime = resultSet.getLong(updateTimeIndex);
        palaces.push(palace);
      }
      
      resultSet.close();
      return palaces;
    } catch (err) {
      console.error(`[DatabaseManager] 查询所有记忆宫殿数据失败: ${JSON.stringify(err)}`);
      throw new Error('查询所有记忆宫殿数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 根据ID删除记忆宫殿数据
   */
  public async deleteMemoryPalace(id: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('memory_palace');
      predicates.equalTo('id', id);
      
      const rowsAffected: number = await this.rdbStore.delete(predicates);
      console.info(`[DatabaseManager] 删除记忆宫殿数据成功: id=${id}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 删除记忆宫殿数据失败: ${JSON.stringify(err)}`);
      throw new Error('删除记忆宫殿数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 检查记忆宫殿表是否已有数据
   */
  public async hasMemoryPalaceData(): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('memory_palace');
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id']);
      const hasData: boolean = resultSet.rowCount > 0;
      resultSet.close();
      return hasData;
    } catch (err) {
      console.error(`[DatabaseManager] 检查记忆宫殿数据失败: ${JSON.stringify(err)}`);
      throw new Error('检查记忆宫殿数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 更新记忆宫殿数据
   */
  public async updateMemoryPalace(palace: MemoryPalaceData): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    if (!palace.id) {
      throw new Error('记忆宫殿ID不能为空');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'name': palace.name,
        'data': palace.data,
        'update_time': Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('memory_palace');
      predicates.equalTo('id', palace.id);
      
      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      console.info(`[DatabaseManager] 更新记忆宫殿数据成功: id=${palace.id}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 更新记忆宫殿数据失败: ${JSON.stringify(err)}`);
      throw new Error('更新记忆宫殿数据失败: ' + JSON.stringify(err));
    }
  }

  // ==================== 思维导图（日常记忆）相关方法 ====================

  /**
   * 插入思维导图数据（从记忆宫殿导入）
   */
  public async insertMindMap(name: string, data: string, sourcePalaceId?: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'name': name,
        'data': data,
        'source_palace_id': sourcePalaceId || null,
        'create_time': Date.now(),
        'update_time': Date.now()
      };

      const insertId: number = await this.rdbStore.insert('mind_map', valuesBucket);
      console.info(`[DatabaseManager] 插入思维导图数据成功: name=${name}, id=${insertId}`);
      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入思维导图数据失败: ${JSON.stringify(err)}`);
      throw new Error('插入思维导图数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有思维导图数据
   */
  public async getAllMindMaps(): Promise<MindMapData[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('mind_map');
      predicates.orderByDesc('create_time');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id', 'name', 'data', 'source_palace_id', 'create_time', 'update_time']);
      
      const mindMaps: MindMapData[] = [];
      const idIndex: number = resultSet.getColumnIndex('id');
      const nameIndex: number = resultSet.getColumnIndex('name');
      const dataIndex: number = resultSet.getColumnIndex('data');
      const sourcePalaceIdIndex: number = resultSet.getColumnIndex('source_palace_id');
      const createTimeIndex: number = resultSet.getColumnIndex('create_time');
      const updateTimeIndex: number = resultSet.getColumnIndex('update_time');
      
      while (resultSet.goToNextRow()) {
        const mindMap: MindMapData = {
          name: resultSet.getString(nameIndex),
          data: resultSet.getString(dataIndex)
        };
        mindMap.id = resultSet.getLong(idIndex);
        const sourcePalaceId = resultSet.getLong(sourcePalaceIdIndex);
        if (sourcePalaceId !== null) {
          mindMap.sourcePalaceId = sourcePalaceId;
        }
        mindMap.createTime = resultSet.getLong(createTimeIndex);
        mindMap.updateTime = resultSet.getLong(updateTimeIndex);
        mindMaps.push(mindMap);
      }
      
      resultSet.close();
      return mindMaps;
    } catch (err) {
      console.error(`[DatabaseManager] 查询所有思维导图数据失败: ${JSON.stringify(err)}`);
      throw new Error('查询所有思维导图数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 根据ID删除思维导图数据
   */
  public async deleteMindMap(id: number): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('mind_map');
      predicates.equalTo('id', id);
      
      const rowsAffected: number = await this.rdbStore.delete(predicates);
      console.info(`[DatabaseManager] 删除思维导图数据成功: id=${id}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 删除思维导图数据失败: ${JSON.stringify(err)}`);
      throw new Error('删除思维导图数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 更新思维导图数据
   */
  public async updateMindMap(id: number, name: string, data: string): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'name': name,
        'data': data,
        'update_time': Date.now()
      };

      const predicates = new relationalStore.RdbPredicates('mind_map');
      predicates.equalTo('id', id);
      
      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      console.info(`[DatabaseManager] 更新思维导图数据成功: id=${id}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 更新思维导图数据失败: ${JSON.stringify(err)}`);
      throw new Error('更新思维导图数据失败: ' + JSON.stringify(err));
    }
  }
}

