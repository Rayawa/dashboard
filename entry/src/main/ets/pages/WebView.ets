import { webview } from "@kit.ArkWeb";
import { HdsActionBar, ActionBarButton, ActionBarStyle } from '@kit.UIDesignKit'
import { curves, prompt, router } from "@kit.ArkUI";
import window from '@ohos.window';
import { motion } from '@kit.MultimodalAwarenessKit';
import { BusinessError } from '@ohos.base';
import { APP_UA } from "../global_data";
import { Logger } from '../utils/Logger';
import { common } from "@kit.AbilityKit";
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { uniformTypeDescriptor as utd } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';
import { preferences } from '@kit.ArkData';
import { tutorial } from '../component/common/tutorial'
import { hdsEffect } from '@kit.UIDesignKit';

@Entry
@Component
export struct WebView {
  @State isExpand: boolean = false;
  @State isPrimaryIconChanged: boolean = false;
  @State primaryHoverTips: ResourceStr = '开始';
  @State actionBarIlluminatedType: hdsEffect.PointLightIlluminatedType = hdsEffect.PointLightIlluminatedType.BORDER;
  @State buttonPressShadow: hdsEffect.PressShadowType = hdsEffect.PressShadowType.NONE;
  @State lightIntensity: number = 8;

  @State showTutorial: boolean = false;
  private IS_FIRST_LAUNCH_KEY: string = 'isFirstLaunch';
  private effect: TransitionEffect =
    TransitionEffect.OPACITY
      .combine(TransitionEffect.move(TransitionEdge.BOTTOM))
      .combine(TransitionEffect.scale({ x: 0, y: 1 }))
      .animation({ curve: curves.springMotion(0.7, 0.8), duration:1000})
  @State url: string = 'https://hmos.txit.top/dashboard';//entry
  @State mode: WebDarkMode = WebDarkMode.Auto;
  @State isLoading: boolean = false;
  @State progress: number = 0;
  private readonly NAV_HEIGHT: number = 82;
  private web_controller: webview.WebviewController = new webview.WebviewController();
  private win: window.Window | null = null;

  @State offsetX: string = '84%';

  holdingHandCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
    switch (data) {
      case 1: // 左手握持
        this.offsetX = '3%';
        break;
      case 2: // 右手握持
        this.offsetX = '84%';
        break;
      default: // 其他状态
        this.offsetX = '84%';
        break;
    }
  };

  async aboutToAppear() {
    //shenjack的UA
    const customUA = webview.WebviewController.getDefaultUserAgent() + " Hm_dashboard";
    webview.WebviewController.setAppCustomUserAgent(customUA);
    this.win = await window.getLastWindow(getContext());
    //UA结束
    //Rayawa的握持监听
    try {
      motion.on('holdingHandChanged', this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("订阅失败，错误码: " + error.code);
    }
    //Rayawa的握持监听结束
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
  onPageShow(): void {
    this.checkFirstLaunch();
  }
  private async checkFirstLaunch(): Promise<void> {
    try {
      let context = getContext(this) as common.UIAbilityContext;
      let prefs = await preferences.getPreferences(context, 'myAppSettings');
      let isFirstLaunchValue: preferences.ValueType = await prefs.get(this.IS_FIRST_LAUNCH_KEY, true);
      let isFirstLaunch: boolean = false;
      if (typeof isFirstLaunchValue === 'boolean') {
        isFirstLaunch = isFirstLaunchValue;
      } else if (typeof isFirstLaunchValue === 'string') {
        isFirstLaunch = isFirstLaunchValue === 'true';
      } else if (typeof isFirstLaunchValue === 'number') {
        isFirstLaunch = isFirstLaunchValue === 1;
      }
      if (isFirstLaunch) {
        console.info('Index', '首次启动，显示引导页。');
        this.showTutorial = true;
        await prefs.put(this.IS_FIRST_LAUNCH_KEY, false);
        await prefs.flush();
        console.info('Index', '已更新首次启动标记。');
      } else {
        console.info('Index', '非首次启动，不显示引导页。');
        this.showTutorial = false;
      }
    } catch (err) {
      let error = err as BusinessError;
      console.error('Index', '检查首选项失败: %{public}s', JSON.stringify(error));
    }
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
    //握持监听
    try {
      motion.off('holdingHandChanged', this.holdingHandCallback);
    } catch (err) {
      const error = err as BusinessError;
      console.error("取消订阅失败，错误码: " + error.code);
    }
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

  //切换版本方法
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

  build() {
    Stack() {
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
      Column({space:10}) {
        Button() {
          Image($r('app.media.arrow_back'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.web_controller.backward();
          prompt.showToast({
            message: '返回上一页',
            duration: 500
          });
        })
        .type(ButtonType.Circle)
        .backgroundColor($r('app.color.background'))
        .width(45)
        .height(45)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .stateEffect(true)

        Button() {
          Image($r('app.media.arrow_up'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.scrollToTop();
          prompt.showToast({
            message: '回到顶部',
            duration: 500
          });
        })
        .type(ButtonType.Circle)
        .backgroundColor($r('app.color.background'))
        .width(45)
        .height(45)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .stateEffect(true)

        Button() {
          Image(this.isLoading ? $r('app.media.stop') : $r('app.media.refresh'))
            .width(24)
            .height(24)
            .fillColor(this.isLoading ? '#ff3b30' : Color.White)
        }
        .onClick(() => {
          if (this.isLoading) {
            this.web_controller.stop();
            this.isLoading = false;
            prompt.showToast({
              message: '已停止加载',
              duration: 1000
            });
          } else {
            this.web_controller.refresh();
            this.isLoading = true;
            prompt.showToast({
              message: '刷新中...',
              duration: 1000
            });

            setTimeout(() => {
              if (this.isLoading) {
                this.isLoading = false;
              }
            }, 3000);
          }
        })
        .type(ButtonType.Circle)
        .backgroundColor($r('app.color.background'))
        .width(45)
        .height(45)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .stateEffect(true)

        Button() {
          Image($r('app.media.switch'))
            .width(24)
            .height(24)
            .fillColor(Color.White)
        }
        .onClick(() => {
          this.switchWebVersion();
        })
        .type(ButtonType.Circle)
        .backgroundColor($r('app.color.background'))
        .width(45)
        .height(45)
        .shadow({
          radius: 4,
          color: '#182431',
          offsetX: 2,
          offsetY: 4
        })
        .stateEffect(true)
        // HdsActionBar({
        //   startButtons: [
        //     new ActionBarButton({
        //       baseIcon: $r('app.media.arrow_back_r'),
        //       hoverTips: '返回上级',
        //       onClick: () => {
        //         this.web_controller.backward();
        //         prompt.showToast({ message: '返回上级', duration: 500 });
        //         // 添加按钮点击效果
        //         this.buttonPressShadow = hdsEffect.PressShadowType.BLEND_GRADIENT;
        //         setTimeout(() => {
        //           this.buttonPressShadow = hdsEffect.PressShadowType.NONE;
        //         }, 300);
        //       }
        //     }),
        //     new ActionBarButton({
        //       baseIcon: this.isLoading ? $r('app.media.stop_r') : $r('app.media.refresh_r'),
        //       hoverTips: this.isLoading ? "停止刷新" : "刷新页面",
        //       onClick: () => {
        //         if (this.isLoading) {
        //           this.web_controller.stop();
        //           this.isLoading = false;
        //           prompt.showToast({ message: '停止刷新', duration: 500 });
        //         } else {
        //           this.web_controller.refresh();
        //           this.isLoading = true;
        //           prompt.showToast({ message: '刷新页面', duration: 500 });
        //         }
        //         this.buttonPressShadow = hdsEffect.PressShadowType.BLEND_GRADIENT;
        //         setTimeout(() => {
        //           this.buttonPressShadow = hdsEffect.PressShadowType.NONE;
        //         }, 300);
        //       }
        //     })
        //   ],
        //   endButtons: [
        //     new ActionBarButton({
        //       baseIcon: $r('app.media.arrow_up_r'),
        //       hoverTips: '回到顶部',
        //       onClick: () => {
        //         this.scrollToTop();
        //         prompt.showToast({ message: '回到顶部', duration: 500 });
        //         this.buttonPressShadow = hdsEffect.PressShadowType.BLEND_GRADIENT;
        //         setTimeout(() => {
        //           this.buttonPressShadow = hdsEffect.PressShadowType.NONE;
        //         }, 300);
        //       }
        //     }),
        //     new ActionBarButton({
        //       baseIcon: $r('app.media.switch_r'),
        //       hoverTips: '切换版本',
        //       onClick: () => {
        //         this.switchWebVersion();
        //         this.buttonPressShadow = hdsEffect.PressShadowType.BLEND_GRADIENT;
        //         setTimeout(() => {
        //           this.buttonPressShadow = hdsEffect.PressShadowType.NONE;
        //         }, 300);
        //       }
        //     })
        //   ],
        //   primaryButton: new ActionBarButton({
        //     baseIcon: $r('app.media.menu_r'),
        //     altIcon: $r('app.media.close_r'),
        //     onClick: () => {
        //       this.isExpand = !this.isExpand;
        //       this.isPrimaryIconChanged = !this.isPrimaryIconChanged;
        //       if (this.isPrimaryIconChanged) {
        //         this.primaryHoverTips = '展开';
        //       } else {
        //         this.primaryHoverTips = '折叠';
        //       }
        //       this.buttonPressShadow = hdsEffect.PressShadowType.BLEND_GRADIENT;
        //       setTimeout(() => {
        //         this.buttonPressShadow = hdsEffect.PressShadowType.NONE;
        //       }, 300);
        //     },
        //     hoverTips: this.primaryHoverTips
        //   }),
        //   actionBarStyle: new ActionBarStyle({
        //     isPrimaryIconChanged: this.isPrimaryIconChanged
        //   }),
        //   isExpand: this.isExpand!!
        // })
        //   .visualEffect(new hdsEffect.HdsEffectBuilder()
        //     .pointLight({
        //       illuminatedType: this.actionBarIlluminatedType,
        //       options: {
        //         color: Color.White,
        //         intensity: this.lightIntensity,
        //         height: 100
        //       }
        //     })
        //     .pressShadow(this.buttonPressShadow)
        //     .buildEffect())
      }.position({x:`${this.offsetX}`,y:'35%'}).animation({curve :curves.springMotion(0.7,0.8), duration:500})
      Column() {
        Column() {
          Text('\n').fontSize(14);
          Row() {
            Text(this.isT ? "应用看板 - T站" : "应用看板 - S站").fontSize(23).fontWeight(FontWeight.Bold).margin({ left: 20 });
            Row() {
              Image($r('app.media.share')).height(28).width(28).margin({ right: 30 }).onClick(() => { this.shareUrl(); });
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
      }.position({ x: 0, y: 0 }).width('100%');
      if (this.showTutorial) {
        Stack(){
          Column(){
            Text('* 点击外部区域或向下滑动关闭页面').fontSize(14).margin({ bottom: 10 }).position({x:'40%',y:'64%'}).fontColor(Color.Grey)
          }.backgroundColor(Color.Transparent).height('300%').width('300%')
          .onClick(() => { this.showTutorial = !this.showTutorial; })
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .transition(TransitionEffect.OPACITY.animation({curve :curves.springMotion(0,1), duration:1000}))
          tutorial()
        }
        .gesture(
          SwipeGesture({ direction: SwipeDirection.Vertical })
            .onAction((move: GestureEvent | undefined) => {
              if (move) {
                this.showTutorial = !this.showTutorial
              }
            })
        ).transition(this.effect)
      }
    }
  }
}