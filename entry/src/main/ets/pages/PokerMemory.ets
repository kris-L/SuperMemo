import { router, promptAction } from '@kit.ArkUI';

/**
 * 扑克记忆页面
 * 显示扑克牌图片，支持自动播放，支持每次显示1-4张扑克牌
 */
@Entry
@Component
struct PokerMemory {
  @State pokerCards: number[] = []; // 扑克牌编号数组（1-52）
  @State currentIndex: number = 0; // 当前显示的起始索引
  @State isPlaying: boolean = false; // 是否正在播放
  @State intervalSeconds: number = 0.5; // 时间间隔（秒）
  @State cardCount: number = 1; // 每次显示的扑克牌张数（1-4）

  private timer: number | null = null;

  aboutToAppear() {
    this.initPokerCards();
  }

  aboutToDisappear() {
    this.stopPlay();
  }

  /**
   * 初始化扑克牌数组（1-52，随机打乱）
   */
  initPokerCards() {
    // 生成1-52的数组
    const cards: number[] = [];
    for (let i = 1; i <= 52; i++) {
      cards.push(i);
    }
    // 随机打乱
    this.pokerCards = this.shuffleArray(cards);
    this.currentIndex = 0;
  }

  /**
   * 打乱数组
   */
  shuffleArray<T>(array: T[]): T[] {
    const arr = [...array];
    for (let i = arr.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      const temp = arr[i];
      arr[i] = arr[j];
      arr[j] = temp;
    }
    return arr;
  }

  /**
   * 获取当前显示的扑克牌编号数组
   */
  getCurrentCards(): number[] {
    const cards: number[] = [];
    for (let i = 0; i < this.cardCount; i++) {
      const index = (this.currentIndex + i) % this.pokerCards.length;
      cards.push(this.pokerCards[index]);
    }
    return cards;
  }

  /**
   * 切换时间间隔
   */
  toggleInterval() {
    const options = [0.5, 1, 2, 3];
    const idx = options.indexOf(this.intervalSeconds);
    const nextIdx = (idx + 1) % options.length;
    this.intervalSeconds = options[nextIdx];
    if (this.isPlaying) {
      this.stopPlay();
      this.startPlay();
    }
  }

  /**
   * 切换每次显示的扑克牌张数
   */
  toggleCardCount() {
    const options = [1, 2, 3, 4];
    const idx = options.indexOf(this.cardCount);
    const nextIdx = (idx + 1) % options.length;
    this.cardCount = options[nextIdx];
  }

  /**
   * 开始播放
   */
  startPlay() {
    if (this.isPlaying || this.pokerCards.length === 0) {
      return;
    }
    this.isPlaying = true;
    this.timer = setInterval(() => {
      this.next();
    }, this.intervalSeconds * 1000);
  }

  /**
   * 停止播放
   */
  stopPlay() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.isPlaying = false;
  }

  /**
   * 切换播放/暂停
   */
  togglePlay() {
    if (this.isPlaying) {
      this.stopPlay();
    } else {
      this.startPlay();
    }
  }

  /**
   * 下一组
   */
  next() {
    if (this.pokerCards.length === 0) {
      return;
    }
    // 每次前进cardCount张
    this.currentIndex = (this.currentIndex + this.cardCount) % this.pokerCards.length;
  }

  /**
   * 上一组
   */
  prev() {
    if (this.pokerCards.length === 0) {
      return;
    }
    // 每次后退cardCount张
    this.currentIndex = (this.currentIndex - this.cardCount + this.pokerCards.length) % this.pokerCards.length;
  }

  /**
   * 获取时间间隔标签
   */
  getIntervalLabel(): string {
    if (this.intervalSeconds === 0.5) {
      return '0.5秒';
    }
    return `${this.intervalSeconds}秒`;
  }

  /**
   * 获取扑克牌图片资源
   */
  getPokerImageResource(cardNumber: number): Resource {
    // 确保编号在1-52范围内
    const num = Math.max(1, Math.min(52, cardNumber));
    // 格式化为两位数字符串
    const numStr = num.toString().padStart(2, '0');
    return $r(`app.media.poker_${numStr}`);
  }

  build() {
    Stack() {
      // 主内容
      Column() {
        // 标题栏
        Row() {
          Button() {
            Image($r('sys.media.ohos_ic_back'))
              .width(24)
              .height(24)
          }
          .width(44)
          .height(44)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            router.back();
          })

          Text('扑克记忆')
            .layoutWeight(1)
            .textAlign(TextAlign.Center)
            .fontSize(20)
            .fontWeight(FontWeight.Medium)

          Blank()
            .width(44)
            .height(44)
        }
        .width('100%')
        .height(56)
        .padding({ left: 12, right: 12 })
        .justifyContent(FlexAlign.Start)
        .alignItems(VerticalAlign.Center)
        .margin({ bottom: 10 })

        // 扑克牌显示区域（叠加显示）
        Scroll() {
          Stack() {
            // 从前往后渲染，后面的牌在上层
            ForEach(this.getCurrentCards(), (cardNumber: number, index: number) => {
              Image(this.getPokerImageResource(cardNumber))
                .width(300)
                .height(420)
                .objectFit(ImageFit.Fill) // 使用Fill填充，不留空白
                .borderRadius(8)
                .position({ 
                  x: index * 100 // 每张牌向右偏移100px（300/3），在前一张的1/3位置开始显示
                })
                .zIndex(index) // 后面的牌在上层
            }, (cardNumber: number, index: number) => `card_${cardNumber}_${index}`)
          }
          .width(300 + (this.cardCount - 1) * 100) // 动态计算宽度：第一张300px + 后续每张偏移100px
          .height(420)
          .alignContent(Alignment.Start) // 左对齐，第一张牌从左边开始
        }
        .scrollable(ScrollDirection.Horizontal) // 横向滚动
        .scrollBar(BarState.Auto) // 自动显示滚动条
        .width('100%')
        .height(420)
        .margin({ bottom: 16 })

        // 播放控制
        Row() {
          Button() {
            Image($r('app.media.ic_previous'))
              .width(28)
              .height(28)
          }
          .width(56)
          .height(56)
          .backgroundColor(Color.Transparent)
          .borderRadius(28)
          .onClick(() => {
            this.prev();
          })

          Button() {
            Image(this.isPlaying ? $r('app.media.ic_pause') : $r('app.media.ic_play'))
              .width(32)
              .height(32)
          }
          .width(56)
          .height(56)
          .backgroundColor(Color.Transparent)
          .borderRadius(28)
          .onClick(() => {
            this.togglePlay();
          })

          Button() {
            Image($r('app.media.ic_next'))
              .width(28)
              .height(28)
          }
          .width(56)
          .height(56)
          .backgroundColor(Color.Transparent)
          .borderRadius(28)
          .onClick(() => {
            this.next();
          })
        }
        .justifyContent(FlexAlign.SpaceAround)
        .width('80%')
        .margin({ bottom: 16 })

        // 功能按钮：时间间隔 / 显示张数
        Row() {
          // 时间间隔
          Column() {
            Image($r('app.media.ic_time_interval'))
              .width(32)
              .height(32)
              .margin({ bottom: 6 })
            Text(`间隔：${this.getIntervalLabel()}`)
              .fontSize(13)
              .fontColor('#333333')
          }
          .width('48%')
          .height(72)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .border({ width: 1, color: '#2196F3' })
          .onClick(() => {
            this.toggleInterval();
          })

          // 显示张数
          Column() {
            Image($r('app.media.ic_code'))
              .width(32)
              .height(32)
              .margin({ bottom: 6 })
            Text(`张数：${this.cardCount}张`)
              .fontSize(13)
              .fontColor('#333333')
          }
          .width('48%')
          .height(72)
          .justifyContent(FlexAlign.Center)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .border({ width: 1, color: '#2196F3' })
          .onClick(() => {
            this.toggleCardCount();
          })
        }
        .width('90%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 24, top: 4 })

        // 返回按钮
        Button('返回')
          .width('70%')
          .height(46)
          .fontSize(16)
          .backgroundColor('#9E9E9E')
          .onClick(() => {
            router.back();
          })
          .margin({ bottom: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 12 })
      .backgroundColor('#F5F5F5')
    }
  }
}

