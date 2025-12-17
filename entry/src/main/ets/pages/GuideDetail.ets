import { router } from '@kit.ArkUI';
import web_webview from '@ohos.web.webview';

/**
 * 学习指南详情页面
 */
@Entry
@Component
struct GuideDetailPage {
  private webviewController: web_webview.WebviewController = new web_webview.WebviewController();
  private htmlFileName: string = '';
  private pageTitle: string = '学习指南';

  aboutToAppear() {
    // 从路由参数获取HTML文件名和标题
    const params = router.getParams() as Record<string, string>;
    this.htmlFileName = params['htmlFile'] || 'brain_memory_one.htm';
    this.pageTitle = params['title'] || '学习指南';
  }

  build() {
    Column() {
      // 顶部栏
      Row() {
        Button() {
          Image($r('sys.media.ohos_ic_back'))
            .width(24)
            .height(24)
        }
        .width(44)
        .height(44)
        .backgroundColor(Color.Transparent)
        .type(ButtonType.Normal)
        .onClick(() => {
          router.back();
        })

        Text(this.pageTitle)
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
      .justifyContent(FlexAlign.SpaceBetween)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(Color.White)

      // Web组件显示HTML内容
      Web({ 
        src: $rawfile(this.htmlFileName), 
        controller: this.webviewController 
      })
      .width('100%')
      .layoutWeight(1)
      .onPageEnd((event) => {
        // 页面加载完成
        console.info(`[GuideDetail] HTML页面加载完成: ${this.htmlFileName}`);
      })
      .onErrorReceive((event) => {
        // 页面加载错误
        console.error(`[GuideDetail] HTML页面加载失败: ${this.htmlFileName}`, event);
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
