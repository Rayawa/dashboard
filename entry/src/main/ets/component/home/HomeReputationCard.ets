import { DiscoveryEnter } from '../discovery/DiscoveryEnter';
import { AppSummaryRow } from '../discovery/AppSummaryRow';
import { BrowserStatus } from '../discovery/BrowserControls';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { fetchReputation } from '../../common/MarketApi';
import { openDiscoveryApp, openMarketRanking } from '../../common/discoveryNavigation';
import { reputationSubtitle, reputationValue } from '../../common/ReputationPresentation';
import type { ReputationPayload, ReputationItem } from '../../common/types';

@Component
export struct HomeReputationCard {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('refresh') refreshVersion: number = 0;
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @State private payload: ReputationPayload | undefined = undefined;
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private stale: boolean = false;
    private token: number = 0;
    private loaded: boolean = false;

    private refresh(): void { if (this.refreshVersion > 0) this.load(true); }
    aboutToDisappear(): void { this.token++; this.loading = false; this.interaction.dispose(); }
    private async load(force: boolean): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = ''; this.stale = false;
        try {
            const result = await fetchReputation({ days: 1, minSamples: 10, sort: 'weighted', force });
            if (token !== this.token) return;
            if (!result.data.success || !result.data.data) throw new Error('口碑榜暂不可用');
            this.payload = result.data.data;
            this.stale = result.stale;
            this.loaded = true;
        } catch (error) {
            if (token === this.token) { this.error = (error as Error).message; this.stale = this.payload !== undefined; }
        } finally { if (token === this.token) this.loading = false; }
    }
    @Builder
    private card(): void {
        Column({ space: 12 }) {
            Row({ space: 8 }) {
                Text('口碑榜').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                Button('刷新', { stateEffect: false }).fontSize(12).enabled(!this.loading)
                    .attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'refresh'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('refresh', event))
                    .onClick((): void => { this.interaction.activate('refresh'); this.load(true); })
                    .accessibilityText('刷新首页口碑榜')
                Button('查看全部', { stateEffect: false }).fontSize(12)
                    .attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'all'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('all', event))
                    .onClick((): void => {
                        this.interaction.activate('all');
                        openMarketRanking(this.pageStack, { kind: 'reputation', days: 1 });
                    }).accessibilityText('查看完整口碑榜')
            }.width('100%')
            Text('近 1 天 · 样本加权得分 · 至少 10 个净样本')
                .fontSize(12).fontColor($r('app.color.v3_text_secondary')).width('100%')
            if (this.payload) {
                Text(`报告日（北京时间）：${this.payload.report_date || '暂无'}\n数据生成时间（UTC）：${this.payload.generated_at}`)
                    .fontSize(12).fontColor($r('app.color.v3_text_secondary')).width('100%')
                if (this.payload.data_stale) {
                    Text('当前为服务端旧数据，请留意生成时间。')
                        .fontSize(12).fontColor($r('app.color.v3_accent_orange')).width('100%')
                }
            }
            BrowserStatus({ loading: this.loading, error: this.error, stale: this.stale,
                empty: !this.payload || this.payload.items.length === 0, emptyText: '该报告日暂无达到门槛的口碑榜数据',
                onRetry: (): void => { this.load(true); } })
            if (this.payload) {
                ForEach(this.payload.items.slice(0, 3), (item: ReputationItem, index: number) => {
                    AppSummaryRow({ enterOrder: index, appId: item.app_id, packageName: item.pkg_name,
                        iconUrl: item.icon_url, name: `${index + 1}. ${item.name}`,
                        subtitle: reputationSubtitle(item), subtitleMaxLines: 8, value: reputationValue(item),
                        onOpen: (): void => {
                            openDiscoveryApp(this.pageStack, { appId: item.app_id, packageName: item.pkg_name });
                        } })
                }, (item: ReputationItem) => item.app_id)
            }
        }.width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .accessibilityGroup(true).accessibilityText('口碑榜摘要，评分净变化排行')
    }
    build() {
        DiscoveryEnter({ content: (): void => { this.card(); } })
            .onAppear((): void => { if (!this.loaded && !this.loading) this.load(false); })
    }
}
