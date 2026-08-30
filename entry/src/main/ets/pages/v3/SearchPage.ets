import { PromptAction } from '@kit.ArkUI';
import { BACKGROUND_REFRESH_DELAY_MS, CONTENT_MAX_WIDTH } from '../../common/constants';
import { consumeSearchTarget, setDetailTarget } from '../../common/appState';
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
} from '../../common/types';

@Component
export struct SearchPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Link @Watch('onRequestVersionChanged') requestVersion: number;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('username') private username: string = '';
    @State private input: string = '';
    @State private note: string = '';
    @State private loading: boolean = false;
    @State private backgroundUpdating: boolean = false;
    @State private status: string = '输入应用名称、包名、App ID 或华为应用市场链接';
    @State private errorMessage: string = '';
    @State private resultApp: MarketApp | undefined = undefined;
    @State private fromCache: boolean = false;
    private activeTarget: AppRouteTarget = {};
    private openDetailAfterSearch: boolean = false;

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
            setTimeout(() => this.search(), 0);
        }
    }

    private targetFromInput(): AppRouteTarget {
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
            return { packageName: decodeURIComponent(idMatch[1]) };
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

    private async findByName(name: string): Promise<AppRouteTarget> {
        const listResult = await fetchAppsPage(1, 8, 'updated_at', true, 'name', name, false, true);
        const response = listResult.data as BaseAPIResponse<PageInfo<MarketApp>>;
        const first = response.data?.data?.[0];
        if (!response.success || !first) {
            throw new Error('未找到同名应用；如需投稿，请输入包名、App ID 或应用市场链接');
        }
        return { appId: first.app_id, packageName: first.pkg_name };
    }

    private async submitNew(target: AppRouteTarget): Promise<void> {
        this.status = '发现新应用，正在进行 simple 投稿…';
        const response = await submitApp({
            app_id: target.appId,
            pkg_name: target.packageName,
            comment: { user: this.username, note: this.note.trim() || undefined },
        });
        if (!response.success || !response.data?.full_info) {
            throw new Error('投稿接口未返回有效应用数据');
        }
        this.resultApp = response.data.full_info;
        this.activeTarget = {
            appId: response.data.full_info.app_id,
            packageName: response.data.full_info.pkg_name,
        };
        this.fromCache = false;
        this.status = '新应用已投稿并完成数据加载';
    }

    private updateExisting(): void {
        this.backgroundUpdating = true;
        this.status = '结果已显示，正在后台 query 并更新数据…';
        setTimeout(() => {
            this.detailRequest(this.activeTarget, true).then((fresh) => {
                if (fresh.data.success && fresh.data.data?.full_info) {
                    this.resultApp = fresh.data.data.full_info;
                    this.fromCache = fresh.stale;
                    this.status = fresh.fromCache ?
                        '后台更新失败，继续使用离线缓存' : '后台 query 更新完成';
                } else {
                    this.status = '结果已显示；后台更新未返回新数据';
                }
            }).catch((error: Error) => {
                this.status = `结果已显示；后台更新失败：${error.message}`;
            }).finally(() => this.backgroundUpdating = false);
        }, BACKGROUND_REFRESH_DELAY_MS);
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
        this.errorMessage = '';
        this.resultApp = undefined;
        this.status = '正在查找应用…';
        try {
            let target = this.targetFromInput();
            if (!target.appId && !target.packageName) {
                this.status = '正在按应用名称检索…';
                target = await this.findByName(raw);
            }
            this.activeTarget = target;
            this.status = '已定位应用，正在从 API 获取完整数据…';
            const detail = await this.detailRequest(target, false);
            if (!detail.data.success || !detail.data.data?.full_info) {
                await this.submitNew(target);
                this.openDetailIfRequested();
                return;
            }
            this.resultApp = detail.data.data.full_info;
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
            console.error('[Dashboard][pages/v3/SearchPage][ERROR]', `搜索或投稿失败: ${message}`);
            showToastSafely(this.prompt, message, 2600, 'V3Search');
        } finally {
            this.loading = false;
        }
    }

    private openDetail(): void {
        if (!this.resultApp) {
            return;
        }
        setDetailTarget({ appId: this.resultApp.app_id, packageName: this.resultApp.pkg_name });
        this.pageStack.pushPathByName('AppDetailPage', null);
    }

    private openDetailIfRequested(): void {
        if (!this.openDetailAfterSearch || !this.resultApp) {
            return;
        }
        this.openDetailAfterSearch = false;
        setTimeout(() => this.openDetail(), 0);
    }

    build() {
        Scroll() {
            Column({ space: 14 }) {
                Column({ space: 5 }) {
                    Text('搜索、投稿与更新')
                        .fontSize(26)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                        .width('100%')
                        .accessibilityText('搜索投稿与更新')
                    Text('搜索结果完整加载后，会自动在后台更新；分享入口也统一使用此流程')
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .width('100%')
                        .accessibilityText('搜索结果完整加载后会自动在后台更新，分享入口也使用此流程')
                }
                .padding({ top: 20, left: 4, right: 4 })
                .alignItems(HorizontalAlign.Start)
                .accessibilityGroup(true)

                Column({ space: 12 }) {
                    Search({
                        value: this.input,
                        placeholder: '应用名称 / 包名 / App ID / 应用市场链接',
                    })
                        .width('100%')
                        .height(48)
                        .searchButton('查找')
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .onChange((value: string) => this.input = value)
                        .onSubmit(() => this.search())
                        .accessibilityText('输入应用名称包名App ID或应用市场链接')
                    TextInput({ text: this.note, placeholder: '投稿备注（可选）' })
                        .width('100%')
                        .height(44)
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .onChange((value: string) => this.note = value)
                        .accessibilityText('输入投稿备注，可选')
                    Button(this.loading ? '处理中…' : '查找并自动投稿或更新')
                        .width('100%')
                        .height(46)
                        .enabled(!this.loading)
                        .backgroundColor($r('app.color.v3_accent_blue'))
                        .onClick(() => this.search())
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
                    if (this.loading || this.backgroundUpdating) {
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

                if (this.resultApp) {
                    Column({ space: 12 }) {
                        if (this.fromCache) {
                            Text('此结果来自离线缓存')
                                .fontSize(12)
                                .fontColor($r('app.color.v3_accent_orange'))
                                .width('100%')
                                .accessibilityText('此搜索结果来自离线缓存')
                        }
                        Row({ space: 14 }) {
                            Image(this.resultApp.icon_url || $r('app.media.startIcon'))
                                .width(72)
                                .height(72)
                                .borderRadius(16)
                                .objectFit(ImageFit.Cover)
                                .alt($r('app.media.startIcon'))
                                .accessibilityText(`${this.resultApp.name}应用图标`)
                            Column({ space: 5 }) {
                                Text(this.resultApp.name || '未知应用')
                                    .fontSize(21)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .maxLines(2)
                                    .accessibilityText(this.resultApp.name || '未知应用')
                                Text(this.resultApp.developer_name || '未知开发者')
                                    .fontSize(13)
                                    .fontColor($r('app.color.v3_accent_blue'))
                                    .maxLines(1)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    .accessibilityText(`开发者${this.resultApp.developer_name || '未知'}`)
                                Text(`${this.resultApp.pkg_name} · ${formatCount(this.resultApp.download_count)} 下载`)
                                    .fontSize(12)
                                    .fontColor($r('app.color.v3_text_secondary'))
                                    .maxLines(1)
                                    .accessibilityText(`包名${this.resultApp.pkg_name}下载量${formatCount(this.resultApp.download_count)}`)
                                Text(`数据更新：${formatDateTime(this.resultApp.updated_at)}`)
                                    .fontSize(12)
                                    .fontColor($r('app.color.v3_text_secondary'))
                                    .accessibilityText(`数据更新时间${formatDateTime(this.resultApp.updated_at)}`)
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)
                        }
                        .width('100%')
                        Button('打开统一应用详情页')
                            .width('100%')
                            .backgroundColor($r('app.color.v3_accent_cyan'))
                            .onClick(() => this.openDetail())
                            .accessibilityText(`打开${this.resultApp.name}的统一应用详情页`)
                    }
                    .width('100%')
                    .padding(18)
                    .borderRadius(18)
                    .backgroundColor($r('app.color.v3_surface'))
                    .border({ width: 1, color: $r('app.color.nd_card_border') })
                    .accessibilityGroup(true)
                    .accessibilityText(`${this.resultApp.name}搜索结果`)
                }

                Column({ space: 8 }) {
                    Text('支持的分享入口')
                        .fontSize(17)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                        .width('100%')
                        .accessibilityText('支持的分享入口')
                    Text('• 查询该应用数据：查找后进入统一详情页')
                        .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                    Text('• 直接投稿到看板：新应用 simple 投稿，已有应用 query 更新')
                        .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                    Text('• 填写信息投稿：自动填充到本页后再处理')
                        .fontSize(13).fontColor($r('app.color.v3_text_secondary'))
                }
                .width('100%')
                .padding(16)
                .borderRadius(16)
                .backgroundColor($r('app.color.v3_surface_alt'))
                .accessibilityGroup(true)
                .accessibilityText('查询直接投稿和填写信息投稿三个分享入口说明')

                Blank().height(96)
            }
            .width('100%')
            .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
            .padding({ left: 14, right: 14 })
            .onAppear(() => this.consumePendingTarget())
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Off)
        .backgroundColor($r('app.color.background'))
        .accessibilityText('搜索投稿与更新页面')
    }
}
