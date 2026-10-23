import { RequestScope } from '../../common/CachedRequest';
import { formatScore } from '../../common/format';
import { DiscoveryEnter } from '../discovery/DiscoveryEnter';
import { AppSummaryRow } from '../discovery/AppSummaryRow';
import { BrowserStatus } from '../discovery/BrowserControls';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { fetchReputation } from '../../common/MarketApi';
import { openDiscoveryApp, openMarketRanking } from '../../common/discoveryNavigation';
import { reputationSummary } from '../../common/ReputationPresentation';
import type { ReputationPayload, ReputationItem } from '../../common/types';

@Component
export struct HomeReputationCard {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onActiveChanged') active: boolean = true;
    private requestScope: RequestScope = new RequestScope();
    private inViewport: boolean = false;
    private refreshPending: boolean = false;
    private onActiveChanged(): void {
        if (!this.active || !this.inViewport) {
            if (this.loading && this.loaded) this.refreshPending = true;
            this.requestScope.cancel(); this.token++; this.loading = false; return;
        }
        if (this.requestScope.cancelled) this.requestScope = new RequestScope();
        if (this.active && this.inViewport && (!this.loaded || this.refreshPending) && !this.loading) {
            const force = this.refreshPending; this.refreshPending = false; this.load(force);
        }
    }
    @Prop @Watch('refresh') refreshVersion: number = 0;
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    @State private payload: ReputationPayload | undefined = undefined;
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private stale: boolean = false;
    private token: number = 0;
    private loaded: boolean = false;

    private refresh(): void { if (this.refreshVersion > 0) { this.refreshPending = true; this.onActiveChanged(); } }
    aboutToDisappear(): void { this.requestScope.cancel(); this.token++; this.loading = false; this.interaction.dispose(); }
    private async load(force: boolean): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = ''; this.stale = false;
        try {
            const result = await fetchReputation({ days: 1, minSamples: 10, sort: 'weighted', force }, this.requestScope);
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
        Column({ space: 8 }) {
            Row({ space: 8 }) {
                Text('口碑榜').fontSize(18).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).layoutWeight(1)
                Button('查看全部', { stateEffect: false }).fontSize(12)
                    .attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'all'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('all', event))
                    .onClick((): void => {
                        this.interaction.activate('all');
                        openMarketRanking(this.pageStack, { kind: 'reputation', days: 1 });
                    }).accessibilityText('查看完整口碑榜')
            }.width('100%')
            Text(`近 1 天 · 样本加权 · 10 个净样本起${this.payload?.report_date ? ' · ' + this.payload.report_date : ''}`)
                .fontSize(12).fontColor($r('app.color.v3_text_secondary')).width('100%')
            if (this.payload) {
                if (this.payload.data_stale) {
                    Text('服务端旧数据，更新时间见完整榜单。')
                        .fontSize(12).fontColor($r('app.color.v3_accent_orange')).width('100%')
                }
            }
            BrowserStatus({ loading: this.loading, error: this.error, stale: this.stale,
                empty: !this.payload || this.payload.items.length === 0, emptyText: '该报告日暂无达到门槛的口碑榜数据',
                onRetry: (): void => { this.load(true); } })
            if (this.payload) {
                ForEach(this.payload.items.slice(0, 3), (item: ReputationItem, index: number) => {
                    AppSummaryRow({ compact: true, enterOrder: index, appId: item.app_id, packageName: item.pkg_name,
                        iconUrl: item.icon_url, name: `${index + 1}. ${item.name}`,
                        subtitle: reputationSummary(item), subtitleMaxLines: 1, value: `${formatScore(item.weighted_score)}\n加权得分`,
                        onOpen: (): void => {
                            openDiscoveryApp(this.pageStack, { appId: item.app_id, packageName: item.pkg_name });
                        } })
                }, (item: ReputationItem) => item.app_id)
            }
        }.width('100%').padding(16).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .accessibilityGroup(false).accessibilityLevel('no').accessibilityText('口碑榜摘要，评分净变化排行')
    }
    build() {
        DiscoveryEnter({ content: (): void => { this.card(); } })
            .onVisibleAreaChange([0, 0.01], (visible: boolean, ratio: number): void => {
                this.inViewport = visible && ratio > 0; this.onActiveChanged();
            })
    }
}
