import { PromptAction } from '@kit.ArkUI';
import {
    BACKGROUND_REFRESH_DELAY_MS,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_SEARCH,
} from '../../common/constants';
import {
    consumeSearchTarget,
    getContinuationState,
    setContinuationView,
    setDetailTarget,
} from '../../common/appState';
import { fetchAppById, fetchAppByPackage, fetchAppsPage, submitApp } from '../../common/MarketApi';
import { formatCount, formatDateTime } from '../../common/format';
import { parseInputSplitLinksPkgsAndAppIds } from '../../common/utils';
import { showToastSafely } from '../../common/safeUi';
import type {
    ApiDataResult,
    AppDetailPayload,
    AppRouteTarget,
    BaseAPIResponse,
    MarketApp,
    PageInfo,
    SearchTarget,
    SubmitAppBody,
} from '../../common/types';
import { vibration } from '../../common/vibration';

interface NameSearchResult {
    apps: MarketApp[];
    stale: boolean;
}

@Component
export struct SearchPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop @Watch('onRequestVersionChanged') requestVersion: number;
    @Prop @Watch('onScrollToTopVersionChanged') scrollToTopVersion: number = 0;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    @StorageLink('username') private username: string = '';
    @State private input: string = '';
    @State private loading: boolean = false;
    @State private status: string = '输入应用名称、包名、App ID 或华为应用市场链接';
    @State private errorMessage: string = '';
    @State private results: MarketApp[] = [];
    @State private resultApp: MarketApp | undefined = undefined;
    @State private fromCache: boolean = false;
    private activeTarget: AppRouteTarget = {};
    private openDetailAfterSearch: boolean = false;
    private backgroundUpdateToken: number = 0;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private restoredScroll: boolean = false;

    private onScrollToTopVersionChanged(): void {
        if (this.scrollToTopVersion <= 0) {
            return;
        }
        try {
            this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
        } catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]', `返回顶部失败: ${JSON.stringify(error)}`);
        }
    }

    private vibrate(): void {
        if (this.vibrationEnabled) vibration.dotVibration();
    }

    private decodeInputValue(value: string): string {
        try {
            return decodeURIComponent(value);
        } catch (error) {
            console.warn('[Dashboard][pages/main/SearchPage][WARN]', `输入链接参数解码失败，保留原值: ${JSON.stringify(error)}`);
            return value;
        }
    }

    private onRequestVersionChanged(): void {
        this.consumePendingTarget();
    }

    private consumePendingTarget(): void {
        const target: SearchTarget = consumeSearchTarget();
        const raw = target.rawText || target.packageName || target.appId || '';
        if (!raw) {
            return;
        }
        this.input = raw;
        this.openDetailAfterSearch = target.openDetailOnSuccess === true;
        if (target.autoRun !== false) {
            setTimeout((): void => {
                this.search();
            }, 0);
        }
    }

    private targetFromInput(): AppRouteTarget {
        const dashboardAppId = this.input.match(/[?&#]app_id=([^&#]+)/);
        if (dashboardAppId && dashboardAppId[1]) {
            return { appId: this.decodeInputValue(dashboardAppId[1]) };
        }
        const dashboardPackage = this.input.match(/[?&#]pkg=([^&#]+)/);
        if (dashboardPackage && dashboardPackage[1]) {
            return { packageName: this.decodeInputValue(dashboardPackage[1]) };
        }
        const parsed = parseInputSplitLinksPkgsAndAppIds(this.input);
        if (parsed.app_ids.length > 0) {
            const appId = parsed.app_ids[parsed.app_ids.length - 1];
            return { appId: appId.startsWith('C') ? appId : `C${appId}` };
        }
        if (parsed.pkgs.length > 0) {
            return { packageName: parsed.pkgs[parsed.pkgs.length - 1] };
        }
        const idMatch = this.input.match(/[?&]id=([^&#]+)/);
        if (idMatch && idMatch[1]) {
            return { packageName: this.decodeInputValue(idMatch[1]) };
        }
        return {};
    }

    private detailRequest(target: AppRouteTarget, force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (target.appId) {
            return fetchAppById(target.appId, force);
        }
        if (target.packageName) {
            return fetchAppByPackage(target.packageName, force);
        }
        return Promise.reject(new Error('缺少应用标识'));
    }

    private relevance(app: MarketApp, query: string): number {
        const normalized = query.trim().toLowerCase();
        const name = (app.name || '').toLowerCase();
        const packageName = (app.pkg_name || '').toLowerCase();
        if (name === normalized || packageName === normalized) return 0;
        if (name.startsWith(normalized)) return 1;
        if (packageName.startsWith(normalized)) return 2;
        if (name.includes(normalized)) return 3;
        if (packageName.includes(normalized)) return 4;
        return 5;
    }

    private async findByName(name: string): Promise<NameSearchResult> {
        const firstResult = await fetchAppsPage(
            1,
            100,
            'download_count',
            true,
            'name',
            name,
            false,
            true,
        );
        const response = firstResult.data as BaseAPIResponse<PageInfo<MarketApp>>;
        let matches: MarketApp[] = response.data?.data ?? [];
        if (!response.success || matches.length === 0) {
            throw new Error('未找到同名应用；如需投稿，请输入包名、App ID 或应用市场链接');
        }
        const totalPages = response.data?.total_pages ?? 1;
        let stale = firstResult.stale;
        for (let page = 2; page <= totalPages; page++) {
            const nextResult = await fetchAppsPage(
                page, 100, 'download_count', true, 'name', name, false, true,
            );
            const nextResponse = nextResult.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (nextResponse.success && nextResponse.data) {
                matches = matches.concat(nextResponse.data.data ?? []);
            }
            stale = stale || nextResult.stale;
        }
        return {
            apps: matches.sort((left: MarketApp, right: MarketApp) =>
                this.relevance(left, name) - this.relevance(right, name)),
            stale,
        };
    }

    private async submitNew(target: AppRouteTarget): Promise<void> {
        const body: SubmitAppBody = { comment: { user: this.username } };
        if (target.appId) {
            body.app_id = target.appId;
        } else if (target.packageName) {
            body.pkg_name = target.packageName;
        } else {
            throw new Error('投稿缺少应用标识');
        }
        const response = await submitApp(body);
        if (!response.success || !response.data?.full_info) {
            throw new Error('投稿接口未返回有效应用数据');
        }
        this.resultApp = response.data.full_info;
        this.results = [response.data.full_info];
        this.activeTarget = {
            appId: response.data.full_info.app_id,
            packageName: response.data.full_info.pkg_name,
        };
        this.fromCache = false;
        this.status = '新应用已收录并完成加载';
        showToastSafely(this.prompt, `已发现并收录新应用：${response.data.full_info.name}`, 2200, 'V3Search');
    }

    private replaceResult(app: MarketApp): void {
        this.results = this.results.map((item: MarketApp) => item.app_id === app.app_id ? app : item);
    }

    private updateExisting(): void {
        const token = this.backgroundUpdateToken;
        const target: AppRouteTarget = {
            appId: this.activeTarget.appId,
            packageName: this.activeTarget.packageName,
        };
        setTimeout((): void => {
            if (token !== this.backgroundUpdateToken) {
                return;
            }
            this.detailRequest(target, true).then((fresh) => {
                if (token !== this.backgroundUpdateToken) {
                    return;
                }
                if (fresh.data.success && fresh.data.data?.full_info) {
                    this.resultApp = fresh.data.data.full_info;
                    this.replaceResult(fresh.data.data.full_info);
                    this.fromCache = fresh.stale;
                }
            }).catch((error: Error) => {
                console.warn('[Dashboard][pages/main/SearchPage][WARN]', `静默后台更新失败: ${error.message}`);
            });
        }, BACKGROUND_REFRESH_DELAY_MS);
    }

    private isMissingApplication(error: Error): boolean {
        return error.message.includes('404') || error.message.includes('未找到');
    }

    private async search(): Promise<void> {
        const raw = this.input.trim();
        if (!raw || this.loading) {
            if (!raw) {
                showToastSafely(this.prompt, '请输入应用信息', 1500, 'V3Search');
            }
            return;
        }
        this.loading = true;
        this.backgroundUpdateToken++;
        this.errorMessage = '';
        this.results = [];
        this.resultApp = undefined;
        this.status = '正在查找应用…';
        try {
            const target = this.targetFromInput();
            if (!target.appId && !target.packageName) {
                this.status = '正在按应用名称检索…';
                const searchResult = await this.findByName(raw);
                const matches = searchResult.apps;
                this.results = matches;
                this.resultApp = matches[0];
                this.activeTarget = {
                    appId: matches[0].app_id,
                    packageName: matches[0].pkg_name,
                };
                this.fromCache = searchResult.stale;
                this.status = searchResult.stale ?
                    `网络不佳，已从缓存加载 ${matches.length} 个匹配结果` :
                    `已加载全部 ${matches.length} 个匹配结果`;
                this.updateExisting();
                this.openDetailIfRequested();
                return;
            }
            this.activeTarget = target;
            this.status = '已定位应用，正在从 API 获取完整数据…';
            let detail: ApiDataResult<BaseAPIResponse<AppDetailPayload>>;
            try {
                detail = await this.detailRequest(target, false);
            } catch (error) {
                const requestError = error as Error;
                if (this.isMissingApplication(requestError)) {
                    await this.submitNew(target);
                    this.openDetailIfRequested();
                    return;
                }
                throw requestError;
            }
            if (!detail.data.success || !detail.data.data?.full_info) {
                await this.submitNew(target);
                this.openDetailIfRequested();
                return;
            }
            this.resultApp = detail.data.data.full_info;
            this.results = [detail.data.data.full_info];
            this.activeTarget = {
                appId: this.resultApp.app_id,
                packageName: this.resultApp.pkg_name,
            };
            this.fromCache = detail.stale;
            this.status = detail.stale ? '已从离线缓存加载结果' : '搜索结果已完整加载';
            if (detail.data.data.new_app) {
                await this.submitNew(this.activeTarget);
            } else {
                this.updateExisting();
            }
            this.openDetailIfRequested();
        } catch (error) {
            const message = (error as Error).message;
            this.errorMessage = message;
            this.status = '搜索或投稿未完成';
            console.error('[Dashboard][pages/main/SearchPage][ERROR]', `搜索或投稿失败: ${message}`);
            showToastSafely(this.prompt, message, 2600, 'V3Search');
        } finally {
            this.loading = false;
        }
    }

    private resultColumns(): MarketApp[][] {
        const columns: MarketApp[][] = [];
        for (let index = 0; index < this.results.length; index += 20) {
            columns.push(this.results.slice(index, index + 20));
        }
        return columns;
    }

    private openDetail(app?: MarketApp): void {
        const targetApp = app ?? this.resultApp;
        if (!targetApp) {
            return;
        }
        this.vibrate();
        const backgroundRefreshHandled = this.resultApp?.app_id === targetApp.app_id;
        setDetailTarget({
            appId: targetApp.app_id,
            packageName: targetApp.pkg_name,
            backgroundRefreshHandled,
        });
        try {
            this.pageStack.pushPathByName('AppDetailPage', null);
        } catch (error) {
            console.error('[Dashboard][pages/main/SearchPage][ERROR]', `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'SearchPage');
        }
    }

    private openDetailIfRequested(): void {
        if (!this.openDetailAfterSearch || !this.resultApp) {
            return;
        }
        this.openDetailAfterSearch = false;
        setTimeout((): void => {
            this.openDetail();
        }, 0);
    }

    @Builder
    resultCard(app: MarketApp): void {
        Row({ space: 12 }) {
            Image(app.icon_url || $r('app.media.startIcon'))
                .width(58)
                .height(58)
                .borderRadius(14)
                .objectFit(ImageFit.Cover)
                .alt($r('app.media.startIcon'))
                .accessibilityText(`${app.name || '未知应用'}应用图标`)
            Column({ space: 4 }) {
                Text(app.name || '未知应用')
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .accessibilityText(app.name || '未知应用')
                Text(app.developer_name || '未知开发者')
                    .fontSize(12)
                    .fontColor($r('app.color.diff_content'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .accessibilityText(`开发者${app.developer_name || '未知'}`)
                Text(`${app.pkg_name} · ${formatCount(app.download_count)} 下载`)
                    .fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .accessibilityText(`包名${app.pkg_name}下载量${formatCount(app.download_count)}`)
                Text(`更新：${formatDateTime(app.updated_at)}`)
                    .fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(`数据更新时间${formatDateTime(app.updated_at)}`)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Image($r('app.media.right'))
                .width(16)
                .height(16)
                .accessibilityText('进入详情')
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onClick(() => this.openDetail(app))
        .accessibilityGroup(true)
        .accessibilityText(`打开${app.name || '未知应用'}详情`)
    }

    build() {
        Scroll(this.scroller) {
            Column({ space: 14 }) {
                Blank().height(100).width('100%')

                Column({ space: 12 }) {
                    Search({
                        value: this.input,
                        placeholder: '应用名称 / 包名 / App ID / 应用市场链接',
                    })
                        .width('100%')
                        .height(48)
                        .defaultFocus(false)
                        .searchButton('查找')
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .onChange((value: string) => this.input = value)
                        .onSubmit(() => {
                            this.vibrate();
                            this.search();
                        })
                        .accessibilityText('输入应用名称包名App ID或应用市场链接')
                    Button(this.loading ? '处理中…' : '查找并自动投稿或更新')
                        .width('100%')
                        .height(46)
                        .enabled(!this.loading)
                        .backgroundColor($r('app.color.v3_accent_blue'))
                        .onClick(() => {
                            this.vibrate();
                            this.search();
                        })
                        .accessibilityText(this.loading ? '正在处理搜索投稿或更新' : '查找应用并自动投稿或更新')
                }
                .width('100%')
                .padding(16)
                .borderRadius(18)
                .backgroundColor($r('app.color.v3_surface'))
                .border({ width: 1, color: $r('app.color.nd_card_border') })
                .accessibilityGroup(true)
                .accessibilityText('应用搜索和投稿表单')

                Row({ space: 10 }) {
                    if (this.loading) {
                        LoadingProgress()
                            .width(24)
                            .height(24)
                            .color($r('app.color.v3_accent_blue'))
                            .accessibilityText('处理进度')
                    } else {
                        Image(this.errorMessage ? $r('app.media.attention') : $r('app.media.approve'))
                            .width(22)
                            .height(22)
                            .objectFit(ImageFit.Contain)
                            .accessibilityText(this.errorMessage ? '处理失败' : '当前状态正常')
                    }
                    Text(this.errorMessage || this.status)
                        .fontSize(13)
                        .fontColor(this.errorMessage ? $r('app.color.v3_accent_red') : $r('app.color.v3_text_primary'))
                        .layoutWeight(1)
                        .accessibilityText(this.errorMessage || this.status)
                }
                .width('100%')
                .padding(12)
                .borderRadius(12)
                .backgroundColor(this.errorMessage ? $r('app.color.v3_warning_bg') : $r('app.color.v3_success_bg'))
                .accessibilityGroup(true)
                .accessibilityText('搜索处理状态')

                if (this.results.length > 0) {
                    Column({ space: 12 }) {
                        if (this.fromCache) {
                            Text('此结果来自离线缓存')
                                .fontSize(12)
                                .fontColor($r('app.color.v3_accent_orange'))
                                .width('100%')
                                .accessibilityText('此搜索结果来自离线缓存')
                        }
                        Text(`匹配结果 ${this.results.length} 个`)
                            .fontSize(14)
                            .fontWeight(FontWeight.Medium)
                            .fontColor($r('app.color.v3_text_primary'))
                            .width('100%')
                            .accessibilityText(`匹配结果${this.results.length}个`)
                        Scroll() {
                            Row({ space: 12 }) {
                                ForEach(this.resultColumns(), (column: MarketApp[], columnIndex: number) => {
                                    Column({ space: 10 }) {
                                        ForEach(column, (app: MarketApp) => {
                                            this.resultCard(app)
                                        }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                                    }
                                    .width(340)
                                    .alignItems(HorizontalAlign.Start)
                                    .accessibilityText(`第${columnIndex + 1}列搜索结果`)
                                }, (_column: MarketApp[], columnIndex: number) => `result-column-${columnIndex}`)
                            }
                            .alignItems(VerticalAlign.Top)
                        }
                        .width('100%')
                        .scrollable(ScrollDirection.Horizontal)
                        .scrollBar(BarState.Auto)
                        .edgeEffect(EdgeEffect.Spring)
                        .accessibilityText('可横向滚动的搜索结果，每列二十个应用')
                    }
                    .width('100%')
                    .padding({ top: 4 })
                    .accessibilityGroup(true)
                    .accessibilityText('应用搜索结果列表')
                }

                Blank().height(96)
            }
            .width('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .onAppear(() => {
                this.consumePendingTarget();
                if (!this.restoredScroll) {
                    this.restoredScroll = true;
                    const continuation = getContinuationState();
                    if (continuation.mainTab === MAIN_TAB_SEARCH && continuation.routeName === CONTINUATION_ROUTE_MAIN &&
                        continuation.scrollDistance > 0) {
                        setTimeout((): void => {
                            try {
                                this.scroller.scrollTo({
                                    xOffset: 0,
                                    yOffset: continuation.scrollDistance,
                                    animation: { duration: 0 },
                                });
                            } catch (error) {
                                console.warn('[Dashboard][pages/main/SearchPage][WARN]',
                                    `恢复滚动位置失败: ${JSON.stringify(error)}`);
                            }
                        }, 80);
                    }
                }
            })
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .onDidScroll((): void => {
            try {
                setContinuationView(MAIN_TAB_SEARCH, this.scroller.currentOffset().yOffset);
            } catch (error) {
                console.warn('[Dashboard][pages/main/SearchPage][WARN]',
                    `保存滚动位置失败: ${JSON.stringify(error)}`);
            }
        })
        .backgroundColor($r('app.color.background'))
        .accessibilityText('搜索投稿与更新页面')
    }
}
