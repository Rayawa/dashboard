import { webview } from '@kit.ArkWeb';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';
import { curves, LengthMetrics, prompt, router } from '@kit.ArkUI';
import window from '@ohos.window';
import { motion } from '@kit.MultimodalAwarenessKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { APP_UA, dashboardURL, SBaseURL, TBaseURL } from '../common/constants';
import { Logger } from '../utils/Logger';
import { common } from '@kit.AbilityKit';
import { harmonyShare, systemShare } from '@kit.ShareKit';
import { preferences, uniformTypeDescriptor as utd } from '@kit.ArkData';
import { resourceManager } from '@kit.LocalizationKit';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername } from '../common/profile';
import { tutorial } from '../component/tutorial';
import URL from '../common/url';

@Entry
@Component
struct Dashboard {
    //==========================状态声明部分==========================
    //控制相关
    @State showButton: boolean = true;
    @State showTutorial: boolean = false;
    @State buttonOnFocus: boolean = false;
    // @State isExpand: boolean = false;
    // @State isPrimaryIconChanged: boolean = false;
    // @State primaryHoverTips: string = '展开';

    //切换版本方法
    @State isT: boolean = true;
    private switchWebVersion(): void {
        this.isT = !this.isT;
        const switchVersion = this.isT ? 'T站' : 'S站';
        this.url = (new URL(dashboardURL, this.isT ? TBaseURL : SBaseURL)).toString();
        this.web_controller.loadUrl(this.url);
        prompt.showToast({ message: `切换至${switchVersion}`, duration: 500 });
    }

    //智感握持
    @State y: number = 300;
    @State buttonShowOffsetX: string = '3%';
    @State buttonHideOffsetX: string = '-20%'
    @State showButtonAnimation: boolean = true;
    holdingHandCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
        switch (data) {
            case 1: // 左手握持
                this.buttonShowOffsetX = '3%';
                this.buttonHideOffsetX = '-20%';
                break;
            case 2: // 右手握持
                this.buttonShowOffsetX = '84%';
                this.buttonHideOffsetX = '101%';
                break;
            default:
                break;
        }
    };

    //动画与振动
    private effect: TransitionEffect =
        TransitionEffect.OPACITY
            .combine(TransitionEffect.move(TransitionEdge.BOTTOM))
            .combine(TransitionEffect.scale({ x: 0, y: 1 }))
            .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 })
    private triggerVibration(): void {
        vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
                console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
                return;
            }
            console.info('Succeed in querying effect');
            if (state) {
                try {
                    vibrator.startVibration({
                        type: 'preset',
                        effectId: 'haptic.effect.hard',
                        count: 1,
                        intensity: 50,
                    }, { usage: 'touch' }, (error: BusinessError) => {
                        if (error) {
                            console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
                        } else {
                            console.info('Succeed in starting vibration');
                        }
                    });
                } catch (tryError) {
                    console.error(`An unexpected error occurred in try block: ${tryError}`);
                }
            }
        });
    }

    //entry
    @State url: string = (new URL(dashboardURL, TBaseURL)).toString();
    private win: window.Window | null = null;
    private IS_FIRST_LAUNCH_KEY: string = 'isFirstLaunch';
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

    //用户名初始化(防止小天才模式）
    @StorageLink('userName') userName: string = ''
    async loadUserName() {
        initializeUserStorage()
        this.userName = await getUsername();
    }
    async saveUserName() {
        await setUsername(this.userName);
    }
    async resetToDeviceName() {
        await setUsername(undefined);
        await this.loadUserName()
    }

    //Web控制
    scroller: Scroller = new Scroller();
    private web_controller: webview.WebviewController = new webview.WebviewController();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

    //==========================页面生命周期部分==========================
    async aboutToAppear() {
        this.loadUserName();
        //UA
        const customUA = webview.WebviewController.getDefaultUserAgent() + " Hm_dashboard";
        webview.WebviewController.setAppCustomUserAgent(customUA);
        //UA结束
        //Rayawa的握持监听
        try {
            motion.on('holdingHandChanged', this.holdingHandCallback);
        } catch (err) {
            const error = err as BusinessError;
            console.error("订阅失败，错误码: " + error.code);
        }
        //Rayawa的握持监听结束

        //Rayawa的分享
        if (this.isNoListening()) {
            this.shareListening();
        }
        const uiContext: UIContext = this.getUIContext();
        const context: Context = uiContext.getHostContext() as Context;
        context.eventHub.on('onFocus', () => {
            if (this.isNoListening()) {
                this.shareListening(); //启用两种监听
            }
        });
        context.eventHub.on('onBackGround', () => {
            this.onBackGround();
        });

    }

    async onPageShow(): Promise<void> {
        this.checkFirstLaunch();
        //Rayawa的状态栏颜色
        this.win = await window.getLastWindow(getContext());
        const isDark = this.mode === WebDarkMode.On;
        this.win.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            statusBarContentColor: isDark ? '#FFFFFF' : '#000000'
        });
        //状态栏颜色结束
    }

    aboutToDisappear() {
        this.shareDisablingListening(); //关闭监听
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

    @State firstBackTime: number = 0;
    private waitTime: number = 2000;
    onBackPress(): boolean | void {
        if (this.showTutorial) {
            this.showTutorial = false;
            this.triggerVibration();
            console.info('关闭教程');
            return true;
        }
        if (this.web_controller.accessStep(-1)) {
            console.info('网页可以返回，执行后退');
            this.web_controller.backward();
            this.triggerVibration();
            prompt.showToast({ message: '返回上一页', duration: 1000 });
            return true;
        }
        const currentTime = new Date().getTime();
        if (currentTime - this.firstBackTime > this.waitTime) {
            this.firstBackTime = currentTime;
            prompt.showToast({ message: '再按一次退出应用', duration: this.waitTime });
            return true;
        } else {
            return false;
        }
    }

    //==========================分享部分==========================
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
    @State ShareStatus: boolean = false;
    @State rejectStatus: boolean = false;
    @State updateStatus: boolean = false;
    private isNoListening() {
        return !this.ShareStatus && !this.rejectStatus && !this.updateStatus;
    }

    //获得页面URL
    @State currentUrl: string = ''; //分享URL注册
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

    //==========================主程序部分==========================
    build() {
        HdsNavigation() {
            Stack() {
                //==========================网页嵌套滚动==========================
                Scroll(this.scroller) {
                    Column() {
                        Blank()
                            .height(70)
                            .width('100%')
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        Web({ src: this.url, controller: this.web_controller, renderMode: RenderMode.SYNC_RENDER })
                            .onControllerAttached(() => {
                                try {
                                    console.warn("before useragent:", this.web_controller.getUserAgent())
                                    console.warn("useragent:", APP_UA)
                                    this.web_controller.setCustomUserAgent(`${APP_UA} Mobile`);
                                } catch {
                                }
                            })
                            .layoutMode(WebLayoutMode.FIT_CONTENT)
                            .nestedScroll({
                                scrollForward: NestedScrollMode.SELF_FIRST,
                                scrollBackward: NestedScrollMode.SELF_FIRST
                            })
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            .domStorageAccess(true)
                            .darkMode(this.mode)
                            .forceDarkAccess(true)
                            .width('100%')
                            .backgroundColor($r('app.color.backcolor'))
                            .onPageBegin(() => this.isLoading = true)
                            .onPageEnd(() => this.isLoading = false)
                            .onControllerAttached(() => {
                                try {
                                    this.web_controller.setCustomUserAgent(APP_UA);
                                } catch {
                                }
                            });

                    }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

                // ==========================悬浮按钮==========================
                Column({ space: 10 }) {
                    Button() { Image($r('app.media.arrow_up')).width(24).height(24)}
                    .onClick(() => {
                        this.scroller.scrollTo({
                            xOffset: 0,
                            yOffset: 0,
                            animation: { duration: 300, curve: Curve.Ease }
                        })
                        this.triggerVibration();
                        prompt.showToast({
                            message: '回到顶部',
                            duration: 500
                        });
                    })
                    .type(ButtonType.Circle)
                    .backgroundBlurStyle(BlurStyle.Thin)
                    .backgroundColor($r('app.color.background'))
                    .width(45)
                    .height(45)
                    .shadow({
                        radius: 6,
                        color: Color.Gray,
                        offsetX: 2,
                        offsetY: 4
                    })

                    Button() { Image(this.isLoading ? $r('app.media.stop') : $r('app.media.refresh')).width(24).height(24) }
                    .onClick(() => {
                        if (this.isLoading) {
                            this.web_controller.stop();
                            this.isLoading = false;
                            this.triggerVibration();
                            prompt.showToast({
                                message: '已停止加载',
                                duration: 1000
                            });
                        } else {
                            this.web_controller.refresh();
                            this.isLoading = true;
                            this.triggerVibration();
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
                    .backgroundBlurStyle(BlurStyle.Thin)
                    .backgroundColor($r('app.color.background'))
                    .width(45)
                    .height(45)
                    .shadow({
                        radius: 4,
                        color: Color.Gray,
                        offsetX: 2,
                        offsetY: 4
                    })

                }
                .position({
                    x: this.showButton ? this.buttonShowOffsetX : this.buttonHideOffsetX,
                    y: this.y
                })
                .animation(this.showButtonAnimation ? { curve: curves.springMotion(0.7, 0.8), duration: 500 } : { duration: 0 })
                .gesture(
                    SwipeGesture({ direction: SwipeDirection.Horizontal })
                        .onAction((move: GestureEvent | undefined) => {
                            if (move) {
                                this.showButton = false;
                                setTimeout(() => {
                                    this.showButtonAnimation = false;
                                }, 300);
                            }
                        })
                )
                .gesture(
                    PanGesture({ direction: PanDirection.Vertical })
                        .onActionEnd((event: GestureEvent) => {
                            this.y = this.y + event.offsetY
                            if (this.y > 660) {
                                this.y = 660;
                                prompt.showToast({ message: '不能再往下啦', duration: 500 })
                            } else if (this.y < 70) {
                                this.y = 70;
                                prompt.showToast({ message: '不能再往上啦', duration: 500 })
                            }
                            console.log('平移中，垂直偏移量 y 为:', this.y);
                        })
                )
                if (!this.showButton) {
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height('100%')
                        .width(15)
                        .zIndex(5)
                        .position({ x: '0%' })
                        .onClick(() => {
                            this.showButtonAnimation = true;
                            this.showButton = true;
                            this.triggerVibration();
                        })
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height('100%')
                        .width(15)
                        .zIndex(5)
                        .position({ x: '96%' })
                        .onClick(() => {
                            this.showButtonAnimation = true;
                            this.showButton = true;
                            this.triggerVibration();
                        })
                }

                //==========================教程==========================
                if (this.showTutorial) {
                    Stack() {
                        Column() {
                            Text('* 点击外部区域或向下滑动关闭页面')
                                .fontSize(14)
                                .margin({ bottom: 10 })
                                .position({ x: '40%', y: '65.3%' })
                                .fontColor(Color.Grey)
                        }
                        .backgroundColor(Color.Transparent)
                        .height('300%')
                        .width('300%')
                        .onClick(() => {
                            this.showTutorial = !this.showTutorial;
                        })
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .transition(TransitionEffect.OPACITY.animation({
                            curve: curves.springMotion(0, 1),
                            duration: 1000
                        }))

                        tutorial()
                    }
                    .zIndex(999)
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
            .width('100%')
            .backgroundColor($r('app.color.backcolor'))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .width('100%')
        .navBarWidth('100%')
        .titleMode(HdsNavigationTitleMode.MODAL)
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20)
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                            subTitleColor: $r('sys.color.font_secondary')
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        },
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        }
                    }
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                            subTitleColor: $r('sys.color.font_secondary')
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        },
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        }
                    }
                }
            },
            content: {
                title: {
                    mainTitle: this.isT ? '应用看板 - T站' : '应用看板 - S站',
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: 'share',
                                icon: $r('app.media.share'),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    this.shareUrl();
                                },
                            }
                        },
                        {
                            content: {
                                label: 'switch',
                                icon: $r('app.media.switch'),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    this.switchWebVersion();
                                },
                            }
                        },
                        {
                            content: {
                                label: 'user',
                                icon: $r('app.media.user'),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    router.pushUrl({ url: 'pages/user' })
                                },
                            }
                        },
                    ]
                },
            }
        })
    }
}