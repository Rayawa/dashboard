import { common, Want } from '@kit.AbilityKit';
import { PromptAction, TextModifier } from '@kit.ArkUI';
import { HdsListItemCard, IconSize, PrefixIcon, SuffixCustomBuilder } from '@kit.UIDesignKit';
import { SettingsPanel } from '../../component/SettingsPanel';
import {
    APP_VERSION,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
    LIST_ITEM_PREFIX_MARGIN,
    LIST_ITEM_SUFFIX_MARGIN,
    LIST_PAGE_HORIZONTAL_PADDING,
    LIST_SECTION_CONTENT_GAP,
    LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
    LIST_SECTION_SPACING,
    LIST_SECTION_TITLE_START_PADDING,
    mainPage,
    MAIN_TAB_MY,
    MEOW_CHANNEL_URL,
    MIIT_ICP_URL,
    ROUTE_APP_LOG,
    ROUTE_DEVELOPER,
    ROUTE_FRIEND_LINKS,
    ROUTE_HTML_PAGE,
    ROUTE_TUTORIAL,
    ROUTE_WEB_PAGE,
    SBaseURL,
} from '../../common/constants';
import { getContinuationState, setContinuationView } from '../../common/appState';
import { WebViewParam } from '../../common/types';
import URL from '../../common/url';
import { showToastSafely } from '../../common/safeUi';
import { EmptyPathParam } from '../../common/safeNavigation';
import { vibration } from '../../common/vibration';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { scrollByAxis } from '../../common/scroll';

interface MoreItem {
    title: string;
    icon: Resource;
    opensExternal?: boolean;
    action: () => void;
}

@Component
struct MoreRow {
    item: MoreItem = { title: '', icon: $r('app.media.info'), action: () => {} };
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;

    @Builder
    private rightSuffix(): void {
        Image($r('app.media.right'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .accessibilityText('进入')
    }

    @Builder
    private externalSuffix(): void {
        Image($r('app.media.share'))
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
            .accessibilityText('直接打开外部链接')
    }

    build() {
        HdsListItemCard({
            prefixItem: new PrefixIcon({
                iconSize: IconSize.SYSTEM_ICON,
                iconValue: { image: this.item.icon },
            }),
            textItem: {
                primaryText: {
                    text: this.item.title,
                    modifier: new TextModifier()
                        .fontSize(16)
                        .fontColor($r('app.color.v3_text_primary')),
                },
            },
            suffixItem: this.item.opensExternal ? new SuffixCustomBuilder(() => {
                this.externalSuffix()
            }) : new SuffixCustomBuilder(() => {
                this.rightSuffix()
            }),
            onClick: () => {
                if (this.vibrationLevel > 0) vibration.dotVibration();
                this.item.action();
            },
            cardHeight: 54,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText: `进入${this.item.title}`,
            },
        })
    }
}

@Component
export struct MyPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    @Prop @Watch('onActiveChanged') active: boolean = false;
    onShowWarning?: () => void;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @State private versionTapCount: number = 0;
    @State private contentWidth: number = 0;
    @State private animStep: number = 0;
    private versionTapTimer: number = -1;
    private restoredScroll: boolean = false;
    private enterAnimationPlayed: boolean = false;
    private enterAnimationTimers: number[] = [];
    private restoreScrollTimer: number = -1;

    private onActiveChanged(): void {
        if (this.active) this.startPageAnimationOnce();
    }

    private startPageAnimationOnce(): void {
        if (this.enterAnimationPlayed) return;
        this.enterAnimationPlayed = true;
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
        if (this.versionTapTimer >= 0) {
            clearTimeout(this.versionTapTimer);
            this.versionTapTimer = -1;
        }
        if (this.restoreScrollTimer >= 0) {
            clearTimeout(this.restoreScrollTimer);
            this.restoreScrollTimer = -1;
        }
    }

    private requiredStep(group: string): number {
        if (this.contentWidth >= 840) {
            if (group === 'identity' || group === 'information' || group === 'settings') return 1;
            if (group === 'more') return 2;
            return 3;
        }
        if (group === 'identity') return 1;
        if (group === 'settings') return 2;
        if (group === 'more') return 3;
        if (group === 'help') return 4;
        return 5;
    }

    private onScrollToTopVersionChanged(): void {
        if (this.scrollToTopVersion <= 0) {
            return;
        }
        try {
            this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
        } catch (error) {
            console.warn('[Dashboard][pages/main/MyPage][WARN]', `返回顶部失败: ${JSON.stringify(error)}`);
        }
    }

    private vibrate(): void {
        if (this.vibrationLevel > 0) vibration.dotVibration();
    }

    private async openExternal(uri: string, label: string): Promise<void> {
        try {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            await context.startAbility({
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                uri,
            } as Want);
        } catch (error) {
            console.error('[Dashboard][pages/main/MyPage][ERROR]', `打开${label}失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, `无法打开${label}`, 1600, 'V3My');
        }
    }

    private pushPage(name: string, param: Object = new EmptyPathParam()): void {
        try {
            this.pageStack.pushPathByName(name, param);
        } catch (error) {
            console.error('[Dashboard][pages/main/MyPage][ERROR]', `打开${name}失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开该页面，请重试', 1800, 'MyPage');
        }
    }

    private moreItems(): MoreItem[] {
        return [
            {
                title: '项目网站首页',
                icon: $r('app.media.app_icon'),
                opensExternal: true,
                action: () => this.openExternal(mainPage.toString(), '网站首页'),
            },
            {
                title: '订阅MeoW频道',
                icon: $r('app.media.MeoW'),
                opensExternal: true,
                action: () => this.openExternal(MEOW_CHANNEL_URL.toString(), 'MeoW频道'),
            },
            {
                title: 'API 文档说明',
                icon: $r('app.media.api'),
                action: () => {
                    const url = new URL('docs', SBaseURL);
                    this.pushPage(ROUTE_WEB_PAGE, new WebViewParam(url.toString(), 'API 文档说明'));
                },
            },
            {
                title: '友情链接',
                icon: $r('app.media.link'),
                action: () => this.pushPage(ROUTE_FRIEND_LINKS),
            },
            {
                title: '赞助我们',
                icon: $r('app.media.sponsor'),
                opensExternal: true,
                action: () => this.openExternal('https://afdian.com/a/shenjack', '爱发电赞助页面'),
            },
        ];
    }

    private helpItems(): MoreItem[] {
        return [
            {
                title: '重要提示',
                icon: $r('app.media.attention'),
                action: () => {
                    if (this.onShowWarning) this.onShowWarning();
                },
            },
            {
                title: '查看教程',
                icon: $r('app.media.tutorial'),
                action: () => this.pushPage(ROUTE_TUTORIAL),
            },
            {
                title: '更新日志',
                icon: $r('app.media.app_log'),
                action: () => this.pushPage(ROUTE_APP_LOG),
            },
            {
                title: '隐私政策',
                icon: $r('app.media.privacy'),
                action: () => this.pushPage(
                    ROUTE_HTML_PAGE,
                    new WebViewParam($rawfile('privacy.html'), '隐私政策'),
                ),
            },
        ];
    }

    private tapVersion(): void {
        this.versionTapCount++;
        if (this.versionTapTimer >= 0) {
            clearTimeout(this.versionTapTimer);
        }
        if (this.versionTapCount >= 10) {
            this.versionTapCount = 0;
            this.pushPage(ROUTE_DEVELOPER);
            return;
        }
        this.versionTapTimer = setTimeout((): void => {
            this.versionTapCount = 0;
        }, 2500);
    }

    private async openIcp(): Promise<void> {
        try {
            showToastSafely(this.prompt, '正在跳转…', 600, 'V3My');
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            await context.startAbility({
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                uri: MIIT_ICP_URL.toString(),
            } as Want);
        } catch (error) {
            console.error('[Dashboard][pages/main/MyPage][ERROR]', `打开备案页面失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '打开备案页面失败', 1500, 'V3My');
        }
    }

    @Builder
    private appIdentity(): void {
        Column({ space: LIST_SECTION_CONTENT_GAP }) {
            Image($r('app.media.app_icon'))
                .width(100)
                .height(100)
                .borderRadius(22)
                .accessibilityText('Dashboard应用看板图标')
                .margin({ bottom: 10 })
            Text('Dashboard应用看板')
                .fontSize(30)
                .fontWeight(800)
                .fontColor($r('app.color.diff_content'))
                .textAlign(TextAlign.Center)
                .accessibilityText('Dashboard应用看板')
            Text('Harmony Dashboard')
                .fontSize(20)
                .fontWeight(600)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .accessibilityText('Harmony Dashboard')
        }
        .width('100%')
        .padding({ top: 18, bottom: 18, left: 12, right: 12 })
        .opacity(this.animStep >= this.requiredStep('identity') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('identity') ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText('Dashboard应用图标和名称')
    }

    @Builder
    private versionInformation(): void {
        Column({ space: 5 }) {
            Text(`版本 ${APP_VERSION}`)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .onClick(() => {
                    this.vibrate();
                    this.tapVersion();
                })
                .accessibilityText(`版本${APP_VERSION}，连续点击十次打开开发者信息`)
            Text('Designed & Developed by Ray Chen (Rayawa)')
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .accessibilityText('Designed and Developed by Ray Chen Rayawa')
            Text('Copyright © 2026. All rights reserved.')
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .accessibilityText('版权所有2026')
            Text('本应用备案域名：rayawa.top')
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .accessibilityText('本应用备案域名rayawa点top')
            Text('京ICP备2025153453号')
                .fontSize(12)
                .fontColor($r('app.color.diff_content'))
                .decoration({ type: TextDecorationType.Underline, color: $r('app.color.diff_content') })
                .onClick(() => {
                    this.vibrate();
                    this.openIcp();
                })
                .accessibilityText('京ICP备2025153453号，点击打开工信部备案页面')
        }
        .width('100%')
        .padding({ top: 14 })
        .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('information') ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText('版本版权和备案信息')
    }

    @Builder
    private actionSection(title: string, items: MoreItem[]): void {
        Column({ space: 8 }) {
            Text(title)
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.diff_content'))
                .width('100%')
                .padding({ left: LIST_SECTION_TITLE_START_PADDING })
                .accessibilityText(title)
            Column() {
                ForEach(items, (item: MoreItem, index: number) => {
                    MoreRow({ item })
                    if (index < items.length - 1) {
                        Divider()
                            .color($r('app.color.v3_chart_grid'))
                            .margin({
                                left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                                right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                            })
                            .accessibilityText(`${title}栏目分隔线`)
                    }
                }, (item: MoreItem) => item.title)
            }
            .width('100%')
            .borderRadius(16)
            .backgroundColor($r('app.color.v3_surface'))
            .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetY: 2 })
            .clip(true)
            .accessibilityGroup(true)
            .accessibilityText(`${title}栏目`)
        }
        .width('100%')
        .opacity(this.animStep >= this.requiredStep(title === '更多' ? 'more' : 'help') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep(title === '更多' ? 'more' : 'help') ? 0 : 20 })
    }

    @Builder
    private settingsSection(): void {
        Column({ space: 8 }) {
            Text('设置')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.diff_content'))
                .width('100%')
                .padding({ left: LIST_SECTION_TITLE_START_PADDING })
                .accessibilityText('设置')
            SettingsPanel({ active: this.active })
        }
        .width('100%')
        .opacity(this.animStep >= this.requiredStep('settings') ? 1 : 0)
        .translate({ y: this.animStep >= this.requiredStep('settings') ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText('设置')
    }

    @Builder
    private settingsAndLinks(): void {
        Column({ space: LIST_SECTION_SPACING }) {
            this.settingsSection()
            Divider()
                .margin({
                    top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
                    bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
                })
                .color($r('app.color.border'))
                .opacity(this.animStep >= this.requiredStep('more') ? 1 : 0)
                .accessibilityText('设置与更多栏目分隔线')
            this.actionSection('更多', this.moreItems())
            Divider()
                .margin({
                    top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
                    bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
                })
                .color($r('app.color.border'))
                .opacity(this.animStep >= this.requiredStep('help') ? 1 : 0)
                .accessibilityText('更多与帮助栏目分隔线')
            this.actionSection('帮助', this.helpItems())
        }
        .width('100%')
        .accessibilityText('设置、更多与帮助列表')
    }

    private restoreScrollPosition(): void {
        if (this.restoredScroll) return;
        this.restoredScroll = true;
        const continuation = getContinuationState();
        if (continuation.mainTab !== MAIN_TAB_MY || continuation.routeName !== CONTINUATION_ROUTE_MAIN ||
            continuation.scrollDistance <= 0) return;
        this.restoreScrollTimer = setTimeout((): void => {
            this.restoreScrollTimer = -1;
            try {
                this.scroller.scrollTo({
                    xOffset: 0,
                    yOffset: continuation.scrollDistance,
                    animation: { duration: 0 },
                });
            } catch (error) {
                console.warn('[Dashboard][pages/main/MyPage][WARN]',
                    `恢复滚动位置失败: ${JSON.stringify(error)}`);
            }
        }, 80);
    }

    private saveScrollPosition(): void {
        try {
            setContinuationView(MAIN_TAB_MY, this.scroller.currentOffset().yOffset);
        } catch (error) {
            console.warn('[Dashboard][pages/main/MyPage][WARN]',
                `保存滚动位置失败: ${JSON.stringify(error)}`);
        }
    }

    build() {
        Stack() {
            if (this.contentWidth >= 840) {
                Column() {
                    Row({ space: 16 }) {
                        Column() {
                            Blank()
                                .height(100)
                                .width('100%')
                            Column({ space: 14 }) {
                                this.appIdentity()
                                Divider()
                                    .color($r('app.color.border'))
                                    .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
                                    .accessibilityText('应用名称与版本信息分隔线')
                                this.versionInformation()
                            }
                            .layoutWeight(1)
                            .width('100%')
                            .justifyContent(FlexAlign.Center)
                        }
                        .layoutWeight(4)
                        .height('100%')
                        .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
                        .accessibilityGroup(true)
                        .accessibilityText('固定显示的应用名称和版本信息')

                        Divider()
                            .vertical(true)
                            .height('100%')
                            .color($r('app.color.border'))
                            .accessibilityText('应用信息与功能列表分隔线')

                        Scroll(this.scroller) {
                            Column() {
                                Blank().height(110).width('100%')
                                this.settingsAndLinks()
                                Blank().height(110).width('100%')
                            }
                            .width('100%')
                            .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
                            .onAppear(() => this.restoreScrollPosition())
                        }
                        .layoutWeight(6)
                        .height('100%')
                        .scrollBar(BarState.Off)
                        .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
                        .onDidScroll((): void => this.saveScrollPosition())
                        .accessibilityText('可滚动的设置、更多与帮助列表')
                    }
                    .layoutWeight(1)
                    .width('100%')
                    .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                    .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
                    .alignItems(VerticalAlign.Top)
                    .accessibilityGroup(true)
                    .accessibilityText('左侧固定应用信息，右侧可滚动功能列表')
                }
                .width('100%')
                .height('100%')
                .alignItems(HorizontalAlign.Center)
                .backgroundColor($r('app.color.background'))
            } else {
                Scroll(this.scroller) {
                    Column({ space: LIST_SECTION_SPACING }) {
                        Blank().height(100).width('100%')
                        this.appIdentity()
                        Divider()
                            .color($r('app.color.border'))
                            .opacity(this.animStep >= this.requiredStep('settings') ? 1 : 0)
                            .accessibilityText('应用信息与功能列表分隔线')
                        this.settingsAndLinks()
                        Divider()
                            .color($r('app.color.border'))
                            .opacity(this.animStep >= this.requiredStep('information') ? 1 : 0)
                            .accessibilityText('功能列表与版本信息分隔线')
                        this.versionInformation()
                        Blank().height(110).width('100%')
                    }
                    .width('100%')
                    .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                    .padding({ left: LIST_PAGE_HORIZONTAL_PADDING, right: LIST_PAGE_HORIZONTAL_PADDING })
                    .onAppear(() => this.restoreScrollPosition())
                }
                .width('100%')
                .height('100%')
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
                .onDidScroll((): void => this.saveScrollPosition())
                .backgroundColor($r('app.color.background'))
                .accessibilityText('可滚动的我的页面')
            }

        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
        .onAreaChange((_oldValue: Area, newValue: Area): void => {
            this.contentWidth = Number(newValue.width);
        })
        .onAppear(() => {
            if (this.active) this.startPageAnimationOnce();
        })
        .accessibilityText('我的与关于页面')
    }
}
