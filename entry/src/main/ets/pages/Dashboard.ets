import {
    BlurStrategy,
    HdsNavigation,
    HdsNavigationTitleMode,
    HdsTabs,
    HdsTabsController,
    TitleSize,
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { getFirstLaunch } from '../common/storage';
import { consumeMainTab, setContinuationView, setMainTab } from '../common/appState';
import { APP_STATE_KEY_DETAIL_TARGET, MAIN_TAB_DEFAULT } from '../common/constants';
import type { AppRouteTarget } from '../common/types';
import { warn } from '../component/warn';
import { vibration } from '../common/vibration';
import { SStationPage } from './main/SStationPage';
import { HomePage } from './main/HomePage';
import { SearchPage } from './main/SearchPage';
import { AppsPage } from './main/AppsPage';
import { MyPage } from './main/MyPage';
import { AppDetailPage } from './detail/AppDetailPage';
import { AboutWebBuilder } from './more/aboutWeb';
import { AppLogBuilder } from './more/appLog';
import { HTMLBuilder } from './more/htmlPage';
import { TutorialPageBuilder } from './more/tutorial';
import { FriendPageBuilder } from './more/friend';
import { FriendPageWebBuilder } from './more/friendWeb';

interface MainTab {
    label: string;
    icon: Resource;
}

@Entry({ useSharedStorage: true })
@Component
struct Dashboard {
    @Provide('pageStack') pageStack: NavPathStack = new NavPathStack();
    private tabsController: HdsTabsController = new HdsTabsController();
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    @StorageLink('immersiveTextureON') private immersiveTexture: boolean = false;
    @State private selectedIndex: number = MAIN_TAB_DEFAULT;
    @State private searchRequestVersion: number = 0;
    @State private showWarning: boolean = false;

    private tabs(): MainTab[] {
        return [
            { label: 'S站', icon: $r('app.media.api') },
            { label: '首页', icon: $r('app.media.startIcon') },
            { label: '搜索', icon: $r('app.media.search') },
            { label: '应用总表', icon: $r('app.media.log') },
            { label: '我的', icon: $r('app.media.user') },
        ];
    }

    private async handlePageShow(): Promise<void> {
        this.selectedIndex = consumeMainTab(this.selectedIndex);
        this.searchRequestVersion++;
        try {
            this.showWarning = await getFirstLaunch();
        } catch (error) {
            console.warn('[Dashboard][pages/Dashboard][WARN]', `[v3] 首启状态读取失败: ${JSON.stringify(error)}`);
        }
        const detail = AppStorage.get<AppRouteTarget>(APP_STATE_KEY_DETAIL_TARGET) ?? {};
        if (detail.appId || detail.packageName) {
            try {
                const existing = this.pageStack.getIndexByName('AppDetailPage');
                if (existing.length > 0) {
                    this.pageStack.removeByName('AppDetailPage');
                }
                setTimeout(() => {
                    try {
                        this.pageStack.pushPathByName('AppDetailPage', null);
                    } catch (error) {
                        console.error('[Dashboard][pages/Dashboard][ERROR]', `恢复应用详情失败: ${JSON.stringify(error)}`);
                    }
                }, 0);
            } catch (error) {
                console.error('[Dashboard][pages/Dashboard][ERROR]', `检查详情导航栈失败: ${JSON.stringify(error)}`);
            }
        }
    }

    onPageShow(): void {
        this.handlePageShow();
    }

    @Builder
    destinationBuilder(name: string) {
        if (name === 'AppDetailPage') {
            AppDetailPage()
        } else if (name === 'AboutWebPage') {
            AboutWebBuilder()
        } else if (name === 'AppLogPage') {
            AppLogBuilder()
        } else if (name === 'HTMLPage') {
            HTMLBuilder()
        } else if (name === 'TutorialPage') {
            TutorialPageBuilder()
        } else if (name === 'FriendPage') {
            FriendPageBuilder()
        } else if (name === 'FriendPageWeb') {
            FriendPageWebBuilder()
        }
    }

    build() {
        HdsNavigation(this.pageStack) {
            Stack() {
                HdsTabs({ controller: this.tabsController, index: this.selectedIndex }) {
                    TabContent() {
                        SStationPage()
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[0].icon, this.tabs()[0].label))
                    .accessibilityText('S站标签页')

                    TabContent() {
                        HomePage()
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[1].icon, this.tabs()[1].label))
                    .accessibilityText('首页标签页')

                    TabContent() {
                        SearchPage({ requestVersion: this.searchRequestVersion })
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[2].icon, this.tabs()[2].label))
                    .accessibilityText('搜索标签页')

                    TabContent() {
                        AppsPage()
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[3].icon, this.tabs()[3].label))
                    .accessibilityText('应用总表标签页')

                    TabContent() {
                        MyPage()
                    }
                    .tabBar(new BottomTabBarStyle(this.tabs()[4].icon, this.tabs()[4].label))
                    .accessibilityText('我的标签页')
                }
                .barPosition(BarPosition.End)
                .vertical(false)
                .barOverlap(true)
                .blurStrategy(BlurStrategy.ENABLE)
                .animation({ duration: 0 })
                .barFloatingStyle({
                    barBottomMargin: 18,
                    lightColor: $r('app.color.light_color'),
                    gradientMask: { maskColor: $r('app.color.mask_color'), maskHeight: 84 },
                    systemMaterialEffect: this.immersiveTexture ? {
                        materialType: hdsMaterial.MaterialType.IMMERSIVE,
                        materialLevel: hdsMaterial.MaterialLevel.EXQUISITE,
                    } : undefined,
                })
                .onChange((index: number) => {
                    this.selectedIndex = index;
                    setMainTab(index);
                    setContinuationView(index, 0);
                    if (this.vibrationEnabled) {
                        vibration.dotVibration();
                    }
                })
                .width('100%')
                .height('100%')
                .accessibilityText('主界面五个标签页')

                if (this.showWarning) {
                    Column()
                        .width('100%')
                        .height('100%')
                        .backgroundColor($r('app.color.v3_scrim'))
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .accessibilityText('首次启动重要提示背景')
                    warn({ isShow: this.showWarning })
                }
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.background'))
            .accessibilityGroup(true)
            .accessibilityText('Dashboard应用看板主界面')
        }
        .mode(NavigationMode.Stack)
        .navDestination(this.destinationBuilder)
        .titleMode(HdsNavigationTitleMode.MINI)
        .hideBackButton(true)
        .divider({ color: $r('app.color.border') })
        .titleBar({
            style: {
                scrollEffectOpts: { enableScrollEffect: false },
                originalStyle: {
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('app.color.diff_content'),
                        },
                    },
                },
            },
            content: {
                title: {
                    mainTitle: 'Dashboard应用看板',
                    mainTitleSize: TitleSize.TITLE_S,
                },
            },
        })
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .accessibilityText('Dashboard应用导航')
    }
}
