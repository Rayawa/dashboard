import { HdsNavigationMenuItemOptions } from '@kit.UIDesignKit';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { openDiscoveryApp, openMarketTopic } from '../../common/discoveryNavigation';
import { MarketPageFrame } from '../../component/discovery/MarketPageFrame';
import { AppSummaryRow } from '../../component/discovery/AppSummaryRow';
import { BrowserPagination, BrowserStatus } from '../../component/discovery/BrowserControls';
import { fetchTopics, fetchTopic } from '../../common/MarketApi';
import { DISCOVERY_PAGE_SIZE } from '../../common/constants';
import { formatDateTime } from '../../common/format';
import type { TopicTarget, TopicSummary, TopicApp } from '../../common/types';

@Builder
export function TopicsPageBuilder() { TopicsPage() }

@Component
export struct TopicsPage {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    @Consume('pageStack') private pageStack: NavPathStack;
    target: TopicTarget = {};
    @State private topics: TopicSummary[] = [];
    @State private apps: TopicApp[] = [];
    @State private subtitle: string = '';
    @State private page: number = 1;
    @State private total: number = 0;
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private stale: boolean = false;
    private token: number = 0;
    private initialized: boolean = false;
    aboutToDisappear(): void { this.interaction.dispose(); this.token++; }
    private async load(force: boolean): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = ''; this.topics = []; this.apps = [];
        try {
            if (this.target.topicId) {
                const result = await fetchTopic(this.target.topicId, force);
                if (token !== this.token) return;
                if (!result.data.success || !result.data.data) throw new Error('专题暂不可用');
                this.apps = result.data.data.apps || [];
                this.subtitle = result.data.data.subtitle || '';
                this.stale = result.stale;
            } else {
                const result = await fetchTopics(this.page, DISCOVERY_PAGE_SIZE, force);
                if (token !== this.token) return;
                if (!result.data.success || !result.data.data) throw new Error('专题列表暂不可用');
                this.topics = result.data.data.data;
                this.total = result.data.data.total_count;
                this.stale = result.stale;
            }
        } catch (error) {
            if (token === this.token) this.error = (error as Error).message;
        } finally { if (token === this.token) this.loading = false; }
    }
    @Builder
    private content(): void {
        Column({ space: 12 }) {
            if (this.subtitle) {
                Text(this.subtitle).fontSize(14).fontColor($r('app.color.v3_text_secondary')).width('100%')
            }
            BrowserStatus({ enterSpeed: 2, loading: this.loading, error: this.error, stale: this.stale,
                empty: this.apps.length + this.topics.length === 0,
                emptyText: this.target.topicId ? '专题暂无已收录应用' : '暂无专题',
                onRetry: (): void => { this.load(true); } })
            ForEach(this.topics, (topic: TopicSummary, index: number) => {
                AppSummaryRow({ enterSpeed: 2, enterOrder: index, showIcon: false, name: topic.title || '未命名专题',
                    subtitle: `${topic.subtitle || ''}\n收录于 ${formatDateTime(topic.created_at)}`.trim(),
                    onOpen: (): void => {
                        openMarketTopic(this.pageStack, { topicId: topic.substance_id, title: topic.title });
                    } })
            }, (topic: TopicSummary) => topic.substance_id)
            ForEach(this.apps.slice((this.page - 1) * DISCOVERY_PAGE_SIZE, this.page * DISCOVERY_PAGE_SIZE), (app: TopicApp, index: number) => {
                AppSummaryRow({ enterSpeed: 2, enterOrder: index, appId: app.app_id, packageName: app.pkg_name, name: app.name, iconUrl: app.icon_url, subtitle: `专题：${this.target.title || '当前专题'}`,
                    onOpen: (): void => {
                        openDiscoveryApp(this.pageStack, { appId: app.app_id, packageName: app.pkg_name });
                    } })
            }, (app: TopicApp) => app.app_id)
            BrowserPagination({ enterSpeed: 2, page: this.page, total: this.target.topicId ? this.apps.length : this.total,
                pageSize: DISCOVERY_PAGE_SIZE, loading: this.loading,
                onPage: (page: number): void => {
                    this.page = page;
                    if (!this.target.topicId) this.load(false);
                } })
        }.width('100%')
    }
    build() {
        MarketPageFrame({ resetKey: String(this.page), title: this.target.title || '专题浏览',
            busy: this.loading, menuProvider: (_busy: boolean): HdsNavigationMenuItemOptions[] => [{ content: { label: '刷新专题', icon: $r('sys.symbol.arrow_clockwise'), isEnabled: !this.loading,
                action: (): void => { this.interaction.activate('refresh'); this.load(true); } } }], content: (): void => { this.content(); },
            onShown: (): void => {
                if (!this.initialized) { this.initialized = true; this.load(false); }
            } })
    }
}
