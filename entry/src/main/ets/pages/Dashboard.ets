import { webview } from '@kit.ArkWeb';
import { tutorial } from './tutorial';
import { motion, userStatus } from '@kit.MultimodalAwarenessKit';
import {
    BlurStrategy,
    hdsEffect,
    HdsNavigation,
    HdsNavigationTitleMode,
    HdsTabs,
    HdsTabsController,
    ScrollEffectType,
    TitleSize
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { vibration } from '../common/vibration';
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import {
    APP_BUNDLE_NAME,
    APP_VERSION,
    customUserAgent,
    FullDeviceInfo,
    ONLY_ID,
    SBaseURL,
    SUBMIT_PLATFORM,
    TBaseURL
} from '../common/constants';
import { AbilityConstant, common } from '@kit.AbilityKit';
import { harmonyShare } from '@kit.ShareKit';
import { WebShareManager } from '../common/shareControl';
import { preferences } from '@kit.ArkData';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername, } from '../common/profile';
import { warn } from '../component/warn';
import type {
    BaseAPIResponse,
    TelemetryDeviceInfo,
    TelemetryIngestResponse,
    TelemetryReportBody
} from '../common/types';
import { http } from '@kit.NetworkKit';
import {
    getButtonPosition,
    getHoldCheckEnabled,
    getImmersiveTexture,
    getTabBarAuto,
    getVibrationEnabled,
    initializeSettings
} from '../common/SettingsStorage';
import { user } from './user';

interface SiteConfig {
    key: string;
    url: string;
    label: string;
    icon: Resource;
}

async function report_user_telemetry(
    event_name: string = customUserAgent,
): Promise<BaseAPIResponse<TelemetryIngestResponse> | null> {
    const final_data: TelemetryReportBody = {
        app_id: APP_BUNDLE_NAME,
        only_id: ONLY_ID,
        app_version: APP_VERSION,
        submit_platform: SUBMIT_PLATFORM,
        custom_user_agent: customUserAgent,
        event_name,
        device_info: new FullDeviceInfo() as TelemetryDeviceInfo,
    };
    const path = "https://ddns.shenjack.top:10003/api/v0/telemetry/report";
    const request = http.createHttp();

    try {
        const dataString = JSON.stringify(final_data);
        const response = await request.request(path.toString(), {
            method: http.RequestMethod.POST,
            header: { "Content-Type": "application/json", "User-Agent": customUserAgent },
            extraData: dataString,
            expectDataType: http.HttpDataType.STRING,
            usingCache: false,
            connectTimeout: 10000,
            readTimeout: 10000,
        });
        console.info(`Status: ${response.responseCode}`);
        if (response.responseCode === 200 && response.result) {
            const rawResult = response.result;
            try {
                if (typeof rawResult === 'string') {
                    if (!rawResult.trim()) {
                        console.error("Error: Received empty string");
                        return null;
                    }
                    return JSON.parse(rawResult) as BaseAPIResponse<TelemetryIngestResponse>;
                }
                return rawResult as BaseAPIResponse<TelemetryIngestResponse>;
            } catch (parseError) {
                console.error(`JSON Parse Failed. Raw Content: ${rawResult}`);
                console.error(`Parse Error Detail: ${parseError.message}`);
                return null;
            }
        } else {
            console.error(`Error Status: ${response.responseCode}`);
            console.error(`Error Detail from Server: ${response.result}`);
            if (typeof response.result !== 'string') {
                console.error(`Error Detail JSON: ${JSON.stringify(response.result)}`);
            }
        }
        console.warn(`Request failed with code: ${response.responseCode}`);
        return null;

    } catch (e) {
        console.error("Network/Request Error:", e);
        return null;
    } finally {
        request.destroy();
    }
}

@Entry
@Component
struct Dashboard {
    @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @State private navBarWidth: string | number = '100%';
    @State navMode: NavigationMode = NavigationMode.Stack;
    private toggleSplitMode(isSplit: boolean) {
        const FIXED_RIGHT_WIDTH = 423;
        if (isSplit && this.getUIContext().px2vp(this.winWidth) >= FIXED_RIGHT_WIDTH*  2) {
            this.navMode = NavigationMode.Split;
            let targetLeftWidth = this.getUIContext().px2vp(this.winWidth) - FIXED_RIGHT_WIDTH;
            animateTo({
                curve: curves.springMotion(0.4, 0.8),
                duration: 400
            }, () => {
                this.navBarWidth = targetLeftWidth;
            })
        } else {
            animateTo({
                curve: curves.springMotion(0.4, 0.8),
                duration: 400
            }, () => {
                this.navBarWidth = '100%';
            })
            this.navMode = NavigationMode.Stack;
        }
    }
    //控制相关
    @State showButton: boolean = true;
    @State barMargin: number = 28;
    @State lockBar: boolean = false;
    private lastOffset: number = 0;
    @State isTabsBarVisible: boolean = true;
    @State showTutorial: boolean = false;
    @State startY: number = 0;
    @State isPressed1: boolean = false;
    @State isPressed2: boolean = false;
    @State touchX: number = 0;
    @State touchY: number = 0;
    @State isTouching: boolean = false;
    @State isSnackBarShow: boolean = false;
    private controller: HdsTabsController = new HdsTabsController();
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("buttonPositionRIGHT") @Watch("onButtonPositionChanged") buttonPositionRIGHT: boolean = false;
    onButtonPositionChanged() {
        const targetRight = this.buttonPositionRIGHT;
        if (targetRight === this.isRightHand) {
            return;
        }
        this.lastSwitchTime = Date.now();
        animateTo({
            duration: 200,
            curve: Curve.FastOutSlowIn,
            onFinish: () => {
                this.isRightHand = targetRight;
                this.funcTranslateX = targetRight ? 120 : -120;
                animateTo({
                    duration: 300,
                    curve: curves.springMotion(0.4, 0.8)
                }, () => {
                    this.funcTranslateX = 0;
                    this.funcScale = 1;
                    this.funcOpacity = 1;
                });
            }
        }, () => {
            this.funcTranslateX = this.isRightHand ? 120 : -120;
            this.funcScale = 0.3;
            this.funcOpacity = 0;
        });
    }
    @StorageLink("tabBarAutoON") tabBarAutoON: boolean = true;
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;
    @StorageLink("showWarn") showWarn: boolean = false;
    @StorageLink("holdCheckON") @Watch("onHoldCheckChanged") holdCheckON: boolean = false;
    onHoldCheckChanged() {
        if (this.holdCheckON) {
            this.subscribeHoldingHand();
        } else {
            this.unsubscribeHoldingHand();
        }
    }
    @StorageLink('winWidth') winWidth: number = 1260;
    @StorageLink('winHeight') winHeight: number = 2224;
    @State buttonY: number = 300;
    @State private isRightHand: boolean = false;
    @State private funcTranslateX: number = 0;
    @State private funcScale: number = 1;
    @State private funcOpacity: number = 1;
    @State private isDragging: boolean = false; // 拖拽逻辑锁
    private lastSwitchTime: number = 0;
    private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
    subscribeHoldingHand() {
        if (this.holdingHandCallback !== null) {
            return;
        }
        try {
            if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
                this.holdingHandCallback = (data: motion.HoldingHandStatus) => {
                    if(this.isDragging) return;
                    const isNowRightHand = data === motion.HoldingHandStatus.RIGHT_HAND_HELD;
                    if (isNowRightHand !== this.isRightHand) {
                        const currentTime = Date.now();
                        if (currentTime - this.lastSwitchTime >= 2000) {
                            this.lastSwitchTime = currentTime;
                            animateTo({
                                duration: 200,
                                curve: Curve.FastOutSlowIn,
                                onFinish: () => {
                                    this.isRightHand = isNowRightHand;
                                    this.funcTranslateX = isNowRightHand ? 120 : -120;
                                    animateTo({
                                        duration: 300,
                                        curve: curves.springMotion(0.4, 0.8)
                                    }, () => {
                                        this.funcTranslateX = 0;
                                        this.funcScale = 1;
                                        this.funcOpacity = 1;
                                    });
                                }
                            }, () => {
                                this.funcTranslateX = this.isRightHand ? 120 : -120;
                                this.funcScale = 0.3;
                                this.funcOpacity = 0;
                            });
                        } else {
                            console.info('未满2秒，拦截频繁握持手势切换');
                        }
                    }
                    console.info(`握持手状态变化: ${data}`);
                };
                motion.on('holdingHandChanged', this.holdingHandCallback);
                console.info('成功订阅握持手状态变化');
            } else {
                this.buttonPositionRIGHT = false;
                console.warn('当前设备不支持智感握持能力');
            }
        } catch (e) {
            console.error('订阅握持手状态变化失败:', e);
        }
    }
    unsubscribeHoldingHand() {
        if (this.holdingHandCallback !== null) {
            try {
                motion.off('holdingHandChanged', this.holdingHandCallback);
                this.holdingHandCallback = null;
                console.info('已成功取消订阅握持手状态变化');
            } catch (e) {
                console.error('取消订阅握持手状态变化失败:', e);
            }
        }
    }
    private hasReportedTelemetry: boolean = false;
    private snackTimer: number = -1; // snack定时器管理
    private buttonAnimationTimer: number = -1; // 按钮动画定时器管理
    private lockBarTimer: number = -1; // 滑动手势定时器管理
    //Web控制
    @State private sitesList: SiteConfig[] = [
        { key: 'T', url: TBaseURL.toString(), label: 'T站', icon: $r('sys.media.wifi_router_fill') },
        { key: 'S', url: SBaseURL.toString(), label: 'S站', icon: $r('sys.media.wifi_router_fill') },
    ];
    @State private url: string = Array.from(this.sitesList.values())[0].url;
    @State private siteIndex: number = 0;
    private controller_T: webview.WebviewController = new webview.WebviewController();
    private controller_S: webview.WebviewController = new webview.WebviewController();
    private controller_R: webview.WebviewController = new webview.WebviewController();
    private controllers: webview.WebviewController[] = [
        this.controller_S,
        this.controller_T,
        this.controller_R
    ];
    private getActiveController(): webview.WebviewController {
        return this.controllers[this.siteIndex] || this.controller_S;
    }
    @StorageLink('scrollDistance') currentDistance: number = 0;

    @State progress: number = 0;
    scroller: Scroller = new Scroller();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

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
    private readonly effect: TransitionEffect = TransitionEffect.OPACITY.combine(
        TransitionEffect.move(TransitionEdge.BOTTOM),
    )
        .combine(TransitionEffect.scale({ x: 0, y: 1 }))
        .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

    private scrollTimer: number = -1;
    private pendingScrollDistance: number = 0;
    private updateScrollDistance(offset: number) {
        this.pendingScrollDistance = offset;
        if (this.scrollTimer !== -1) return;
        this.scrollTimer = setTimeout(() => {
            AppStorage.setOrCreate('scrollDistance', this.pendingScrollDistance);
            this.scrollTimer = -1;
        }, 100);
    }

    //==========================页面生命周期部分==========================
    //entry
    @StorageLink("IS_FIRST_LAUNCH_KEY") IS_FIRST_LAUNCH_KEY: string = "isFirstLaunch";
    private async checkFirstLaunch(): Promise<void> {
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let preference = await preferences.getPreferences(context, "myAppSettings");

            let isFirstLaunch = await preference.get(this.IS_FIRST_LAUNCH_KEY, true);

            if (isFirstLaunch === true) {
                console.info("Index", "检测到首次启动，准备弹出协议。");
                this.showWarn = true;
            } else {
                console.info("Index", "非首次启动。");
                this.showWarn = false;
            }
        } catch (err) {
            let error = err as BusinessError;
            console.error("Index", "检查失败", JSON.stringify(error));
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
            this.vibrationON = await getVibrationEnabled();
            this.holdCheckON = await getHoldCheckEnabled();
            this.buttonPositionRIGHT = await getButtonPosition();
            this.tabBarAutoON = await getTabBarAuto();
            this.immersiveTextureON = await getImmersiveTexture();
        } catch (error) {
            console.error("加载设置失败:", error);
        }
    }
    private shareManager?: WebShareManager;
    private context = getContext(this) as common.UIAbilityContext;
    //旋转屏幕关闭分屏
    private lastOrientation: display.Orientation = display.Orientation.PORTRAIT;
    private displayCallback = (): void => {
        let defaultDisplay = display.getDefaultDisplaySync();
        if (this.lastOrientation !== defaultDisplay.orientation) {
            this.lastOrientation = defaultDisplay.orientation;
            this.toggleSplitMode(false);
        }
    };
    async aboutToAppear() {
        //初始化设置内容
        initializeSettings();
        await this.loadSettings();
        this.loadUserName();
        this.isRightHand = this.buttonPositionRIGHT;
        if (this.holdCheckON) this.subscribeHoldingHand();
        let defaultDisplay = display.getDefaultDisplaySync();
        this.lastOrientation = defaultDisplay.orientation;
        display.on('change', this.displayCallback);
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
        this.checkFirstLaunch();
        this.context.setMissionContinueState(AbilityConstant.ContinueState.ACTIVE, (result) => {
            console.info('setMissionContinueState ACTIVE result: ', JSON.stringify(result));
        });
        if (!this.hasReportedTelemetry) {
            this.hasReportedTelemetry = true;
            try {
                report_user_telemetry(customUserAgent);
            } catch (error) {
                console.warn(`report telemetry failed: ${error}`);
            }
        }
        console.log("currentUsername",this.userName)
        // if(!this.showWarn){
        //     if(!this.showTutorial){
        //         if(this.userName == '' || this.userName == deviceInfo.productModel){
        //             console.info("currentUsername_pop!!")
        //             setTimeout(() => {
        //                 this.isSnackBarShow = true;
        //                 this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
        //                 this.snackTimer = -1;
        //             },3000)
        //             this.isSnackBarShow = false;
        //         } else {
        //             console.info("currentUsername_set")
        //         }
        //     }
        // }
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
    }

    aboutToDisappear() {
        // 清理计时器
        if (this.snackTimer !== -1) { clearTimeout(this.snackTimer); this.snackTimer = -1; }
        if (this.buttonAnimationTimer !== -1) { clearTimeout(this.buttonAnimationTimer); this.buttonAnimationTimer = -1; }
        if (this.lockBarTimer !== -1) { clearTimeout(this.lockBarTimer); this.lockBarTimer = -1; }
        if (this.scrollTimer !== -1) { clearTimeout(this.scrollTimer); this.scrollTimer = -1; }
        this.unsubscribeHoldingHand(); // 取消订阅握持手
        // this.hdsSnackBar.dismiss(); // 取消snack
        display.off('change', this.displayCallback);
        this.shareManager?.disablePassiveShare(); // 取消分享
        const hostContext = this.context;
        hostContext.eventHub.off("onFocus");
        hostContext.eventHub.off("onBackGround");
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
    }

    onBackGround() {
        harmonyShare.on("knockShare", (sharableTarget: harmonyShare.SharableTarget) => {
            sharableTarget.reject(harmonyShare.SharableErrorCode.NO_CONTENT_ERROR);
        });
    }

    //自定义返回逻辑
    @State firstBackTime: number = 0;
    private readonly waitTime: number = 2000;
    onBackPress(): boolean | void {
        if(this.vibrationON) vibration.dotVibration()
        // if (this.isSnackBarShow) {
        //     // this.hdsSnackBar.dismiss();
        // }
        if (this.showTutorial) {
            this.showTutorial = false;
            console.info("关闭教程");
            return true;
        }
        try {
            let activeCtrl = this.getActiveController();
            if (activeCtrl.accessStep(-1)) {
                activeCtrl.backward();
                return true;
            }
        } catch (e) {
            console.warn("BackPress: Controller not attached");
        }
        if (this.pageStack.size() > 0) {
            this.pageStack.pop();
            if (this.pageStack.size() === 0) {
                setTimeout(() => { this.toggleSplitMode(false); }, 480);
            }
            return true;
        }
        const currentTime = new Date().getTime();
        if (currentTime - this.firstBackTime > this.waitTime) {
            this.firstBackTime = currentTime;
            this.PromptAction.showToast({ message: "再按一次退出应用", duration: this.waitTime });
            if(this.vibrationON) vibration.dotVibration()
            return true;
        } else {
            return false;
        }
    }

    //==========================主程序部分==========================
    // private uiContext: UIContext = this.getUIContext();
    // private hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);
    // private icon: SnackBarIconOptions = {
    //     icon: $r('sys.symbol.rename')
    // }
    // private message: SnackBarMessageOptions = {
    //     title: "您还未设置用户名",
    //     content: "前往我的页面设置用户名"
    // }
    // private operation: SnackBarOperationOptions = {
    //     operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
    // }
    // private style: SnackBarStyleOptions = {
    //     backgroundBlurStyle: BlurStyle.Thin,
    //     nextFocusId: 'button',
    //     duration: 7999
    // }
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
        if (name === "TutorialPage") {
            tutorial({
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
    private openSplitPage(targetPage: string) {
        if (this.vibrationON) {
            vibration.dotVibration();
        }
        if (this.showWarn) {
            this.PromptAction.showToast({ message: "请先阅读并同意重要提示！" });
            return;
        }
        const splitPages = ["TutorialPage", "UserPage"];
        const activeSplitPage = splitPages.find(
            (page) => this.pageStack.getIndexByName(page).length > 0
        );

        if (activeSplitPage === targetPage) {
            this.pageStack.removeByName(targetPage);
            this.toggleSplitMode(false);
        } else {
            if (activeSplitPage) {
                this.pageStack.removeByName(activeSplitPage);
            }
            if (this.getUIContext().px2vp(this.winWidth) >= 600) {
                this.toggleSplitMode(true);
            }
            this.pageStack.pushPathByName(targetPage, null);
        }
    }
    @Builder Web(site: SiteConfig, ctrl: webview.WebviewController) {
        Stack() {
            if (this.isLoading) {
                Progress({ value: this.progress, total: 100 }).width("100%").height(90).position({ y: 5 }).zIndex(99);
            }
            Scroll(this.scroller) {
                Column() {
                    Blank().height(80).width("100%").expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM],)
                    Web({
                        src: site.url,
                        controller: ctrl,
                        renderMode: RenderMode.SYNC_RENDER,
                    })
                        .backgroundColor($r("app.color.backcolor"))
                        .id(`HmDashboard_${site.key}`)
                        .onControllerAttached(() => {
                            try {
                                if (this.url !== "") {
                                    ctrl.loadUrl(this.url);
                                }
                                ctrl.setCustomUserAgent(customUserAgent);
                            } catch (e) {
                                console.error(`Attach error for ${site.key}: ${e.code}`);
                            }
                        })
                        .onPageBegin((event) => {
                            this.isLoading = true;
                            if (event) {
                                AppStorage.setOrCreate('pageUrl', event.url);
                            }
                        })
                        .onPageEnd((event) => {
                            this.isLoading = false
                            if (event) {
                                try {
                                    const realUrl = ctrl.getUrl();
                                    this.shareManager?.updateShareData(realUrl);
                                    AppStorage.setOrCreate('pageUrl', realUrl);
                                } catch (e) {
                                }
                            }
                        })
                        .onScroll((event) => { this.updateScrollDistance(event.yOffset); })
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
                        .metaViewport(true)
                }
            }
            .onWillScroll(() => {
                if (this.tabBarAutoON) {
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
                    ForEach(this.sitesList, (site: SiteConfig, index: number) => {
                        TabContent() { this.Web(site, this.controllers[index]) }
                        .tabBar(new BottomTabBarStyle(site.icon, site.label))
                    }, (item: SiteConfig) => item.key + item.url)
                }
                .onChange((index: number) => {
                    if(this.vibrationON) vibration.dotVibration()
                    this.siteIndex = index;
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
                    systemMaterialEffect: this.immersiveTextureON ? {
                        materialType: hdsMaterial.MaterialType.IMMERSIVE,
                        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                    } : undefined
                })

                // ==========================悬浮按钮==========================
                if (this.showButton) {
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
                            if (this.vibrationON) vibration.dotVibration()
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
                                if (this.vibrationON) vibration.dotVibration()
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
                                if (this.vibrationON) vibration.dotVibration()
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
                                    this.buttonAnimationTimer = -1;
                                }, 3000);
                            }
                        })
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
                        x: this.isRightHand ? (this.getUIContext().px2vp(this.winWidth) - 45 - 8) : 8,
                        y: this.buttonY
                    })
                    .translate({ x: this.funcTranslateX, y: 0 })
                    .scale({ x: this.funcScale, y: this.funcScale })
                    .opacity(this.funcOpacity)
                    .gesture(
                        GestureGroup(GestureMode.Exclusive,
                            SwipeGesture({ direction: SwipeDirection.Horizontal })
                                .onAction((move: GestureEvent | undefined) => {
                                    if (move) {
                                        const offset = this.isRightHand ? 120 : -120;
                                        animateTo({
                                            duration: 300,
                                            curve: Curve.FastOutSlowIn,
                                            onFinish: () => {
                                                this.showButton = false;
                                                this.funcTranslateX = 0;
                                                this.funcOpacity = 1;
                                                this.funcScale = 1;
                                            }
                                        }, () => {
                                            this.funcTranslateX = offset;
                                            this.funcOpacity = 0;
                                            this.funcScale = 0.8;
                                        });
                                    }
                                }),

                            PanGesture({ direction: PanDirection.Vertical })
                                .onActionStart(() => {
                                    this.isDragging = true;
                                    this.startY = this.buttonY;
                                })
                                .onActionUpdate((event: GestureEvent) => {
                                    let nextY = this.startY + event.offsetY;
                                    const topLimit = 100;
                                    const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                                    if (nextY > bottomLimit) {
                                        nextY = bottomLimit;
                                    } else if (nextY < topLimit) {
                                        nextY = topLimit;
                                    }
                                    this.buttonY = nextY;
                                })
                                .onActionEnd(() => {
                                    this.isDragging = false;
                                    const topLimit = 100;
                                    const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                                    if (this.buttonY >= bottomLimit) {
                                        this.PromptAction.showToast({ message: "不能再往下啦", duration: 500 });
                                    } else if (this.buttonY <= topLimit) {
                                        this.PromptAction.showToast({ message: "不能再往上啦", duration: 500 });
                                    }
                                })
                                .onActionCancel(() => {
                                    this.isDragging = false;
                                })
                        )
                    )
                }
                if (!this.showButton) {
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height("100%")
                        .width(20)
                        .zIndex(5)
                        .position({ x: 0, y: 0 })
                        .gesture(
                            TapGesture()
                                .onAction((event: GestureEvent) => {
                                    this.showButton = true;
                                    const touchY = event.fingerList[0].localY - 50;
                                    const topLimit = 100;
                                    const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                                    this.buttonY = Math.min(Math.max(touchY, topLimit), bottomLimit);

                                    const offset = this.isRightHand ? 120 : -120;
                                    this.funcTranslateX = offset;
                                    this.funcOpacity = 0;
                                    this.funcScale = 0.8;
                                    setTimeout(() => {
                                        animateTo({ duration: 300, curve: curves.springMotion(0.4, 0.8) }, () => {
                                            this.funcTranslateX = 0;
                                            this.funcOpacity = 1;
                                            this.funcScale = 1;
                                        });
                                    }, 0);
                                    if (this.vibrationON)  vibration.dotVibration();
                                })
                        );
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height("100%")
                        .width(20)
                        .zIndex(5)
                        .position({ x: this.getUIContext().px2vp(this.winWidth) - 20, y: 0 })
                        .gesture(
                            TapGesture()
                                .onAction((event: GestureEvent) => {
                                    this.showButton = true;
                                    const touchY = event.fingerList[0].localY - 50;
                                    const topLimit = 100;
                                    const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                                    this.buttonY = Math.min(Math.max(touchY, topLimit), bottomLimit);

                                    const offset = this.isRightHand ? 120 : -120;
                                    this.funcTranslateX = offset;
                                    this.funcOpacity = 0;
                                    this.funcScale = 0.8;
                                    setTimeout(() => {
                                        animateTo({ duration: 300, curve: curves.springMotion(0.4, 0.8) }, () => {
                                            this.funcTranslateX = 0;
                                            this.funcOpacity = 1;
                                            this.funcScale = 1;
                                        });
                                    }, 0);
                                    if (this.vibrationON)  vibration.dotVibration();
                                })
                        );
                }
                if (this.tabBarAutoON && !this.isTabsBarVisible) {
                    Column()
                        .backgroundColor(Color.Transparent)
                        .height(50)
                        .width("100%")
                        .zIndex(5)
                        .position({ y: this.getUIContext().px2vp(this.winHeight) - 50 })
                        .onClick(() => {
                            if (this.lockBar) return;
                            animateTo({ curve: curves.springMotion(0.36, 0.6) }, () => {
                                this.barMargin = 28;
                                this.isTabsBarVisible = true;
                            })
                            if(this.vibrationON) vibration.dotVibration()
                            this.lockBar = true;
                            setTimeout(() => {
                                this.lockBar = false;
                                this.lockBarTimer = -1;
                            }, 1000);
                        });
                }

                //==========================首次进入==========================
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
                    warn({ isShow: this.showWarn }).transition(this.effect)
                }
            }
            .width("100%")
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
        // .bindSheet($$this.showTutorial, this.tutorialPage(), {
        //     title: { title: "教程页面" },
        //     height: SheetSize.FIT_CONTENT,
        //     preferType: SheetType.CENTER,
        //     backgroundColor: $r('app.color.backcolor'),
        //     blurStyle: BlurStyle.BACKGROUND_ULTRA_THICK,
        //     borderWidth: 2,
        //     borderColor: $r("app.color.border"),
        //     onWillDisappear: () => { this.showTutorial = false; if (this.vibrationON) { vibration.dotVibration();} }
        // })
        .backgroundColor($r('app.color.backcolor'))
        .mode(this.navMode)
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
                systemMaterialEffect: this.immersiveTextureON ? {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                } : undefined
            },
            content: {
                title: {
                    mainTitle: "Dashboard应用看板",
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
                                    this.openSplitPage("TutorialPage");
                                },
                            },
                        },
                        {
                            content: {
                                label: "share",
                                icon: $r("sys.symbol.share"),
                                isEnabled: true,
                                action: () => {
                                    if (this.vibrationON) vibration.dotVibration();
                                    if (this.showWarn) {
                                        this.PromptAction.showToast({ message: "请先阅读并同意重要提示！" });
                                        return;
                                    }
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
                                    this.openSplitPage("UserPage");
                                },
                            },
                        },
                    ],
                },
            },
        });

    }
}
