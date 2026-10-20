import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle, DiscoverySelectStyle } from '../../common/DiscoveryTheme';
import { appCollectionSubtitle } from '../../common/AppListPresentation';
import { showToastSafely } from '../../common/safeUi';
import { openDiscoveryApp } from '../../common/discoveryNavigation';
import { MarketPageFrame } from '../../component/discovery/MarketPageFrame';
import { AppSummaryRow } from '../../component/discovery/AppSummaryRow';
import { BrowserPagination, BrowserStatus } from '../../component/discovery/BrowserControls';
import { fetchAppsQuery } from '../../common/MarketApi';
import { collectionExpression, collectionSort } from '../../common/DiscoveryQuery';
import { getLocalCollection, saveFollowedDeveloper } from '../../common/storage';
import { DISCOVERY_PAGE_SIZE } from '../../common/constants';
import { formatCount } from '../../common/format';
import type { AppCollectionTarget, MarketApp, FollowedDeveloper } from '../../common/types';

@Builder
export function AppCollectionPageBuilder() { AppCollectionPage() }

@Component
export struct AppCollectionPage {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @Consume('pageStack') private pageStack: NavPathStack;
    target: AppCollectionTarget = { title: '应用列表' };
    @State private apps: MarketApp[] = [];
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private stale: boolean = false;
    @State private page: number = 1;
    @State private total: number = 0;
    @State private sortIndex: number = 0;
    @State private followed: boolean = false;
    @State private saving: boolean = false;
    private token: number = 0;
    private initialized: boolean = false;
    private readonly sorts: string[] = ['download_count', 'release_date', 'listed_at', 'average_rating'];
    private readonly sortOptions: SelectOption[] = [
        { value: '累计下载' }, { value: '版本发布' }, { value: '最近收录' }, { value: '评分' },
    ];

    private alive: boolean = false;
    aboutToAppear(): void { this.alive = true; }
    aboutToDisappear(): void { this.interaction.dispose(); this.alive = false; this.token++; }
    private shown(): void {
        if (!this.initialized) {
            this.initialized = true;
            this.sortIndex = Math.max(0, this.sorts.indexOf(collectionSort(this.target)));
            this.load(false);
        }
        this.refreshFollowed();
    }
    private async refreshFollowed(): Promise<void> {
        if (!this.target.developerId || this.saving) return;
        try {
            const saved = await getLocalCollection();
            if (this.alive && !this.saving) this.followed = saved.developers.some((d: FollowedDeveloper) =>
                d.developerId === this.target.developerId);
        } catch (_) { /* 列表浏览不依赖本地关注状态。 */ }
    }
    private async load(force: boolean): Promise<void> {
        const token = ++this.token;
        this.loading = true;
        this.error = '';
        this.apps = [];
        try {
            const result = await fetchAppsQuery({
                page: this.page, pageSize: DISCOVERY_PAGE_SIZE, sort: this.sorts[this.sortIndex], desc: true, force,
            }, collectionExpression(this.target));
            if (token !== this.token) return;
            if (!result.data.success || !result.data.data) throw new Error('应用列表暂不可用');
            this.apps = result.data.data.data;
            this.total = result.data.data.total_count;
            this.stale = result.stale;

        } catch (error) {
            if (token === this.token) this.error = (error as Error).message;
        } finally {
            if (token === this.token) this.loading = false;
        }
    }
    private async follow(): Promise<void> {
        if (this.saving || !this.target.developerId) return;
        this.saving = true;
        const next = !this.followed;
        try {
            await saveFollowedDeveloper({ developerId: this.target.developerId,
                developerName: this.target.developerName || this.target.title }, next);
            if (this.alive) this.followed = next;
        } catch (_) {
            showToastSafely(this.getUIContext().getPromptAction(), '保存失败，请重试');
        } finally { if (this.alive) this.saving = false; }
    }
    @Builder
    private content(): void {
        Column({ space: 12 }) {
            if (this.target.developerId) {
                Button(this.followed ? '已关注 · 点击取消' : '关注开发者', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-0'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-0', event)).enabled(!this.saving)
                    .onClick((): void => { this.interaction.activate('discovery-0'); this.follow(); })
            }
            if (this.target.preset === 'rated') {
                Text('评分至少 4.5，且至少有 100 条评分').fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            if (this.target.early) {
                Text('当前累计下载量 1000–99999 的应用；按当前数据筛选，与赛道统计快照可能存在差异。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            Row({ space: 12 }) {
                Select(this.sortOptions).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-1'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-1', event)).selected(this.sortIndex).value(this.sortOptions[this.sortIndex].value)
                    .onSelect((index: number): void => { this.interaction.activate('discovery-1'); this.sortIndex = index; this.page = 1; this.load(false); })
                Button('刷新', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-2'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-2', event)).enabled(!this.loading).onClick((): void => { this.interaction.activate('discovery-2'); this.load(true); })
            }.width('100%')
            BrowserStatus({ loading: this.loading, error: this.error, stale: this.stale,
                empty: this.apps.length === 0, onRetry: (): void => { this.load(true); } })
            ForEach(this.apps, (app: MarketApp, index: number) => {
                AppSummaryRow({ enterOrder: index, appId: app.app_id, packageName: app.pkg_name, name: app.name, iconUrl: app.icon_url,
                    subtitle: appCollectionSubtitle(app, this.target),
                    value: `${formatCount(app.download_count)} 次`,
                    onOpen: (): void => {
                        openDiscoveryApp(this.pageStack,
                            { appId: app.app_id, packageName: app.pkg_name, previewApp: app });
                    },
                })
            }, (app: MarketApp) => app.app_id)
            BrowserPagination({ page: this.page, total: this.total, pageSize: DISCOVERY_PAGE_SIZE,
                loading: this.loading, onPage: (page: number): void => { this.page = page; this.load(false); } })
        }.width('100%')
    }
    build() {
        MarketPageFrame({ resetKey: `${this.page}-${this.sortIndex}`, title: this.target.title, content: (): void => { this.content(); },
            onShown: (): void => this.shown() })
    }
}
