import { webview } from "@kit.ArkWeb";
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
import { getTDev } from "../common/SettingsStorage";

@Entry
@Component
struct Dashboard {
    //==========================状态声明部分==========================
    //控制相关
    @State showButton: boolean = true;
    @State showTutorial: boolean = false;
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    //切换版本方法
    @State siteMode: SiteMode = SiteMode.SSite;

    private getNextWebVersion() {
        switch (this.siteMode) {
            case SiteMode.SSite:
                return SiteMode.TSite;
            default:
                return SiteMode.SSite;
        }
    }

    private async getWebUrl(): Promise<URL> {
        const isTDev = await getTDev();
        return siteMapping[
            isTDev && this.siteMode == SiteMode.TSite ? SiteMode.TDevSite : this.siteMode
        ];
    }

    private async switchWebVersion(): Promise<void> {
        // const isTDev = await getTDev()
        let next = this.getNextWebVersion();
        const switchVersion = next == SiteMode.SSite ? "S站" : "T站";
        this.siteMode = next;
        this.url = (await this.getWebUrl()).toString();
        this.web_controller.loadUrl(this.url);
        prompt.showToast({ message: `切换至${switchVersion}`, duration: 500 });
    }

    //智感握持
    @State Vp: number = 376;
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
                    this.buttonShowX = this.Vp - 45 - 10;
                    this.buttonHideX = this.Vp + 10;
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
        .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

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
    @State url: string = new URL(dashboardURL, SBaseURL).toString();
    private win: window.Window | null = null;
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
        //获取屏幕右边位置
        const displayInfo = display.getDefaultDisplaySync();
        const screenWidthVp = px2vp(displayInfo.width);
        this.Vp = screenWidthVp;
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
        this.siteMode = this.defaultSiteT ? SiteMode.TSite : SiteMode.SSite;
        //默认站点
        if (this.defaultSiteT) {
            this.url = new URL(dashboardURL, TBaseURL).toString();
        } else {
            this.url = new URL(dashboardURL, SBaseURL).toString();
        }
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
        if (this.defaultSiteT) {
            this.url = new URL(dashboardURL, TBaseURL).toString();
        } else {
            this.url = new URL(dashboardURL, SBaseURL).toString();
        }
        if (this.buttonPositionRIGHT) {
            this.buttonShowX = this.Vp - 45 - 10;
            this.buttonHideX = this.Vp + 10;
        } else {
            this.buttonShowX = 10;
            this.buttonHideX = -45 - 10;
        }
        await this.isLoading;
        const rect = componentUtils.getRectangleById("Dashboard");
        const vpHeight = px2vp(rect.size.height);
        console.log(`px高度: ${rect.size.height}`);
        console.log(`vp高度: ${vpHeight}`);
        //教程页面检测
        this.checkFirstLaunch();
        //状态栏颜色
        this.win = await window.getLastWindow(getContext());
        const isDark = this.mode === WebDarkMode.On;
        this.win.setWindowSystemBarProperties({
            statusBarColor: "#00000000",
            statusBarContentColor: isDark ? "#FFFFFF" : "#000000",
        });
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
                Column({ space: 10 }) {
                    Button() {
                        Image($r("app.media.arrow_up"))
                            .width(24)
                            .height(24)
                    }
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
                    .backgroundBlurStyle(BlurStyle.Thin)
                    .backgroundColor($r("app.color.background"))
                    .width(45)
                    .height(45)
                    .shadow({
                        radius: 6,
                        color: Color.Gray,
                        offsetX: 2,
                        offsetY: 4,
                    })
                    Button() {
                        Image(this.isLoading ? $r("app.media.stop") : $r("app.media.refresh"))
                            .width(24)
                            .height(24)
                    }
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
                    .type(ButtonType.Circle)
                    .backgroundBlurStyle(BlurStyle.Thin)
                    .backgroundColor($r("app.color.background"))
                    .width(45)
                    .height(45)
                    .shadow({
                        radius: 4,
                        color: Color.Gray,
                        offsetX: 2,
                        offsetY: 4,
                    })
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
                    PanGesture({ direction: PanDirection.Vertical }).onActionEnd(
                        (event: GestureEvent) => {
                            this.buttonY = this.buttonY + event.offsetY;
                            if (this.buttonY > 660) {
                                this.buttonY = 660;
                                prompt.showToast({ message: "不能再往下啦", duration: 500 });
                            } else if (this.buttonY < 70) {
                                this.buttonY = 70;
                                prompt.showToast({ message: "不能再往上啦", duration: 500 });
                            }
                            console.log("平移中，垂直偏移量 y 为:", this.buttonY);
                        },
                    ),
                )

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
                        .position({ x: this.Vp - 15 })
                        .onClick(() => {
                            this.showButtonAnimation = true;
                            this.showButton = true;
                            this.triggerVibration();
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
                    mainTitle:
                        this.siteMode == SiteMode.SSite ? "应用看板 - S站" : "应用看板 - T站",
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
                                label: "switch",
                                icon: $r("app.media.switch"),
                                isEnabled: true,
                                action: async () => {
                                    this.triggerVibration();
                                    await this.switchWebVersion();
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
