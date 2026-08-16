// 原生看板页面：复刻 S 站 web 看板（get_market/assets/html/main.html）的内容框架
// 数据来源与 web 版一致：/api/v0 下的 market_info、apps/list、charts/*
import { mediaquery, PromptAction } from '@kit.ArkUI';
import {
    fetchAppsPage,
    fetchMarketInfo,
    fetchRatingDist,
    fetchSdkDist,
    fetchTopDownloads,
    formatDate,
    formatNumber,
    formatSize
} from './api';
import type {
    AppSummary,
    AppsListResponse,
    MarketInfoResponse,
    RatingDistribution,
    SdkBucket
} from './types';

interface StatCardDef {
    label: string;
    value: string;
    color: string;
}

interface DistBarDef {
    label: string;
    count: number;
    percent: number;
    color: string;
}

interface SearchFieldOption {
    key: string;
    label: string;
}

interface SearchOpOption {
    key: string;
    label: string;
    exact: boolean;
}

const ACCENT_ROSE: string = '#E11D48';
const ACCENT_AMBER: string = '#D97706';
const ACCENT_EMERALD: string = '#059669';
const ACCENT_INDIGO: string = '#4F46E5';
const ACCENT_PURPLE: string = '#9333EA';
const ACCENT_BLUE: string = '#2563EB';
const ACCENT_TEAL: string = '#0D9488';
const BAR_PALETTE: string[] = [
    '#2563EB', '#0D9488', '#059669', '#D97706', '#E11D48', '#7C3AED', '#0891B2', '#65A30D',
];

// ==================== 子组件：概览统计卡片 ====================
@Component
struct NdStatCard {
    card: StatCardDef = { label: '', value: '-', color: ACCENT_INDIGO };

    build() {
        Column({ space: 6 }) {
            Text(this.card.label)
                .fontSize(12)
                .fontColor(this.card.color)
            Text(this.card.value)
                .fontSize(20)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.card.color)
        }
        // 宽度由外部 Row + layoutWeight 均分（保证最后一行也占满整行）
        .width('100%')
        .padding({ top: 14, bottom: 14 })
        .borderRadius(12)
        .backgroundColor($r('app.color.nd_card_bg'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
    }
}

// ==================== 子组件：下载榜单行 ====================
@Component
struct NdRankingRow {
    app: AppSummary = { app_id: '' };
    rank: number = 0;
    maxCount: number = 0;
    accent: string = ACCENT_BLUE;

    build() {
        Row({ space: 8 }) {
            Text(String(this.rank))
                .fontSize(13)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.rank <= 3 ? this.accent : $r('app.color.nd_text_sub'))
                .width(24)
                .textAlign(TextAlign.End)
            if (this.app.icon_url) {
                Image(this.app.icon_url)
                    .width(28).height(28).borderRadius(6)
                    .alt($r('app.media.startIcon'))
                    .objectFit(ImageFit.Cover)
            }
            Column({ space: 2 }) {
                Text(this.app.name ?? '未知')
                    .fontSize(13)
                    .fontColor($r('app.color.nd_text_main'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: 120 })
                Text(this.app.developer_name ?? '')
                    .fontSize(10)
                    .fontColor($r('app.color.nd_text_sub'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .constraintSize({ maxWidth: 120 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Stack({ alignContent: Alignment.Start }) {
                Row()
                    .width('100%')
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.nd_bar_track'))
                Row()
                    .width(this.maxCount > 0 ? `${Math.max((this.app.download_count ?? 0) / this.maxCount * 100, 4)}%` : '0%')
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor(this.accent)
            }
            .width(80)

            Text(formatNumber(this.app.download_count))
                .fontSize(12)
                .fontColor($r('app.color.nd_text_main'))
                .width(56)
                .textAlign(TextAlign.End)
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 5, bottom: 5 })
    }
}

// ==================== 子组件：分布比例条 ====================
@Component
struct NdDistBar {
    bar: DistBarDef = { label: '', count: 0, percent: 0, color: ACCENT_BLUE };

    build() {
        Column({ space: 3 }) {
            Row() {
                Text(this.bar.label)
                    .fontSize(11)
                    .fontColor($r('app.color.nd_text_sub'))
                Blank()
                Text(`${formatNumber(this.bar.count)} · ${this.bar.percent.toFixed(1)}%`)
                    .fontSize(11)
                    .fontColor($r('app.color.nd_text_main'))
            }
            .width('100%')
            Stack({ alignContent: Alignment.Start }) {
                Row()
                    .width('100%')
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor($r('app.color.nd_bar_track'))
                Row()
                    .width(`${Math.max(this.bar.percent, 1)}%`)
                    .height(8)
                    .borderRadius(4)
                    .backgroundColor(this.bar.color)
            }
            .width('100%')
        }
        .width('100%')
        .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    }
}

// ==================== 子组件：分布区块（评分/SKD） ====================
@Component
struct NdDistSection {
    title: string = '';
    accent: string = ACCENT_PURPLE;
    // 直接实例化的固定组件（非 ForEach），普通成员不会随父组件 @State 更新，必须用 @Prop 同步
    @Prop bars: DistBarDef[] = [];
    // 窄屏纵向排列时占满整行；1+2 布局 49.5%；1x3 布局 32%
    @Prop sectionWidth: string = '49.5%';

    build() {
        Column() {
            Text(this.title)
                .fontSize(16)
                .fontWeight(FontWeight.Bold)
                .fontColor(this.accent)
                .width('100%')
                .textAlign(TextAlign.Center)
                .padding({ top: 10, bottom: 8 })
            Divider().color($r('app.color.nd_card_border'))
            if (this.bars.length === 0) {
                Text('暂无数据')
                    .fontSize(12)
                    .fontColor($r('app.color.nd_text_sub'))
                    .padding(20)
            } else {
                ForEach(this.bars, (bar: DistBarDef) => {
                    NdDistBar({ bar: bar })
                }, (bar: DistBarDef) => bar.label)
            }
        }
        .width(this.sectionWidth)
        .backgroundColor($r('app.color.nd_card_bg'))
        .borderRadius(12)
        .clip(true)
    }
}

// ==================== 子组件：应用列表行 ====================
@Component
struct NdAppRow {
    app: AppSummary = { app_id: '' };
    seq: number = 0;

    private ratingLabel(): string {
        // 后端 numeric 字段序列化成了字符串（如 "3.9"），也可能为 null/undefined，统一 Number() 转换
        const raw = this.app.average_rating;
        if (raw === undefined || raw === null) {
            return '-';
        }
        const rating = Number(raw);
        if (Number.isNaN(rating)) {
            return '-';
        }
        return rating.toFixed(1);
    }

    build() {
        Row() {
            Text(String(this.seq))
                .fontSize(11)
                .fontColor($r('app.color.nd_text_sub'))
                .width(40)
            Row({ space: 6 }) {
                if (this.app.icon_url) {
                    Image(this.app.icon_url)
                        .width(24).height(24).borderRadius(5)
                        .alt($r('app.media.startIcon'))
                        .objectFit(ImageFit.Cover)
                }
                Text(this.app.name ?? '未知')
                    .fontSize(12)
                    .fontColor($r('app.color.nd_text_main'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
            }
            .width(170)
            .alignItems(VerticalAlign.Center)

            Text(this.app.developer_name ?? '未知')
                .fontSize(11)
                .fontColor(ACCENT_BLUE)
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(120)

            Text(`${this.app.kind_type_name ?? '-'}-${this.app.kind_name ?? '-'}-${this.app.tag_name ?? '-'}`)
                .fontSize(10)
                .fontColor($r('app.color.nd_text_main'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .width(150)

            Text(this.ratingLabel())
                .fontSize(11)
                .fontColor($r('app.color.nd_text_main'))
                .width(60)

            Text(formatNumber(this.app.total_star_rating_count))
                .fontSize(11)
                .fontColor($r('app.color.nd_text_main'))
                .width(70)

            Text(formatNumber(this.app.download_count))
                .fontSize(11)
                .fontColor($r('app.color.nd_text_main'))
                .width(80)

            Text(formatSize(this.app.size_bytes))
                .fontSize(11)
                .fontColor($r('app.color.nd_text_sub'))
                .width(70)

            Text(formatDate(this.app.updated_at))
                .fontSize(11)
                .fontColor($r('app.color.nd_text_sub'))
                .width(90)
        }
        .width('100%')
        .padding({ top: 6, bottom: 6 })
        .alignItems(VerticalAlign.Center)
    }
}

// ==================== 主组件 ====================
@Component
export struct NativeDashboard {
    // Dashboard 页通过父子 @Link 传递刷新信号，避免跨页面事件总线。
    @Link @Watch('onRefreshTick') nativeRefreshTick: number;

    // 概览统计
    @State statCards: StatCardDef[] = [];
    @State lastUpdate: string = '-';
    @State overviewError: string = '';

    // 下载榜
    @State topDownloads: AppSummary[] = [];
    @State topDownloadsNH: AppSummary[] = [];
    @State maxTotalDownload: number = 0;
    @State maxNHDownload: number = 0;
    @State rankingsLoading: boolean = true;

    // 分布图（用原生比例条替代 web 的饼图）
    @State ratingBars: DistBarDef[] = [];
    @State minSdkBars: DistBarDef[] = [];
    @State targetSdkBars: DistBarDef[] = [];

    // 布局宽度分界（mediaquery 基于应用窗口宽度，窗口模式/分屏/旋转/折叠都会跟随）：
    // < 432vp（普通手机竖屏）：纵向排列
    // >= 432vp（Pura X 展开态宽度）：1+2 横排
    // >= 840vp（官方 lg 断点，平板横屏/大窗口）：1x3 三列
    @State private isWideLayout: boolean = false;
    @State private useThreeColumn: boolean = false;
    private readonly wideLayoutQuery: string = '(min-width: 432vp)';
    private readonly threeColumnQuery: string = '(min-width: 840vp)';
    private wideQueryListener: mediaquery.MediaQueryListener | null = null;
    private threeColumnListener: mediaquery.MediaQueryListener | null = null;

    // 应用列表
    @State apps: AppSummary[] = [];
    @State appsTotal: number = 0;
    @State appsPage: number = 1;
    @State appsLoading: boolean = false;
    @State searchField: string = 'name';
    @State searchOp: string = 'ilike';
    @State searchValue: string = '';
    @State sortField: string = 'download_count';
    @State sortDesc: boolean = true;

    // 下拉框选项（aboutToAppear 里生成）
    @State searchFieldOptions: SelectOption[] = [];
    @State searchOpOptions: SelectOption[] = [];

    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    private readonly pageSize: number = 20;
    // 与 web 端一致的输入防抖自动搜索（dashboard.js debounce 500ms）
    private searchDebounceTimer: number = -1;
    private readonly searchDebounceDelay: number = 500;
    private readonly fieldKeys: string[] = ['name', 'pkg_name', 'app_id', 'developer_name', 'kind_name', 'tag_name'];
    private readonly fieldLabels: string[] = ['应用名称', '包名', '应用ID', '开发者名称', '分类名称', '标签'];
    private readonly opKeys: string[] = ['ilike', 'eq', 'not_ilike', 'ne', 'gt', 'lt'];
    private readonly opLabels: string[] = ['包含', '等于', '不包含', '不等于', '大于', '小于'];
    private readonly opExact: boolean[] = [false, true, false, true, true, true];

    aboutToAppear(): void {
        // 模块级 matchMediaSync 已弃用，改用 UIContext.getMediaQuery() 实例入口
        const mediaQuery = this.getUIContext().getMediaQuery();
        const wideQuery = mediaQuery.matchMediaSync(this.wideLayoutQuery);
        this.isWideLayout = wideQuery.matches;
        this.wideQueryListener = wideQuery;
        wideQuery.on('change', (result: mediaquery.MediaQueryResult) => {
            this.isWideLayout = result.matches;
        });
        const threeQuery = mediaQuery.matchMediaSync(this.threeColumnQuery);
        this.useThreeColumn = threeQuery.matches;
        this.threeColumnListener = threeQuery;
        threeQuery.on('change', (result: mediaquery.MediaQueryResult) => {
            this.useThreeColumn = result.matches;
        });
        const fieldOptions: SelectOption[] = [];
        for (let i = 0; i < this.fieldKeys.length; i++) {
            const option: SelectOption = { value: this.fieldLabels[i] };
            fieldOptions.push(option);
        }
        this.searchFieldOptions = fieldOptions;
        const opOptions: SelectOption[] = [];
        for (let i = 0; i < this.opKeys.length; i++) {
            const option: SelectOption = { value: this.opLabels[i] };
            opOptions.push(option);
        }
        this.searchOpOptions = opOptions;
        this.loadAll();
    }

    aboutToDisappear(): void {
        if (this.wideQueryListener !== null) {
            this.wideQueryListener.off('change');
            this.wideQueryListener = null;
        }
        if (this.threeColumnListener !== null) {
            this.threeColumnListener.off('change');
            this.threeColumnListener = null;
        }
        this.cancelSearchDebounce();
    }

    private onRefreshTick(): void {
        this.loadAll();
    }

    private loadAll(): void {
        this.loadOverview();
        this.loadRankings();
        this.loadCharts();
        this.loadApps();
    }

    private loadOverview(): void {
        this.overviewError = '';
        fetchMarketInfo().then((res: MarketInfoResponse) => {
            if (!res.success || !res.data || !res.data.app_count) {
                this.overviewError = '数据加载失败';
                return;
            }
            const cards: StatCardDef[] = [
                { label: '鸿蒙装机量', value: formatNumber(res.data.app_count.max_download_count), color: ACCENT_ROSE },
                { label: '鸿蒙应用总数', value: formatNumber(res.data.app_count.apps), color: ACCENT_AMBER },
                { label: '鸿蒙元服务总数', value: formatNumber(res.data.app_count.atomic_services), color: ACCENT_EMERALD },
                { label: '鸿蒙开发者总数', value: formatNumber(res.data.developer_count), color: ACCENT_INDIGO },
                { label: '已知专题数量', value: formatNumber(res.data.substance_count), color: ACCENT_PURPLE },
            ];
            this.statCards = cards;
            this.lastUpdate = res.timestamp ? formatDate(res.timestamp) : '-';
        }).catch((e: Error) => {
            this.overviewError = `概览加载失败: ${e.message}`;
        });
    }

    private loadRankings(): void {
        this.rankingsLoading = true;
        const total = fetchTopDownloads(false).then((list: AppSummary[]) => {
            this.topDownloads = list;
            this.maxTotalDownload = list.length > 0 ? (list[0].download_count ?? 0) : 0;
        });
        const nonHuawei = fetchTopDownloads(true).then((list: AppSummary[]) => {
            this.topDownloadsNH = list;
            this.maxNHDownload = list.length > 0 ? (list[0].download_count ?? 0) : 0;
        });
        Promise.all([total, nonHuawei]).then(() => {
            this.rankingsLoading = false;
        }).catch(() => {
            this.rankingsLoading = false;
        });
    }

    private toDistBars(pairs: SdkBucket[]): DistBarDef[] {
        const sorted = pairs.slice().sort((a: SdkBucket, b: SdkBucket) => b.count - a.count).slice(0, 8);
        const sum = sorted.reduce((acc: number, item: SdkBucket) => acc + item.count, 0);
        const bars: DistBarDef[] = [];
        for (let idx = 0; idx < sorted.length; idx++) {
            const item = sorted[idx];
            const bar: DistBarDef = {
                label: `API ${item.sdk}`,
                count: item.count,
                percent: sum > 0 ? (item.count / sum) * 100 : 0,
                color: BAR_PALETTE[idx % BAR_PALETTE.length],
            };
            bars.push(bar);
        }
        return bars;
    }

    private loadCharts(): void {
        fetchRatingDist().then((dist: RatingDistribution) => {
            const entries: DistBarDef[] = [];
            const labels: string[] = ['无评分', '[1-2)星', '[2-3)星', '[3-4)星', '[4-5]星'];
            const values: number[] = [dist.star_1, dist.star_2, dist.star_3, dist.star_4, dist.star_5];
            const colors: string[] = [ACCENT_ROSE, ACCENT_AMBER, '#CA8A04', ACCENT_EMERALD, ACCENT_BLUE];
            const sum = values.reduce((acc: number, v: number) => acc + v, 0);
            for (let i = 0; i < values.length; i++) {
                const bar: DistBarDef = {
                    label: labels[i],
                    count: values[i],
                    percent: sum > 0 ? (values[i] / sum) * 100 : 0,
                    color: colors[i],
                };
                entries.push(bar);
            }
            this.ratingBars = entries;
        }).catch((e: Error) => {
            console.error(`[nativeDashboard] 评分分布加载失败: ${e.message}`);
        });
        fetchSdkDist('min_sdk').then((buckets: SdkBucket[]) => {
            this.minSdkBars = this.toDistBars(buckets);
        }).catch((e: Error) => {
            console.error(`[nativeDashboard] min_sdk 分布加载失败: ${e.message}`);
        });
        fetchSdkDist('target_sdk').then((buckets: SdkBucket[]) => {
            this.targetSdkBars = this.toDistBars(buckets);
        }).catch((e: Error) => {
            console.error(`[nativeDashboard] target_sdk 分布加载失败: ${e.message}`);
        });
    }

    private currentSearchExact(): boolean {
        const idx = this.opKeys.indexOf(this.searchOp);
        return idx >= 0 ? this.opExact[idx] : false;
    }

    private loadApps(): void {
        this.appsLoading = true;
        fetchAppsPage(
            this.appsPage,
            this.pageSize,
            this.sortField,
            this.sortDesc,
            this.searchValue.trim() !== '' ? this.searchField : undefined,
            this.searchValue.trim(),
            this.currentSearchExact(),
            false,
        ).then((res: AppsListResponse) => {
            if (!res.data || !res.data.data) {
                throw new Error(`应用列表接口返回异常 (success=${res.success})`);
            }
            this.apps = res.data.data;
            this.appsTotal = res.data.total_count ?? 0;
            this.appsLoading = false;
        }).catch((e: Error) => {
            this.appsLoading = false;
            this.PromptAction.showToast({ message: `应用列表加载失败: ${e.message}`, duration: 2000 });
        });
    }

    private totalPages(): number {
        return Math.max(1, Math.ceil(this.appsTotal / this.pageSize));
    }

    private submitSearch(): void {
        this.cancelSearchDebounce();
        this.appsPage = 1;
        this.loadApps();
    }

    // 输入停顿 500ms 后自动搜索（含清空输入恢复默认列表）
    private scheduleAutoSearch(): void {
        this.cancelSearchDebounce();
        this.searchDebounceTimer = setTimeout(() => {
            this.appsPage = 1;
            this.loadApps();
        }, this.searchDebounceDelay);
    }

    private cancelSearchDebounce(): void {
        if (this.searchDebounceTimer !== -1) {
            clearTimeout(this.searchDebounceTimer);
            this.searchDebounceTimer = -1;
        }
    }

    // 字段/操作符切换时，输入框有内容就立即搜索（对应 web 端 change 监听）
    private onSearchOptionChanged(): void {
        if (this.searchValue.trim() !== '') {
            this.submitSearch();
        }
    }

    private clearSearch(): void {
        this.cancelSearchDebounce();
        this.searchValue = '';
        this.appsPage = 1;
        this.loadApps();
    }

    private changeSort(field: string): void {
        if (this.sortField === field) {
            this.sortDesc = !this.sortDesc;
        } else {
            this.sortField = field;
            this.sortDesc = true;
        }
        this.appsPage = 1;
        this.loadApps();
    }

    build() {
        Scroll() {
            Column({ space: 10 }) {
                // 顶部安全区留白（与 web tab 的处理保持一致）
                Blank().height(80).width('100%')

                // ===================== 头部卡片 =====================
                Column({ space: 10 }) {
                    Column({ space: 4 }) {
                        Text('鸿蒙应用看板')
                            .fontSize(22)
                            .fontWeight(FontWeight.Bold)
                            .fontColor(ACCENT_INDIGO)
                        Text('数据收集自网络，不保证来源的准确性、完整性和真实性，仅供参考')
                            .fontSize(11)
                            .fontColor($r('app.color.nd_text_sub'))
                    }
                    .width('100%')

                    // 刷新走 Dashboard 页的悬浮按钮（原生 tab 下触发 nativeRefreshTick）
                    Text(`最后更新: ${this.lastUpdate}`)
                        .fontSize(11)
                        .fontColor($r('app.color.nd_text_sub'))
                        .width('100%')

                    if (this.overviewError !== '') {
                        Text(this.overviewError)
                            .fontSize(11)
                            .fontColor(ACCENT_ROSE)
                            .width('100%')
                    }
                }
                .width('100%')
                .padding(14)
                .borderRadius(12)
                .backgroundColor($r('app.color.nd_card_bg'))
                .border({ width: 1, color: $r('app.color.nd_card_border') })

                // ===================== 概览统计卡片 =====================
                if (this.statCards.length === 0 && this.overviewError === '') {
                    Row({ space: 8 }) {
                        LoadingProgress().width(24).height(24).color(ACCENT_INDIGO)
                        Text('加载概览数据...')
                            .fontSize(12)
                            .fontColor($r('app.color.nd_text_sub'))
                    }
                    .justifyContent(FlexAlign.Center)
                    .padding(16)
                }
                // 断点分行渲染：每行内 layoutWeight 均分，最后一行也占满整行
                if (this.useThreeColumn) {
                    // 大屏：一行 5 个
                    Row({ space: 8 }) {
                        ForEach(this.statCards, (card: StatCardDef) => {
                            NdStatCard({ card: card }).layoutWeight(1)
                        }, (card: StatCardDef) => card.label + card.value)
                    }
                    .width('100%')
                } else if (this.isWideLayout) {
                    // 中等：3 + 2，两行都均分整行
                    Column({ space: 8 }) {
                        Row({ space: 8 }) {
                            ForEach(this.statCards.slice(0, 3), (card: StatCardDef) => {
                                NdStatCard({ card: card }).layoutWeight(1)
                            }, (card: StatCardDef) => card.label + card.value)
                        }
                        .width('100%')
                        Row({ space: 8 }) {
                            ForEach(this.statCards.slice(3, 5), (card: StatCardDef) => {
                                NdStatCard({ card: card }).layoutWeight(1)
                            }, (card: StatCardDef) => card.label + card.value)
                        }
                        .width('100%')
                    }
                    .width('100%')
                } else {
                    // 窄屏：2 + 2 + 1
                    Column({ space: 8 }) {
                        Row({ space: 8 }) {
                            ForEach(this.statCards.slice(0, 2), (card: StatCardDef) => {
                                NdStatCard({ card: card }).layoutWeight(1)
                            }, (card: StatCardDef) => card.label + card.value)
                        }
                        .width('100%')
                        Row({ space: 8 }) {
                            ForEach(this.statCards.slice(2, 4), (card: StatCardDef) => {
                                NdStatCard({ card: card }).layoutWeight(1)
                            }, (card: StatCardDef) => card.label + card.value)
                        }
                        .width('100%')
                        Row({ space: 8 }) {
                            ForEach(this.statCards.slice(4, 5), (card: StatCardDef) => {
                                NdStatCard({ card: card }).layoutWeight(1)
                            }, (card: StatCardDef) => card.label + card.value)
                        }
                        .width('100%')
                    }
                    .width('100%')
                }

                // ===================== 总下载榜 =====================
                Column() {
                    Text('总下载榜')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ACCENT_BLUE)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .padding({ top: 10, bottom: 8 })
                    Divider().color($r('app.color.nd_card_border'))
                    if (this.rankingsLoading) {
                        LoadingProgress().width(28).height(28).margin(16).color(ACCENT_BLUE)
                    } else {
                        ForEach(this.topDownloads, (app: AppSummary, idx: number) => {
                            NdRankingRow({
                                app: app,
                                rank: idx + 1,
                                maxCount: this.maxTotalDownload,
                                accent: ACCENT_BLUE,
                            })
                        }, (app: AppSummary) => app.app_id + String(app.download_count))
                    }
                }
                .width('100%')
                .backgroundColor($r('app.color.nd_card_bg'))
                .borderRadius(12)
                .clip(true)

                // ===================== 下载量历史（原生图表施工中） =====================
                Column({ space: 6 }) {
                    Text('鸿蒙应用下载量历史')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ACCENT_EMERALD)
                        .padding({ top: 10, bottom: 4 })
                    Text('原生折线图施工中，请前往 S 站查看')
                        .fontSize(11)
                        .fontColor($r('app.color.nd_text_sub'))
                        .padding({ bottom: 12 })
                }
                .width('100%')
                .backgroundColor($r('app.color.nd_card_bg'))
                .borderRadius(12)
                .clip(true)

                // ===================== 三个分布卡片 =====================
                // < 432vp 纵向；432-840vp 1+2；>= 840vp 1x3
                if (this.useThreeColumn) {
                    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
                        NdDistSection({ title: '总应用评分分布', accent: ACCENT_PURPLE, bars: this.ratingBars, sectionWidth: '32%' })
                        NdDistSection({ title: '应用目标SDK分布', accent: ACCENT_PURPLE, bars: this.targetSdkBars, sectionWidth: '32%' })
                        NdDistSection({ title: '应用最小SDK分布', accent: ACCENT_PURPLE, bars: this.minSdkBars, sectionWidth: '32%' })
                    }
                    .width('100%')
                } else if (this.isWideLayout) {
                    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.SpaceBetween }) {
                        NdDistSection({ title: '总应用评分分布', accent: ACCENT_PURPLE, bars: this.ratingBars, sectionWidth: '49.5%' })
                        NdDistSection({ title: '应用目标SDK分布', accent: ACCENT_PURPLE, bars: this.targetSdkBars, sectionWidth: '49.5%' })
                        NdDistSection({ title: '应用最小SDK分布', accent: ACCENT_PURPLE, bars: this.minSdkBars, sectionWidth: '49.5%' })
                    }
                    .width('100%')
                } else {
                    Column({ space: 10 }) {
                        NdDistSection({ title: '总应用评分分布', accent: ACCENT_PURPLE, bars: this.ratingBars, sectionWidth: '100%' })
                        NdDistSection({ title: '应用目标SDK分布', accent: ACCENT_PURPLE, bars: this.targetSdkBars, sectionWidth: '100%' })
                        NdDistSection({ title: '应用最小SDK分布', accent: ACCENT_PURPLE, bars: this.minSdkBars, sectionWidth: '100%' })
                    }
                    .width('100%')
                }

                // ===================== 非华为应用下载榜 =====================
                Column() {
                    Text('非华为应用/内置应用下载榜')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ACCENT_TEAL)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .padding({ top: 10, bottom: 8 })
                    Divider().color($r('app.color.nd_card_border'))
                    if (this.rankingsLoading) {
                        LoadingProgress().width(28).height(28).margin(16).color(ACCENT_TEAL)
                    } else {
                        ForEach(this.topDownloadsNH, (app: AppSummary, idx: number) => {
                            NdRankingRow({
                                app: app,
                                rank: idx + 1,
                                maxCount: this.maxNHDownload,
                                accent: ACCENT_TEAL,
                            })
                        }, (app: AppSummary) => app.app_id + String(app.download_count))
                    }
                }
                .width('100%')
                .backgroundColor($r('app.color.nd_card_bg'))
                .borderRadius(12)
                .clip(true)

                // ===================== 应用列表 =====================
                Column() {
                    Text('应用列表')
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor(ACCENT_AMBER)
                        .width('100%')
                        .textAlign(TextAlign.Center)
                        .padding({ top: 10, bottom: 8 })
                    Divider().color($r('app.color.nd_card_border'))

                    // 快速搜索区
                    Column({ space: 8 }) {
                        Row({ space: 8 }) {
                            Select(this.searchFieldOptions)
                                .selected(this.fieldKeys.indexOf(this.searchField))
                                .value(this.fieldLabels[this.fieldKeys.indexOf(this.searchField)] ?? '应用名称')
                                .fontColor(ACCENT_AMBER)
                                .font({ size: 13 })
                                .backgroundColor($r('app.color.nd_bar_track'))
                                .borderRadius(8)
                                .onSelect((index: number) => {
                                    this.searchField = this.fieldKeys[index];
                                    this.onSearchOptionChanged();
                                })

                            Select(this.searchOpOptions)
                                .selected(this.opKeys.indexOf(this.searchOp))
                                .value(this.opLabels[this.opKeys.indexOf(this.searchOp)] ?? '包含')
                                .fontColor(ACCENT_AMBER)
                                .font({ size: 13 })
                                .backgroundColor($r('app.color.nd_bar_track'))
                                .borderRadius(8)
                                .onSelect((index: number) => {
                                    this.searchOp = this.opKeys[index];
                                    this.onSearchOptionChanged();
                                })
                        }
                        .width('100%')

                        Row({ space: 8 }) {
                            TextInput({ placeholder: '输入关键词搜索...', text: this.searchValue })
                                .fontSize(13)
                                .layoutWeight(1)
                                .backgroundColor($r('app.color.nd_bar_track'))
                                .borderRadius(8)
                                .onChange((value: string) => {
                                    this.searchValue = value;
                                    this.scheduleAutoSearch();
                                })
                                .onSubmit(() => {
                                    // Enter 立即搜索，取消防抖中的自动搜索
                                    this.submitSearch();
                                })
                            Button('搜索')
                                .fontSize(13)
                                .backgroundColor(ACCENT_INDIGO)
                                .onClick(() => {
                                    this.submitSearch();
                                })
                            Button('清除')
                                .fontSize(13)
                                .backgroundColor($r('app.color.nd_text_sub'))
                                .onClick(() => {
                                    this.clearSearch();
                                })
                        }
                        .width('100%')
                    }
                    .width('100%')
                    .padding(10)

                    // 表格（横向滚动）
                    Scroll() {
                        Column() {
                            Row() {
                                Text('序号')
                                    .fontSize(11).fontColor($r('app.color.nd_text_sub')).width(40)
                                Text('应用名称')
                                    .fontSize(11).fontColor($r('app.color.nd_text_sub')).width(170)
                                Text('开发者')
                                    .fontSize(11).fontColor($r('app.color.nd_text_sub')).width(120)
                                Text('分类')
                                    .fontSize(11).fontColor($r('app.color.nd_text_sub')).width(150)
                                Text('评分')
                                    .fontSize(11).fontColor($r('app.color.nd_text_sub')).width(60)
                                Text('评分数量')
                                    .fontSize(11).fontColor(ACCENT_BLUE).fontWeight(FontWeight.Bold).width(70)
                                    .onClick(() => {
                                        this.changeSort('total_star_rating_count');
                                    })
                                Text(this.sortField === 'download_count' ? (this.sortDesc ? '下载量 ↓' : '下载量 ↑') : '下载量')
                                    .fontSize(11).fontColor(ACCENT_BLUE).fontWeight(FontWeight.Bold).width(80)
                                    .onClick(() => {
                                        this.changeSort('download_count');
                                    })
                                Text(this.sortField === 'size_bytes' ? (this.sortDesc ? '大小 ↓' : '大小 ↑') : '大小')
                                    .fontSize(11).fontColor(ACCENT_BLUE).fontWeight(FontWeight.Bold).width(70)
                                    .onClick(() => {
                                        this.changeSort('size_bytes');
                                    })
                                Text(this.sortField === 'updated_at' ? (this.sortDesc ? '上次数据更新 ↓' : '上次数据更新 ↑') : '上次数据更新')
                                    .fontSize(11).fontColor(ACCENT_BLUE).fontWeight(FontWeight.Bold).width(90)
                                    .onClick(() => {
                                        this.changeSort('updated_at');
                                    })
                            }
                            .width(866)
                            .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                            .backgroundColor($r('app.color.nd_bar_track'))

                            if (this.appsLoading) {
                                LoadingProgress().width(28).height(28).margin(16).color(ACCENT_AMBER)
                            } else if (this.apps.length === 0) {
                                Text('未找到应用')
                                    .fontSize(12)
                                    .fontColor($r('app.color.nd_text_sub'))
                                    .margin(16)
                            } else {
                                ForEach(this.apps, (app: AppSummary, idx: number) => {
                                    NdAppRow({ app: app, seq: (this.appsPage - 1) * this.pageSize + idx + 1 })
                                }, (app: AppSummary) => app.app_id + String(app.download_count))
                            }
                        }
                        .width(866)
                        .constraintSize({ minWidth: 866 })
                    }
                    .width('100%')
                    .scrollable(ScrollDirection.Horizontal)
                    .scrollBar(BarState.Off)
                    .edgeEffect(EdgeEffect.None)

                    // 分页
                    Row({ space: 12 }) {
                        Button('上一页')
                            .fontSize(13)
                            .backgroundColor($r('app.color.nd_text_sub'))
                            .enabled(this.appsPage > 1)
                            .onClick(() => {
                                if (this.appsPage > 1) {
                                    this.appsPage -= 1;
                                    this.loadApps();
                                }
                            })
                        Text(`第 ${this.appsPage} / ${this.totalPages()} 页 · 共 ${formatNumber(this.appsTotal)} 条`)
                            .fontSize(11)
                            .fontColor($r('app.color.nd_text_sub'))
                        Button('下一页')
                            .fontSize(13)
                            .backgroundColor(ACCENT_AMBER)
                            .enabled(this.appsPage < this.totalPages())
                            .onClick(() => {
                                if (this.appsPage < this.totalPages()) {
                                    this.appsPage += 1;
                                    this.loadApps();
                                }
                            })
                    }
                    .width('100%')
                    .justifyContent(FlexAlign.Center)
                    .padding(12)
                }
                .width('100%')
                .backgroundColor($r('app.color.nd_card_bg'))
                .borderRadius(12)
                .clip(true)

                // 底部安全区留白
                Blank().height(100).width('100%')
            }
            .width('100%')
            .padding({ left: 12, right: 12 })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .edgeEffect(EdgeEffect.Spring)
        .backgroundColor($r('app.color.background'))
    }
}
