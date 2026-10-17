import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { AppIcon } from '../apps/AppIcon';
import { openAppCollection, openMarketRanking } from '../../common/discoveryNavigation';
import { hdsEffect } from '@kit.UIDesignKit';
import { formatExactCount } from '../../common/format';
import type { DailyMaxDownloadApp, DeveloperRankingEntry } from '../../common/types';
import { cancelStaggerEnterAnimation, contentEnterTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { vibration } from '../../common/vibration';

@Component
export struct HomeRankings {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop dailyApps: DailyMaxDownloadApp[] = [];
    @Prop developers: DeveloperRankingEntry[] = [];
    onOpenApp: (app: DailyMaxDownloadApp) => void = (): void => {};
    @State private pressedItem: string = '';
    @State private animStep: number = 0;
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private enterAnimationTimers: number[] = [];

    private updatePressed(key: string, event: TouchEvent): void {
        if (event.type === TouchType.Down) this.pressedItem = key;
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedItem = '';
    }

    private startEnterAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 2, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    @Builder
    private downloadRanking(): void {
        Column({ space: 10 }) {
            Row({ space: 8 }) {
                Text('每日累计下载最高记录').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                Button('查看全部').attributeModifier(new DiscoveryButtonStyle()).fontSize(12).onClick((): void => {
                    openMarketRanking(this.pageStack, { kind: 'daily' });
                })
            }.width('100%')
            Text('每款应用保留最近一次记录，数值为累计下载量').fontSize(12)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
            if (this.dailyApps.length === 0) {
                Text('暂无每日快照数据').fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                    .width('100%').padding({ top: 12, bottom: 12 })
            } else {
                ForEach(this.dailyApps, (app: DailyMaxDownloadApp) => {
                    Row({ space: 10 }) {
                        AppIcon({ appId: app.app_id, packageName: app.pkg_name })
                        Column({ space: 3 }) {
                            Text(app.app_name || '未知应用').fontSize(14).fontWeight(FontWeight.Medium)
                                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(`最近记录：${app.report_date}`).fontSize(11)
                                .fontColor($r('app.color.v3_text_secondary'))
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                        Text(formatExactCount(app.download_count)).fontSize(13)
                            .fontColor($r('app.color.v3_accent_orange'))
                    }
                    .width('100%').padding({ top: 8, bottom: 8 })
                    .borderRadius(10)
                    .scale({ x: this.pressedItem === `app-${app.report_date}-${app.app_id}` ? 0.98 : 1,
                        y: this.pressedItem === `app-${app.report_date}-${app.app_id}` ? 0.98 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedItem === `app-${app.report_date}-${app.app_id}`,
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(
                        this.pressedItem === `app-${app.report_date}-${app.app_id}`))
                    .onTouch((event: TouchEvent): void =>
                        this.updatePressed(`app-${app.report_date}-${app.app_id}`, event))
                    .onClick((): void => {
                        if (this.vibrationLevel > 0) vibration.dotVibration();
                        this.onOpenApp(app);
                    })
                    .transition(contentEnterTransition(6))
                    .accessibilityText(`${app.report_date}，${app.app_name}，累计下载量${app.download_count}，点击查看详情`)
                }, (app: DailyMaxDownloadApp) => `${app.report_date}-${app.app_id}`)
            }
        }
        .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 20 })
        .accessibilityGroup(true)
    }

    @Builder
    private developerRanking(): void {
        Column({ space: 10 }) {
            Row({ space: 8 }) {
                Text('开发者应用数量排行').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                Button('查看全部').attributeModifier(new DiscoveryButtonStyle()).fontSize(12).onClick((): void => {
                    openMarketRanking(this.pageStack, { kind: 'developers' });
                })
            }.width('100%')
            if (this.developers.length === 0) {
                Text('暂无开发者排行数据').fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                    .width('100%').padding({ top: 12, bottom: 12 })
            } else {
                ForEach(this.developers, (developer: DeveloperRankingEntry, index: number) => {
                    Row({ space: 10 }) {
                        Text(String(index + 1)).width(24).fontSize(13).fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.v3_accent_purple')).textAlign(TextAlign.Center)
                        Text(developer.developerName || '未知开发者').fontSize(14)
                            .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                            .textOverflow({ overflow: TextOverflow.Ellipsis }).layoutWeight(1)
                        Text(`${formatExactCount(developer.appCount)} 款`).fontSize(13)
                            .fontColor($r('app.color.v3_accent_cyan'))
                    }
                    .width('100%').padding({ top: 8, bottom: 8 })
                    .borderRadius(10)
                    .scale({ x: this.pressedItem === `developer-${developer.developerId}` ? 0.98 : 1,
                        y: this.pressedItem === `developer-${developer.developerId}` ? 0.98 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(
                        this.pressedItem === `developer-${developer.developerId}`,
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(
                        this.pressedItem === `developer-${developer.developerId}`))
                    .onTouch((event: TouchEvent): void =>
                        this.updatePressed(`developer-${developer.developerId}`, event))
                    .onClick((): void => {
                        if (this.vibrationLevel > 0) vibration.dotVibration();
                        openAppCollection(this.pageStack, {
                            title: developer.developerName, developerId: developer.developerId,
                            developerName: developer.developerName,
                        });
                    })
                    .transition(contentEnterTransition(6))
                    .accessibilityText(`第${index + 1}名，${developer.developerName}，${developer.appCount}款应用，点击查看开发者应用`)
                }, (developer: DeveloperRankingEntry) => `${developer.developerId}-${developer.developerName}`)
            }
        }
        .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= 2 ? 1 : 0)
        .translate({ y: this.animStep >= 2 ? 0 : 20 })
        .accessibilityGroup(true)
    }

    build() {
        Column({ space: 14 }) {
            this.downloadRanking()
            this.developerRanking()
        }
        .width('100%')
        .onAppear((): void => this.startEnterAnimation())
        .accessibilityText('应用与开发者排行榜')
    }
}
