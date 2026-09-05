import {
  BottomBuilderShowType,
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
  consumeMainTab, getContinuationState, setAppsViewIndex, setContinuationView, setMainTab,
} from '../common/appState';
import {
  APP_STATE_KEY_DETAIL_TARGET,
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
} from '../common/constants';
import type { AppRouteTarget } from '../common/types';
import { warn } from '../component/warn';
import { vibration } from '../common/vibration';
import { pushPathSafely } from '../common/safeNavigation';
import { showToastSafely } from '../common/safeUi';
import { SStationPage } from './main/SStationPage';
import { HomePage } from './main/HomePage';
import { AppsPage } from './main/AppsPage';
import { MyPage } from './main/MyPage';
import { AppDetailPage } from './detail/AppDetailPage';
import { AboutWebBuilder, AboutWebParams } from './more/aboutWeb';
import { AppLogBuilder } from './more/appLog';
import { HTMLBuilder } from './more/htmlPage';
import { TutorialPageBuilder } from './more/tutorial';
import { FriendPageBuilder } from './more/friend';
import { FriendPageWebBuilder, FriendWebParams } from './more/friendWeb';
import { DeveloperPage } from './more/DeveloperPage';
import { HdsTitleBarSegment } from '../component/HdsTitleBarSegment';

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
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') private vibrationLevel: number = 0;
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: hdsMaterial.MaterialLevel =
        hdsMaterial.MaterialLevel.SMOOTH;
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
    @State private appDetailShow: boolean = false;
    @State private appDetailTarget: AppRouteTarget = {};
    @State private mainContentAlpha: number = 1;
    private appsSegmentItems: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '应用概况', accessibilityText: '应用概况' },
        { text: '应用列表', accessibilityText: '应用列表' },
    ]);

    @Builder
    private appsTitleSegment(): void {
        Column() {
            HdsTitleBarSegment({
                items: this.appsSegmentItems,
                selectedIndexes: $appsViewIndexes,
                maxFontScale: 2,
                segmentHeight: 48,
                normalWidth: '100%',
                experimentalWidth: '100%',
                experimentalHeight: 52,
                onItemClicked: (index: number): void => {
                    this.vibrate();
                    setAppsViewIndex(index);
                },
            })
        }
        .width('100%')
        .height('100%')
        .padding({ left: 16, right: 16 })
        .constraintSize({ maxWidth: 532 })
        .justifyContent(FlexAlign.Center)
    }

    private tabs(): MainTab[] {
        return [
            { label: 'S站', icon: $r('sys.media.wifi_router_fill') },
            { label: '首页', icon: $r('sys.media.return_home_fill') },
            { label: '应用详情', icon: $r('sys.media.rectangle_filled_and_line_horizontal_and_rectangle') },
            { label: '我的', icon: $r('sys.media.person_badge_waveform') },
        ];
    }

    private mainTitle(): string {
        return this.tabs()[this.selectedIndex]?.label ?? '首页';
    }

    private vibrate(): void {
        if (this.vibrationLevel > 0) vibration.dotVibration();
    }

    private preventWarningDismiss(): void {
        this.vibrate();
        showToastSafely(this.prompt, '请先阅读并同意重要提示！', 1000, 'Warning');
    }

    private openTutorial(): void {
        this.vibrate();
        pushPathSafely(this.pageStack, 'TutorialPage');
    }

    private dispatchSStationCommand(command: number): void {
        this.vibrate();
        this.sStationCommand = command;
        this.sStationCommandVersion++;
    }

    private preloadSStation(): void {
        try {
            this.tabsController.preloadItems([MAIN_TAB_S_STATION]).catch((error: Error) => {
                console.warn('[Dashboard][pages/Dashboard][WARN]', `S站标签页预加载失败: ${error.message}`);
            });
        } catch (error) {
            console.warn('[Dashboard][pages/Dashboard][WARN]', `S站标签页预加载无法启动: ${JSON.stringify(error)}`);
        }
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
        return [{
            content: {
                label: '打开教程',
                icon: $r('sys.symbol.questionmark_circle'),
                isEnabled: true,
                action: (): void => this.openTutorial(),
            },
        }];
    }

    private showAppDetail(target: AppRouteTarget): void {
        this.appDetailTarget = target;
        this.appDetailShow = true;
        this.mainContentAlpha = 0;
    }

    private closeAppDetail(): void {
        if (!this.appDetailShow) {
            return;
        }
        vibration.backVibration();
        this.getUIContext().animateTo({
            duration: 350,
            curve: Curve.Friction,
        }, (): void => {
            this.appDetailShow = false;
            this.mainContentAlpha = 1;
        });
    }

    @Builder
    private AppDetailCover(): void {
        AppDetailPage({
            routeTarget: this.appDetailTarget,
            onClose: (): void => this.closeAppDetail(),
        })
    }

    private async handlePageShow(): Promise<void> {
        this.selectedIndex = Math.max(MAIN_TAB_S_STATION, Math.min(MAIN_TAB_MY,
            consumeMainTab(this.selectedIndex)));
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
        const detail = AppStorage.get<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET) ?? {};
        if (detail.appId || detail.packageName) {
            this.appDetailTarget = detail;
            this.appDetailShow = true;
            this.mainContentAlpha = 0;
        }
    }

    onPageShow(): void {
        this.handlePageShow();
    }

    onBackPress(): boolean {
        if (this.appDetailShow) {
            this.closeAppDetail();
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
            return true;
        }
        return false;
    }

    @Builder
    destinationBuilder(name: string, param: Object) {
        if (name === 'AboutWebPage') {
            AboutWebBuilder(param as AboutWebParams)
        } else if (name === 'AppLogPage') {
            AppLogBuilder()
        } else if (name === 'HTMLPage') {
            HTMLBuilder()
        } else if (name === 'TutorialPage') {
            TutorialPageBuilder()
        } else if (name === 'FriendPage') {
            FriendPageBuilder()
        } else if (name === 'FriendPageWeb') {
            FriendPageWebBuilder(param as FriendWebParams)
        } else if (name === 'DeveloperPage') {
            DeveloperPage()
        }
    }

    @Builder
    private WarningSheet(): void {
        warn({ isShow: this.showWarning, requiresConfirmation: this.warningRequiresConfirmation })
    }

    build() {
        HdsNavigation(this.pageStack) {
            Stack() {
                HdsTabs({ controller: this.tabsController, index: this.selectedIndex }) {
                    TabContent() {
                        SStationPage({
                            command: this.sStationCommand,
                            commandVersion: this.sStationCommandVersion,
                            active: this.selectedIndex === MAIN_TAB_S_STATION,
                            onDetailOpenChanged: (open: boolean): void => {
                                this.sStationDetailOpen = open;
                            },
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[0].icon, this.tabs()[0].label))
                    .opacity(this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.92)
                    .scale({ x: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985,
                        y: this.selectedIndex === MAIN_TAB_S_STATION ? 1 : 0.985 })
                    .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
                    .accessibilityText('S站标签页')

                    TabContent() {
                        HomePage({
                            scrollToTopVersion: this.mainActionIndex === MAIN_TAB_HOME ? this.mainActionVersion : 0,
                            onOpenAppDetail: (target: AppRouteTarget): void => this.showAppDetail(target),
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[1].icon, this.tabs()[1].label))
                    .opacity(this.selectedIndex === MAIN_TAB_HOME ? 1 : 0.92)
                    .scale({ x: this.selectedIndex === MAIN_TAB_HOME ? 1 : 0.985,
                        y: this.selectedIndex === MAIN_TAB_HOME ? 1 : 0.985 })
                    .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
                    .accessibilityText('首页标签页')

                    TabContent() {
                        AppsPage({
                            selectedIndexes: $appsViewIndexes,
                            scrollToTopVersion: this.mainActionIndex === MAIN_TAB_APPS ? this.mainActionVersion : 0,
                            requestVersion: this.searchRequestVersion,
                            searchCommandVersion: this.appsSearchCommandVersion,
                            searchCloseVersion: this.appsSearchCloseVersion,
                            onSearchOpenChanged: (open: boolean): void => {
                                this.appsSearchOpen = open;
                            },
                            onOpenAppDetail: (target: AppRouteTarget): void => this.showAppDetail(target),
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[2].icon, this.tabs()[2].label))
                    .opacity(this.selectedIndex === MAIN_TAB_APPS ? 1 : 0.92)
                    .scale({ x: this.selectedIndex === MAIN_TAB_APPS ? 1 : 0.985,
                        y: this.selectedIndex === MAIN_TAB_APPS ? 1 : 0.985 })
                    .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
                    .accessibilityText('应用详情标签页')

                    TabContent() {
                        MyPage({
                            scrollToTopVersion: this.mainActionIndex === MAIN_TAB_MY ? this.mainActionVersion : 0,
                            onShowWarning: (): void => {
                                this.warningRequiresConfirmation = false;
                                this.showWarning = true;
                            },
                        })
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[3].icon, this.tabs()[3].label))
                    .opacity(this.selectedIndex === MAIN_TAB_MY ? 1 : 0.92)
                    .scale({ x: this.selectedIndex === MAIN_TAB_MY ? 1 : 0.985,
                        y: this.selectedIndex === MAIN_TAB_MY ? 1 : 0.985 })
                    .animation({ curve: curves.springMotion(0.62, 0.88), duration: 260 })
                    .accessibilityText('我的标签页')
                }
                .barPosition(BarPosition.End)
                .barWidth(280)
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
                    setMainTab(index);
                    const continuation = getContinuationState();
                    if (continuation.routeName !== CONTINUATION_ROUTE_DETAIL) {
                        setContinuationView(index, 0);
                    }
                    if (this.vibrationLevel > 0) {
                        vibration.dotVibration();
                    }
                })
                .accessibilityText('主界面四个标签页，依次为S站、首页、应用详情和我的')
                .onAppear((): void => this.preloadSStation())

            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.background'))
            .opacity(this.mainContentAlpha)
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
                systemMaterialEffect: this.selectedIndex !== MAIN_TAB_APPS ? {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: this.immersiveMaterialLevel,
                } : undefined,
            },
            content: {
                title: {
                    mainTitle: this.mainTitle(),
                    mainTitleSize: TitleSize.TITLE_S,
                },
                menu: {
                    value: this.titleMenuItems(),
                },
                bottomBuilder: this.selectedIndex === MAIN_TAB_APPS && !this.appsSearchOpen ? {
                    builder: (): void => {
                        this.appsTitleSegment();
                    },
                    height: 52,
                    showType: BottomBuilderShowType.DIRECTLY_SHOW,
                } : undefined,
            },
        })
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .accessibilityText('Dashboard应用导航')
        .bindContentCover(this.appDetailShow, this.AppDetailCover(), {
            modalTransition: ModalTransition.NONE,
            onWillDismiss: (_action: DismissContentCoverAction): void => {
                this.closeAppDetail();
            },
        })
        .bindSheet($$this.showWarning, this.WarningSheet(), {
            title: { title: '重要提示', subtitle: '使用前请阅读以下说明' },
            height: SheetSize.LARGE,
            detents: [SheetSize.LARGE],
            preferType: SheetType.BOTTOM,
            showClose: !this.warningRequiresConfirmation,
            dragBar: true,
            maskColor: $r('app.color.v3_scrim'),
            blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
            scrollSizeMode: ScrollSizeMode.CONTINUOUS,
            onWillDismiss: (action: DismissSheetAction): void => {
                if (this.warningRequiresConfirmation) {
                    this.preventWarningDismiss();
                    return;
                }
                action.dismiss();
            },
        })
    }
}
