import { relationalStore, ValuesBucket } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';
import { NumberPeg } from '../model/NumberPeg';
import { MemoryPalaceData } from '../model/MemoryPalace';

/**
 * 用户统计数据接口
 */
export interface UserStats {
  id?: number;
  username: string;
  avatar?: string;
  points: number;
  trainCount: number;
  trainDuration: number; // 单位：分钟
  lastSignInDate?: number; // 例如 20250101
}

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

/**
 * 今日训练进度数据
 */
export interface DailyTrainingProgress {
  id?: number;
  dateKey: number; // 例如 20250101
  roundsCompleted: number;
  totalRounds: number;
  startTime?: number; // 训练开始时间戳（毫秒）
  elapsedTime?: number; // 已用时间（秒）
}

/**
 * 积分记录数据接口
 */
export interface PointsRecord {
  id?: number;
  dateKey: number; // 例如 20250101，用于判断同一天
  source: string; // 获取方式，如：'每日签到'、'训练完成'等
  points: number; // 获得的积分数
  createTime: number; // 创建时间戳
}

/**
 * 训练记录数据接口
 */
export interface TrainingRecord {
  id?: number;
  gameType: string; // 游戏类型：'看图选数'、'连连看'、'数字记忆'
  duration: number; // 训练时长（秒）
  createTime: number; // 创建时间戳
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

const SQL_CREATE_USER_STATS_TABLE = `
  CREATE TABLE IF NOT EXISTS user_stats (
    id INTEGER PRIMARY KEY,
    username TEXT NOT NULL,
    avatar TEXT,
    points INTEGER NOT NULL DEFAULT 0,
    train_count INTEGER NOT NULL DEFAULT 0,
    train_duration INTEGER NOT NULL DEFAULT 0,
    last_signin_date INTEGER
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

const SQL_CREATE_DAILY_TRAINING_TABLE = `
  CREATE TABLE IF NOT EXISTS daily_training_progress (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_key INTEGER NOT NULL UNIQUE,
    rounds_completed INTEGER NOT NULL DEFAULT 0,
    total_rounds INTEGER NOT NULL DEFAULT 10,
    start_time INTEGER,
    elapsed_time INTEGER NOT NULL DEFAULT 0
  )
`;

const SQL_CREATE_POINTS_RECORD_TABLE = `
  CREATE TABLE IF NOT EXISTS points_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    date_key INTEGER NOT NULL,
    source TEXT NOT NULL,
    points INTEGER NOT NULL,
    create_time INTEGER NOT NULL
  )
`;

const SQL_CREATE_TRAINING_RECORD_TABLE = `
  CREATE TABLE IF NOT EXISTS training_record (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    game_type TEXT NOT NULL,
    duration INTEGER NOT NULL,
    create_time INTEGER NOT NULL
  )
`;

/**
 * 110数字桩考试记录数据接口
 */
export interface NumberPegExamRecord {
  id?: number;
  examDate: number; // 考试日期（例如 20250101）
  examTime: number; // 考试时间戳（毫秒）
  duration: number; // 总时长（秒）
}

const SQL_CREATE_NUMBER_PEG_EXAM_TABLE = `
  CREATE TABLE IF NOT EXISTS number_peg_exam (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    exam_date INTEGER NOT NULL,
    exam_time INTEGER NOT NULL,
    duration INTEGER NOT NULL
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
      await this.rdbStore.executeSql(SQL_CREATE_USER_STATS_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_DAILY_TRAINING_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_POINTS_RECORD_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_TRAINING_RECORD_TABLE);
      await this.rdbStore.executeSql(SQL_CREATE_NUMBER_PEG_EXAM_TABLE);
      
      // 迁移 daily_training_progress 表，添加新字段（如果不存在）
      await this.migrateDailyTrainingTable();
      
      this.isInitialized = true;
      console.info('[DatabaseManager] 数据库初始化成功');
    } catch (err) {
      console.error('[DatabaseManager] 数据库初始化失败: ' + JSON.stringify(err));
      throw new Error('数据库初始化失败: ' + JSON.stringify(err));
    }
  }

  // ==================== 用户统计相关方法 ====================

  /**
   * 获取用户统计数据（如不存在则创建默认数据）
   */
  public async getUserStats(): Promise<UserStats> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('user_stats');
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, [
        'id',
        'username',
        'avatar',
        'points',
        'train_count',
        'train_duration',
        'last_signin_date'
      ]);

      if (resultSet.goToFirstRow()) {
        const idIndex = resultSet.getColumnIndex('id');
        const usernameIndex = resultSet.getColumnIndex('username');
        const avatarIndex = resultSet.getColumnIndex('avatar');
        const pointsIndex = resultSet.getColumnIndex('points');
        const trainCountIndex = resultSet.getColumnIndex('train_count');
        const trainDurationIndex = resultSet.getColumnIndex('train_duration');
        const lastSignInDateIndex = resultSet.getColumnIndex('last_signin_date');

        const stats: UserStats = {
          id: resultSet.getLong(idIndex),
          username: resultSet.getString(usernameIndex),
          avatar: resultSet.getString(avatarIndex) || undefined,
          points: resultSet.getLong(pointsIndex),
          trainCount: resultSet.getLong(trainCountIndex),
          trainDuration: resultSet.getLong(trainDurationIndex),
          lastSignInDate: resultSet.getLong(lastSignInDateIndex)
        };
        resultSet.close();
        return stats;
      }

      resultSet.close();

      // 如果没有数据，创建一条默认记录
      const randomSuffix = Math.floor(1000 + Math.random() * 9000);
      const defaultUsername = `最强大脑${randomSuffix}`;
      const valuesBucket: ValuesBucket = {
        'id': 1,
        'username': defaultUsername,
        'avatar': '',
        'points': 0,
        'train_count': 0,
        'train_duration': 0,
        'last_signin_date': null
      };

      const insertId: number = await this.rdbStore.insert('user_stats', valuesBucket);
      console.info(`[DatabaseManager] 创建默认用户统计数据成功: id=${insertId}`);

      const stats: UserStats = {
        id: insertId,
        username: defaultUsername,
        avatar: undefined,
        points: 0,
        trainCount: 0,
        trainDuration: 0,
        lastSignInDate: undefined
      };
      return stats;
    } catch (err) {
      console.error(`[DatabaseManager] 获取用户统计数据失败: ${JSON.stringify(err)}`);
      throw new Error('获取用户统计数据失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 更新用户统计数据
   */
  public async updateUserStats(stats: UserStats): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    if (!stats.id) {
      throw new Error('用户统计ID不能为空');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'username': stats.username,
        'avatar': stats.avatar || '',
        'points': stats.points,
        'train_count': stats.trainCount,
        'train_duration': stats.trainDuration,
        'last_signin_date': stats.lastSignInDate ?? null
      };

      const predicates = new relationalStore.RdbPredicates('user_stats');
      predicates.equalTo('id', stats.id);

      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      console.info(`[DatabaseManager] 更新用户统计数据成功: id=${stats.id}, rowsAffected=${rowsAffected}`);
      return rowsAffected;
    } catch (err) {
      console.error(`[DatabaseManager] 更新用户统计数据失败: ${JSON.stringify(err)}`);
      throw new Error('更新用户统计数据失败: ' + JSON.stringify(err));
    }
  }

  // ==================== 今日训练进度相关方法 ====================

  /**
   * 迁移 daily_training_progress 表，添加新字段
   */
  private async migrateDailyTrainingTable(): Promise<void> {
    if (!this.rdbStore) {
      return;
    }

    try {
      // 尝试添加 start_time 字段（如果不存在会报错，忽略即可）
      try {
        await this.rdbStore.executeSql('ALTER TABLE daily_training_progress ADD COLUMN start_time INTEGER');
        console.info('[DatabaseManager] 添加 start_time 字段成功');
      } catch (err) {
        // 字段已存在，忽略错误
        console.info('[DatabaseManager] start_time 字段已存在或添加失败（可忽略）');
      }

      // 尝试添加 elapsed_time 字段（如果不存在会报错，忽略即可）
      try {
        await this.rdbStore.executeSql('ALTER TABLE daily_training_progress ADD COLUMN elapsed_time INTEGER NOT NULL DEFAULT 0');
        console.info('[DatabaseManager] 添加 elapsed_time 字段成功');
      } catch (err) {
        // 字段已存在，忽略错误
        console.info('[DatabaseManager] elapsed_time 字段已存在或添加失败（可忽略）');
      }
    } catch (err) {
      console.error(`[DatabaseManager] 迁移 daily_training_progress 表失败: ${JSON.stringify(err)}`);
      // 不抛出错误，避免影响应用启动
    }
  }

  /**
   * 获取当前日期的日期键（格式：yyyyMMdd，例如 20250101）
   */
  public static getTodayDateKey(): number {
    const now = new Date();
    return now.getFullYear() * 10000 + (now.getMonth() + 1) * 100 + now.getDate();
  }

  /**
   * 清理非当天的训练进度数据（保留当天的数据）
   */
  public async cleanupOldTrainingProgress(): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const todayKey = DatabaseManager.getTodayDateKey();
      
      // 删除所有非当天的记录
      const predicates = new relationalStore.RdbPredicates('daily_training_progress');
      predicates.notEqualTo('date_key', todayKey);
      
      const rowsAffected: number = await this.rdbStore.delete(predicates);
      console.info(`[DatabaseManager] 清理旧训练进度数据成功: 删除了${rowsAffected}条非当天记录`);
    } catch (err) {
      console.error(`[DatabaseManager] 清理旧训练进度数据失败: ${JSON.stringify(err)}`);
      // 不抛出错误，避免影响应用启动
    }
  }

  /**
   * 获取某天的今日训练进度（不存在则创建默认记录）
   */
  public async getDailyTrainingProgress(dateKey: number): Promise<DailyTrainingProgress> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('daily_training_progress');
      predicates.equalTo('date_key', dateKey);

      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, [
        'id',
        'date_key',
        'rounds_completed',
        'total_rounds',
        'start_time',
        'elapsed_time'
      ]);

      if (resultSet.goToFirstRow()) {
        const idIndex = resultSet.getColumnIndex('id');
        const dateKeyIndex = resultSet.getColumnIndex('date_key');
        const roundsIndex = resultSet.getColumnIndex('rounds_completed');
        const totalIndex = resultSet.getColumnIndex('total_rounds');
        const startTimeIndex = resultSet.getColumnIndex('start_time');
        const elapsedTimeIndex = resultSet.getColumnIndex('elapsed_time');

        const progress: DailyTrainingProgress = {
          id: resultSet.getLong(idIndex),
          dateKey: resultSet.getLong(dateKeyIndex),
          roundsCompleted: resultSet.getLong(roundsIndex),
          totalRounds: resultSet.getLong(totalIndex),
          startTime: resultSet.isColumnNull(startTimeIndex) ? undefined : resultSet.getLong(startTimeIndex),
          elapsedTime: resultSet.isColumnNull(elapsedTimeIndex) ? 0 : resultSet.getLong(elapsedTimeIndex)
        };
        resultSet.close();
        return progress;
      }

      resultSet.close();

      // 不存在则创建默认记录
      const valuesBucket: ValuesBucket = {
        'date_key': dateKey,
        'rounds_completed': 0,
        'total_rounds': 10,
        'start_time': null,
        'elapsed_time': 0
      };
      const insertId: number = await this.rdbStore.insert('daily_training_progress', valuesBucket);
      console.info(`[DatabaseManager] 创建默认今日训练进度成功: id=${insertId}, dateKey=${dateKey}`);

      const progress: DailyTrainingProgress = {
        id: insertId,
        dateKey,
        roundsCompleted: 0,
        totalRounds: 10,
        startTime: undefined,
        elapsedTime: 0
      };
      return progress;
    } catch (err) {
      console.error(`[DatabaseManager] 获取今日训练进度失败: ${JSON.stringify(err)}`);
      throw new Error('获取今日训练进度失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 更新某天的今日训练轮次进度
   */
  public async updateDailyTrainingProgress(dateKey: number, roundsCompleted: number, totalRounds: number = 10, startTime?: number, elapsedTime?: number): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'rounds_completed': roundsCompleted,
        'total_rounds': totalRounds
      };
      
      if (startTime !== undefined) {
        valuesBucket['start_time'] = startTime;
      }
      if (elapsedTime !== undefined) {
        valuesBucket['elapsed_time'] = elapsedTime;
      }

      const predicates = new relationalStore.RdbPredicates('daily_training_progress');
      predicates.equalTo('date_key', dateKey);

      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      if (rowsAffected === 0) {
        // 记录不存在时插入
        const insertBucket: ValuesBucket = {
          'date_key': dateKey,
          'rounds_completed': roundsCompleted,
          'total_rounds': totalRounds,
          'start_time': startTime || null,
          'elapsed_time': elapsedTime || 0
        };
        await this.rdbStore.insert('daily_training_progress', insertBucket);
      }
      console.info(`[DatabaseManager] 更新今日训练进度成功: dateKey=${dateKey}, rounds=${roundsCompleted}/${totalRounds}`);
    } catch (err) {
      console.error(`[DatabaseManager] 更新今日训练进度失败: ${JSON.stringify(err)}`);
      throw new Error('更新今日训练进度失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 保存今日训练的时间信息（开始时间和已用时间）
   */
  public async saveTrainingTime(dateKey: number, startTime: number, elapsedTime: number): Promise<void> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'start_time': startTime,
        'elapsed_time': elapsedTime
      };

      const predicates = new relationalStore.RdbPredicates('daily_training_progress');
      predicates.equalTo('date_key', dateKey);

      const rowsAffected: number = await this.rdbStore.update(valuesBucket, predicates);
      if (rowsAffected === 0) {
        // 记录不存在时插入
        const insertBucket: ValuesBucket = {
          'date_key': dateKey,
          'rounds_completed': 0,
          'total_rounds': 10,
          'start_time': startTime,
          'elapsed_time': elapsedTime
        };
        await this.rdbStore.insert('daily_training_progress', insertBucket);
      }
      console.info(`[DatabaseManager] 保存训练时间成功: dateKey=${dateKey}, startTime=${startTime}, elapsedTime=${elapsedTime}`);
    } catch (err) {
      console.error(`[DatabaseManager] 保存训练时间失败: ${JSON.stringify(err)}`);
      throw new Error('保存训练时间失败: ' + JSON.stringify(err));
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

  // ==================== 积分记录相关方法 ====================

  /**
   * 插入积分记录
   */
  public async insertPointsRecord(record: PointsRecord): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'date_key': record.dateKey,
        'source': record.source,
        'points': record.points,
        'create_time': record.createTime
      };

      const insertId: number = await this.rdbStore.insert('points_record', valuesBucket);
      console.info(`[DatabaseManager] 插入积分记录成功: source=${record.source}, points=${record.points}, id=${insertId}`);
      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入积分记录失败: ${JSON.stringify(err)}`);
      throw new Error('插入积分记录失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有积分记录（按时间倒序）
   */
  public async getAllPointsRecords(): Promise<PointsRecord[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('points_record');
      predicates.orderByDesc('create_time');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, [
        'id',
        'date_key',
        'source',
        'points',
        'create_time'
      ]);
      
      const records: PointsRecord[] = [];
      const idIndex: number = resultSet.getColumnIndex('id');
      const dateKeyIndex: number = resultSet.getColumnIndex('date_key');
      const sourceIndex: number = resultSet.getColumnIndex('source');
      const pointsIndex: number = resultSet.getColumnIndex('points');
      const createTimeIndex: number = resultSet.getColumnIndex('create_time');
      
      while (resultSet.goToNextRow()) {
        const record: PointsRecord = {
          id: resultSet.getLong(idIndex),
          dateKey: resultSet.getLong(dateKeyIndex),
          source: resultSet.getString(sourceIndex),
          points: resultSet.getLong(pointsIndex),
          createTime: resultSet.getLong(createTimeIndex)
        };
        records.push(record);
      }
      
      resultSet.close();
      return records;
    } catch (err) {
      console.error(`[DatabaseManager] 查询积分记录失败: ${JSON.stringify(err)}`);
      throw new Error('查询积分记录失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 检查指定日期是否已有指定来源的积分记录（用于防止同一天重复签到）
   */
  public async hasPointsRecordByDateAndSource(dateKey: number, source: string): Promise<boolean> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('points_record');
      predicates.equalTo('date_key', dateKey);
      predicates.equalTo('source', source);
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, ['id']);
      const hasRecord: boolean = resultSet.rowCount > 0;
      resultSet.close();
      return hasRecord;
    } catch (err) {
      console.error(`[DatabaseManager] 检查积分记录失败: ${JSON.stringify(err)}`);
      throw new Error('检查积分记录失败: ' + JSON.stringify(err));
    }
  }

  // ==================== 训练记录相关方法 ====================

  /**
   * 插入训练记录并更新用户统计数据
   */
  public async insertTrainingRecord(record: TrainingRecord): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      // 插入训练记录
      const valuesBucket: ValuesBucket = {
        'game_type': record.gameType,
        'duration': record.duration,
        'create_time': record.createTime
      };

      const insertId: number = await this.rdbStore.insert('training_record', valuesBucket);
      console.info(`[DatabaseManager] 插入训练记录成功: gameType=${record.gameType}, duration=${record.duration}, id=${insertId}`);

      // 更新用户统计数据
      const stats = await this.getUserStats();
      stats.trainCount = (stats.trainCount || 0) + 1;
      // 将秒转换为分钟（保留小数），以0.01分钟为单位存储（乘以100）
      // 例如：20秒 = 0.33分钟，存储为33；60秒 = 1.00分钟，存储为100
      // 对于小于0.01分钟的训练，至少记录为1个单位（0.01分钟），避免丢失数据
      const durationMinutes = record.duration / 60; // 转换为分钟（小数）
      const durationInHundredths = Math.max(1, Math.round(durationMinutes * 100)); // 转换为0.01分钟单位，至少为1
      stats.trainDuration = (stats.trainDuration || 0) + durationInHundredths;
      
      await this.updateUserStats(stats);
      console.info(`[DatabaseManager] 更新用户统计数据成功: trainCount=${stats.trainCount}, trainDuration=${stats.trainDuration}`);

      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入训练记录失败: ${JSON.stringify(err)}`);
      throw new Error('插入训练记录失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有训练记录（按时间倒序）
   */
  public async getAllTrainingRecords(): Promise<TrainingRecord[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('training_record');
      predicates.orderByDesc('create_time');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, [
        'id',
        'game_type',
        'duration',
        'create_time'
      ]);
      
      const records: TrainingRecord[] = [];
      const idIndex: number = resultSet.getColumnIndex('id');
      const gameTypeIndex: number = resultSet.getColumnIndex('game_type');
      const durationIndex: number = resultSet.getColumnIndex('duration');
      const createTimeIndex: number = resultSet.getColumnIndex('create_time');
      
      while (resultSet.goToNextRow()) {
        const record: TrainingRecord = {
          id: resultSet.getLong(idIndex),
          gameType: resultSet.getString(gameTypeIndex),
          duration: resultSet.getLong(durationIndex),
          createTime: resultSet.getLong(createTimeIndex)
        };
        records.push(record);
      }
      
      resultSet.close();
      return records;
    } catch (err) {
      console.error(`[DatabaseManager] 查询训练记录失败: ${JSON.stringify(err)}`);
      throw new Error('查询训练记录失败: ' + JSON.stringify(err));
    }
  }

  // ==================== 110数字桩考试记录相关方法 ====================

  /**
   * 插入110数字桩考试记录
   */
  public async insertNumberPegExamRecord(record: NumberPegExamRecord): Promise<number> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const valuesBucket: ValuesBucket = {
        'exam_date': record.examDate,
        'exam_time': record.examTime,
        'duration': record.duration
      };

      const insertId: number = await this.rdbStore.insert('number_peg_exam', valuesBucket);
      console.info(`[DatabaseManager] 插入110数字桩考试记录成功: examDate=${record.examDate}, duration=${record.duration}, id=${insertId}`);
      return insertId;
    } catch (err) {
      console.error(`[DatabaseManager] 插入110数字桩考试记录失败: ${JSON.stringify(err)}`);
      throw new Error('插入110数字桩考试记录失败: ' + JSON.stringify(err));
    }
  }

  /**
   * 查询所有110数字桩考试记录（按时间倒序）
   */
  public async getAllNumberPegExamRecords(): Promise<NumberPegExamRecord[]> {
    if (!this.rdbStore) {
      throw new Error('数据库未初始化');
    }

    try {
      const predicates = new relationalStore.RdbPredicates('number_peg_exam');
      predicates.orderByDesc('exam_time');
      
      const resultSet: relationalStore.ResultSet = await this.rdbStore.query(predicates, [
        'id',
        'exam_date',
        'exam_time',
        'duration'
      ]);
      
      const records: NumberPegExamRecord[] = [];
      const idIndex: number = resultSet.getColumnIndex('id');
      const examDateIndex: number = resultSet.getColumnIndex('exam_date');
      const examTimeIndex: number = resultSet.getColumnIndex('exam_time');
      const durationIndex: number = resultSet.getColumnIndex('duration');
      
      while (resultSet.goToNextRow()) {
        const record: NumberPegExamRecord = {
          id: resultSet.getLong(idIndex),
          examDate: resultSet.getLong(examDateIndex),
          examTime: resultSet.getLong(examTimeIndex),
          duration: resultSet.getLong(durationIndex)
        };
        records.push(record);
      }
      
      resultSet.close();
      return records;
    } catch (err) {
      console.error(`[DatabaseManager] 查询110数字桩考试记录失败: ${JSON.stringify(err)}`);
      throw new Error('查询110数字桩考试记录失败: ' + JSON.stringify(err));
    }
  }
}

