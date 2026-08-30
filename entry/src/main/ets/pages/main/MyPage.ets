import { common, Want } from '@kit.AbilityKit';
import { PromptAction } from '@kit.ArkUI';
import { settings } from '../../component/settings';
import { contact } from '../../component/contact';
import { warn } from '../../component/warn';
import {
    APP_BUILD_NUMBER,
    APP_VERSION,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    mainPage,
    MAIN_TAB_MY,
    MEOW_CHANNEL_URL,
    MIIT_ICP_URL,
    SBaseURL,
} from '../../common/constants';
import { getContinuationState, setContinuationView } from '../../common/appState';
import { WebViewParam } from '../../common/types';
import URL from '../../common/url';
import { showToastSafely } from '../../common/safeUi';
import { EmptyPathParam } from '../../common/safeNavigation';
import { vibration } from '../../common/vibration';

interface MoreItem {
    title: string;
    icon: Resource;
    action: () => void;
}

@Component
struct MoreRow {
    item: MoreItem = { title: '', icon: $r('app.media.info'), action: () => {} };
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    build() {
        Row({ space: 12 }) {
            Image(this.item.icon)
                .width(24)
                .height(24)
                .objectFit(ImageFit.Contain)
                .accessibilityText(`${this.item.title}图标`)
            Text(this.item.title)
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .layoutWeight(1)
                .accessibilityText(this.item.title)
            Image($r('app.media.right'))
                .width(16)
                .height(16)
                .objectFit(ImageFit.Contain)
                .accessibilityText('进入')
        }
        .width('100%')
        .height(54)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
            if (this.vibrationEnabled) vibration.dotVibration();
            this.item.action();
        })
        .accessibilityGroup(true)
        .accessibilityText(`进入${this.item.title}`)
    }
}

@Component
export struct MyPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    @State private showWarning: boolean = false;
    @State private showContact: boolean = false;
    private restoredScroll: boolean = false;

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
        if (this.vibrationEnabled) vibration.dotVibration();
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
                title: '重要提示',
                icon: $r('app.media.attention'),
                action: () => this.showWarning = true,
            },
            {
                title: '网站首页',
                icon: $r('app.media.app_icon'),
                action: () => this.openExternal(mainPage.toString(), '网站首页'),
            },
            {
                title: 'MeoW 频道',
                icon: $r('app.media.MeoW'),
                action: () => this.openExternal(MEOW_CHANNEL_URL.toString(), 'MeoW频道'),
            },
            {
                title: '查看教程',
                icon: $r('app.media.tutorial'),
                action: () => this.pushPage('TutorialPage'),
            },
            {
                title: '友情链接',
                icon: $r('app.media.sponsor'),
                action: () => this.pushPage('FriendPage'),
            },
            {
                title: 'API 文档说明',
                icon: $r('app.media.api'),
                action: () => {
                    const url = new URL('docs', SBaseURL);
                    this.pushPage('AboutWebPage', new WebViewParam(url.toString(), 'API 文档说明'));
                },
            },
            {
                title: '更新日志',
                icon: $r('app.media.app_log'),
                action: () => this.pushPage('AppLogPage'),
            },
            {
                title: '联系我们',
                icon: $r('app.media.contact'),
                action: () => this.showContact = true,
            },
            {
                title: '隐私政策',
                icon: $r('app.media.privacy'),
                action: () => this.pushPage(
                    'HTMLPage',
                    new WebViewParam($rawfile('privacy.html'), '隐私政策'),
                ),
            },
        ];
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

    build() {
        Stack() {
            Scroll(this.scroller) {
                Column({ space: 14 }) {
                    Blank().height(40).width('100%')
                    Column({ space: 8 }) {
                        Image($r('app.media.app_icon'))
                            .width(92)
                            .height(92)
                            .borderRadius(22)
                            .accessibilityText('Dashboard应用看板图标')
                        Text('鸿蒙应用看板')
                            .fontSize(22)
                            .fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.diff_content'))
                            .accessibilityText('鸿蒙应用看板')
                        Text('Harmony Dashboard')
                            .fontSize(15)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('Harmony Dashboard')
                    }
                    .width('100%')
                    .padding({ bottom: 10 })
                    .accessibilityGroup(true)
                    .accessibilityText('关于应用')

                    Divider()
                        .margin({ top: 4, bottom: 4 })
                        .color($r('app.color.border'))
                        .accessibilityText('应用信息与设置分隔线')

                    Text('设置')
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.diff_content'))
                        .width('100%')
                        .padding({ left: 4 })
                        .accessibilityText('设置')
                    settings()

                    Divider()
                        .margin({ top: 6, bottom: 4 })
                        .color($r('app.color.border'))
                        .accessibilityText('设置与更多分隔线')

                    Text('更多')
                        .fontSize(14)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.diff_content'))
                        .width('100%')
                        .padding({ left: 4, top: 6 })
                        .accessibilityText('更多')
                    Column() {
                        ForEach(this.moreItems(), (item: MoreItem, index: number) => {
                            MoreRow({ item })
                            if (index < this.moreItems().length - 1) {
                                Divider()
                                    .color($r('app.color.v3_chart_grid'))
                                    .margin({ left: 16, right: 16 })
                                    .accessibilityText('更多栏目分隔线')
                            }
                        }, (item: MoreItem) => item.title)
                    }
                    .width('100%')
                    .borderRadius(16)
                    .backgroundColor($r('app.color.v3_surface'))
                    .border({ width: 1, color: $r('app.color.nd_card_border') })
                    .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetY: 2 })
                    .clip(true)
                    .accessibilityGroup(true)
                    .accessibilityText('更多栏目')

                    Divider()
                        .margin({ top: 6, bottom: 4 })
                        .color($r('app.color.border'))
                        .accessibilityText('更多与版本信息分隔线')

                    Column({ space: 5 }) {
                        Text(`版本 ${APP_VERSION} · 构建 ${APP_BUILD_NUMBER}`)
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText(`版本${APP_VERSION}构建号${APP_BUILD_NUMBER}`)
                        Text('Designed & Developed by Ray Chen (Rayawa)')
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('Designed and Developed by Ray Chen Rayawa')
                        Text('Copyright © 2026. All rights reserved.')
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('版权所有2026')
                        Text('本应用备案域名：rayawa.top')
                            .fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
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
                    .padding({ top: 14, bottom: 110 })
                    .accessibilityGroup(true)
                    .accessibilityText('版本版权和备案信息')
                }
                .width('100%')
                .constraintSize({ maxWidth: Math.min(CONTENT_MAX_WIDTH, 900) })
                .padding({ left: 14, right: 14 })
                .onAppear(() => {
                    if (!this.restoredScroll) {
                        this.restoredScroll = true;
                        const continuation = getContinuationState();
                        if (continuation.mainTab === MAIN_TAB_MY && continuation.routeName === CONTINUATION_ROUTE_MAIN &&
                            continuation.scrollDistance > 0) {
                            setTimeout((): void => {
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
                    }
                })
            }
            .width('100%')
            .height('100%')
            .scrollBar(BarState.Off)
            .onDidScroll((): void => {
                try {
                    setContinuationView(MAIN_TAB_MY, this.scroller.currentOffset().yOffset);
                } catch (error) {
                    console.warn('[Dashboard][pages/main/MyPage][WARN]',
                        `保存滚动位置失败: ${JSON.stringify(error)}`);
                }
            })
            .backgroundColor($r('app.color.background'))
            .accessibilityText('我的页面')

            if (this.showWarning) {
                Column()
                    .width('100%')
                    .height('100%')
                    .backgroundColor($r('app.color.v3_scrim'))
                    .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                    .onClick(() => this.showWarning = false)
                    .accessibilityText('点击关闭重要提示')
                warn({ isShow: this.showWarning })
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.background'))
        .accessibilityText('我的与关于页面')
        .bindSheet($$this.showContact, this.ContactSheet(), {
            title: { title: '联系我们' },
            height: SheetSize.FIT_CONTENT,
            onWillDisappear: () => this.showContact = false,
        })
    }

    @Builder
    ContactSheet() {
        Column() {
            contact()
        }
        .width('100%')
        .padding({ top: 8, bottom: 20 })
        .accessibilityGroup(true)
        .accessibilityText('联系我们内容')
    }
}
