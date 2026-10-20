import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle, DiscoverySelectStyle, DiscoveryToggleStyle } from '../../common/DiscoveryTheme';
import { reputationSubtitle, reputationValue } from '../../common/ReputationPresentation';
import { latestDailyMaxRecords } from '../../common/DailyRanking';
import { openDiscoveryApp, openAppCollection } from '../../common/discoveryNavigation';
import { LengthMetrics } from '@kit.ArkUI';
import { MarketPageFrame } from '../../component/discovery/MarketPageFrame';
import { AppSummaryRow } from '../../component/discovery/AppSummaryRow';
import { BrowserPagination, BrowserStatus } from '../../component/discovery/BrowserControls';
import {
    fetchReputation,
    fetchAppsPage,
    fetchDownloadGrowth,
    fetchDailyMaxDownloads,
    fetchDeveloperRanking,
    fetchCategoryGrowth
} from '../../common/MarketApi';
import { DISCOVERY_PAGE_SIZE } from '../../common/constants';
import { formatCount } from '../../common/format';
import type {
    ReputationItem,
    ReputationCategory,
    ReputationPayload,
    RankingTarget,
    RankingKind,
    MarketApp,
    DownloadGrowthApp,
    DailyMaxDownloadApp,
    DeveloperRankingEntry,
    CategoryGrowth,
    AppCollectionTarget
} from '../../common/types';

@Builder
export function MarketRankingsPageBuilder() { RankingPage() }

@Component
export struct RankingPage {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @Consume('pageStack') private pageStack: NavPathStack;
    target: RankingTarget = {};
    @State private index: number = 0;
    @State private period: number = 1;
    @State private page: number = 1;
    @State private total: number = 0;
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private stale: boolean = false;
    @State private excludeHuawei: boolean = false;
    @State private excludeAtomic: boolean = false;
    @State private apps: MarketApp[] = [];
    @State private growth: DownloadGrowthApp[] = [];
    @State private daily: DailyMaxDownloadApp[] = [];
    @State private developers: DeveloperRankingEntry[] = [];
    @State private categories: CategoryGrowth[] = [];
    @State private reputation: ReputationItem[] = [];
    @State private reputationInfo: ReputationPayload | undefined = undefined;
    @State private reputationCategories: ReputationCategory[] = [];
    @State private categoryIndex: number = 0;
    @State private sampleIndex: number = 0;
    @State private sortIndex: number = 0;
    private readonly sampleOptions: SelectOption[] = [{ value: '至少 10 个净样本' }, { value: '至少 50 个净样本' }, { value: '至少 100 个净样本' }];
    private readonly samples: number[] = [10, 50, 100];
    private readonly sortOptions: SelectOption[] = [{ value: '按样本加权得分' }, { value: '按评分指标' }];
    private token: number = 0;
    private initialized: boolean = false;
    private readonly kinds: RankingKind[] = ['downloads', 'growth', 'developers', 'daily', 'category', 'segment', 'early', 'reputation'];
    private readonly options: SelectOption[] = [
        { value: '累计下载榜' }, { value: '下载增长榜' }, { value: '开发者应用数量榜' },
        { value: '每日累计下载最高记录' }, { value: '分类增长榜' }, { value: '细分赛道增长榜' },
        { value: '早期应用赛道增长' }, { value: '口碑榜（评分净变化）' },
    ];
    private readonly periodOptions: SelectOption[] = [{ value: '近 1 天' }, { value: '近 7 天' }, { value: '近 30 天' }];
    private readonly days: number[] = [1, 7, 30];
    aboutToDisappear(): void { this.interaction.dispose(); this.token++; }
    private kind(): RankingKind { return this.kinds[this.index]; }
    private shown(): void {
        if (!this.initialized) {
            this.initialized = true;
            this.index = Math.max(0, this.kinds.indexOf(this.target.kind || 'downloads'));
            if (this.target.days !== undefined) this.period = Math.max(0, this.days.indexOf(this.target.days));
            this.load(false);
        }
    }
    private reset(): void { this.page = 1; this.total = 0; this.load(false); }
    private async load(force: boolean): Promise<void> {
        const token = ++this.token;
        this.loading = true;
        this.error = '';
        this.stale = false;
        this.reputation = []; this.reputationInfo = undefined;
        this.apps = []; this.growth = []; this.daily = []; this.developers = []; this.categories = [];
        try {
            const kind = this.kind();
            if (kind === 'reputation') {
                const category = this.reputationCategories[this.categoryIndex - 1];
                const result = await fetchReputation({ days: this.days[this.period],
                    minSamples: this.samples[this.sampleIndex], sort: this.sortIndex === 1 ? 'raw' : 'weighted',
                    kindName: category?.kind_name, tagName: category?.tag_name ?? undefined, force });
                if (token !== this.token) return;
                if (!result.data.success || !result.data.data) throw new Error('口碑榜暂不可用');
                const payload = result.data.data;
                this.reputation = payload.items; this.reputationInfo = payload;
                this.total = payload.items.length; this.stale = result.stale;
                // 保留选中的分类；窗口改变时 controls 会显式重置分类。
                if (this.categoryIndex === 0) this.reputationCategories = payload.categories;
            } else if (kind === 'downloads') {
                const result = await fetchAppsPage({ page: this.page, pageSize: DISCOVERY_PAGE_SIZE,
                    sort: 'download_count', desc: true, excludeHuawei: this.excludeHuawei,
                    excludeAtomic: this.excludeAtomic, force });
                if (token !== this.token) return;
                if (!result.data.success || !result.data.data) throw new Error('下载榜暂不可用');
                this.apps = result.data.data.data; this.total = result.data.data.total_count; this.stale = result.stale;
            } else if (kind === 'growth') {
                const result = await fetchDownloadGrowth({ days: this.days[this.period], page: this.page,
                    limit: DISCOVERY_PAGE_SIZE, excludeHuawei: this.excludeHuawei, excludeAtomic: this.excludeAtomic, force });
                if (token !== this.token) return;
                if (!result.data.success) throw new Error('增长榜暂不可用');
                this.growth = result.data.data || []; this.total = result.data.total || 0; this.stale = result.stale;
            } else if (kind === 'developers') {
                const result = await fetchDeveloperRanking(DISCOVERY_PAGE_SIZE, this.page, force);
                if (token !== this.token) return;
                if (!result.data.success) throw new Error('开发者榜暂不可用');
                this.developers = result.data.data || []; this.total = result.data.total || 0; this.stale = result.stale;
            } else if (kind === 'daily') {
                const result = await fetchDailyMaxDownloads(force);
                if (token !== this.token) return;
                if (!result.data.success) throw new Error('每日记录暂不可用');
                const records = latestDailyMaxRecords(result.data.data || []);
                this.total = records.length;
                this.daily = records.slice((this.page - 1) * DISCOVERY_PAGE_SIZE, this.page * DISCOVERY_PAGE_SIZE);
                this.stale = result.stale;
            } else {
                const result = await fetchCategoryGrowth({ kind, days: this.days[this.period],
                    page: this.page, limit: DISCOVERY_PAGE_SIZE, force });
                if (token !== this.token) return;
                if (!result.data.success) throw new Error('赛道增长数据暂不可用');
                this.categories = result.data.data || []; this.total = result.data.total || 0; this.stale = result.stale;
            }
        } catch (error) {
            if (token === this.token) this.error = (error as Error).message;
        } finally { if (token === this.token) this.loading = false; }
    }
    private empty(): boolean {
        return this.apps.length + this.growth.length + this.daily.length + this.developers.length + this.categories.length + this.reputation.length === 0;
    }
    private openApp(appId: string, packageName: string): void {
        openDiscoveryApp(this.pageStack, { appId, packageName });
    }
    private openCategory(item: CategoryGrowth): void {
        const target: AppCollectionTarget = {
            title: item.segment_name || item.kind_name, category: item.kind_name,
            segment: item.segment_name, early: this.kind() === 'early',
        };
        openAppCollection(this.pageStack, target);
    }
    private categoryOptions(): SelectOption[] {
        const options: SelectOption[] = [{ value: '全部分类' }];
        for (const category of this.reputationCategories) {
            options.push({ value: category.tag_name ? `${category.kind_name} / ${category.tag_name}` : `${category.kind_name}（全部）` });
        }
        return options;
    }
    private changePeriod(index: number): void {
        this.period = index;
        this.categoryIndex = 0;
        this.reputationCategories = [];
        this.reset();
    }
    @Builder
    private controls(): void {
        Column({ space: 12 }) {
            Select(this.options).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-0'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-0', event)).selected(this.index).value(this.options[this.index].value)
                .onSelect((index: number): void => { this.interaction.activate('discovery-0'); this.index = index; this.reset(); })
                .accessibilityText('选择排行榜')
            if (this.kind() === 'growth' || this.kind() === 'category' || this.kind() === 'segment' || this.kind() === 'early' || this.kind() === 'reputation') {
                Select(this.periodOptions).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-1'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-1', event)).selected(this.period).value(this.periodOptions[this.period].value)
                    .onSelect((index: number): void => { this.interaction.activate('discovery-1'); this.changePeriod(index); })
            }
            if (this.kind() === 'reputation') {
                Select(this.sampleOptions).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-2'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-2', event))
                    .selected(this.sampleIndex).value(this.sampleOptions[this.sampleIndex].value)
                    .onSelect((index: number): void => { this.interaction.activate('discovery-2'); this.sampleIndex = index; this.reset(); })
                    .accessibilityText('口碑榜净样本门槛')
                Select(this.sortOptions).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-3'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-3', event))
                    .selected(this.sortIndex).value(this.sortOptions[this.sortIndex].value)
                    .onSelect((index: number): void => { this.interaction.activate('discovery-3'); this.sortIndex = index; this.reset(); })
                    .accessibilityText('口碑榜排序方式')
                Select(this.categoryOptions()).attributeModifier(new DiscoverySelectStyle(this.interaction.pressedKey === 'discovery-4'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-4', event))
                    .selected(this.categoryIndex).value(this.categoryOptions()[this.categoryIndex].value)
                    .onSelect((index: number): void => { this.interaction.activate('discovery-4'); this.categoryIndex = index; this.reset(); })
                    .accessibilityText('口碑榜大分类或细分类')
                Text('报告日固定为北京时间昨天，最多展示前 100 名，当日无数据时为空榜。1 天逐档截零；7／30 天保留带符号净变化，评分指标可能超出 1～5，不代表累计星级均分。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                if (this.reputationInfo) {
                    Text(`报告日（北京时间）：${this.reputationInfo.report_date || '暂无'}\n数据生成时间（UTC）：${this.reputationInfo.generated_at}`)
                        .fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                    if (this.reputationInfo.data_stale) {
                        Text('服务端暂不可用，当前为服务端旧数据，生成时间如上。')
                            .fontSize(13).fontColor($r('app.color.v3_accent_orange'))
                    }
                    Text(this.reputationInfo.weight_formula).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                }
            }
            if (this.kind() === 'downloads' || this.kind() === 'growth') {
                Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(12), cross: LengthMetrics.vp(8) } }) {
                    Row({ space: 6 }) {
                        Text('排除华为').fontSize(13).fontColor($r('app.color.v3_text_primary'))
                        Toggle({ type: ToggleType.Switch, isOn: this.excludeHuawei }).selectedColor($r('app.color.diff_content'))
                            .attributeModifier(new DiscoveryToggleStyle(this.interaction.pressedKey === 'excludeHuawei'))
                            .onTouch((event: TouchEvent): void => this.interaction.touch('excludeHuawei', event))
                            .onChange((value: boolean): void => { this.interaction.activate('excludeHuawei'); this.excludeHuawei = value; this.reset(); })
                    }
                    Row({ space: 6 }) {
                        Text('排除元服务').fontSize(13).fontColor($r('app.color.v3_text_primary'))
                        Toggle({ type: ToggleType.Switch, isOn: this.excludeAtomic }).selectedColor($r('app.color.diff_content'))
                            .attributeModifier(new DiscoveryToggleStyle(this.interaction.pressedKey === 'excludeAtomic'))
                            .onTouch((event: TouchEvent): void => this.interaction.touch('excludeAtomic', event))
                            .onChange((value: boolean): void => { this.interaction.activate('excludeAtomic'); this.excludeAtomic = value; this.reset(); })
                    }
                }
            }
            if (this.kind() === 'daily') {
                Text('每款应用仅保留最近一次累计下载最高记录，按记录日期排列；数值为该次采集的累计下载量。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            } else if (this.kind() === 'growth') {
                Text('按快照周期比较累计下载量。期初缺少历史记录时以 0 为基线，可能产生较大增量。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            } else if (this.kind() === 'early') {
                Text('累计下载量 1000–99999 的应用，按细分赛道汇总增长；不代表最近上架。缺少基线时按 0 计算。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            } else if (this.kind() === 'category' || this.kind() === 'segment') {
                Text('按统计快照窗口内新增下载量排序。缺少基线的应用按 0 计算；点击查看该分类当前收录应用。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
            }
            Button('刷新', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-5'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-5', event)).enabled(!this.loading).onClick((): void => { this.interaction.activate('discovery-5'); this.load(true); })
        }.width('100%').alignItems(HorizontalAlign.Start)
    }
    @Builder
    private rows(): void {
        ForEach(this.reputation, (item: ReputationItem, i: number) => {
            AppSummaryRow({ enterOrder: i, name: `${i + 1}. ${item.name}`, appId: item.app_id, packageName: item.pkg_name,
                iconUrl: item.icon_url, subtitle: reputationSubtitle(item), subtitleMaxLines: 8,
                value: reputationValue(item),
                onOpen: (): void => this.openApp(item.app_id, item.pkg_name) })
        }, (item: ReputationItem) => item.app_id)
        ForEach(this.apps, (app: MarketApp, i: number) => {
            AppSummaryRow({ enterOrder: i, name: `${(this.page - 1) * DISCOVERY_PAGE_SIZE + i + 1}. ${app.name}`,
                appId: app.app_id, packageName: app.pkg_name, iconUrl: app.icon_url, subtitle: app.developer_name, value: `${formatCount(app.download_count)} 次`,
                onOpen: (): void => this.openApp(app.app_id, app.pkg_name) })
        }, (app: MarketApp) => app.app_id)
        ForEach(this.growth, (app: DownloadGrowthApp, i: number) => {
            AppSummaryRow({ enterOrder: i, appId: app.app_id, packageName: app.pkg_name, name: `${(this.page - 1) * DISCOVERY_PAGE_SIZE + i + 1}. ${app.name}`,
                subtitle: `${app.prior_period_date} → ${app.current_period_date}\n累计 ${formatCount(app.current_download_count)} 次`,
                value: `+${formatCount(app.download_increment)}`,
                onOpen: (): void => this.openApp(app.app_id, app.pkg_name) })
        }, (app: DownloadGrowthApp) => app.app_id)
        ForEach(this.daily, (app: DailyMaxDownloadApp, i: number) => {
            AppSummaryRow({ enterOrder: i, appId: app.app_id, packageName: app.pkg_name, name: app.app_name, subtitle: `最近记录：${app.report_date}`,
                value: `${formatCount(app.download_count)} 次`, onOpen: (): void => this.openApp(app.app_id, app.pkg_name) })
        }, (app: DailyMaxDownloadApp) => `${app.report_date}-${app.app_id}`)
        ForEach(this.developers, (developer: DeveloperRankingEntry, i: number) => {
            AppSummaryRow({ enterOrder: i, showIcon: false, name: `${(this.page - 1) * DISCOVERY_PAGE_SIZE + i + 1}. ${developer.developerName}`,
                value: `${developer.appCount} 款`, onOpen: (): void => {
                    openAppCollection(this.pageStack, { title: developer.developerName,
                        developerId: developer.developerId, developerName: developer.developerName });
                } })
        }, (developer: DeveloperRankingEntry) => `${developer.developerId}-${developer.developerName}`)
        ForEach(this.categories, (item: CategoryGrowth, i: number) => {
            AppSummaryRow({ enterOrder: i, showIcon: false, name: `${(this.page - 1) * DISCOVERY_PAGE_SIZE + i + 1}. ${item.segment_name || item.kind_name}`,
                subtitle: `${item.kind_name} · ${item.app_count} 款 · ${item.growing_app_pct}% 应用增长\n${item.no_baseline_apps} 款无基线`,
                value: `+${formatCount(item.downloads_increase)}`, onOpen: (): void => this.openCategory(item) })
        }, (item: CategoryGrowth) => `${item.kind_id}-${item.segment_name || ''}`)
    }
    @Builder
    private content(): void {
        Column({ space: 12 }) {
            this.controls()
            BrowserStatus({ loading: this.loading, error: this.error, stale: this.stale, empty: this.empty(),
                emptyText: '当前条件暂无可用数据', onRetry: (): void => { this.load(true); } })
            this.rows()
            if (this.kind() !== 'reputation') {
                BrowserPagination({ page: this.page, total: this.total, pageSize: DISCOVERY_PAGE_SIZE,
                    loading: this.loading, onPage: (page: number): void => { this.page = page; this.load(false); } })
            }
        }.width('100%')
    }
    build() {
        MarketPageFrame({ resetKey: `${this.index}-${this.period}-${this.excludeHuawei}-${this.excludeAtomic}-${this.sampleIndex}-${this.sortIndex}-${this.categoryIndex}-${this.page}`, title: '排行榜', content: (): void => { this.content(); }, onShown: (): void => this.shown() })
    }
}
