import { webview } from "@kit.ArkWeb";
import { userStatus } from '@kit.MultimodalAwarenessKit';
import {
    HdsNavigation,
    HdsNavigationTitleMode,
    ScrollEffectType,
    HdsNavigationAttribute,
} from "@kit.UIDesignKit";
import { curves, LengthMetrics, prompt, router, window, display } from "@kit.ArkUI";
import { motion } from "@kit.MultimodalAwarenessKit";
import { vibrator } from "@kit.SensorServiceKit";
import { BusinessError } from "@kit.BasicServicesKit";
import {
    customUserAgent,
    dashboardURL,
    SBaseURL,
    siteMapping,
    TBaseURL,
    RBaseURL,
    NBaseURL,
    OBaseURL
} from "../common/constants";
import { Logger } from "../utils/Logger";
import { deviceInfo } from "@kit.BasicServicesKit";
import { common } from "@kit.AbilityKit";
import { harmonyShare, systemShare } from "@kit.ShareKit";
import { preferences, uniformTypeDescriptor as utd } from "@kit.ArkData";
import { resourceManager } from "@kit.LocalizationKit";
import {
    getUsername,
    initialize as initializeUserStorage,
    setUsername as setUsername,
} from "../common/profile";
import { tutorial } from "../component/tutorial";
import URL from "../common/url";
import componentUtils from "@ohos.arkui.componentUtils";
import { SiteMode } from "../common/types";
import { hdsEffect } from '@kit.UIDesignKit';
import {
    getButtonPosition,
    getDefaultSite,
    getHoldCheckEnabled,
    getThemeColor,
    getVibrationEnabled,
    initializeSettings,
    getTDev,
} from "../common/SettingsStorage";

@Entry
@Component
struct Dashboard {
    //==========================状态声明部分==========================
    //控制相关
    @State showButton: boolean = true;
    @State buttonOnPageShow: boolean = false;
    @State showTutorial: boolean = false;
    @State isPressed2: boolean = false;
    @State touchX: number = 0;
    @State touchY: number = 0;
    @State isTouching: boolean = false;
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @State currentSite: string = 'T';
    @Builder SiteButton(text: string, siteKey: string, targetUrl: string) {
        Button(text)
            .fontSize(this.currentSite === siteKey ? 20 : 18)
            .fontColor(this.currentSite === siteKey ? $r('app.color.diff_content') : Color.Grey)
            .height(40)
            .backgroundColor(Color.Transparent)
            .onClick(() => {
                this.currentSite = siteKey;
                this.url = targetUrl.toString();
                this.web_controller.loadUrl(this.url);
                this.triggerVibration();
            })
    }
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @State isTDev: boolean = false;
    @State themeColor: string = "blue";

    //智感握持
    @State Vp: number = 376;
    @State buttonX: number = 20;
    @State buttonHeight: number = 0;
    @State showButtonAnimation: boolean = true;
    holdingHandCallback: Callback<motion.HoldingHandStatus> = (data: motion.HoldingHandStatus) => {
        if (this.holdCheckON) {
            switch (data) {
                case 1: // 左手握持
                    this.buttonX = 20;
                    break;
                case 2: // 右手握持
                    this.buttonX = this.Vp - 200 - 5;
                    break;
                default:
                    break;
            }
        }
    };
    //动画与振动
    private effect: TransitionEffect = TransitionEffect.OPACITY.combine(
        TransitionEffect.move(TransitionEdge.BOTTOM),
    )
        .combine(TransitionEffect.scale({ x: 0, y: 1 }))
        .animation({ curve: curves.springMotion(0.7, 0.9), duration: 1000 });
    private effectOnPageShow: TransitionEffect = TransitionEffect.asymmetric(
        TransitionEffect.OPACITY
            .combine(TransitionEffect.scale({ x: 0, y: 0 }))
            .animation({ curve: curves.springMotion(0.5, 0.6)}),
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

    //entry
    @State url: string = "";
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
    // 加载所有设置
    private async loadSettings() {
        try {
            this.defaultSiteT = await getDefaultSite();
            this.vibrationON = await getVibrationEnabled();
            this.holdCheckON = await getHoldCheckEnabled();
            this.buttonPositionRIGHT = await getButtonPosition();
            this.themeColor = await getThemeColor();
            // this.siteTDev = await getTDev();
            if(this.buttonPositionRIGHT){
                this.buttonX = this.Vp - 200 - 5;
            } else {
                this.buttonX = 20;
            }
            this.url = this.defaultSiteT? TBaseURL.toString() : SBaseURL.toString()
            this.web_controller.loadUrl(this.url);
        } catch (error) {
            console.error("加载设置失败:", error);
        }
    }

    //用户名初始化(防止小天才模式）
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

    //Web控制
    @State DashboardHeight: number = 2100;
    @State progress: number = 0;
    scroller: Scroller = new Scroller();
    private web_controller: webview.WebviewController = new webview.WebviewController();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

    //==========================页面生命周期部分==========================

    async aboutToAppear() {
        this.buttonOnPageShow = false;
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
        //获取屏幕右边位置
        const displayInfo = display.getDefaultDisplaySync();
        const screenWidthVp = px2vp(displayInfo.width);
        this.Vp = screenWidthVp;
        const buttonHeight = px2vp(displayInfo.height);
        this.buttonHeight = buttonHeight
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
        if (this.isNoListening()) {
            this.shareListening();
        }
        const uiContext: UIContext = this.getUIContext();
        const context: Context = uiContext.getHostContext() as Context;
        context.eventHub.on("onFocus", () => {
            if (this.isNoListening()) {
                this.shareListening(); //启用两种监听
            }
        });
        context.eventHub.on("onBackGround", () => {
            this.onBackGround();
        });
    }

    async onPageShow(): Promise<void> {
        this.buttonOnPageShow = false;
        // const rect = componentUtils.getRectangleById("Dashboard");
        // const vpHeight = px2vp(rect.size.height);
        // console.log(`px高度: ${rect.size.height}`);
        // console.log(`vp高度: ${vpHeight}`);
        this.checkFirstLaunch();
        this.buttonPositionRIGHT = await getButtonPosition();
        if(this.buttonPositionRIGHT){
            this.buttonX = this.Vp - 200 - 5;
        } else {
            this.buttonX = 20;
        }
        setTimeout(() => {
            this.buttonOnPageShow = true;
        }, 500);
    }

    aboutToDisappear() {
        this.shareDisablingListening(); //关闭监听
        const uiContext: UIContext = this.getUIContext();
        const context: Context = uiContext.getHostContext() as Context;
        context.eventHub.off("onFocus");
        context.eventHub.off("onBackGround");
        this.shareDisablingListening();
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
        //握持监听
        try {
            motion.off("holdingHandChanged", this.holdingHandCallback);
        } catch (err) {
            const error = err as BusinessError;
            console.error("取消订阅失败，错误码: " + error.code);
        }
    }

    private onBackGround() {
        this.shareDisablingListening();
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
    }

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
            return true;
        } else {
            return false;
        }
    }

    //==========================分享部分==========================
    //开启关闭监听方法
    private shareListening() {
        if (this.isNoListening()) {
            harmonyShare.on("knockShare", this.purityCallback);
            harmonyShare.on("gesturesShare", this.immersiveCallback);
            this.ShareStatus = true;
        } else {
            try {
                const uiContext: UIContext = this.getUIContext();
                uiContext.getPromptAction().showToast({ message: "Disable other knock events." });
            } catch (error) {
                Logger.error(`showToast error. Code: ${error?.code}, message: ${error?.message}`);
            }
        }
    }

    private shareDisablingListening() {
        harmonyShare.off("knockShare", this.purityCallback);
        harmonyShare.off("gesturesShare", this.immersiveCallback);
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
    @State currentUrl: string = ""; //分享URL注册

    public async getCurrentWebUrl(): Promise<string> {
        try {
            return this.web_controller.getUrl();
        } catch (err) {
            Logger.error("WebView", "获取 WebView URL 失败: " + (err as BusinessError).message);
            return "";
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
            fileData = await resourceMgr.getMediaContent($r("app.media.app_icon").id);
        } catch (error) {
            Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
        }
        let shareData: systemShare.SharedData = new systemShare.SharedData({
            utd: utd.UniformDataType.HYPERLINK,
            content: `${this.currentUrl}`,
            title: "应用看板链接分享",
            description: `${this.currentUrl}`,
            thumbnail: fileData,
        });
        let controller: systemShare.ShareController = new systemShare.ShareController(shareData);
        const context: common.UIAbilityContext =
            uiContext.getHostContext() as common.UIAbilityContext;
        controller
            .show(context, {
                previewMode: systemShare.SharePreviewMode.DEFAULT,
                selectionMode: systemShare.SelectionMode.SINGLE,
            })
            .then(() => {
                Logger.info("ShareController show success.");
            })
            .catch((error: BusinessError) => {
                Logger.error(
                    `ShareController show error. code: ${error?.code}, message: ${error?.message}`,
                );
            });
    }

    //碰一碰分享方法
    private purityCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
        this.currentUrl = await this.getCurrentWebUrl();
        let shareData: systemShare.SharedData = new systemShare.SharedData({
            utd: utd.UniformDataType.HYPERLINK,
            content: `${this.currentUrl}`,
            title: "应用看板链接分享",
            description: this.currentUrl,
        });
        sharableTarget.share(shareData);
    };
    //隔空抓取方法
    private immersiveCallback = async (sharableTarget: harmonyShare.SharableTarget) => {
        const uiContext: UIContext = this.getUIContext();
        const contextFaker: Context = uiContext.getHostContext() as Context;
        const resourceMgr: resourceManager.ResourceManager = contextFaker.resourceManager;
        this.currentUrl = await this.getCurrentWebUrl();
        let fileData: Uint8Array | undefined = undefined;
        try {
            fileData = await resourceMgr.getMediaContent($r("app.media.app_icon").id);
        } catch (error) {
            Logger.error(`getMediaContent error. Code: ${error?.code}, message: ${error?.message}`);
        }
        let shareData: systemShare.SharedData = new systemShare.SharedData({
            utd: utd.UniformDataType.HYPERLINK,
            content: `${this.currentUrl}`,
            title: "应用看板链接分享",
            description: this.currentUrl,
            thumbnail: fileData,
        });
        sharableTarget.share(shareData);
    };

    //==========================主程序部分==========================
    build() {
        HdsNavigation() {
            Stack() {
                //==========================网页嵌套滚动==========================
                if (this.isLoading) {
                    Progress({ value: this.progress, total: 100 })
                        .width("100%")
                        .height(3)
                        .position({ y: 5 })
                        .zIndex(99);
                }
                Scroll(this.scroller) {
                    Column() {
                        Blank()
                            .height(50)
                            .width("100%")
                            .expandSafeArea(
                                [SafeAreaType.SYSTEM],
                                [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],
                            )
                        Web({
                            src: this.url,
                            controller: this.web_controller,
                            renderMode: RenderMode.SYNC_RENDER,
                        })
                            .id("Dashboard")
                            .onControllerAttached(() => {
                                if (this.url !== "") {
                                    this.web_controller.loadUrl(this.url);
                                }
                                try {
                                    this.web_controller.setCustomUserAgent(customUserAgent);
                                } catch {}
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
                    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                }
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

                // ==========================悬浮按钮==========================
                if(this.buttonOnPageShow){
                    Row({ space: 10 }) {
                        Button() {
                            Image($r("app.media.arrow_up"))
                                .width(22)
                                .height(22)
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
                        .width(45)
                        .height(45)
                        .backgroundColor('rgba(255, 255, 255, 0.1)')
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN,
                            { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
                        .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
                        .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.25)' })
                        .shadow(ShadowStyle.OUTER_DEFAULT_MD)
                        .border({
                            width: 1,
                            color: $r('app.color.border')
                        })
                        .borderRadius(40)

                        Row({ space: 15 }) {
                            this.SiteButton("T站", 'T', TBaseURL.toString())
                            this.SiteButton("S站", 'S', SBaseURL.toString())
                            // this.SiteButton("统计数据", 'R', RBaseURL.toString())
                            // this.SiteButton("OpenStore", 'O', OBaseURL.toString())
                            // this.SiteButton("NEXTStore", 'N', NBaseURL.toString())
                        }.justifyContent(FlexAlign.SpaceEvenly)
                        .height(45)
                        .backgroundColor('rgba(255, 255, 255, 0.1)')
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN,
                            { colorMode: ThemeColorMode.SYSTEM, adaptiveColor: AdaptiveColor.AVERAGE, scale: 1.0 })
                        .linearGradientBlur(60,
                            { fractionStops: [[0, 0], [0.5, 0.8], [1, 0]], direction: GradientDirection.Bottom })
                        .border({ width: 0.5, color: 'rgba(255, 255, 255, 0.25)' })
                        .shadow(ShadowStyle.OUTER_DEFAULT_MD)
                        .border({
                            width: 1,
                            color: $r('app.color.border')
                        })
                        .borderRadius(40)
                    }
                    .position({ x: this.buttonX, y: this.buttonHeight - 120})
                    .animation({ curve: curves.springMotion(0.4, 0.8) })
                    .transition(this.effectOnPageShow)
                    .animation(
                        this.showButtonAnimation
                            ? { curve: curves.springMotion(0.8, 0.8), duration: 400 }
                            : { duration: 0 },
                    )
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
                        tutorial()
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
                    .transition(this.effect);
                }
            }
            .width("100%")
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        .width("100%")
        .navBarWidth("100%")
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
            },
            content: {
                title: {
                    mainTitle: "应用看板",
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "share",
                                icon: $r("app.media.share"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    this.shareUrl();
                                },
                            },
                        },
                        {
                            content: {
                                label: "refresh",
                                icon: this.isLoading
                                    ? $r("app.media.stop")
                                    : $r("app.media.refresh"),
                                isEnabled: true,
                                action: () => {
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
                                        this.isLoading = true;
                                        this.triggerVibration();
                                        prompt.showToast({
                                            message: "刷新中...",
                                            duration: 1000,
                                        });

                                        setTimeout(() => {
                                            if (this.isLoading) {
                                                this.isLoading = false;
                                            }
                                        }, 3000);
                                    }
                                },
                            },
                        },
                        {
                            content: {
                                label: "user",
                                icon: $r("app.media.user"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    router.pushUrl({ url: "pages/user" });
                                },
                            },
                        },
                    ],
                },
            },
        });
    }
}
