import { HdsNavigationMenuItemOptions } from '@kit.UIDesignKit';
import { SymbolGlyphModifier } from '@kit.ArkUI';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
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
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
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
    private async chooseSort(): Promise<void> {
        this.interaction.activate('sort');
        try {
            const result = await this.getUIContext().getPromptAction().showActionMenu({
                title: `排序方式 · 当前${this.sortOptions[this.sortIndex].value}`,
                buttons: [
                    { text: '累计下载', color: $r('app.color.diff_content') },
                    { text: '版本发布', color: $r('app.color.diff_content') },
                    { text: '最近收录', color: $r('app.color.diff_content') },
                    { text: '评分', color: $r('app.color.diff_content') },
                ],
            });
            if (!this.alive || result.index < 0 || result.index >= this.sorts.length) return;
            this.sortIndex = result.index; this.page = 1; this.load(false);
        } catch (_) { /* 取消排序菜单时保留当前条件。 */ }
    }
    private titleMenus(): HdsNavigationMenuItemOptions[] {
        const items: HdsNavigationMenuItemOptions[] = [
            { content: { label: '筛选与排序', icon: $r('sys.symbol.slider_horizontal_2_square'),
                action: (): void => { this.chooseSort(); } } },
            { content: { label: '刷新应用列表', icon: $r('sys.symbol.arrow_clockwise'), isEnabled: !this.loading,
                action: (): void => { this.interaction.activate('refresh'); this.load(true); } } },
        ];
        if (this.target.developerId) items.push({ content: {
            label: this.followed ? '取消关注开发者' : '关注开发者',
            icon: new SymbolGlyphModifier(this.followed ? $r('sys.symbol.star_fill') : $r('sys.symbol.star'))
                .fontColor([this.followed ? $r('app.color.diff_content') : $r('sys.color.icon_primary')]),
            isEnabled: !this.saving,
            action: (): void => { this.interaction.activate('follow'); this.follow(); },
        } });
        return items;
    }
    @Builder
    private content(): void {
        Column({ space: 12 }) {
            if (this.target.preset === 'rated') {
                Text('评分至少 4.5，且至少有 100 条评分').fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            if (this.target.early) {
                Text('当前累计下载量 1000–99999 的应用；按当前数据筛选，与赛道统计快照可能存在差异。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            BrowserStatus({ enterSpeed: 2, loading: this.loading, error: this.error, stale: this.stale,
                empty: this.apps.length === 0, onRetry: (): void => { this.load(true); } })
            ForEach(this.apps, (app: MarketApp, index: number) => {
                AppSummaryRow({ enterSpeed: 2, enterOrder: index, appId: app.app_id, packageName: app.pkg_name, name: app.name, iconUrl: app.icon_url,
                    subtitle: appCollectionSubtitle(app, this.target),
                    value: `${formatCount(app.download_count)} 次`,
                    onOpen: (): void => {
                        openDiscoveryApp(this.pageStack,
                            { appId: app.app_id, packageName: app.pkg_name, previewApp: app });
                    },
                })
            }, (app: MarketApp) => app.app_id)
            BrowserPagination({ enterSpeed: 2, page: this.page, total: this.total, pageSize: DISCOVERY_PAGE_SIZE,
                loading: this.loading, onPage: (page: number): void => { this.page = page; this.load(false); } })
        }.width('100%')
    }
    build() {
        MarketPageFrame({ resetKey: `${this.page}-${this.sortIndex}`, title: this.target.title, subtitle: `按${this.sortOptions[this.sortIndex].value}排序`, busy: this.loading || this.saving,
            menuProvider: (_busy: boolean): HdsNavigationMenuItemOptions[] => this.titleMenus(), content: (): void => { this.content(); },
            onShown: (): void => this.shown() })
    }
}
