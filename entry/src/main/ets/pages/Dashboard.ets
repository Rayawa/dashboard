import {
  BlurStrategy,
  HdsNavigation,
  HdsNavigationTitleMode,
  HdsTabs,
  HdsTabsController,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { curves, LengthMetrics, PromptAction, SegmentButtonV2Items } from '@kit.ArkUI';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { getFirstLaunch } from '../common/storage';
import {
  consumeMainTab, getContinuationState, peekDetailTarget, setAppsViewIndex, setContinuationView, setMainTab,
} from '../common/appState';
import {
  CONTINUATION_ROUTE_DETAIL,
  MAIN_TAB_APPS,
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
} from '../common/constants';
import type { AppRouteTarget } from '../common/types';
import { WarningContent } from '../component/WarningContent';
import { vibration } from '../common/vibration';
import { pushPathSafely } from '../common/safeNavigation';
import { showToastSafely } from '../common/safeUi';
import { HomePage } from './main/HomePage';
import { AppsPage } from './main/AppsPage';
import { MyPage } from './main/MyPage';
import { AppDetailPage } from './detail/AppDetailPage';
import { AppLogBuilder } from './more/AppLogPage';
import { HTMLBuilder } from './more/LocalHtmlPage';
import { TutorialPageBuilder } from './more/TutorialPage';
import { FriendPageBuilder } from './more/FriendLinksPage';
import { DeveloperPage } from './more/DeveloperPage';
import { WebPageBuilder, WebPageParams } from './more/WebPage';
import { HdsTitleBarSegment } from '../component/HdsTitleBarSegment';
import { SStationNodeParams, SStationPreloadNodeController } from '../component/SStationPreloadNode';

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
    private sStationNodeController: SStationPreloadNodeController = new SStationPreloadNodeController();
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: hdsMaterial.MaterialLevel =
        hdsMaterial.MaterialLevel.GENTLE;
    @State private selectedIndex: number = MAIN_TAB_DEFAULT;
    @State private searchRequestVersion: number = 0;
    @State private showWarning: boolean = false;
    @State private warningRequiresConfirmation: boolean = true;
    @State private mainActionIndex: number = -1;
    @State private mainActionVersion: number = 0;
    @State private appsSearchCommandVersion: number = 0;
    @State private appsSearchOpen: boolean = false;
    @State private appsViewIndexes: number[] = [0];
    @State private appsSearchCloseVersion: number = 0;
    @State private sStationCommand: number = S_STATION_COMMAND_NONE;
    @State private sStationCommandVersion: number = 0;
    @State private sStationDetailOpen: boolean = false;
    private appsSegmentItems: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '概况', accessibilityText: '概况' },
        { text: '总表', accessibilityText: '总表' },
    ]);
    private readonly mainTabs: MainTab[] = [
        { label: 'S站', icon: $r('sys.media.wifi_router_fill') },
        { label: '首页', icon: $r('sys.media.return_home_fill') },
        { label: '详情', icon: $r('sys.media.rectangle_filled_and_line_horizontal_and_rectangle') },
        { label: '我的', icon: $r('sys.media.person_badge_waveform') },
    ];

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
            active: this.selectedIndex === MAIN_TAB_S_STATION,
            onDetailOpenChanged: (open: boolean): void => {
                this.sStationDetailOpen = open;
            },
        };
    }

    private updateSStationNode(): void {
        this.sStationNodeController.update(this.sStationNodeParams());
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

    private async handlePageShow(): Promise<void> {
        this.selectedIndex = Math.max(MAIN_TAB_S_STATION, Math.min(MAIN_TAB_MY,
            consumeMainTab(this.selectedIndex)));
        this.updateSStationNode();
        // consumeMainTab 用于读取 Ability/接续指定页；立即写回，供各标签页恢复滚动位置。
        setMainTab(this.selectedIndex);
        this.searchRequestVersion++;
        try {
            const shouldShowWarning = await getFirstLaunch();
            if (shouldShowWarning) {
                this.warningRequiresConfirmation = true;
                this.showWarning = true;
            }
        } catch (error) {
            console.warn('[Dashboard][pages/Dashboard][WARN]', `[v3] 首启状态读取失败: ${JSON.stringify(error)}`);
        }
        const detail = peekDetailTarget();
        if (detail.appId || detail.packageName) {
            try {
                if (this.pageStack.getIndexByName(ROUTE_APP_DETAIL).length > 0) {
                    this.pageStack.removeByName(ROUTE_APP_DETAIL);
                }
                setTimeout((): void => {
                    pushPathSafely(this.pageStack, ROUTE_APP_DETAIL, detail, 'pages/Dashboard');
                }, 0);
            } catch (error) {
                console.error('[Dashboard][pages/Dashboard][ERROR]',
                    `恢复应用详情失败: ${JSON.stringify(error)}`);
            }
        }
    }

    onPageShow(): void {
        this.handlePageShow();
    }

    aboutToAppear(): void {
        // BuilderNode 会立即创建并加载 Web；首次点击 S 站时仅执行节点挂载。
        this.sStationNodeController.initialize(this.getUIContext(), this.sStationNodeParams());
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
        if (name === ROUTE_APP_DETAIL) {
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

    build() {
        HdsNavigation(this.pageStack) {
            Stack() {
                HdsTabs({ controller: this.tabsController, index: this.selectedIndex }) {
                    TabContent() {
                        NodeContainer(this.sStationNodeController)
                            .width('100%')
                            .height('100%')
                    }
                    .tabBar(new BottomTabBarStyle(this.mainTabs[0].icon, this.mainTabs[0].label))
                    .opacity(this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.92)
                    .scale({ x: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985,
                        y: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985 })
                    .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
                    .accessibilityText('S站标签页')

                    TabContent() {
                        HomePage({
                            active: this.selectedIndex === MAIN_TAB_HOME,
                            scrollToTopVersion: this.mainActionIndex === MAIN_TAB_HOME ? this.mainActionVersion : 0,
                            onOpenAppDetail: (target: AppRouteTarget): void => this.openAppDetail(target),
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.mainTabs[1].icon, this.mainTabs[1].label))
                    .accessibilityText('首页标签页')

                    TabContent() {
                        AppsPage({
                            active: this.selectedIndex === MAIN_TAB_APPS,
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
                    .tabBar(new BottomTabBarStyle(this.mainTabs[2].icon, this.mainTabs[2].label))
                    .accessibilityText('详情标签页')

                    TabContent() {
                        MyPage({
                            active: this.selectedIndex === MAIN_TAB_MY,
                            scrollToTopVersion: this.mainActionIndex === MAIN_TAB_MY ? this.mainActionVersion : 0,
                            onShowWarning: (): void => {
                                this.warningRequiresConfirmation = false;
                                this.showWarning = true;
                            },
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.mainTabs[3].icon, this.mainTabs[3].label))
                    .accessibilityText('我的标签页')
                }
                .barPosition(BarPosition.End)
                .barWidth(250)
                // S站由离线节点独立预加载；Tabs 缓存负责保留已切换的其余主页面。
                .cachedMaxCount(4, TabsCacheMode.CACHE_LATEST_SWITCHED)
                .scrollable(false)
                .vertical(false)
                .barOverlap(true)
                .blurStrategy(BlurStrategy.ENABLE)
                .barFloatingStyle({
                    barBottomMargin: 28,
                    lightColor: $r('app.color.diff_content'),
                    gradientMask: { maskColor: Color.Transparent, maskHeight: 92 },
                    systemMaterialEffect: {
                        materialType: hdsMaterial.MaterialType.IMMERSIVE,
                        materialLevel: this.immersiveMaterialLevel,
                    },
                })
                .onTabBarClick((index: number) => this.handleTabBarClick(index))
                .onChange((index: number) => {
                    this.selectedIndex = index;
                    this.updateSStationNode();
                    setMainTab(index);
                    const continuation = getContinuationState();
                    if (continuation.routeName !== CONTINUATION_ROUTE_DETAIL) {
                        setContinuationView(index, 0);
                    }
                    if (this.vibrationLevel > 0) {
                        vibration.dotVibration();
                    }
                })
                .accessibilityText('主界面四个标签页，依次为S站、首页、详情和我的')

            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.background'))
            .accessibilityGroup(true)
            .accessibilityText('Dashboard应用看板主界面')
        }
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
        .divider({ color: $r('app.color.border') })
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
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: this.immersiveMaterialLevel,
                },
            },
            content: {
                title: {
                    mainTitle: this.mainTitle(),
                    mainTitleSize: TitleSize.TITLE_S,
                },
                menu: {
                    value: this.titleMenuItems(),
                },
                stackBuilder: this.selectedIndex === MAIN_TAB_APPS && !this.appsSearchOpen ? (): void => {
                    this.appsTitleSegment();
                } : undefined,
            },
        })
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .accessibilityText('Dashboard应用导航')
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
            // 仅首次强制阅读时拦截关闭。普通查看让系统直接完成交互式下拉关闭，
            // 避免在手势动画末尾再次调用 dismiss() 导致 sheet 先回弹再退出。
            onWillDismiss: this.warningRequiresConfirmation ? (_action: DismissSheetAction): void => {
                    this.preventWarningDismiss();
            } : undefined,
            onWillDisappear: (): void => {
                if (!this.warningRequiresConfirmation) this.vibrate();
            },
        })
    }
}
