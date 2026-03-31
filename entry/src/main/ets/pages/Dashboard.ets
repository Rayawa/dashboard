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
    SnackBarStyleOptions,
    TitleSize
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { vibration } from '../common/vibration';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { customUserAgent, EguiBaseURL, SBaseURL, TBaseURL } from '../common/constants';
import { AbilityConstant, common } from '@kit.AbilityKit';
import { harmonyShare } from '@kit.ShareKit';
import { WebShareManager } from '../common/shareControl';
import { preferences } from '@kit.ArkData';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername, } from '../common/profile';
import { tutorial } from '../component/tutorial';
import { warn } from '../component/warn';
import {
    getButtonPosition,
    getDefaultSite,
    getHoldCheckEnabled,
    getTabBarAuto,
    getThemeColor,
    getVibrationEnabled,
    initializeSettings
} from '../common/SettingsStorage';
import { blurPopup } from '../component/blurPopup';
import { user } from './user';

interface SiteConfig {
    key: string;
    url: string;
    label: string;
    icon: Resource;
}

@Entry
@Component
struct Dashboard {
    @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
    PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @State navBarWidth: string | number = '100%';

    private toggleSplitMode(isSplit: boolean) {
        animateTo({
            curve: curves.springMotion(0.4, 0.8),
            duration: 400
        }, () => {
            this.navBarWidth = isSplit ? (this.WVp - 390) : '100%';
        })
    }
    //控制相关
    @State showButton: boolean = true;
    @State barMargin: number = 28;
    @State lockBar: boolean = false;
    @State buttonOnPageShow: boolean = false;
    private lastOffset: number = 0;
    @State isTabsBarVisible: boolean = true;
    @State showTutorial: boolean = false;
    @State showWarn: boolean = false;
    @State startY: number = 0;
    @State isPressed1: boolean = false;
    @State isPressed2: boolean = false;
    @State touchX: number = 0;
    @State touchY: number = 0;
    @State isTouching: boolean = false;
    @State isSnackBarShow: boolean = false;
    private controller: HdsTabsController = new HdsTabsController();
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("tabBarAuto") tabBarAuto: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @State holdCheckTMP: boolean = false;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @State isTDev: boolean = false;
    @State themeColor: string = "blue";

    //Web控制
    @State private sitesList: SiteConfig[] = [
        { key: 'T', url: TBaseURL.toString(), label: 'T站', icon: $r('sys.media.wifi_router_fill') },
        { key: 'Egui', url: EguiBaseURL.toString(), label: 'Egui (开发中)', icon: $r('sys.media.wifi_router_fill') },
        { key: 'S', url: SBaseURL.toString(), label: 'S站', icon: $r('sys.media.wifi_router_fill') },
    ];

    @State private url: string = Array.from(this.sitesList.values())[0].url;
    @State DashboardHeight: number = 2100;
    @State progress: number = 0;
    scroller: Scroller = new Scroller();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

    private controller_T: webview.WebviewController = new webview.WebviewController();
    private controller_S: webview.WebviewController = new webview.WebviewController();
    private controller_E: webview.WebviewController = new webview.WebviewController();
    @State private siteIndex: number = 0;

    private getActiveController(): webview.WebviewController {
        if (this.siteIndex === 0) {
            return this.controller_T;
        } else if (this.siteIndex === 1) {
            return this.controller_E;
        } else {
            return this.controller_S;
        }
    }

    private syncShareData() {
        try {
            const activeCtrl = this.getActiveController();
            const currentUrl = activeCtrl.getUrl();
            if (currentUrl && currentUrl !== "about:blank") {
                this.shareManager?.updateShareData(currentUrl);
            }
        } catch (e) {
            console.error("SyncData", "Controller not ready yet");
        }
    }

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
    private buttonEffect: TransitionEffect = TransitionEffect.asymmetric(
        TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 0, y: 0 }))
            .animation({ curve: curves.springMotion(0.9, 0.5), duration: 500 }),
        TransitionEffect.IDENTITY
    );

    private triggerVibration(): void {
        if (this.vibrationON) {
            vibration.dotVibration()
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
                console.info("Index", "首次启动，显示。");
                this.showWarn = true;
                await prefs.put(this.IS_FIRST_LAUNCH_KEY, false);
                await prefs.flush();
                console.info("Index", "已更新首次启动标记。");
            } else {
                console.info("Index", "非首次启动，不显示。");
                this.showWarn = false;
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
        } catch (error) {
            console.error("加载设置失败:", error);
        }
    }
    private shareManager?: WebShareManager;
    private context = getContext(this) as common.UIAbilityContext;
    @State isContinuation: boolean = false;
    async aboutToAppear() {
        this.buttonOnPageShow = false;
        //年龄分级
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
        //初始化设置内容
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
        this.shareManager = WebShareManager.getInstance(context);
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
        console.log("currentUsername",this.userName)
        if(!this.showTutorial){
            if(this.userName == '' || this.userName == deviceInfo.productModel){
                console.info("currentUsername_pop!!")
                setTimeout(() => {
                    this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
                    this.isSnackBarShow = true;
                },3000)
                this.isSnackBarShow = false;
            } else {
                console.info("currentUsername_set")
            }
        }
    }

    aboutToDisappear() {
        this.hdsSnackBar.dismiss();
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
        this.triggerVibration();
        if (this.isSnackBarShow) {
            this.hdsSnackBar.dismiss();
        }
        if (this.showTutorial) {
            this.showTutorial = false;
            console.info("关闭教程");
            return true;
        }
        let activeCtrl = this.getActiveController();
        if (activeCtrl.accessStep(-1)) {
            activeCtrl.backward();
            return true;
        }
        if (this.pageStack.size() > 0) {
            this.pageStack.pop();

            if (this.pageStack.size() === 0) {
                this.toggleSplitMode(false);
            }
            return true;
        }
        const currentTime = new Date().getTime();
        if (currentTime - this.firstBackTime > this.waitTime) {
            this.firstBackTime = currentTime;
            this.PromptAction.showToast({ message: "再按一次退出应用", duration: this.waitTime });
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
    @Builder
    PageMap(name: string) {
        if (name === "UserPage") {
            user({
                onCloseSplit: () => {
                    animateTo({
                        curve: curves.springMotion(0.4, 0.8),
                        duration: 350
                    }, () => {
                        this.navBarWidth= '100%';
                    })
                }
            })
        }
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
                        controller: site.key === 'T' ? this.controller_T :
                            (site.key === 'E' ? this.controller_E : this.controller_S),
                        renderMode: RenderMode.SYNC_RENDER,
                    })
                        .backgroundColor($r("app.color.backcolor"))
                        .id(`HmDashboard_${site.key}`)
                        .onControllerAttached(() => {
                            const currentCtrl = site.key === 'T' ? this.controller_T :
                                (site.key === 'S' ? this.controller_S : this.controller_E);

                            if (this.url !== "") {
                                currentCtrl.loadUrl(this.url);
                            }
                            try {
                                currentCtrl.setCustomUserAgent(customUserAgent);
                            } catch (e) {}
                        })
                        .onPageEnd((event) => {
                            if (event) {
                                const currentCtrl = site.key === 'T' ? this.controller_T :
                                    (site.key === 'S' ? this.controller_S : this.controller_E);
                                const realUrl = currentCtrl.getUrl();
                                this.shareManager?.updateShareData(realUrl);
                            }
                        })
                        .onRefreshAccessedHistory(() => {
                            try {
                                const activeCtrl: webview.WebviewController = this.getActiveController();
                                const realUrl: string = activeCtrl.getUrl();
                                if (this.shareManager !== undefined && this.shareManager !== null) {
                                    this.shareManager.updateShareData(realUrl);
                                }
                            } catch (err) {
                                const error: BusinessError = err as BusinessError;
                                if (error.code === 17100001) {
                                    console.warn('WebviewController not yet attached, skipping URL update.');
                                } else {
                                    console.error(`Webview error: ${error.code} - ${error.message}`);
                                }
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
        HdsNavigation(this.pageStack) {
            Stack() {
                //==========================HdsTabs携带web==========================
                HdsTabs({ controller: this.controller }) {
                    ForEach(this.sitesList, (site: SiteConfig) => {
                        TabContent() { this.Web(site) }
                        .tabBar(new BottomTabBarStyle(site.icon, site.label))
                    }, (item: SiteConfig) => item.key + item.url)
                }
                .onChange((index: number) => {
                    this.triggerVibration();
                    this.siteIndex = index;
                    preferences.getPreferences(this.context, 'myStore').then((pref) => {
                        pref.putSync('defaultSite', index);
                        pref.flush();
                    });
                    this.syncShareData();
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
                            this.PromptAction.showToast({
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
                            const activeCtrl = this.getActiveController();

                            if (this.isLoading) {
                                activeCtrl.stop();
                                this.isLoading = false;
                                this.triggerVibration();
                            } else {
                                activeCtrl.refresh();
                                try {
                                    Promise.all([
                                        activeCtrl.removeCache(true),
                                    activeCtrl.removeCache(false),
                                    ]);
                                } catch (error) {
                                    console.warn(`hm dashboard e: ${error}`);
                                }
                                this.isLoading = true;
                                this.triggerVibration();
                                this.PromptAction.showToast({
                                    message: "刷新中...",
                                    duration: 1000,
                                });
                                setTimeout(() => {
                                    if (this.isLoading) {
                                        this.isLoading = false;
                                        this.PromptAction.showToast({
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
                                    this.PromptAction.showToast({ message: "不能再往下啦", duration: 500 });
                                } else if (this.buttonY <= 70) {
                                    this.PromptAction.showToast({ message: "不能再往上啦", duration: 500 });
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
                    Column()
                        .width('100%')
                        .height('100%')
                        .backgroundColor(Color.Transparent)
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        .onClick(() => {
                            this.showTutorial = false;
                            this.triggerVibration();
                        })
                }
                blurPopup({ isShow: $showTutorial }) { tutorial().margin({ top: 40 }) }

                if (this.showWarn) {
                    Column()
                        .width('100%')
                        .height('100%')
                        .backgroundColor(Color.Transparent)
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        .onClick(() => {
                            this.showWarn = false;
                            this.triggerVibration();
                        })
                }
                blurPopup({ isShow: this.showWarn }) { warn() }
            }
            .width("100%")
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .backgroundColor($r('app.color.backcolor'))
        .mode(NavigationMode.Auto)
        .navBarWidth(this.navBarWidth)
        .navDestination(this.PageMap)
        .width("100%")
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .titleMode(HdsNavigationTitleMode.MINI)
        .hideBackButton(true)
        .divider({ color: $r('app.color.border')  })
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
                    mainTitle: "鸿蒙应用看板",
                    mainTitleSize: TitleSize.TITLE_S,
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "tutorial",
                                icon: $r("sys.symbol.questionmark_circle"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    this.showTutorial = true;
                                },
                            },
                        },
                        {
                            content: {
                                label: "share",
                                icon: $r("sys.symbol.share"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    const activeCtrl = this.getActiveController();
                                    const realUrl = activeCtrl.getUrl();
                                    this.shareManager?.showSystemShare(realUrl);
                                },
                            },
                        },
                        {
                            content: {
                                label: "user",
                                icon: $r("sys.symbol.person"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    let index = this.pageStack.getIndexByName("UserPage");
                                    if (index.length > 0) {
                                        this.pageStack.moveToTop("UserPage");
                                    } else {
                                        this.pageStack.pushPathByName("UserPage", null);
                                        this.toggleSplitMode(true);
                                    }
                                },
                            },
                        },
                    ],
                },
            },
        });

    }
}
