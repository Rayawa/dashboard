import { hdsEffect } from '@kit.UIDesignKit';
import { formatDateTime, formatDuration, formatExactCount } from '../../common/format';
import type { SyncDuration, SyncStatusInfo } from '../../common/types';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';

function durationSeconds(duration: SyncDuration | undefined): number | undefined {
    if (!duration) return undefined;
    return Math.max(0, Number(duration.secs ?? 0) + Number(duration.nanos ?? 0) / 1000000000);
}

@Component
export struct SyncStatusCard {
    @Prop @Watch('resetCountdown') status: SyncStatusInfo = {
        is_syncing_all: false,
        total_failed: 0,
        total_inserted: 0,
        total_processed: 0,
        total_skipped: 0,
    };
    @Prop lastUpdated: string = '';
    @Prop backendVersion: string = '';
    @State private countdown: number = -1;
    @State private pressed: boolean = false;
    @State private animStep: number = 0;
    private countdownTimer: number = -1;
    private enterAnimationTimers: number[] = [];

    private resetCountdown(): void {
        if (this.status.next_sync_countdown === null || this.status.next_sync_countdown === undefined) {
            this.countdown = -1;
            this.startCountdown();
            return;
        }
        const value = Number(this.status.next_sync_countdown);
        this.countdown = Number.isFinite(value) && value >= 0 ? Math.floor(value) : -1;
        this.startCountdown();
    }

    private startCountdown(): void {
        if (this.countdownTimer >= 0) clearInterval(this.countdownTimer);
        this.countdownTimer = -1;
        if (this.countdown < 0 || this.status.is_syncing_all) return;
        this.countdownTimer = setInterval((): void => {
            if (this.countdown > 0) this.countdown--;
        }, 1000);
    }

    aboutToAppear(): void {
        this.resetCountdown();
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 1, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
        if (this.countdownTimer >= 0) {
            clearInterval(this.countdownTimer);
            this.countdownTimer = -1;
        }
    }

    private progressTotal(): number {
        const total = Number(this.status.progress?.[1] ?? 0);
        return total > 0 ? total : Math.max(1, this.status.total_processed);
    }

    private progressValue(): number {
        return Math.min(this.progressTotal(), Number(this.status.progress?.[0] ?? this.status.total_processed));
    }

    private remainingSeconds(): number | undefined {
        const elapsed = durationSeconds(this.status.elapsed_time);
        const estimated = durationSeconds(this.status.estimated_total_time);
        if (elapsed === undefined || estimated === undefined) return undefined;
        return Math.max(0, estimated - elapsed);
    }

    build() {
        Column({ space: 11 }) {
            Row() {
                Text('同步信息').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                Blank()
                Text(this.status.is_syncing_all ? '全量同步中' : '服务正常').fontSize(13)
                    .fontColor(this.status.is_syncing_all ?
                        $r('app.color.v3_accent_orange') : $r('app.color.v3_accent_green'))
            }.width('100%')
            if (this.status.is_syncing_all) {
                Progress({ value: this.progressValue(), total: this.progressTotal() })
                    .width('100%').height(6).color($r('app.color.diff_content'))
                Text(`进度 ${formatExactCount(this.progressValue())} / ${formatExactCount(this.progressTotal())}`)
                    .fontSize(12).fontColor($r('app.color.v3_text_secondary')).width('100%')
            }
            GridRow({ columns: 2, gutter: { x: 10, y: 8 } }) {
                GridCol({ span: 1 }) {
                    Text(`已处理：${formatExactCount(this.status.total_processed)}`).fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                }
                GridCol({ span: 1 }) {
                    Text(`新增：${formatExactCount(this.status.total_inserted)}`).fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                }
                GridCol({ span: 1 }) {
                    Text(`跳过：${formatExactCount(this.status.total_skipped)}`).fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                }
                GridCol({ span: 1 }) {
                    Text(`失败：${formatExactCount(this.status.total_failed)}`).fontSize(13)
                        .fontColor(this.status.total_failed > 0 ?
                            $r('app.color.v3_accent_red') : $r('app.color.v3_text_secondary'))
                }
                GridCol({ span: 1 }) {
                    Text(`已用时：${formatDuration(durationSeconds(this.status.elapsed_time))}`).fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                }
                GridCol({ span: 1 }) {
                    Text(`预计总耗时：${formatDuration(durationSeconds(this.status.estimated_total_time))}`).fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                }
            }.width('100%')
            Text(this.status.is_syncing_all ?
                `预计剩余：${formatDuration(this.remainingSeconds())}` :
                `下次同步：${this.countdown >= 0 ? formatDuration(this.countdown) : '等待服务安排'}`)
                .fontSize(13).fontColor($r('app.color.v3_text_primary')).width('100%')
            Divider().color($r('app.color.v3_chart_grid'))
            Text(`最后更新：${formatDateTime(this.lastUpdated)}`).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
            Text(`后端版本：${this.backendVersion || '-'}`).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
        }
        .width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
        .animation({ duration: 130, curve: Curve.EaseOut })
        .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText(this.status.is_syncing_all ? '服务当前正在全量同步' : '服务当前状态正常')
    }
}
