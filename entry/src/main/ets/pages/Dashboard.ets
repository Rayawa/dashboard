import { IdleTask } from '../utils/runtime/FrameScheduler';
import lazy { RankingPage } from './discovery/RankingPage';
import lazy { AppCollectionPage } from './discovery/AppCollectionPage';
import lazy { TopicsPage } from './discovery/TopicsPage';
import lazy { CollectionPage } from './main/CollectionPage';
import lazy { CollectionManagementPage } from './collection/CollectionManagementPage';
import type { RankingTarget, AppCollectionTarget, TopicTarget } from '../models/types';
import { ROUTE_RANKINGS, ROUTE_APP_COLLECTION, ROUTE_TOPICS, ROUTE_COLLECTION_MANAGEMENT } from '../config/constants';
import {
  BlurStrategy,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
} from '@kit.UIDesignKit';
import { curves, LengthMetrics, PromptAction, SegmentButtonV2Items, SymbolGlyphModifier } from '@kit.ArkUI';
import { deviceInfo } from '@kit.BasicServicesKit';
import { getFirstLaunch } from '../services/storage/storage';
import {
  consumeMainTab, getContinuationState, peekDetailTarget, setAppsViewIndex, setContinuationView, setMainTab,
} from '../state/appState';
import {
  CONTINUATION_ROUTE_DETAIL,
  customUserAgent,
  MAIN_TAB_APPS,
  MAIN_TAB_COLLECTION,
  MAIN_TAB_DEFAULT,
  MAIN_TAB_HOME,
  MAIN_TAB_MY,
  MAIN_TAB_S_STATION,
  S_STATION_COMMAND_BACK,
  S_STATION_COMMAND_HOME,
  S_STATION_COMMAND_NONE,
  S_STATION_COMMAND_SHARE,
  S_STATION_COMMAND_SCROLL_TOP,
  ROUTE_APP_DETAIL,
  ROUTE_APP_LOG,
  ROUTE_DEVELOPER,
  ROUTE_FRIEND_LINKS,
  ROUTE_HTML_PAGE,
  ROUTE_TUTORIAL,
  ROUTE_WEB_PAGE,
} from '../config/constants';
import type { AppRouteTarget } from '../models/types';
import { WarningContent } from '../components/privacy/WarningContent';
import { vibration } from '../utils/device/vibration';
import { pushPathSafely } from '../ui/navigation/safeNavigation';
import { showToastSafely } from '../ui/feedback/safeUi';
import {
  HDS_MATERIAL_LEVEL_GENTLE,
  HDS_MATERIAL_TYPE_ADAPTIVE,
  HDS_TITLE_SIZE_SMALL,
  SUPPORTS_HARMONY_API_23,
} from '../config/platformCompatibility';
import { HomePage } from './main/HomePage';
import lazy { AppsPage } from './main/AppsPage';
import lazy { MyPage } from './main/MyPage';
import lazy { AppDetailPage } from './detail/AppDetailPage';
import lazy { AppLogBuilder } from './settings/AppLogPage';
import lazy { HTMLBuilder } from './web/LocalHtmlPage';
import lazy { TutorialPageBuilder } from './settings/TutorialPage';
import lazy { FriendPageBuilder } from './settings/FriendLinksPage';
import lazy { DeveloperPage } from './settings/DeveloperPage';
import lazy { WebPageBuilder } from './web/WebPage';
import type { WebPageParams } from './web/WebPage';
import { HdsTitleBarSegment } from '../components/common/HdsTitleBarSegment';
import lazy { SStationNodeParams, SStationPreloadNodeController } from '../ui/station/SStationPreloadNode';
import { reportUserTelemetry } from '../services/telemetry/TelemetryService';

interface MainTab {
    label: string;
    icon: Resource;
}

interface MainTitleMenuContent {
    label: string;
    icon: Resource;
    isEnabled: boolean;
    action: () => void;
}

interface MainTitleMenuItem {
    content: MainTitleMenuContent;
}

@Entry({ useSharedStorage: true })
@Component
struct Dashboard {
    @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
    private tabsController: HdsTabsController = new HdsTabsController();
    private sStationNodeController?: SStationPreloadNodeController;
    @State private stationInitialized: boolean = false;
    @State private mainVisible: boolean = true;
    @StorageLink('applicationActive') @Watch('onApplicationActivityChanged') private applicationActive: boolean = true;
    private stationPreload?: IdleTask;
    private telemetryTask?: IdleTask;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
    @State private selectedIndex: number = MAIN_TAB_DEFAULT;
    @State private searchRequestVersion: number = 0;
    @State private showWarning: boolean = false;
    @State private warningRequiresConfirmation: boolean = true;
    @State private mainActionIndex: number = -1;
    @State private mainActionVersion: number = 0;
    @State private homeRefreshVersion: number = 0;
    @State private appsSearchCommandVersion: number = 0;
    @State private appsSearchOpen: boolean = false;
    @State private appsViewIndexes: number[] = [0];
    @State private collectionViewIndexes: number[] = [0];
    @State private appsSearchCloseVersion: number = 0;
    @State private sStationCommand: number = S_STATION_COMMAND_NONE;
    @State private sStationCommandVersion: number = 0;
    @State private sStationDetailOpen: boolean = false;
    private hasReportedTelemetry: boolean = false;
    private warningHostReady: boolean = false;
    private pageShowToken: number = 0;
    private detailRestoreTimer: number = -1;
    private appsSegmentItems: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '概况', accessibilityText: '概况' },
        { text: '总表', accessibilityText: '总表' },
    ]);
    private collectionSegmentItems: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '应用', accessibilityText: '收藏的应用' },
        { text: '开发者', accessibilityText: '收藏的开发者' },
    ]);
    private readonly mainTabs: MainTab[] = [
        { label: 'S站', icon: $r('sys.symbol.wifi_router') },
        { label: '首页', icon: $r('sys.symbol.house') },
        { label: '收藏', icon: $r('sys.symbol.star') },
        { label: '详情', icon: $r('sys.symbol.square_grid_2x2') },
        { label: '我的', icon: $r('sys.symbol.person') },
    ];

    private mainTabStyle(tab: MainTab): BottomTabBarStyle {
        return new BottomTabBarStyle({
            normal: new SymbolGlyphModifier(tab.icon).fontColor([$r('app.color.v3_text_secondary')]),
            selected: new SymbolGlyphModifier(tab.icon).fontColor([$r('app.color.diff_content')]),
        }, tab.label)
            .labelStyle({
                selectedColor: $r('app.color.diff_content'),
                unselectedColor: $r('app.color.v3_text_secondary'),
            });
    }

    @Builder
    private appsTitleSegment(): void {
        Column() {
            HdsTitleBarSegment({
                items: this.appsSegmentItems,
                selectedIndexes: $appsViewIndexes,
                maxFontScale: 2,
                segmentHeight: 48,
                normalWidth: '50%',
                experimentalWidth: '50%',
                experimentalHeight: 52,
                onItemClicked: (index: number): void => {
                    this.vibrate();
                    this.appsViewIndexes = [index];
                    setAppsViewIndex(index);
                },
            })
            .align(Alignment.Center)
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
    }

    @Builder
    private collectionTitleSegment(): void {
        Column() {
            HdsTitleBarSegment({
                items: this.collectionSegmentItems,
                selectedIndexes: $collectionViewIndexes,
                segmentHeight: 48,
                experimentalWidth: '50%',
                experimentalHeight: 52,
                onItemClicked: (index: number): void => {
                    this.vibrate();
                    this.collectionViewIndexes = [index];
                },
            })
            .align(Alignment.Center)
            .margin({ top: 8 })
        }
        .width('100%').height('100%').justifyContent(FlexAlign.Center)
    }

    @Builder
    private mainTitleSegment(): void {
        if (this.selectedIndex === MAIN_TAB_COLLECTION) {
            this.collectionTitleSegment()
        } else {
            this.appsTitleSegment()
        }
    }

    private mainTitle(): string {
        return this.mainTabs[this.selectedIndex]?.label ?? '首页';
    }

    private vibrate(): void {
        if (this.vibrationLevel > 0) vibration.dotVibration();
    }

    private preventWarningDismiss(): void {
        // 首次启动时，重要提示不能通过侧滑或返回关闭；用长振动与提示一同反馈。
        // 普通的短振动仍由各常规交互使用，避免两种反馈混淆。
        vibration.waveVibration();
        showToastSafely(this.prompt, '请先阅读并同意重要提示！', 1000, 'Warning');
    }

    private openTutorial(): void {
        this.vibrate();
        pushPathSafely(this.pageStack, ROUTE_TUTORIAL);
    }

    private dispatchSStationCommand(command: number): void {
        this.vibrate();
        this.sStationCommand = command;
        this.sStationCommandVersion++;
        this.updateSStationNode();
    }

    private sStationNodeParams(): SStationNodeParams {
        return {
            command: this.sStationCommand,
            commandVersion: this.sStationCommandVersion,
            active: this.applicationActive && this.mainVisible && this.selectedIndex === MAIN_TAB_S_STATION,
            onDetailOpenChanged: (open: boolean): void => {
                this.sStationDetailOpen = open;
            },
        };
    }

    private updateSStationNode(): void {
        this.sStationNodeController?.update(this.sStationNodeParams());
    }

    private handleTabBarClick(index: number): void {
        if (index !== this.selectedIndex) {
            return;
        }
        if (index === MAIN_TAB_S_STATION) {
            this.dispatchSStationCommand(S_STATION_COMMAND_HOME);
            return;
        }
        this.vibrate();
        this.mainActionIndex = index;
        this.mainActionVersion++;
    }

    private titleMenuItems(): MainTitleMenuItem[] {
        if (this.selectedIndex === MAIN_TAB_S_STATION) {
            return [
                {
                    content: {
                        label: '分享当前S站页面',
                        icon: $r('sys.symbol.share'),
                        isEnabled: true,
                        action: (): void => this.dispatchSStationCommand(S_STATION_COMMAND_SHARE),
                    },
                },
                {
                    content: {
                        label: 'S站回到顶部',
                        icon: $r('sys.symbol.arrowshape_up_to_line'),
                        isEnabled: true,
                        action: (): void => this.dispatchSStationCommand(S_STATION_COMMAND_SCROLL_TOP),
                    },
                },
            ];
        }
        if (this.selectedIndex === MAIN_TAB_HOME) {
            return [
                { content: {
                    label: '刷新首页', icon: $r('sys.symbol.arrow_clockwise'), isEnabled: true,
                    action: (): void => { this.vibrate(); this.homeRefreshVersion++; },
                } },
                {
                    content: {
                        label: '打开教程',
                        icon: $r('sys.symbol.questionmark_circle'),
                        isEnabled: true,
                        action: (): void => this.openTutorial(),
                    },
                },
            ];
        }
        if (this.selectedIndex === MAIN_TAB_COLLECTION) {
            return [{ content: {
                label: '管理收藏', icon: $r('sys.symbol.slider_horizontal_2_square'), isEnabled: true,
                action: (): void => {
                    this.vibrate();
                    pushPathSafely(this.pageStack, ROUTE_COLLECTION_MANAGEMENT, this.collectionViewIndexes[0] ?? 0);
                },
            } }];
        }
        if (this.selectedIndex === MAIN_TAB_APPS) {
            return [{
                content: {
                    label: '打开应用搜索',
                    icon: $r('sys.media.ohos_ic_public_search_filled'),
                    isEnabled: true,
                    action: (): void => {
                        this.vibrate();
                        this.appsSearchCommandVersion++;
                    },
                },
            }];
        }
        // “我的”页内已有教程入口，标题栏不再重复展示。
        return [];
    }

    private openAppDetail(target: AppRouteTarget): void {
        pushPathSafely(this.pageStack, ROUTE_APP_DETAIL, target, 'pages/Dashboard');
    }

    private async handlePageShow(pageShowToken: number): Promise<void> {
        this.selectedIndex = Math.max(MAIN_TAB_S_STATION, Math.min(MAIN_TAB_MY,
            consumeMainTab(this.selectedIndex)));
        this.updateSStationNode();
        // consumeMainTab 用于读取 Ability/接续指定页；立即写回，供各标签页恢复滚动位置。
        setMainTab(this.selectedIndex);
        this.searchRequestVersion++;
        if (this.warningHostReady) await this.checkWarning(pageShowToken);
        if (pageShowToken !== this.pageShowToken) return;
        const detail = peekDetailTarget();
        if (detail.appId || detail.packageName) {
            try {
                if (this.pageStack.getIndexByName(ROUTE_APP_DETAIL).length > 0) {
                    this.pageStack.removeByName(ROUTE_APP_DETAIL);
                }
                if (this.detailRestoreTimer >= 0) clearTimeout(this.detailRestoreTimer);
                this.detailRestoreTimer = setTimeout((): void => {
                    this.detailRestoreTimer = -1;
                    if (pageShowToken !== this.pageShowToken) return;
                    pushPathSafely(this.pageStack, ROUTE_APP_DETAIL, detail, 'pages/Dashboard');
                }, 0);
            } catch (error) {
                console.error('[Dashboard][pages/Dashboard][ERROR]',
                    `恢复应用详情失败: ${JSON.stringify(error)}`);
            }
        }
    }

    private async checkWarning(pageShowToken: number): Promise<void> {
        try {
            const shouldShowWarning = await getFirstLaunch();
            if (pageShowToken !== this.pageShowToken || !this.warningHostReady) return;
            if (shouldShowWarning) {
                this.warningRequiresConfirmation = true;
                this.showWarning = true;
            }
        } catch (error) {
            console.warn('[Dashboard][pages/Dashboard][WARN]', `[v3] 首启状态读取失败: ${JSON.stringify(error)}`);
        }
    }

    onPageShow(): void {
        this.handlePageShow(++this.pageShowToken);
        if (!this.hasReportedTelemetry) {
            this.telemetryTask?.cancel();
            this.telemetryTask = new IdleTask(this.getUIContext(), (): void => {
                if (!this.applicationActive) return;
                this.hasReportedTelemetry = true;
                reportUserTelemetry(customUserAgent);
            });
        }
    }

    aboutToDisappear(): void {
        this.pageShowToken++;
        this.stationPreload?.cancel(); this.telemetryTask?.cancel();
        this.sStationNodeController?.dispose(); this.sStationNodeController = undefined;
        this.stationInitialized = false;
        if (this.detailRestoreTimer >= 0) {
            clearTimeout(this.detailRestoreTimer);
            this.detailRestoreTimer = -1;
        }
    }

    private onApplicationActivityChanged(): void {
        this.updateSStationNode();
        if (this.applicationActive && this.mainVisible) this.scheduleStationPreload();
        else { this.stationPreload?.cancel(); this.telemetryTask?.cancel(); }
    }

    private initializeStation(): void {
        if (this.stationInitialized) return;
        this.sStationNodeController = new SStationPreloadNodeController();
        this.sStationNodeController.initialize(this.getUIContext(), this.sStationNodeParams());
        this.stationInitialized = true;
    }

    aboutToAppear(): void {
        this.selectedIndex = getContinuationState().mainTab;
        this.mainVisible = !(peekDetailTarget().appId || peekDetailTarget().packageName);
        if (this.selectedIndex === MAIN_TAB_S_STATION && this.mainVisible) this.initializeStation();
    }

    private scheduleStationPreload(): void {
        this.stationPreload?.cancel();
        this.stationPreload = new IdleTask(this.getUIContext(), (): void => {
            if (this.applicationActive && this.mainVisible) this.initializeStation();
        }, 2500);
    }

    onBackPress(): boolean {
        // 首启重要提示展示时，系统返回键和边缘侧滑都应保持在当前页。
        if (this.showWarning && this.warningRequiresConfirmation) {
            this.preventWarningDismiss();
            return true;
        }
        if (this.appsSearchOpen) {
            vibration.backVibration();
            this.appsSearchCloseVersion++;
            return true;
        }
        if (this.selectedIndex === MAIN_TAB_S_STATION && this.sStationDetailOpen) {
            vibration.backVibration();
            this.sStationCommand = S_STATION_COMMAND_BACK;
            this.sStationCommandVersion++;
            this.updateSStationNode();
            return true;
        }
        return false;
    }

    @Builder
    destinationBuilder(name: string, param: Object) {
        if (name === ROUTE_RANKINGS) {
            RankingPage({ target: param as RankingTarget })
        } else if (name === ROUTE_APP_COLLECTION) {
            AppCollectionPage({ target: param as AppCollectionTarget })
        } else if (name === ROUTE_TOPICS) {
            TopicsPage({ target: param as TopicTarget })
        } else if (name === ROUTE_COLLECTION_MANAGEMENT) {
            CollectionManagementPage({ initialIndex: param as number })
        } else if (name === ROUTE_APP_DETAIL) {
            AppDetailPage({ routeTarget: param as AppRouteTarget })
        } else if (name === ROUTE_WEB_PAGE) {
            WebPageBuilder(param as WebPageParams)
        } else if (name === ROUTE_APP_LOG) {
            AppLogBuilder()
        } else if (name === ROUTE_HTML_PAGE) {
            HTMLBuilder()
        } else if (name === ROUTE_TUTORIAL) {
            TutorialPageBuilder()
        } else if (name === ROUTE_FRIEND_LINKS) {
            FriendPageBuilder()
        } else if (name === ROUTE_DEVELOPER) {
            DeveloperPage()
        }
    }

    @Builder
    private warningSheet(): void {
        WarningContent({ isShow: this.showWarning, requiresConfirmation: this.warningRequiresConfirmation })
    }

    @Builder
    private mainTabContents(): void {
        TabContent() {
            if (this.stationInitialized) {
                NodeContainer(this.sStationNodeController!).width('100%').height('100%')
            } else {
                Column().width('100%').height('100%').backgroundColor($r('app.color.s_station_placeholder'))
            }
        }
        .tabBar(this.mainTabStyle(this.mainTabs[0]))
        .opacity(this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.92)
        .scale({ x: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985,
            y: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985 })
        .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
        .accessibilityText('S站标签页')

        TabContent() {
            HomePage({
                refreshVersion: this.homeRefreshVersion,
                active: this.applicationActive && this.mainVisible && this.selectedIndex === MAIN_TAB_HOME,
                scrollToTopVersion: this.mainActionIndex === MAIN_TAB_HOME ? this.mainActionVersion : 0,
                onOpenAppDetail: (target: AppRouteTarget): void => this.openAppDetail(target),
            })
        }
        .tabBar(this.mainTabStyle(this.mainTabs[1]))
        .accessibilityText('首页标签页')

        TabContent() {
            CollectionPage({
                selectedIndexes: $collectionViewIndexes,
                active: this.applicationActive && this.mainVisible && this.selectedIndex === MAIN_TAB_COLLECTION,
                scrollToTopVersion: this.mainActionIndex === MAIN_TAB_COLLECTION ? this.mainActionVersion : 0,
            })
        }
        .tabBar(this.mainTabStyle(this.mainTabs[MAIN_TAB_COLLECTION]))
        .accessibilityText('收藏标签页')

        TabContent() {
            AppsPage({
                active: this.applicationActive && this.mainVisible && this.selectedIndex === MAIN_TAB_APPS,
                selectedIndexes: $appsViewIndexes,
                scrollToTopVersion: this.mainActionIndex === MAIN_TAB_APPS ? this.mainActionVersion : 0,
                requestVersion: this.searchRequestVersion,
                searchCommandVersion: this.appsSearchCommandVersion,
                searchCloseVersion: this.appsSearchCloseVersion,
                onSearchOpenChanged: (open: boolean): void => {
                    this.appsSearchOpen = open;
                },
                onOpenAppDetail: (target: AppRouteTarget): void => this.openAppDetail(target),
            })
        }
        .tabBar(this.mainTabStyle(this.mainTabs[MAIN_TAB_APPS]))
        .accessibilityText('详情标签页')

        TabContent() {
            MyPage({
                active: this.applicationActive && this.mainVisible && this.selectedIndex === MAIN_TAB_MY,
                scrollToTopVersion: this.mainActionIndex === MAIN_TAB_MY ? this.mainActionVersion : 0,
                onShowWarning: (): void => {
                    this.warningRequiresConfirmation = false;
                    this.showWarning = true;
                },
            })
        }
        .tabBar(this.mainTabStyle(this.mainTabs[MAIN_TAB_MY]))
        .accessibilityText('我的标签页')
    }

    private onMainTabChanged(index: number): void {
        this.selectedIndex = index;
        if (index === MAIN_TAB_S_STATION) this.initializeStation();
        this.updateSStationNode();
        setMainTab(index);
        const continuation = getContinuationState();
        if (continuation.routeName !== CONTINUATION_ROUTE_DETAIL) {
            setContinuationView(index, 0);
        }
        if (this.vibrationLevel > 0) {
            vibration.dotVibration();
        }
    }

    @Builder
    private mainTabsView(): void {
        // distributionOSApiVersion 6.1.0 对应 HarmonyOS API 23。
        if (deviceInfo.distributionOSApiVersion >= 60100) {
            HdsTabs({ controller: this.tabsController, index: this.selectedIndex }) {
                this.mainTabContents()
            }
            .barPosition(BarPosition.End)
            .barWidth(320)
            // API 23+ 缓存最近切换页面，并使用系统浮动材质底栏。
            .cachedMaxCount(5, TabsCacheMode.CACHE_LATEST_SWITCHED)
            .scrollable(false)
            .vertical(false)
            .barOverlap(true)
            .blurStrategy(BlurStrategy.ENABLE)
            .barFloatingStyle({
                barBottomMargin: 28,
                lightColor: $r('app.color.diff_content'),
                gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
                systemMaterialEffect: {
                    materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
                    materialLevel: this.immersiveMaterialLevel,
                },
            })
            .onTabBarClick((index: number) => this.handleTabBarClick(index))
            .onChange((index: number) => this.onMainTabChanged(index))
            .accessibilityText('主界面五个标签页，依次为S站、首页、收藏、详情和我的')
        } else {
            HdsTabs({ controller: this.tabsController, index: this.selectedIndex }) {
                this.mainTabContents()
            }
            .barPosition(BarPosition.End)
            .barWidth(320)
            .scrollable(false)
            .vertical(false)
            .barOverlap(true)
            .blurStrategy(BlurStrategy.ENABLE)
            .barBackgroundColor($r('app.color.v3_surface'))
            .barBackgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THICK)
            .onTabBarClick((index: number) => this.handleTabBarClick(index))
            .onChange((index: number) => this.onMainTabChanged(index))
            .accessibilityText('主界面五个标签页，依次为S站、首页、收藏、详情和我的')
        }
    }

    build() {
        HdsNavigation(this.pageStack) {
            Stack() {
                this.mainTabsView()
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.background'))
            .accessibilityGroup(false).accessibilityLevel('no')
            .accessibilityText('Dashboard应用看板主界面')
            .onAppear((): void => {
                this.scheduleStationPreload();
                this.warningHostReady = true;
                this.checkWarning(this.pageShowToken);
            })
            .bindSheet($$this.showWarning, this.warningSheet(), {
                title: { title: '重要提示', subtitle: '使用前请阅读以下说明' },
                height: SheetSize.FIT_CONTENT,
                detents: [SheetSize.FIT_CONTENT],
                preferType: SheetType.BOTTOM,
                showClose: !this.warningRequiresConfirmation,
                dragBar: true,
                maskColor: $r('app.color.v3_scrim'),
                blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
                scrollSizeMode: ScrollSizeMode.CONTINUOUS,
                onWillDismiss: this.warningRequiresConfirmation ? (_action: DismissSheetAction): void => {
                    this.preventWarningDismiss();
                } : undefined,
                onWillDisappear: (): void => {
                    if (!this.warningRequiresConfirmation) this.vibrate();
                },
            })
        }
        .onNavBarStateChange((visible: boolean): void => {
            const pending = peekDetailTarget();
            this.mainVisible = visible && !pending.appId && !pending.packageName;
            this.updateSStationNode();
            if (visible) this.scheduleStationPreload();
        })
        .mode(NavigationMode.Stack)
        .customNavContentTransition((_from: NavContentInfo, _to: NavContentInfo,
            operation: NavigationOperation) => {
            // 覆盖标题栏返回、系统返回键和侧滑返回；去重由 vibration.backVibration 负责。
            if (operation === NavigationOperation.POP) vibration.backVibration();
            return undefined;
        })
        .navDestination(this.destinationBuilder)
        .titleMode(HdsNavigationTitleMode.MINI)
        .hideBackButton(true)
        .hideTitleBar(this.appsSearchOpen)
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: false,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: Color.Transparent,
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
                    materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
                    materialLevel: this.immersiveMaterialLevel,
                } : undefined,
            },
            content: {
                title: {
                    mainTitle: this.mainTitle(),
                    mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
                },
                menu: {
                    value: this.titleMenuItems(),
                },
                stackBuilder: (this.selectedIndex === MAIN_TAB_APPS || this.selectedIndex === MAIN_TAB_COLLECTION) &&
                    !this.appsSearchOpen ? (): void => {
                    this.mainTitleSegment();
                } : undefined,
            },
        })
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .accessibilityText('Dashboard应用导航')
    }
}
