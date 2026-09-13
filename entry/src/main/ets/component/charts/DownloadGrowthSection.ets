import { hdsEffect } from '@kit.UIDesignKit';
import { fetchDownloadGrowth } from '../../common/MarketApi';
import { formatDateTime, formatExactCount } from '../../common/format';
import type { BaseAPIResponse, DownloadGrowthApp } from '../../common/types';
import { cancelStaggerEnterAnimation, contentEnterTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { vibration } from '../../common/vibration';

@Component
export struct DownloadGrowthSection {
    @State private apps: DownloadGrowthApp[] = [];
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private periodIndex: number = 0;
    @State private errorMessage: string = '';
    @State private pressedControl: string = '';
    @State private animStep: number = 0;
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    private readonly periods: number[] = [1, 7, 30];
    private readonly periodOptions: SelectOption[] = [
        { value: '近 1 天' }, { value: '近 7 天' }, { value: '近 30 天' },
    ];
    private loadToken: number = 0;
    private enterAnimationTimers: number[] = [];

    private vibrate(): void {
        if (this.vibrationLevel > 0) vibration.dotVibration();
    }

    private updatePressed(key: string, event: TouchEvent): void {
        if (event.type === TouchType.Down) this.pressedControl = key;
        else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedControl = '';
    }

    private startEnterAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 1, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        this.loadToken++;
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    private async load(force: boolean): Promise<void> {
        const token = ++this.loadToken;
        this.loading = true;
        this.errorMessage = '';
        try {
            const result = await fetchDownloadGrowth({
                days: this.periods[this.periodIndex],
                limit: 10,
                page: 1,
                force,
            });
            const response = result.data as BaseAPIResponse<DownloadGrowthApp[]>;
            if (!response.success || !response.data) throw new Error('下载增长数据不可用');
            if (token !== this.loadToken) return;
            this.apps = response.data;
            this.loaded = true;
        } catch (error) {
            if (token !== this.loadToken) return;
            this.errorMessage = (error as Error).message;
        } finally {
            if (token === this.loadToken) this.loading = false;
        }
    }

    build() {
        Column({ space: 12 }) {
            Row({ space: 10 }) {
                Column({ space: 3 }) {
                    Text('下载增长榜').fontSize(18).fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                    Text('按快照周期对比下载量增量').fontSize(12)
                        .fontColor($r('app.color.v3_text_secondary'))
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Select(this.periodOptions).selected(this.periodIndex).value(this.periodOptions[this.periodIndex].value)
                    .height(38).backgroundColor($r('app.color.v3_surface_alt'))
                    .scale({ x: this.pressedControl === 'period' ? 0.97 : 1,
                        y: this.pressedControl === 'period' ? 0.97 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === 'period',
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === 'period'))
                    .onTouch((event: TouchEvent): void => this.updatePressed('period', event))
                    .onSelect((index: number): void => {
                        this.vibrate();
                        this.periodIndex = index;
                        this.load(false);
                    })
            }.width('100%')
            if (this.loading && !this.loaded) {
                LoadingProgress().width(30).height(30).color($r('app.color.diff_content')).margin(24)
            } else if (this.errorMessage.length > 0) {
                Row({ space: 8 }) {
                    Text(`加载失败：${this.errorMessage}`).fontSize(13)
                        .fontColor($r('app.color.v3_accent_red')).layoutWeight(1)
                    Button('重试', { stateEffect: false }).height(36)
                        .backgroundColor($r('app.color.diff_content'))
                        .scale({ x: this.pressedControl === 'retry' ? 0.97 : 1,
                            y: this.pressedControl === 'retry' ? 0.97 : 1 })
                        .animation({ duration: 120, curve: Curve.EaseOut })
                        .visualEffect(pressVisualEffect(this.pressedControl === 'retry',
                            hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                        .compositingFilter(pressLightFieldFilter(this.pressedControl === 'retry'))
                        .onTouch((event: TouchEvent): void => this.updatePressed('retry', event))
                        .onClick((): void => { this.vibrate(); this.load(true); })
                }.width('100%')
            } else if (this.apps.length === 0) {
                Text('当前周期暂无可比较的快照，数据生成后会自动显示')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                    .width('100%').padding({ top: 18, bottom: 18 })
            } else {
                ForEach(this.apps, (app: DownloadGrowthApp, index: number) => {
                    Row({ space: 10 }) {
                        Text(String(index + 1)).width(24).fontSize(13).fontWeight(FontWeight.Bold)
                            .fontColor($r('app.color.diff_content')).textAlign(TextAlign.Center)
                        Column({ space: 3 }) {
                            Text(app.name || '未知应用').fontSize(14).fontWeight(FontWeight.Medium)
                                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                                .textOverflow({ overflow: TextOverflow.Ellipsis })
                            Text(`${formatDateTime(app.prior_period_date)} → ${formatDateTime(app.current_period_date)}`)
                                .fontSize(11).fontColor($r('app.color.v3_text_secondary'))
                        }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                        Column({ space: 2 }) {
                            Text(`+${formatExactCount(app.download_increment)}`).fontSize(14).fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.v3_accent_green'))
                            Text(formatExactCount(app.current_download_count)).fontSize(11)
                                .fontColor($r('app.color.v3_text_secondary'))
                        }.alignItems(HorizontalAlign.End)
                    }
                    .width('100%').padding({ top: 8, bottom: 8 })
                    .borderRadius(10)
                    .scale({ x: this.pressedControl === `growth-${app.app_id}` ? 0.985 : 1,
                        y: this.pressedControl === `growth-${app.app_id}` ? 0.985 : 1 })
                    .animation({ duration: 120, curve: Curve.EaseOut })
                    .visualEffect(pressVisualEffect(this.pressedControl === `growth-${app.app_id}`,
                        hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 4, 72))
                    .compositingFilter(pressLightFieldFilter(this.pressedControl === `growth-${app.app_id}`))
                    .onTouch((event: TouchEvent): void => this.updatePressed(`growth-${app.app_id}`, event))
                    .transition(contentEnterTransition(6))
                    .accessibilityText(`第${index + 1}名，${app.name}，下载增长${app.download_increment}`)
                }, (app: DownloadGrowthApp) => `${app.app_id}-${app.current_period_date}`)
            }
        }
        .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 20 })
        .onAppear((): void => {
            this.startEnterAnimation();
            if (!this.loaded) this.load(false);
        })
        .accessibilityGroup(true)
        .accessibilityText('应用下载增长排行榜')
    }
}
