type FieldType = 'province' | 'capital' | 'abbr';

interface ProvinceInfo {
  province: string;
  capital: string;
  abbr: string;
}

interface SpeedOption {
  label: string;
  interval: number;
}

const PROVINCE_DATA: ProvinceInfo[] = [
  { province: '北京市', capital: '北京市', abbr: '京' },
  { province: '天津市', capital: '天津市', abbr: '津' },
  { province: '上海市', capital: '上海市', abbr: '沪' },
  { province: '重庆市', capital: '重庆市', abbr: '渝' },
  { province: '河北省', capital: '石家庄市', abbr: '冀' },
  { province: '山西省', capital: '太原市', abbr: '晋' },
  { province: '辽宁省', capital: '沈阳市', abbr: '辽' },
  { province: '吉林省', capital: '长春市', abbr: '吉' },
  { province: '黑龙江省', capital: '哈尔滨市', abbr: '黑' },
  { province: '江苏省', capital: '南京市', abbr: '苏' },
  { province: '浙江省', capital: '杭州市', abbr: '浙' },
  { province: '安徽省', capital: '合肥市', abbr: '皖' },
  { province: '福建省', capital: '福州市', abbr: '闽' },
  { province: '江西省', capital: '南昌市', abbr: '赣' },
  { province: '山东省', capital: '济南市', abbr: '鲁' },
  { province: '河南省', capital: '郑州市', abbr: '豫' },
  { province: '湖北省', capital: '武汉市', abbr: '鄂' },
  { province: '湖南省', capital: '长沙市', abbr: '湘' },
  { province: '广东省', capital: '广州市', abbr: '粤' },
  { province: '海南省', capital: '海口市', abbr: '琼' },
  { province: '四川省', capital: '成都市', abbr: '川' },
  { province: '贵州省', capital: '贵阳市', abbr: '黔' },
  { province: '云南省', capital: '昆明市', abbr: '云' },
  { province: '陕西省', capital: "西安市", abbr: '陕' },
  { province: '甘肃省', capital: '兰州市', abbr: '甘' },
  { province: '青海省', capital: '西宁市', abbr: '青' },
  { province: '台湾省', capital: '台北市', abbr: '台' },
  { province: '内蒙古自治区', capital: '呼和浩特市', abbr: '蒙' },
  { province: '广西壮族自治区', capital: '南宁市', abbr: '桂' },
  { province: '西藏自治区', capital: '拉萨市', abbr: '藏' },
  { province: '宁夏回族自治区', capital: '银川市', abbr: '宁' },
  { province: '新疆维吾尔自治区', capital: '乌鲁木齐市', abbr: '新' },
  { province: '香港特别行政区', capital: '香港', abbr: '港' },
  { province: '澳门特别行政区', capital: '澳门', abbr: '澳' }
];

const FIELD_LABELS: Record<FieldType, string> = {
  "province": '省名',
  "capital": '省会',
  "abbr": '简称'
};

@Entry
@Component
struct Index {
  private timerId: number = -1;
  private readonly speedOptions: SpeedOption[] = [
    { label: '节奏一', interval: 1000 },
    { label: '节奏二', interval: 2000 },
    { label: '节奏三', interval: 3000 },
    { label: '节奏四', interval: 4000 }
  ];

  @State speedIndex: number = 0;
  @State isRunning: boolean = false;
  @State showCard: boolean = false;
  @State currentItem: ProvinceInfo = PROVINCE_DATA[0];
  @State currentField: FieldType = 'province';
  @State feedback: string = '点击开始体验超级记忆';
  @State reservedStatus: string = '接口待接入';

  build() {
    Column({ space: 12 }) {
      Text('超级记忆')
        .fontSize(26)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 24 })

      Text('中国34省省名 · 省会 · 简称飞图')
        .fontColor('#888888')
        .fontSize(14)

      this.buildControlPanel()
      this.buildCard()
      this.buildGuessPanel()
      this.buildSpeedSelector()
      this.buildActionButtons()
      this.buildReservedInterface()
    }
    .padding(24)
    .height('100%')
    .backgroundColor('#101820')
  }

  @Builder
  private buildControlPanel() {
    Row({ space: 8 }) {
      Text('当前状态：')
        .fontColor('#AAAAAA')
      Text(this.isRunning ? '记忆飞行中' : '待命')
        .fontColor(this.isRunning ? '#4ADE80' : '#FACC15')

      Blank()

      Text(this.feedback)
        .fontColor('#FFFFFF')
        .fontSize(16)
        .textAlign(TextAlign.End)
        .layoutWeight(1)
    }
  }
  @Builder
  private buildCard() {
    if (!this.showCard) {
      Column() {
        Text('请点击“开始”按钮')
          .fontColor('#CCCCCC')
        Text('飞图将在选择速度后滚动展示')
          .fontColor('#555555')
          .fontSize(12)
      }
      .height(180)
      .width('100%')
      .backgroundColor('#1F2933')
      .borderRadius(16)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)

    }

    Column({ space: 12 }) {
      Text('飞图在脑')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor('#8B5CF6')

      Text(FIELD_LABELS[this.currentField])
        .fontSize(14)
        .fontColor('#7DD3FC')

      Text(this.getCurrentFieldValue())
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
        .textAlign(TextAlign.Center)
        .margin({ top: 12 })

      Text(`${this.currentItem.province} · ${this.currentItem.capital} · ${this.currentItem.abbr}`)
        .fontColor('#94A3B8')
        .fontSize(12)
        .textAlign(TextAlign.Center)
    }
    .height(180)
    .width('100%')
    .backgroundColor('#1F2933')
    .borderRadius(16)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
  @Builder
  private buildGuessPanel() {
    Column({ space: 8 }) {
      Text('判断当前展示内容类型')
        .fontColor('#E5E7EB')

      Row({ space: 8 }) {
        this.buildGuessButton('province')
        this.buildGuessButton('capital')
        this.buildGuessButton('abbr')
      }
    }
  }
  @Builder
  private buildGuessButton(type: FieldType) {
    Button(FIELD_LABELS[type])
      .width('30%')
      .height(44)
      .backgroundColor('#2563EB')
      .fontColor('#FFFFFF')
      .enabled(this.showCard)
      .onClick(() => this.handleGuess(type))
  }
  @Builder
  private buildSpeedSelector() {
    Column({ space: 12 }) {
      Text('飞图速度')
        .fontColor('#E5E7EB')

      Row({ space: 10 }) {
        ForEach(this.speedOptions, (option: SpeedOption, index: number) => {
          Button(option.label)
            .width('22%')
            .height(40)
            .backgroundColor(this.speedIndex === index ? '#10B981' : '#374151')
            .fontColor('#FFFFFF')
            .onClick(() => this.updateSpeed(index))
        })
      }
      Text(`当前间隔：${this.speedOptions[this.speedIndex].interval / 1000} 秒`)
        .fontColor('#9CA3AF')
        .fontSize(12)
    }
  }
  @Builder
  private buildActionButtons() {
    Row({ space: 12 }) {
      Button(this.isRunning ? '暂停' : '开始')
        .layoutWeight(1)
        .height(48)
        .backgroundColor('#F97316')
        .fontColor('#FFFFFF')
        .onClick(() => this.toggleStart())

      Button('返回')
        .layoutWeight(1)
        .height(48)
        .backgroundColor('#4B5563')
        .fontColor('#FFFFFF')
        .onClick(() => this.resetSession())
    }
  }

  @Builder
  private buildReservedInterface() {
    Column({ space: 6 }) {
      Text('预留接口')
        .fontColor('#EAB308')

      Button(this.reservedStatus)
        .height(40)
        .backgroundColor('#334155')
        .fontColor('#F1F5F9')
        .onClick(() => this.handleReservedFeature('future-extension'))
    }
  }

  private toggleStart() {
    if (this.isRunning) {
      this.stopTimer();
      this.isRunning = false;
      this.feedback = '飞图已暂停';
      return;
    }

    this.startSession();
  }

  private startSession() {
    if (!this.showCard) {
      this.showCard = true;
    }
    this.isRunning = true;
    this.feedback = '请判断展示内容';
    this.pickRandomCard();
    this.restartTimer();
  }

  private resetSession() {
    this.stopTimer();
    this.isRunning = false;
    this.showCard = false;
    this.feedback = '已返回，等待新的开始';
  }

  private updateSpeed(index: number) {
    this.speedIndex = index;
    if (this.isRunning) {
      this.restartTimer();
    }
  }

  private pickRandomCard() {
    const randomIndex = Math.floor(Math.random() * PROVINCE_DATA.length);
    this.currentItem = PROVINCE_DATA[randomIndex];

    const fields: FieldType[] = ['province', 'capital', 'abbr'];
    this.currentField = fields[Math.floor(Math.random() * fields.length)];
  }

  private getCurrentFieldValue(): string {
    switch (this.currentField) {
      case 'province':
        return this.currentItem.province;
      case 'capital':
        return this.currentItem.capital;
      default:
        return this.currentItem.abbr;
    }
  }

  private handleGuess(type: FieldType) {
    if (!this.showCard) {
      return;
    }
    const correct = type === this.currentField;
    this.feedback = correct ? '答对啦！继续保持' : `答错了，是${FIELD_LABELS[this.currentField]}`;
  }

  private restartTimer() {
    this.stopTimer();
    this.timerId = setInterval(() => {
      this.pickRandomCard();
    }, this.speedOptions[this.speedIndex].interval);
  }

  private stopTimer() {
    if (this.timerId !== -1) {
      clearInterval(this.timerId);
      this.timerId = -1;
    }
  }

  private handleReservedFeature(feature: string) {
    // 预留接口，可接入排行榜、个性化训练等扩展
    console.info(`Reserved feature trigger: ${feature}`);
    this.reservedStatus = '接口保留中...';
  }

  aboutToDisappear() {
    this.stopTimer();
  }
}