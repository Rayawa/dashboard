import { webview } from '@kit.ArkWeb';
import KnockShareGuideCard, { CardRes } from '../component/KnockShareGuideCard';
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
    mainPage,
    ONLY_ID,
    SBaseURL,
    SUBMIT_PLATFORM,
    TBaseURL
} from '../common/constants';
import { AbilityConstant, common, Want } from '@kit.AbilityKit';
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
    @State private holdCheckTMP: boolean = false;
    private lastSwitchTime: number = 0;
    private holdingHandCallback: Callback<motion.HoldingHandStatus> | null = null;
    subscribeHoldingHand() {
        if (this.holdingHandCallback !== null) {
            return;
        }
        try {
            if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
                this.holdingHandCallback = (data: motion.HoldingHandStatus) => {
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
    private currentIndex: number = 0;
    private readonly cardSwiperResourcesPhone: CardRes[] = [
        {
            text: "对方手机需HarmonyOS 5及以上版本。",
            rawfilePrefix: "knock_share_guide/knock_share_guide_phone_",
            framesCount: 128,
            startDelay: 50,
            stopDelay: 500,
        },
    ];
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
    @Builder tutorialPage(){
        Swiper() {
            // 欢迎页面
            Column() {
                Text("欢迎来到Dashboard应用看板")
                    .fontSize(23)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })

                Text("详情请查看：项目总网页")
                    .margin({ bottom: 10 })
                    .fontSize(14)
                    .fontColor(Color.Blue)
                    .margin({bottom: 10})
                    .decoration({ type: TextDecorationType.Underline, color: Color.Blue })
                    .onClick(async () => {
                        if(this.vibrationON) vibration.dotVibration()
                        const ui_content = this.getUIContext();
                        try {
                            this.PromptAction.showToast({ message: "正在跳转...", duration: 500 });
                            let context = ui_content.getHostContext() as common.UIAbilityContext;
                            await context.startAbility({
                                action: "ohos.want.action.viewData",
                                entities: ["entity.system.browsable"],
                                uri: mainPage.toString(),
                            } as Want);
                        } catch (error) {
                            console.error("打开链接失败:", (error as BusinessError).message);
                            this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
                        }
                    })

                Text(
                    "本应用是由Harmony Dashboard项目组直接参与编写的鸿蒙应用。应用收集华为应用市场的公开数据，转化为直观的图表与报告。简单来说，您能在这里查看几乎所有鸿蒙应用的动态。\n" +
                        " 1. 数据总览与图表分析：\n   通过榜单、饼图与折线图，直观查看应用下载量、评分趋势与市场分布。\n" +
                        " 2. 搜索应用与查看详情：\n   支持按名称、评分等条件搜索排序、应用内搜索应用、分享链接搜索应用。您可查看各种应用数据与趋势图。\n" +
                        " 3. 数据定时自动更新：\n    后台每30分钟同步一次数据，确保您始终获取最新数据。\n" +
                        " 4. 交互式操作与分享：\n    点击图表可进行数据筛选，点击应用可进入详情页；您也可通过链接、隔空抓取或鸿蒙碰一碰便捷分享应用页面。\n" +
                        " 5. 投稿更新应用信息：\n    您可通过应用市场分享与“我的”页面向应用看板投稿，协助投稿新应用或更新应用信息。\n",
                )
                    .fontSize(14)
                    .margin({ bottom: 5 })
                Text(
                    "重要提示：\n本应用的所有数据均来源于华为应用市场的公开信息，数据仅供参考，不保证来源的准确性、完整性和真实性。",
                )
                    .fontSize(17)
                    .fontColor(Color.Red)
                    .fontWeight(FontWeight.Medium)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 主界面部分
            Column() {
                Text("主界面")
                    .fontSize(23)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text("您可以选择您喜欢的站点\n").fontSize(18).margin({ top: 5, bottom: 10 }).fontWeight(FontWeight.Bold)

                Column() {
                    Text("🚀 主要功能").fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 5 })
                    Text("• 数据统计 - 展示应用总数、元服务总数、开发者总数等关键指标的统计数据。\n",).fontSize(14)
                    Text("• 下载榜 - 提供下载量排名前20的应用列表，以及排除华为系应用后的下载量排名。\n",).fontSize(14)
                    Text("• 应用详情 - 点击任意应用相关图标查看应用的详细信息，包括下载量、评分、支持设备、版本信息等。\n",).fontSize(14)
                    Text("• 趋势分析 - 展示应用下载量的变化趋势和增量趋势图表。\n").fontSize(14)
                    Text("• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选功能。\n").fontSize(14)
                }.alignItems(HorizontalAlign.Start).margin({ bottom: 10 })

                Column() {
                    Text("📝 使用说明").fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 5 })
                    Text("• 刷新数据 - 点击“刷新数据”按钮获取最新数据").fontSize(14)
                    Text("• 搜索应用 - 支持按名称、包名、开发者等搜索").fontSize(14)
                    Text("• 快速筛选 - 点击组件可快速查看对应应用").fontSize(14)
                    Text("• 排序功能 - 按评分、下载量、大小等排序").fontSize(14)
                    Text("• 查看详情 - 点击应用行查看详细信息").fontSize(14)
                    Text("• 过滤选项 - 可排除华为/元服务应用").fontSize(14)
                }.alignItems(HorizontalAlign.Start)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 投稿与查询功能
            Column() {
                Text("投稿与查询功能")
                    .fontSize(23)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text(
                    "  投稿功能可以触发应用抓取与更新，您可以通过App内【投稿应用】或在应用市场中【分享应用至看板】以投稿新的App或更新App信息。\n\n  在【查询应用】输入应用信息可以查询应用的具体数据，您还可以在应用市场里【分享应用链接至看板】查询信息！",
                ).fontSize(14).margin({ bottom: 10 })

                Row() {
                    Text("  投稿与查询功能支持AI智能提取，将应用信息输入或粘贴进文本框即可自动提取！\n").fontSize(14).blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                }
                .linearGradient({
                    direction: GradientDirection.LeftBottom,
                    colors: [
                        [$r("app.color.gradient_start_color"), 0.0],
                        [$r("app.color.gradient_end_color"), 1],
                    ],
                })
                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
                Row() {
                    Column({ space: 5 }) {
                        Text("1. 应用商店投稿与查询：在任意App详情页点击分享并选择应用看板进行投稿与查询。")
                            .fontSize(14)
                            .width("100%")
                            .textAlign(TextAlign.Start)
                            .height(60)
                            .margin({ bottom: 25 })

                        Image($r("app.media.submit_store"))
                            .objectFit(ImageFit.Contain)
                            .borderRadius(7)
                            .borderWidth(1)
                            .borderColor($r("app.color.border"))
                            .width("100%")

                    }
                    .height("100%")
                    .width("48%")

                    Column({ space: 5 }) {
                        Text("2. 应用内投稿与查询：在“我的”界面内投稿与查询。")
                            .fontSize(14)
                            .width("100%")
                            .textAlign(TextAlign.Start)
                            .height(60)
                            .margin({ bottom: 25 })

                        Image($r("app.media.submit_app"))
                            .objectFit(ImageFit.Contain)
                            .borderRadius(7)
                            .borderWidth(1)
                            .borderColor($r("app.color.border"))
                            .width("100%")
                    }
                    .height("100%")
                    .width("48%")
                }
                .width("100%")
                .padding({ left: 10, right: 10 })
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 分享功能与友情链接
            Column() {
                Text("友情链接与分享功能")
                    .fontSize(23)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text("  您可以在主界面访问友情链接。友情链接页面内点击地球仪图标可以在浏览器内访问页面。\n").fontSize(14)
                Text("  友情链接内网站展示的任何内容均与应用看板无关，Harmony Dashboard项目组不负责维护友情链接内容。").fontSize(14).fontColor($r('app.color.diff_content')).margin({ bottom: 20 })
                Text("  1. 链接分享：在主界面或任意应用详情页点击分享按钮分享当前页面链接。\n\n").fontSize(14)
                Text("  2. 碰一碰分享：在任意界面使用碰一碰分享将当前页面链接分享给其他HarmonyOS设备。\n",).fontSize(14)
                KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
                    .margin({ bottom: 20 })
                Text("  3. 隔空传送：在任意界面隔空传送将当前页面链接分享给其他HarmonyOS设备。\n")
                    .fontSize(14)
                Image($r("app.media.grasp"))
                    .width("70%")
                    .height(150)
                    .borderRadius(16)
                    .margin({ bottom: 10 })
                    .borderWidth(1)
                    .borderColor($r("app.color.border"))
                Text("    * 使用前，请确保两台设备均在设置中开启“隔空传送”功能。\n").fontSize(10).fontColor(Color.Grey)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)
        }
        .loop(false)
        .effectMode(EdgeEffect.Spring)
        .width("100%").height("100%")
        .indicator(
            new DotIndicator()
                .itemWidth(6)
                .itemHeight(6)
                .selectedItemWidth(12)
                .selectedItemHeight(6)
                .color($r("sys.color.comp_background_secondary"))
                .selectedColor($r("sys.color.comp_background_emphasize")),
        )
        .index(this.currentIndex);
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
                                    if (this.holdCheckON) {
                                        this.holdCheckON = false;
                                        this.holdCheckTMP = true;
                                    }
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
                                    if (this.holdCheckTMP) {
                                        this.holdCheckON = true;
                                        this.holdCheckTMP = false;
                                    }
                                    const topLimit = 100;
                                    const bottomLimit = this.getUIContext().px2vp(this.winHeight) - 140;
                                    if (this.buttonY >= bottomLimit) {
                                        this.PromptAction.showToast({ message: "不能再往下啦", duration: 500 });
                                    } else if (this.buttonY <= topLimit) {
                                        this.PromptAction.showToast({ message: "不能再往上啦", duration: 500 });
                                    }
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
        .bindSheet($$this.showTutorial, this.tutorialPage(), {
            title: { title: "教程页面" },
            height: SheetSize.FIT_CONTENT,
            preferType: SheetType.CENTER,
            backgroundColor: $r('app.color.backcolor'),
            blurStyle: BlurStyle.BACKGROUND_ULTRA_THICK,
            borderWidth: 2,
            borderColor: $r("app.color.border"),
            onWillDisappear: () => { this.showTutorial = false; if (this.vibrationON) { vibration.dotVibration();} }
        })
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
                                    if(this.vibrationON) vibration.dotVibration()

                                    if(this.showWarn){
                                        this.PromptAction.showToast({ message: "请先阅读并同意重要提示！" })
                                        return;
                                    }
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
                                    if(this.vibrationON) vibration.dotVibration()

                                    if(this.showWarn){
                                        this.PromptAction.showToast({ message: "请先阅读并同意重要提示！" })
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
                                    if(this.vibrationON) vibration.dotVibration()
                                    if(this.showWarn){
                                        this.PromptAction.showToast({ message: "请先阅读并同意重要提示！" })
                                        return;
                                    }
                                    let index = this.pageStack.getIndexByName("UserPage");
                                    if (index.length > 0) {
                                        this.pageStack.removeByName("UserPage");
                                        this.toggleSplitMode(false);
                                    } else {
                                        if (this.getUIContext().px2vp(this.winWidth) >= 600) {
                                            this.toggleSplitMode(true);
                                        }
                                        this.pageStack.pushPathByName("UserPage", null);
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
