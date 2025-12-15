import { router, promptAction } from '@kit.ArkUI';
import { NumberPegService } from '../utils/NumberPegService';
import { NumberPeg } from '../model/NumberPeg';

type SortMode = '顺序' | '倒序' | '随机';

/**
 * 编码学习页面
 * 显示110数字桩的编号、文字编码和图片，支持自动播放与跳转
 */
@Entry
@Component
struct CodeStudy {
  @State pegs: NumberPeg[] = [];
  @State currentIndex: number = 0;
  @State isPlaying: boolean = false;
  @State sortMode: SortMode = '顺序';
  @State intervalSeconds: number = 0.5;
  @State showSkipDialog: boolean = false;
  @State skipInput: string = '';

  private timer: number | null = null;

  aboutToAppear() {
    this.loadData();
  }

  aboutToDisappear() {
    this.stopPlay();
  }

  async loadData() {
    try {
      const service = NumberPegService.getInstance();
      const all = await service.getAllNumberPegs();
      this.pegs = all;
      this.applySort(true);
    } catch (error) {
      console.error('加载数字桩失败', error);
    }
  }

  getCurrentPeg(): NumberPeg | null {
    if (this.pegs.length === 0) {
      return null;
    }
    const idx = Math.min(Math.max(this.currentIndex, 0), this.pegs.length - 1);
    return this.pegs[idx];
  }

  applySort(resetIndex: boolean = false) {
    if (this.pegs.length === 0) {
      return;
    }
    let sorted: NumberPeg[] = [];
    if (this.sortMode === '顺序') {
      sorted = [...this.pegs].sort((a, b) => a.number - b.number);
    } else if (this.sortMode === '倒序') {
      sorted = [...this.pegs].sort((a, b) => b.number - a.number);
    } else {
      // 随机
      sorted = [...this.pegs];
      for (let i = sorted.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        const tmp = sorted[i];
        sorted[i] = sorted[j];
        sorted[j] = tmp;
      }
    }
    this.pegs = sorted;
    if (resetIndex) {
      this.currentIndex = 0;
    } else {
      this.currentIndex = Math.min(this.currentIndex, this.pegs.length - 1);
    }
  }

  toggleSort() {
    if (this.sortMode === '顺序') {
      this.sortMode = '倒序';
    } else if (this.sortMode === '倒序') {
      this.sortMode = '随机';
    } else {
      this.sortMode = '顺序';
    }
    this.applySort(true);
  }

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

  startPlay() {
    if (this.isPlaying || this.pegs.length === 0) {
      return;
    }
    this.isPlaying = true;
    this.timer = setInterval(() => {
      this.next();
    }, this.intervalSeconds * 1000);
  }

  stopPlay() {
    if (this.timer !== null) {
      clearInterval(this.timer);
      this.timer = null;
    }
    this.isPlaying = false;
  }

  togglePlay() {
    if (this.isPlaying) {
      this.stopPlay();
    } else {
      this.startPlay();
    }
  }

  next() {
    if (this.pegs.length === 0) {
      return;
    }
    this.currentIndex = (this.currentIndex + 1) % this.pegs.length;
  }

  prev() {
    if (this.pegs.length === 0) {
      return;
    }
    this.currentIndex = (this.currentIndex - 1 + this.pegs.length) % this.pegs.length;
  }

  jumpToNumber() {
    const num = parseInt(this.skipInput);
    if (isNaN(num) || num < 0 || num > 109) {
      promptAction.showToast({
        message: '请输入0-109的数字',
        duration: 2000
      });
      return;
    }
    const idx = this.pegs.findIndex(p => p.number === num);
    if (idx !== -1) {
      this.currentIndex = idx;
      this.showSkipDialog = false;
    } else {
      promptAction.showToast({
        message: '未找到该编码',
        duration: 2000
      });
    }
  }

  getIntervalLabel(): string {
    if (this.intervalSeconds === 0.5) {
      return '0.5秒';
    }
    return `${this.intervalSeconds}秒`;
  }

  getImageResource(imageName: string): Resource {
    const service = NumberPegService.getInstance();
    return service.getImageResourceId(imageName);
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

          Text('编码学习')
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

      // 编号与编码（如 1 -> 衣）
      if (this.getCurrentPeg()) {
        Text(`${this.getCurrentPeg()?.number} -> ${this.getCurrentPeg()?.code}`)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .margin({ bottom: 14 })
      } else {
        Text('正在加载数据...')
          .fontSize(16)
          .fontColor('#666666')
          .margin({ bottom: 14 })
      }

      // 图片
      if (this.getCurrentPeg()) {
        Image(this.getImageResource(this.getCurrentPeg()!.imageName))
          .width('80%')
          .height(240)
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .backgroundColor(Color.White)
          .margin({ bottom: 16 })
      } else {
        Text('暂无图片')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 16 })
      }

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

      // 功能按钮：排序 / 时间间隔 / 跳转
      Row() {
        // 排序
        Column() {
          Image($r('app.media.ic_sort'))
            .width(32)
            .height(32)
            .margin({ bottom: 6 })
          Text(`排序：${this.sortMode}`)
            .fontSize(13)
            .fontColor('#333333')
        }
        .width('30%')
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .border({ width: 1, color: '#2196F3' })
        .onClick(() => {
          this.toggleSort();
        })

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
        .width('30%')
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .border({ width: 1, color: '#2196F3' })
        .onClick(() => {
          this.toggleInterval();
        })

        // 跳转
        Column() {
          Image($r('app.media.ic_skip'))
            .width(32)
            .height(32)
            .margin({ bottom: 6 })
          Text('跳转')
            .fontSize(13)
            .fontColor('#333333')
        }
        .width('30%')
        .height(72)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.White)
        .borderRadius(10)
        .border({ width: 1, color: '#2196F3' })
        .onClick(() => {
          this.skipInput = '';
          this.showSkipDialog = true;
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

      // 跳转弹窗
      if (this.showSkipDialog) {
        Column() {
          Column() {
            Text('跳转到指定编号 (0-109)')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .margin({ bottom: 10 })
            TextInput({ placeholder: '输入编号', text: this.skipInput })
              .type(InputType.Number)
              .maxLength(3)
              .width('100%')
              .onChange((val: string) => {
                this.skipInput = val;
              })
              .margin({ bottom: 12 })

          Row() {
            Button('取消')
              .width('45%')
              .height(40)
              .backgroundColor('#9E9E9E')
              .onClick(() => {
                this.showSkipDialog = false;
              })
              .margin({ right: 10 })
            Button('确定')
              .width('45%')
              .height(40)
              .backgroundColor('#2196F3')
              .onClick(() => {
                this.jumpToNumber();
              })
          }
          .justifyContent(FlexAlign.Start)
          }
          .width('80%')
          .padding(16)
          .backgroundColor(Color.White)
          .borderRadius(10)
          .shadow({ radius: 10, color: '#00000020', offsetX: 0, offsetY: 2 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor('#80000000')
        .position({ x: 0, y: 0 })
      }
    }
  }
}


