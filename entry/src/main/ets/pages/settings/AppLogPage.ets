import { UPDATE_LOGS } from '../../config/updateLogs';
import type { UpdateLog } from '../../models/updateLogTypes';
import { UpdateLogCard } from '../../components/settings/UpdateLogCard';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import {
    HdsNavDestination,
    HdsNavDestinationTitleMode,
    ScrollEffectType,
} from '@kit.UIDesignKit';
import { vibration } from '../../utils/device/vibration';
import { popPathSafely } from '../../ui/navigation/safeNavigation';
import { showToastSafely } from '../../ui/feedback/safeUi';
import { cancelStaggerEnterAnimation, pageTransition, startStaggerEnterAnimation } from '../../ui/animation/motion';
import { scrollByAxis } from '../../ui/interaction/scroll';
import {
    HDS_MATERIAL_LEVEL_GENTLE,
    HDS_MATERIAL_TYPE_ADAPTIVE,
    HDS_TITLE_SIZE_SMALL,
    SUPPORTS_HARMONY_API_23,
} from '../../config/platformCompatibility';

@Component
struct AppLogPage {
    @Consume('pageStack') pageStack: NavPathStack;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
    @State private animStep: number = 0;
    private scroller: Scroller = new Scroller();
    private enterAnimationTimers: number[] = [];
    @State private showBeta: boolean = true;
    @State private showRc: boolean = true;
    @State private showRelease: boolean = true;
    @State private filteredLogs: UpdateLog[] = [];

    aboutToAppear(): void {
        this.updateFilteredLogs();
    }

    private startPageAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    toggleFilter(type: "beta" | "rc" | "release"): void {
        if(this.vibrationLevel > 0) vibration.dotVibration()
        switch (type) {
            case "beta":
                this.showBeta = !this.showBeta;
                break;
            case "rc":
                this.showRc = !this.showRc;
                break;
            case "release":
                this.showRelease = !this.showRelease;
                break;
        }
        this.updateFilteredLogs();
    }

    build() {
        HdsNavDestination() {
            Scroll(this.scroller) {
                Column() {
                    Blank().height(100).width('100%')
                    Column() {
                        ForEach(this.filteredLogs, (log: UpdateLog, index: number) => {
                            UpdateLogCard({ log, animStep: this.animStep, enterStep: Math.min(index + 1, 5) })
                        })
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)

                    if (this.filteredLogs.length === 0) {
                        Column() {
                            Image($r("app.media.empty"))
                                .borderRadius($r("sys.float.corner_radius_level6"))
                                .accessibilityText('没有符合筛选条件的更新日志')
                            Text("暂无符合条件的日志")
                                .fontWeight(800)
                                .fontSize(30)
                                .margin({ top: 10 })
                                .fontColor($r("app.color.diff_content"))
                        }
                        .width("100%")
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center)
                        .accessibilityGroup(true)
                        .accessibilityText('暂无符合条件的日志');
                    }
                }
                .margin({ bottom: 20 })
                .width("100%")
                .alignItems(HorizontalAlign.Center)
            }
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
            .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
            .backgroundColor($r("app.color.backcolor"))
            .accessibilityText('可滚动的应用更新日志')
            .onAppear((): void => this.startPageAnimation())
        }
        .onBackPressed(() => {
            if(this.vibrationLevel > 0) vibration.backVibration()
            return false;
        })
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
        .transition(pageTransition())
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
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
                        backgroundColor: Color.Transparent,
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
                systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
                    materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
                    materialLevel: this.immersiveMaterialLevel
                } : undefined
            },
            content: {
                title: {
                    mainTitle: "App更新日志",
                    mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "筛选Beta日志",
                                icon: this.showBeta ? $r("app.media.betaON") : $r("app.media.beta"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("beta");
                                    showToastSafely(this.prompt, this.showBeta ? '打开Beta版本日志' : '关闭Beta版本日志', 500, 'AppLog');
                                },
                            },
                        },
                        {
                            content: {
                                label: "筛选RC日志",
                                icon: this.showRc ? $r("app.media.rcON") : $r("app.media.rc"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("rc");
                                    showToastSafely(this.prompt, this.showRc ? '打开ReleaseCandidate版本日志' : '关闭ReleaseCandidate版本日志', 500, 'AppLog');
                                },
                            },
                        },
                        {
                            content: {
                                label: "筛选正式版日志",
                                icon: this.showRelease
                                    ? $r("app.media.releaseON")
                                    : $r("app.media.release"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("release");
                                    showToastSafely(this.prompt, this.showRelease ? '打开正式版日志' : '关闭正式版日志', 500, 'AppLog');
                                },
                            },
                        },
                    ],
                },
                backIcon: {
                    action: () => {
                        if(this.vibrationLevel > 0) vibration.backVibration()
                        popPathSafely(this.pageStack, 'pages/more/AppLogPage')
                    },
                },
            },
        })
        .accessibilityText('应用更新日志导航页');

    }

    private updateFilteredLogs(): void {
        this.filteredLogs = UPDATE_LOGS.filter((log) => {
            switch (log.type) {
                case "beta":
                    return this.showBeta;
                case "rc":
                    return this.showRc;
                case "release":
                    return this.showRelease;
                default:
                    return true;
            }
        });
    }
}

@Builder
export function AppLogBuilder(){
    AppLogPage()
}
