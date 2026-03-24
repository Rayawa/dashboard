import { webview } from '@kit.ArkWeb';
import { motion, userStatus } from '@kit.MultimodalAwarenessKit';
import {
  BlurStrategy,
  hdsEffect,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsSnackBar,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarOperationType,
  SnackBarStyleOptions
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, prompt, router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { customUserAgent, EguiBaseURL, SBaseURL, TBaseURL } from '../common/constants';
import { AbilityConstant, common } from '@kit.AbilityKit';
import { harmonyShare } from '@kit.ShareKit';
import { WebShareManager } from '../common/shareControl';
import { preferences } from '@kit.ArkData';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername, } from '../common/profile';
import { tutorial } from '../component/tutorial';
import { SiteMode } from '../common/types';
import {
  getButtonPosition,
  getDefaultSite,
  getHoldCheckEnabled,
  getTabBarAuto,
  getThemeColor,
  getVibrationEnabled,
  initializeSettings
} from '../common/SettingsStorage';

interface SiteConfig {
    key: string;
    url: string;
    label: string;
    icon: Resource;
}

@Entry
@Component
struct Dashboard {
    //控制相关
    @State showButton: boolean = true;
    @State barMargin: number = 28;
    @State lockBar: boolean = false;
    @State buttonOnPageShow: boolean = false;
    private lastOffset: number = 0;
    @State isTabsBarVisible: boolean = true;
    @State showTutorial: boolean = false;
    @State startY: number = 0;
    @State isPressed1: boolean = false;
    @State isPressed2: boolean = false;
    @State touchX: number = 0;
    @State touchY: number = 0;
    @State isTouching: boolean = false;
    private controller: HdsTabsController = new HdsTabsController();
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("tabBarAuto") tabBarAuto: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @State holdCheckTMP: boolean = false;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @State isTDev: boolean = false;
    @State themeColor: string = "blue";
    @State siteMode: SiteMode = SiteMode.SSite;

    //Web控制
    @State private sitesList: SiteConfig[] = [
        { key: 'T', url: TBaseURL.toString(), label: 'T站', icon: $r('sys.media.wifi_router_fill') },
        { key: 'Egui', url: EguiBaseURL.toString(), label: 'Egui (开发中)', icon: $r('sys.media.wifi_router_fill') },
        { key: 'S', url: SBaseURL.toString(), label: 'S站', icon: $r('sys.media.wifi_router_fill') },
    ];
    @State private currentIndex: number = 0;
    @LocalStorageProp('migratedUrl') mUrl: string = "";
    @LocalStorageProp('migratedIndex') mIndex: number = 0;
    @State private url: string = Array.from(this.sitesList.values())[0].url;
    @State DashboardHeight: number = 2100;
    @State progress: number = 0;
    scroller: Scroller = new Scroller();
    private web_controller: webview.WebviewController = new webview.WebviewController();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

    //智感握持
    @State WVp: number = 376;
    @State HVp: number = 376;
    @State buttonY: number = 300;
    @State buttonShowX: number = 10;
    @State buttonHideX: number = -25 - 10;
    @State showButtonAnimation: boolean = true;
    holdingHandCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
        if (this.holdCheckON) {
            switch (data) {
                case 1: // 左手握持
                    this.buttonShowX = 10;
                    this.buttonHideX = -45 - 10;
                    break;
                case 2: // 右手握持
                    this.buttonShowX = this.WVp - 45 - 10;
                    this.buttonHideX = this.WVp + 10;
                    break;
                default:
                    break;
            }
        }
    };
    //动画与振动
    private pageEffect: TransitionEffect = TransitionEffect.OPACITY.combine(
        TransitionEffect.move(TransitionEdge.BOTTOM),
    )
        .combine(TransitionEffect.scale({ x: 0, y: 1 }))
        .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });
    private buttonEffect: TransitionEffect = TransitionEffect.asymmetric(
        TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 0, y: 0 }))
            .animation({ curve: curves.springMotion(0.9, 0.5), duration: 500 }),
        TransitionEffect.IDENTITY
    );

    private triggerVibration(): void {
        if (this.vibrationON) {
            vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
                if (err) {
                    console.error(
                        `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
                    );
                    return;
                }
                console.info("Succeed in querying effect");
                if (state) {
                    try {
                        vibrator.startVibration(
                            {
                                type: "preset",
                                effectId: "haptic.effect.hard",
                                count: 1,
                                intensity: 50,
                            },
                            { usage: "touch" },
                            (error: BusinessError) => {
                                if (error) {
                                    console.error(
                                        `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                                    );
                                } else {
                                    console.info("Succeed in starting vibration");
                                }
                            },
                        );
                    } catch (tryError) {
                        console.error(`An unexpected error occurred in try block: ${tryError}`);
                    }
                }
            });
        }
    }


    //==========================页面生命周期部分==========================
    //entry
    private IS_FIRST_LAUNCH_KEY: string = "isFirstLaunch";
    private async checkFirstLaunch(): Promise<void> {
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let prefs = await preferences.getPreferences(context, "myAppSettings");
            let isFirstLaunchValue: preferences.ValueType = await prefs.get(
                this.IS_FIRST_LAUNCH_KEY,
                true,
            );
            let isFirstLaunch: boolean = false;
            if (typeof isFirstLaunchValue === "boolean") {
                isFirstLaunch = isFirstLaunchValue;
            } else if (typeof isFirstLaunchValue === "string") {
                isFirstLaunch = isFirstLaunchValue === "true";
            } else if (typeof isFirstLaunchValue === "number") {
                isFirstLaunch = isFirstLaunchValue === 1;
            }
            if (isFirstLaunch) {
                console.info("Index", "首次启动，显示引导页。");
                this.showTutorial = true;
                await prefs.put(this.IS_FIRST_LAUNCH_KEY, false);
                await prefs.flush();
                console.info("Index", "已更新首次启动标记。");
            } else {
                console.info("Index", "非首次启动，不显示引导页。");
                this.showTutorial = false;
            }
        } catch (err) {
            let error = err as BusinessError;
            console.error("Index", "检查首选项失败: %{public}s", JSON.stringify(error));
        }
    }
    @StorageLink("userName") userName: string = "";
    async loadUserName() {
        initializeUserStorage();
        this.userName = await getUsername();
    }
    async saveUserName() {
        await setUsername(this.userName);
    }
    async resetToDeviceName() {
        await setUsername(undefined);
        await this.loadUserName();
    }
    // 加载所有设置
    private async loadSettings() {
        try {
            this.defaultSiteT = await getDefaultSite();
            this.vibrationON = await getVibrationEnabled();
            this.holdCheckON = await getHoldCheckEnabled();
            this.buttonPositionRIGHT = await getButtonPosition();
            this.tabBarAuto = await getTabBarAuto();
            this.themeColor = await getThemeColor();
            // this.siteTDev = await getTDev();
            if(this.buttonPositionRIGHT){
                this.buttonShowX = this.WVp - 45 - 10;
                this.buttonHideX = this.WVp + 10;
            } else {
                this.buttonShowX = 10;
                this.buttonHideX = -45 - 10;
            }
            if (!this.isContinuation) {
                this.web_controller.loadUrl(this.url);
            } else {
                // 如果是接续，确保控制器加载的是接续的 URL
                this.web_controller.loadUrl(this.mUrl);
            }
        } catch (error) {
            console.error("加载设置失败:", error);
        }
    }
    private shareManager?: WebShareManager;
    private context = getContext(this) as common.UIAbilityContext;
    @State isContinuation: boolean = false;
    async aboutToAppear() {
        this.buttonOnPageShow = false;
        if (this.mUrl) {
            this.isContinuation = true;
            this.currentIndex = this.mIndex;
            this.url = this.mUrl;
            if (this.sitesList[this.mIndex]) {
                this.sitesList[this.mIndex].url = this.mUrl;
            }
        }
        let callback : Callback<userStatus.UserClassification> = (data : userStatus.UserClassification) => {
            console.info('callback succeeded, ageGroup:' + data.ageGroup + ", confidence:" + data.confidence);
        };
        try {
            userStatus.on('userAgeGroupDetected', callback);
            console.info("on succeeded");
        } catch (err) {
            let error = err as BusinessError;
            console.error("Failed on and err code is " + error.code);
        }
        //获取屏幕尺寸
        const displayInfo = display.getDefaultDisplaySync();
        const screenWidthVp = px2vp(displayInfo.width);
        const screenHeightVp = px2vp(displayInfo.height);
        this.WVp = screenWidthVp;
        this.HVp = screenHeightVp;
        initializeSettings();
        await this.loadSettings();
        //UA
        try {
            webview.WebviewController.initializeWebEngine();
            if (deviceInfo.sdkApiVersion > 20) {
                webview.WebviewController.setAppCustomUserAgent(customUserAgent);
            }
        } catch (error) {
            console.error(
                `UserAgent Error, ErrorCode: ${(error as BusinessError).code},  Message: ${(error as BusinessError).message}`,
            );
        }
        //用户名
        this.loadUserName();
        //握持监听
        try {
            motion.on("holdingHandChanged", this.holdingHandCallback);
        } catch (err) {
            const error = err as BusinessError;
            console.error("订阅失败，错误码: " + error.code);
        }

        //分享
        const context = getContext(this) as common.UIAbilityContext;
        this.shareManager = WebShareManager.getInstance(context, this.web_controller);
        this.shareManager.enablePassiveShare();
        this.context.eventHub.on("onFocus", () => {
            this.shareManager?.enablePassiveShare();
        });
        this.context.eventHub.on("onBackGround", () => {
            this.onBackGround();
            this.shareManager?.disablePassiveShare();
        });
    }

    async onPageShow(): Promise<void> {
        this.buttonOnPageShow = false;
        this.checkFirstLaunch();
        this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (result) => {
            console.info('setMissionContinueState ACTIVE result: ', JSON.stringify(result));
        });
        this.buttonPositionRIGHT = await getButtonPosition();
        if(this.buttonPositionRIGHT){
            this.buttonShowX = this.WVp - 45 - 10;
            this.buttonHideX = this.WVp + 10;
        } else {
            this.buttonShowX = 10;
            this.buttonHideX = -45 - 10;
        }
        setTimeout(() => {
            this.buttonOnPageShow = true;
        }, 500);
        console.log("currentusername",this.userName)
        if(!this.showTutorial){
            if(this.userName == '' || this.userName == deviceInfo.productModel){
                console.info("currentusername_pop!!")
                setTimeout(() => {
                    this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
                },3000)
            } else {
                console.info("currentusername_set")
            }
        }
    }

    aboutToDisappear() {
        this.shareManager?.disablePassiveShare();
        const hostContext = this.context;
        hostContext.eventHub.off("onFocus");
        hostContext.eventHub.off("onBackGround");
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
        try {
            motion.off("holdingHandChanged", this.holdingHandCallback);
        } catch (err) {
            const error = err as BusinessError;
            console.error("Motion off failed: " + error.code);
        }
    }

    onBackGround() {
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
    }
    //自定义返回逻辑
    @State firstBackTime: number = 0;
    private waitTime: number = 2000;
    onBackPress(): boolean | void {
        if (this.showTutorial) {
            this.showTutorial = false;
            this.triggerVibration();
            console.info("关闭教程");
            return true;
        }
        if (this.web_controller.accessStep(-1)) {
            console.info("网页可以返回，执行后退");
            this.web_controller.backward();
            this.triggerVibration();
            prompt.showToast({ message: "返回上一页", duration: 1000 });
            return true;
        }
        const currentTime = new Date().getTime();
        if (currentTime - this.firstBackTime > this.waitTime) {
            this.firstBackTime = currentTime;
            prompt.showToast({ message: "再按一次退出应用", duration: this.waitTime });
            this.triggerVibration()
            return true;
        } else {
            return false;
        }
    }


    //==========================主程序部分==========================
    uiContext: UIContext = this.getUIContext();
    hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);
    icon: SnackBarIconOptions = {
        icon: $r('sys.symbol.rename')
    }
    message: SnackBarMessageOptions = {
        title: "您还未设置用户名",
        content: "前往我的页面设置用户名"
    }
    operation: SnackBarOperationOptions = {
        operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
    }
    style: SnackBarStyleOptions = {
        backgroundBlurStyle: BlurStyle.Thin,
        nextFocusId: 'button',
        duration: 7999
    }
    @Builder Web(site: SiteConfig) {
        Stack() {
            if (this.isLoading) {
                Progress({ value: this.progress, total: 100 })
                    .width("100%")
                    .height(90)
                    .position({ y: 5 })
                    .zIndex(99);
            }
            Scroll(this.scroller) {
                Column() {
                    Blank()
                        .height(80)
                        .width("100%")
                        .expandSafeArea(
                            [SafeAreaType.SYSTEM],
                            [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
                        )
                    Web({
                        src: site.url,
                        controller: this.web_controller,
                        renderMode: RenderMode.SYNC_RENDER,
                    })
                        .id(`HmDashboard_${site.key}`)
                        .onControllerAttached(() => {
                            if (this.url !== "") {
                                this.web_controller.loadUrl(this.url);
                            }
                            try {
                                this.web_controller.setCustomUserAgent(customUserAgent);
                            } catch {
                            }
                        })
                        .onPageBegin((event) => {
                            this.isLoading = true;
                            if (event) {
                                AppStorage.setOrCreate('latestWebUrl', event.url);
                            }
                        })
                        .layoutMode(WebLayoutMode.FIT_CONTENT)
                        .nestedScroll({
                            scrollForward: NestedScrollMode.SELF_FIRST,
                            scrollBackward: NestedScrollMode.SELF_FIRST,
                        })
                        .expandSafeArea(
                            [SafeAreaType.SYSTEM],
                            [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
                        )
                        .domStorageAccess(true)
                        .darkMode(this.mode)
                        .forceDarkAccess(true)
                        .width("100%")
                        .backgroundColor($r("app.color.backcolor"))
                        .onProgressChange((p) => (this.progress = p.newProgress))
                        .onPageBegin(() => (this.isLoading = true))
                        .onPageEnd(() => (this.isLoading = false))
                        .metaViewport(true)
                }
            }
            .onWillScroll(() => {
                if (this.tabBarAuto) {
                    const currentOffset = this.scroller.currentOffset().yOffset;
                    if (currentOffset > this.lastOffset && currentOffset > 50) {
                        if (this.isTabsBarVisible && !this.lockBar) {
                            animateTo({ curve: curves.springMotion(0.9, 0.8) }, () => {
                                this.barMargin = -90;
                                this.isTabsBarVisible = false;
                            })
                        }
                    } else if (currentOffset < this.lastOffset) {
                        if (!this.isTabsBarVisible && !this.lockBar) {
                            animateTo({ curve: curves.springMotion(0.36, 0.6) }, () => {
                                this.barMargin = 28;
                                this.isTabsBarVisible = true;
                            })
                        }
                    }
                    this.lastOffset = currentOffset;
                }
            })
        }
    }
    build() {
        HdsNavigation() {
            Stack() {
                //==========================HdsTabs携带web==========================
                HdsTabs({ controller: this.controller }) {
                    ForEach(this.sitesList, (site: SiteConfig) => {
                        TabContent() { this.Web(site) }
                        .tabBar(new BottomTabBarStyle(site.icon, site.label))
                    }, (item: SiteConfig) => item.key + item.url)
                }
                .onChange((index: number) => {
                    this.currentIndex = index;
                    AppStorage.setOrCreate('latestIndex', index);
                    this.scroller.scrollTo({
                        xOffset: 0,
                        yOffset: 0,
                        animation: { duration: 300, curve: Curve.Ease },
                    });
                    this.web_controller.refresh()
                    this.triggerVibration();
                })
                .animation({ curve: curves.springMotion(0.8, 0.8), duration: 400 })
                .blurStrategy(BlurStrategy.ENABLE)
                .barOverlap(true)
                .barPosition(BarPosition.End)
                .vertical(false)
                .onAppear(() => {
                    this.controller.bindScroller(0, this.scroller);
                })
                .barFloatingStyle({
                    barBottomMargin: this.barMargin,
                    lightColor: $r('app.color.light_color'),
                    gradientMask: { maskColor: $r('app.color.mask_color'), maskHeight: 92 },
                    systemMaterialEffect: {
                        materialType: hdsMaterial.MaterialType.IMMERSIVE,
                        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                    }
                })

                // ==========================悬浮按钮==========================
                if(this.buttonOnPageShow){
                    Column({ space: 10 }) {
                        Button() {
                            Image($r("app.media.arrow_up"))
                                .width(24)
                                .height(24)
                        }
                        .onTouch((event: TouchEvent) => {
                            if (event && event.touches[0]) {
                                if (event.type === TouchType.Down || event.type === TouchType.Move) {
                                    this.isPressed1 = true;
                                    this.touchX = event.touches[0].x;
                                    this.touchY = event.touches[0].y;
                                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                    this.isPressed1 = false;
                                }
                            }
                        })
                        .onClick(() => {
                            this.scroller.scrollTo({
                                xOffset: 0,
                                yOffset: 0,
                                animation: { duration: 300, curve: Curve.Ease },
                            });
                            this.triggerVibration();
                            prompt.showToast({
                                message: "回到顶部",
                                duration: 500,
                            });
                        })
                        .type(ButtonType.Circle)
                        .width(45).height(45)
                        .backgroundColor('rgba(255, 255, 255, 0.2)')
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN, { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
                        .linearGradientBlur(60, { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
                        .visualEffect(new hdsEffect.HdsEffectBuilder()
                            .pressShadow(this.isPressed1 ? hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE)
                            .pointLight({
                                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
                                options: {
                                    color: $r('app.color.light_color'),
                                    intensity: this.isPressed1 ? 40.0 : 0.2,
                                    height: 30.0,
                                } as hdsEffect.PointLightOptions
                            })
                            .buildEffect())
                        .border({
                            width: 1,
                            color: $r('app.color.button_border')
                        })
                        .borderRadius(22.5)

                        Button() {
                            Image(this.isLoading ? $r("app.media.stop") : $r("app.media.refresh"))
                                .width(24)
                                .height(24)
                        }
                        .onTouch((event: TouchEvent) => {
                            if (event && event.touches[0]) {
                                if (event.type === TouchType.Down || event.type === TouchType.Move) {
                                    this.isPressed2 = true;
                                    this.touchX = event.touches[0].x;
                                    this.touchY = event.touches[0].y;
                                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                                    this.isPressed2 = false;
                                }
                            }
                        })
                        .onClick(() => {
                            if (this.isLoading) {
                                this.web_controller.stop();
                                this.isLoading = false;
                                this.triggerVibration();
                                prompt.showToast({
                                    message: "已停止加载",
                                    duration: 1000,
                                });
                            } else {
                                this.web_controller.refresh();
                                try {
                                    Promise.all([
                                        this.web_controller.removeCache(true),
                                        this.web_controller.removeCache(false),
                                    ]);
                                } catch (error) {
                                    // man! what can I say
                                    console.warn(`hm dashboard 清除缓存失败 e: ${error}`);
                                }
                                this.isLoading = true;
                                this.triggerVibration();
                                prompt.showToast({
                                    message: "刷新中...",
                                    duration: 1000,
                                });
                                setTimeout(() => {
                                    if (this.isLoading) {
                                        this.isLoading = false;
                                        prompt.showToast({
                                            message: "加载超时！",
                                            duration: 1000,
                                        });
                                    }
                                }, 3000);
                            }
                        })
                        .shadow(ShadowStyle.OUTER_DEFAULT_LG)
                        .type(ButtonType.Circle)
                        .width(45).height(45)
                        .backgroundColor('rgba(255, 255, 255, 0.2)')
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN, { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
                        .linearGradientBlur(60, { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
                        .shadow(ShadowStyle.OUTER_DEFAULT_MD)
                        .visualEffect(new hdsEffect.HdsEffectBuilder()
                            .pressShadow(this.isPressed2 ? hdsEffect.PressShadowType.BLEND_GRADIENT : hdsEffect.PressShadowType.NONE)
                            .pointLight({
                                illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
                                options: {
                                    color: $r('app.color.light_color'),
                                    intensity: this.isPressed2 ? 40.0 : 0.2,
                                    height: 30.0,
                                } as hdsEffect.PointLightOptions
                            })
                            .buildEffect())
                        .border({
                            width: 1,
                            color: $r('app.color.button_border')
                        })
                        .borderRadius(22.5)
                    }
                    .position({
                        x: this.showButton ? this.buttonShowX : this.buttonHideX,
                        y: this.buttonY,
                    })
                    .animation(
                        this.showButtonAnimation
                            ? { curve: curves.springMotion(0.8, 0.8), duration: 400 }
                            : { duration: 0 },
                    )
                    .transition(this.buttonEffect)
                    .gesture(
                        SwipeGesture({ direction: SwipeDirection.Horizontal }).onAction(
                            (move: GestureEvent | undefined) => {
                                if (move) {
                                    this.showButton = false;
                                    setTimeout(() => {
                                        this.showButtonAnimation = false;
                                    }, 300);
                                }
                            },
                        ),
                    )
                    .gesture(
                        PanGesture({ direction: PanDirection.Vertical })
                            .onActionStart(() => {
                                if(this.holdCheckON){ this.holdCheckON = false; this.holdCheckTMP = true; }
                                this.showButtonAnimation = false;
                                this.startY = this.buttonY;
                            })
                            .onActionUpdate((event: GestureEvent) => {
                                //判断实际位置
                                let nextY = this.startY + event.offsetY;
                                if (nextY > 660) {
                                    nextY = 660;
                                } else if (nextY < 70) {
                                    nextY = 70;
                                }
                                this.buttonY = nextY;
                            })
                            .onActionEnd(() => {
                                this.showButtonAnimation = true;
                                if(this.holdCheckTMP){ this.holdCheckON = true; }
                                if (this.buttonY >= 660) {
                                    prompt.showToast({ message: "不能再往下啦", duration: 500 });
                                } else if (this.buttonY <= 70) {
                                    prompt.showToast({ message: "不能再往上啦", duration: 500 });
                                }
                            }),
                    )
                }
                if (!this.showButton) {
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height("100%")
                        .width(15)
                        .zIndex(5)
                        .position({ x: 0 })
                        .onClick(() => {
                            this.showButtonAnimation = true;
                            this.showButton = true;
                            this.triggerVibration();
                        });
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height("100%")
                        .width(15)
                        .zIndex(5)
                        .position({ x: this.WVp - 15 })
                        .onClick(() => {
                            this.showButtonAnimation = true;
                            this.showButton = true;
                            this.triggerVibration();
                        });
                }
                if (this.tabBarAuto && !this.isTabsBarVisible) {
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height(50)
                        .width("100%")
                        .zIndex(5)
                        .position({ y: this.HVp - 50 })
                        .onClick(() => {
                            if (this.lockBar) return;
                            animateTo({ curve: curves.springMotion(0.36, 0.6) }, () => {
                                this.barMargin = 28;
                                this.isTabsBarVisible = true;
                            })
                            this.triggerVibration()
                            this.lockBar = true;
                            setTimeout(() => {
                                this.lockBar = false;
                            }, 1000);
                        });
                }

                //==========================教程==========================
                if (this.showTutorial) {
                    Stack() {
                        Column() {
                            Text("* 点击外部区域或向下滑动关闭页面")
                                .fontSize(14)
                                .margin({ bottom: 10 })
                                .position({ x: "40%", y: "65.3%" })
                                .fontColor(Color.Grey)
                        }
                        .backgroundColor(Color.Transparent)
                        .height("300%")
                        .width("300%")
                        .onClick(() => {
                            this.showTutorial = !this.showTutorial;
                        })
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        tutorial().margin({ top: 120 }).height("95%")
                    }
                    .zIndex(999)
                    .gesture(
                        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(
                            (move: GestureEvent | undefined) => {
                                if (move) {
                                    this.showTutorial = !this.showTutorial;
                                }
                            },
                        ),
                    )
                    .transition(this.pageEffect);
                }
            }
            .width("100%")
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .width("100%")
        .navBarWidth("100%")
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .titleMode(HdsNavigationTitleMode.MODAL)
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background_transparent"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                },
            },
            content: {
                title: {
                    mainTitle: "HmDashboard",
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "share",
                                icon: $r("sys.symbol.share"),
                                isEnabled: true,
                                action: () => {
                                    this.shareManager?.showSystemShare();
                                    this.triggerVibration();
                                },
                            },
                        },
                        {
                            content: {
                                label: "friend",
                                icon: $r("sys.symbol.list_bullet"),
                                isEnabled: true,
                                action: () => {
                                    router.pushUrl({ url: "pages/friend" });
                                    this.triggerVibration();
                                },
                            },
                        },
                        {
                            content: {
                                label: "user",
                                icon: $r("sys.symbol.person"),
                                isEnabled: true,
                                action: () => {
                                    router.pushUrl({ url: "pages/user" });
                                    this.triggerVibration();
                                },
                            },
                        },
                    ],
                },
            },
        });
    }
}