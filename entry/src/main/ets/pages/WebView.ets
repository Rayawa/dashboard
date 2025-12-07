import { webview } from "@kit.ArkWeb";
import { curves, prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { BusinessError } from '@ohos.base';
import { APP_UA } from "../global_data";
import { Logger } from '../utils/Logger';
import { common } from "@kit.AbilityKit";
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';

@Entry
@Component
export struct WebView {
  @State showTutorial: boolean = false;
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.move(TransitionEdge.TOP))
      .combine(TransitionEffect.scale({ x: 0, y: 1 }))
      .animation({ curve: curves.springMotion(0.7, 0.8), duration:1000})
  @State url: string = 'https://hmos.txit.top/dashboard';//entry
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  private readonly NAV_HEIGHT: number = 82;
  private web_controller: webview.WebviewController = new webview.WebviewController();
  private win: window.Window | null = null;

  async aboutToAppear() {
    //shenjack的UA
    const customUA = webview.WebviewController.getDefaultUserAgent() + " Hm_dashboard";
    webview.WebviewController.setAppCustomUserAgent(customUA);
    this.win = await window.getLastWindow(getContext());
    //UA结束

    //Rayawa的状态栏颜色
    const isDark = this.mode === WebDarkMode.On;
    this.win.setWindowSystemBarProperties({
      statusBarColor: '#00000000',
      statusBarContentColor: isDark ? '#FFFFFF' : '#000000'
    });
    //状态栏颜色结束

    //Rayawa的分享
    if (this.isNoListening()) {
      this.shareListening();
    }
    const uiContext: UIContext = this.getUIContext();
    const context: Context = uiContext.getHostContext() as Context;
    context.eventHub.on('onFocus', () => {
      if (this.isNoListening()) {
        this.shareListening();//启用两种监听
      }
    });
    context.eventHub.on('onBackGround', () => {
      this.onBackGround();
    });

  }
  aboutToDisappear() {
    this.shareDisablingListening();//关闭监听
    const uiContext: UIContext = this.getUIContext();
    const context: Context = uiContext.getHostContext() as Context;
    context.eventHub.off('onFocus');
    context.eventHub.off('onBackGround');
    this.shareDisablingListening();
    harmonyShare.on('knockShare', (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }
  private onBackGround() {
    this.shareDisablingListening();
    harmonyShare.on('knockShare', (sharableTarget: harmonyShare.SharableTarget) => {
      sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
    });
  }

  //回到顶部方法
  @State scrollY: number = 0;
  private scrollToTop() {
    const duration = 500;
    const frames = 60;
    const interval = duration / frames;
    const startY = this.scrollY;
    let frame = 0;
    const timer = setInterval(() => {
      frame++;
      const progress = frame / frames;
      const easing = 1 - Math.pow(1 - progress, 3);
      const newY = startY * (1 - easing);
      this.web_controller.scrollTo(0, newY);
      if (frame >= frames) {
        clearInterval(timer);
        this.web_controller.scrollTo(0, 0);
      }
    }, interval);
  }

  //切换V1V2方法
  @State isT: boolean = true;
  private switchWebVersion(): void {
    const switchVersion = this.isT ? 'S站' : ' T站';
    this.url = this.isT ? 'http://shenjack.top:10003/dashboard' : 'https://hmos.txit.top/dashboard';
    this.isT = !this.isT;
    this.web_controller.loadUrl(this.url);
    prompt.showToast({ message: `切换至${switchVersion}`, duration: 500 });
  }

  //开启关闭监听方法
  private shareListening() {
    if (this.isNoListening()) {
      harmonyShare.on('knockShare', this.purityCallback);
      harmonyShare.on('gesturesShare', this.immersiveCallback);
      this.ShareStatus = true;
    } else {
      try {
        const uiContext: UIContext = this.getUIContext();
        uiContext.getPromptAction().showToast({ message: 'Disable other knock events.' });
      } catch (error) {
        Logger.error(`showToast error. Code: ${error?.code}, message: ${error?.message}`);
      }
    }
  }
  private shareDisablingListening() {
    harmonyShare.off('knockShare', this.purityCallback);
    harmonyShare.off('gesturesShare', this.immersiveCallback);
    this.ShareStatus = false;
  }

  //监听状态控制
  @State ShareStatus: boolean = false;//监听状态控制
  @State rejectStatus: boolean = false;//监听状态控制
  @State updateStatus: boolean = false;//监听状态控制
  private isNoListening() {
    return !this.ShareStatus && !this.rejectStatus && !this.updateStatus;
  }

  //获得页面URL
  @State currentUrl: string = '';//分享URL注册
  public async getCurrentWebUrl(): Promise<string> {
    try {
      return this.web_controller.getUrl();
    } catch (err) {
      Logger.error('WebView', '获取 WebView URL 失败: ' + (err as BusinessError).message);
      return '';
    }
  }

  //按钮分享URL方法
  private async shareUrl() {
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    this.currentUrl = await this.getCurrentWebUrl();
    let fileData: Uint8Array | undefined = undefined;
    try {
      fileData = await resourceMgr.getMediaContent($r('app.media.app_icon').id);
    } catch (error) {
      Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
    }
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: `${this.currentUrl}`,
      thumbnail: fileData,
    });
    let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
    const context: common.UIAbilityContext = uiContext.getHostContext() as common.UIAbilityContext;
    controller.show(context, {
      previewMode: systemShare.SharePreviewMode.DEFAULT,
      selectionMode: systemShare.SelectionMode.SINGLE
    }).then(() => {
      Logger.info('ShareController show success.');
    }).catch((error: BusinessError) => {
      Logger.error(`ShareController show error. code: ${error?.code}, message: ${error?.message}`);
    });
  }
  //碰一碰分享方法
  private purityCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
    this.currentUrl = await this.getCurrentWebUrl();
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: this.currentUrl,
    });
    sharableTarget.share(shareData);
  }
  //隔空抓取方法
  private immersiveCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
    this.currentUrl = await this.getCurrentWebUrl();
    let fileData: Uint8Array | undefined = undefined;
    try {
      fileData = await resourceMgr.getMediaContent($r('app.media.app_icon').id);
    } catch (error) {
      Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
    }
    let shareData: systemShare.SharedData = new systemShare.SharedData({
      utd: utd.UniformDataType.HYPERLINK,
      content: `${this.currentUrl}`,
      title: '应用看板链接分享',
      description: this.currentUrl,
      thumbnail: fileData,
    });
    sharableTarget.share(shareData);
  }

  //菜单栏
  @Builder
  Menu() {
    MenuItemGroup() {
      MenuItem({ startIcon: $r('app.media.api'), content: "(dev)API" })
        .onClick(() => { router.pushUrl({ url: 'pages/index' }); prompt.showToast({ message: '原生版本', duration: 500 }); });
      MenuItem({ startIcon: $r('app.media.arrow_back'), content: "返回上级" })
        .onClick(() => { this.web_controller.backward(); prompt.showToast({ message: '返回上级', duration: 500 }); });
      MenuItem({ startIcon: this.isLoading ? $r('app.media.stop') : $r('app.media.refresh'), content: this.isLoading ? "停止刷新" : "刷新页面" })
        .onClick(() => {
          if (this.isLoading) {
            this.web_controller.stop();
            this.isLoading = false;
            prompt.showToast({ message: '停止刷新', duration: 500 });
          } else {
            this.web_controller.refresh();
            this.isLoading = true;
            prompt.showToast({ message: '刷新页面', duration: 500 });
          }
        });
      MenuItem({ startIcon: $r('app.media.arrow_up'), content: "回到顶部" })
        .onClick(() => { this.scrollToTop(); prompt.showToast({ message: '回到顶部', duration: 500 }); });
      MenuItem({ startIcon: $r('app.media.switch'), content: this.isT ? "切换到S版本" : "切换到T版本" })
        .onClick(() => { this.switchWebVersion(); });
      MenuItem({ startIcon: $r('app.media.info'), content: "重新播放教程" })
        .onClick(() => {  this.showTutorial = !this.showTutorial; prompt.showToast({ message: '播放教程', duration: 500 }); });
    }
  }

  build() {
    Stack() {
      if (this.showTutorial) {
        Stack(){
          Column().backgroundColor(Color.Transparent).height('200%').width('200%')
            .onClick(() => { this.showTutorial = !this.showTutorial; })
            .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
            .transition(TransitionEffect.OPACITY.animation({curve :curves.springMotion(0,1), duration:1000}))
          Swiper() {
            // 欢迎页面
            Column() {
              Column() {
                // 主标题
                Text('欢迎来到应用看板')
                  .fontSize(24)
                  .fontWeight(FontWeight.Bold)
                  .margin({ bottom: 16 })
                Scroll(){Column(){
                  // 副标题
                  Text('这个App能帮你做什么？')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 12 })

                  // 主要用途列表
                  Text('本应用收集华为应用市场的公开数据，并将其转化为直观的图表和数据展示给用户。简单来说，您能在这个应用里看到几乎所有鸿蒙应用等情况。\n' +
                    '\n' +
                    '查看应用表现：轻松跟踪任何应用的下载量、评分与日活跃度。通过清晰的折线图、饼图，直观把握数据的变化趋势与生命周期。\n' +
                    '\n' +
                    '分析市场格局：通过总下载榜、评分分布等榜单，快速了解哪些应用最受欢迎，以及用户口碑的整体情况，把握市场风向。\n' +
                    '\n' +
                    '深入研究详情：点击任一应用，即可进入详情页，深度查看其更新记录、开发商信息，并独立分析该应用的下载趋势图。\n' +
                    '\n' +
                    '高效查找与筛选：通过智能搜索，并支持按名称、评分、下载量等多种条件灵活排序，帮助您从海量应用中瞬间定位目标。\n' +
                    '\n' +
                    '获取最新数据：我们的数据后台每30分钟自动更新，确保您看到的下载量、评分等关键指标始终为市场最新状态。\n' +
                    '\n' +
                    '交互与分享：所有图表支持点击交互，便于数据对比。您还可以通过链接、或鸿蒙独特的“碰一碰”功能，轻松将应用页面分享给伙伴。')
                    .fontSize(14)
                    .margin({ bottom: 8 })
                    .textAlign(TextAlign.Start)


                  // 重要提示标题
                  Text('重要提示：')
                    .fontSize(18)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 12 })

                  // 重要提示内容
                  Text('本应用的所有数据均来源于华为应用市场的公开信息。我们致力于提供准确、及时的数据呈现，但无法对数据的原始准确性、完整性和真实性做出绝对保证。所有信息仅供参考，不构成任何决策的唯一依据。')
                    .fontSize(14)
                    .fontColor('#666666')
                    .margin({ bottom: 20 })
                    .textAlign(TextAlign.Start)
                }}
              }
              .width('100%')
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 主界面部分
            Column() {
              Text('主界面部分')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 数据概览 - 显示已爬取总数、应用总数、元服务总数、开发者总数')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 总下载榜 - 展示应用下载量排行榜')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 评分分布 - 显示应用评分的分布情况')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 非华为应用下载榜 - 展示非华为应用和内置应用的下载排行')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选')
                .fontSize(15)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 应用详情页
            Column() {
              Text('应用详情页')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 刷新数据 - 点击“刷新数据”按钮获取最新数据')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 搜索应用 - 支持按名称、包名、开发者等搜索')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 快速筛选 - 点击开发者名称可快速查看其全部应用')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 排序功能 - 按多列（评分、下载量、大小等）排序')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 查看详情 - 点击应用行查看详细信息')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 过滤选项 - 可排除华为/元服务应用')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 分页浏览 - 使用底部分页控件查看更多应用')
                .fontSize(15)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 应用列表与搜索功能
            Column() {
              Text('应用列表与搜索功能')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 部分功能仍在开发中，可能出现数据不完整或bug')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 数据更新可能延迟，请以官方数据为准')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 应用详情页面仍在开发，部分数据可能错误')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 按 ESC 可快速关闭弹窗')
                .fontSize(15)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 菜单栏
            Column() {
              Text('菜单栏')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('如遇到问题或需要技术支持，请联系相关开发人员。')
                .fontSize(15)
                .fontColor($r('app.color.diff_content'))
                .lineHeight(22)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 分享功能
            Column() {
              Text('分享功能')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('如遇到问题或需要技术支持，请联系相关开发人员。')
                .fontSize(15)
                .fontColor($r('app.color.diff_content'))
                .lineHeight(22)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

            // 投稿功能
            Column() {
              Text('投稿功能')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('如遇到问题或需要技术支持，请联系相关开发人员。')
                .fontSize(15)
                .fontColor($r('app.color.diff_content'))
                .lineHeight(22)
            }
            .height('70%')
            .width('95%')
            .borderRadius(16)
            .padding(20)

          }
          .loop(false)
          .effectMode(EdgeEffect.Spring)
          .width('90%')
          .borderRadius(20)
          .backgroundColor($r('app.color.backcolor'))
          .indicator(new DotIndicator()
            .itemWidth(6)
            .itemHeight(6)
            .selectedItemWidth(12)
            .selectedItemHeight(6)
            .color($r('sys.color.comp_background_secondary'))
            .selectedColor($r('sys.color.comp_background_emphasize')))
          .shadow({
            radius: 20,
            color: Color.Gray,
            offsetX: 0,
            offsetY: 4
          })
        }
        .transition(this.effect)
        // .gesture(
        //   SwipeGesture({ direction: SwipeDirection.Vertical })
        //     .onAction((move: GestureEvent|undefined) => {
        //       if(move){
        //         this.showTutorial = !this.showTutorial
        //       }
        //     })
        // )
        .zIndex(2)
        .height('100%')
        .width('100%')

      }
      Column() {
        Column().width('100%').backgroundColor($r('app.color.navcolor')).height(Math.max(this.NAV_HEIGHT - this.scrollY, 0));
        Web({ src: this.url, controller: this.web_controller })
          .domStorageAccess(true)
          .darkMode(this.mode)
          .forceDarkAccess(true)
          .width('100%')
          .backgroundColor($r('app.color.backcolor'))
          .height('100%')
          .onPageBegin(() => this.isLoading = true)
          .onProgressChange((p) => this.progress = p.newProgress)
          .onPageEnd(() => this.isLoading = false)
          .onScroll((e) => this.scrollY = e.yOffset)
          .onControllerAttached(() => { try { this.web_controller.setCustomUserAgent(APP_UA); } catch {} });//shenjack的UA
        Column().width('100%').backgroundColor($r('app.color.backcolor')).height(200);
      }
      Column() {
        Column() {
          Text('\n').fontSize(14);
          Row() {
            Text(this.isT ? "应用看板 - T站" : "应用看板 - S站").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image($r('app.media.share')).height(28).width(28).margin({ right: 30 }).onClick(() => { this.shareUrl(); });
              Image($r('app.media.menu')).height(28).width(28).margin({ right: 30 }).bindMenu(this.Menu);
              Image($r('app.media.user')).height(28).width(28).margin({ right: 25 }).onClick(() => router.pushUrl({ url: 'pages/user' }));
            }
          }
          .width('100%').justifyContent(FlexAlign.SpaceBetween).height(55);
          Rect().width('100%').height(0.5).fill($r('app.color.border')).position({ x: 0, y: 87 });
        }
        .backgroundBlurStyle(BlurStyle.Thin).position({ x: 0, y: 0 }).width('100%');

        if (this.isLoading) {
          Progress({ value: this.progress, total: 100 }).width('100%').height(3).position({ x: 0, y: 87 });
        }
      }
      .position({ x: 0, y: 0 }).zIndex(3).width('100%');
    }
  }
}