import { DiscoveryEnter } from '../discovery/DiscoveryEnter';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { formatDateTime } from '../../common/format';
import type { VersionChange } from '../../common/types';

@Component
export struct VersionTimeline {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @Prop changes: VersionChange[] = [];
    @Prop loading: boolean = false;
    @Prop error: string = '';
    @Prop stale: boolean = false;
    onRetry: () => void = (): void => {};
    @State private visibleCount: number = 5;
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Builder
    private changeRow(change: VersionChange): void {
        Column({ space: 6 }) {
            Text(change.version).fontSize(15).fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            Text(formatDateTime(change.observedAt)).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary')).width('100%')
            Text(change.summary).fontSize(13).fontColor($r('app.color.diff_content')).width('100%')
            if (change.notes) {
                Text(change.notes).fontSize(13).fontColor($r('app.color.v3_text_secondary')).width('100%')
            }
            Divider().color($r('app.color.v3_chart_grid')).margin({ top: 6 })
        }.width('100%').accessibilityGroup(true)
    }
    @Builder
    private body(): void {
        Column({ space: 12 }) {
            Text('版本变化时间线').fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            Text('根据采集记录展示版本、大小、SDK 与价格变化，时间为采集时间。')
                .fontSize(12).fontColor($r('app.color.v3_text_secondary')).width('100%')
            if (this.stale) {
                Text('当前历史指标来自离线缓存').fontSize(12).fontColor($r('app.color.v3_text_secondary'))
            }
            if (this.loading) { LoadingProgress().width(30).height(30).color($r('app.color.diff_content')) }
            if (this.error) {
                Text(this.error).fontSize(13).fontColor($r('app.color.v3_accent_red'))
                Button('重试', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-0'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-0', event)).onClick((): void => { this.interaction.activate('discovery-0'); this.onRetry(); })
            } else if (!this.loading && this.changes.length === 0) {
                Text('暂无历史指标记录').fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            ForEach(this.changes.slice(0, this.visibleCount), (change: VersionChange, index: number) => {
                DiscoveryEnter({ order: index, content: (): void => { this.changeRow(change); } })
            }, (change: VersionChange) => change.key)
            if (this.changes.length > this.visibleCount) {
                Button(`查看更多变化（共 ${this.changes.length} 条）`, { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-1'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-1', event)).onClick((): void => { this.interaction.activate('discovery-1'); this.visibleCount += 20; })
            }
        }.width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
    }
    build() {
        DiscoveryEnter({ order: 0, content: (): void => { this.body(); } })
    }
}
