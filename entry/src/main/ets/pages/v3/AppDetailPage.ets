import { common, Want } from '@kit.AbilityKit';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import {
    BACKGROUND_REFRESH_DELAY_MS,
    CONTENT_MAX_WIDTH,
    HUAWEI_APP_DETAIL_URL_PREFIX,
    RESPONSIVE_BREAKPOINT_LARGE,
    RESPONSIVE_BREAKPOINT_MEDIUM,
} from '../../common/constants';
import { consumeDetailTarget } from '../../common/appState';
import { fetchAppById, fetchAppByPackage, fetchAppMetrics } from '../../common/MarketApi';
import { formatBytes, formatCount, formatDateTime } from '../../common/format';
import { showToastSafely } from '../../common/safeUi';
import type {
    ApiDataResult,
    AppDetailPayload,
    AppMetric,
    AppRouteTarget,
    BaseAPIResponse,
    MarketApp,
    ScreenshotInfo,
} from '../../common/types';

interface DetailField {
    label: string;
    value: string;
}

@Component
struct MetricBars {
    @Prop metrics: AppMetric[] = [];
    @State private selected: number = 0;

    private visible(): AppMetric[] {
        return this.metrics.slice(Math.max(0, this.metrics.length - 12));
    }

    private maximum(): number {
        let max = 1;
        this.visible().forEach((metric: AppMetric) => max = Math.max(max, metric.download_count));
        return max;
    }

    private selectedText(): string {
        const list = this.visible();
        if (list.length === 0) {
            return '暂无下载量历史';
        }
        const metric = list[Math.min(this.selected, list.length - 1)];
        return `${formatDateTime(metric.created_at)}，下载量${formatCount(metric.download_count)}，版本${metric.version}`;
    }

    build() {
        Column({ space: 12 }) {
            Text('下载量趋势')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText('下载量趋势')
            if (this.visible().length > 0) {
                Row({ space: 5 }) {
                    ForEach(this.visible(), (metric: AppMetric, index: number) => {
                        Column() {
                            Blank()
                                .width('100%')
                                .height(Math.max(4, 130 * metric.download_count / this.maximum()))
                                .borderRadius({ topLeft: 5, topRight: 5 })
                                .backgroundColor(index === this.selected ? $r('app.color.v3_accent_blue') : $r('app.color.v3_accent_cyan'))
                                .accessibilityText(`第${index + 1}个下载量柱形`)
                        }
                        .height(140)
                        .layoutWeight(1)
                        .justifyContent(FlexAlign.End)
                        .onClick(() => this.selected = index)
                        .accessibilityText(`查看${formatDateTime(metric.created_at)}下载量`)
                    }, (metric: AppMetric) => `${metric.created_at}-${metric.download_count}`)
                }
                .height(140)
                .width('100%')
                .alignItems(VerticalAlign.Bottom)
                .accessibilityText('最近十二次下载量柱状图')
                Text(this.selectedText())
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(this.selectedText())
            } else {
                Text('暂无下载量历史')
                    .fontColor($r('app.color.v3_text_secondary'))
                    .padding(24)
                    .accessibilityText('暂无下载量历史')
            }
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(true)
        .accessibilityText('应用下载量趋势图')
    }
}

@Component
export struct AppDetailPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private target: AppRouteTarget = {};
    @State private app: MarketApp | undefined = undefined;
    @State private metrics: AppMetric[] = [];
    @State private loading: boolean = true;
    @State private refreshing: boolean = false;
    @State private fromCache: boolean = false;
    @State private errorMessage: string = '';
    @State private started: boolean = false;

    private request(force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (this.target.appId) {
            return fetchAppById(this.target.appId, force);
        }
        if (this.target.packageName) {
            return fetchAppByPackage(this.target.packageName, force);
        }
        return Promise.reject(new Error('缺少应用标识'));
    }

    private load(force: boolean, background: boolean = false): void {
        if (background) {
            this.refreshing = true;
        } else {
            this.loading = true;
            this.errorMessage = '';
        }
        this.request(force).then((result) => {
            if (!result.data.success || !result.data.data?.full_info) {
                throw new Error('未找到该应用');
            }
            this.app = result.data.data.full_info;
            this.fromCache = result.stale;
            if (this.app.pkg_name) {
                fetchAppMetrics(this.app.pkg_name, force).then((metricResult) => {
                    if (metricResult.data.success) {
                        this.metrics = metricResult.data.data ?? [];
                    }
                }).catch((error: Error) => console.warn('[Dashboard][pages/v3/AppDetailPage][WARN]', `[detail] 指标加载失败: ${error.message}`));
            }
            if (!force) {
                setTimeout(() => this.load(true, true), BACKGROUND_REFRESH_DELAY_MS);
            }
        }).catch((error: Error) => {
            if (!background) {
                this.errorMessage = `详情加载失败：${error.message}`;
            }
        }).finally(() => {
            this.loading = false;
            this.refreshing = false;
        });
    }

    private fields(): DetailField[] {
        if (!this.app) {
            return [];
        }
        return [
            { label: '应用 ID', value: this.app.app_id || '-' },
            { label: '包名', value: this.app.pkg_name || '-' },
            { label: '开发者', value: this.app.developer_name || '-' },
            { label: '分类', value: `${this.app.kind_type_name || '-'} · ${this.app.kind_name || '-'}` },
            { label: '版本', value: `${this.app.version || '-'} (${this.app.version_code || 0})` },
            { label: '应用大小', value: formatBytes(this.app.size_bytes) },
            { label: '最低 SDK', value: String(this.app.minsdk ?? '-') },
            { label: '目标 SDK', value: String(this.app.target_sdk ?? '-') },
            { label: '编译 SDK', value: String(this.app.compile_sdk_version ?? '-') },
            { label: '最低 Harmony API', value: String(this.app.min_hmos_api_level ?? '-') },
            { label: '下载量', value: formatCount(this.app.download_count) },
            { label: '评分', value: this.app.average_rating ? `${this.app.average_rating} / 5` : '-' },
            { label: '评分数量', value: formatCount(this.app.total_star_rating_count) },
            { label: '供应商', value: this.app.supplier || '-' },
            { label: '标签', value: this.app.tag_name || '-' },
            { label: '价格', value: String(this.app.price ?? '免费') },
            { label: '发行国家/地区', value: this.app.release_countries?.join('、') || '-' },
            { label: '备案主体', value: this.app.recordal_entity_name || this.app.recordal_entity_title || '-' },
            { label: '备案信息', value: this.app.app_recordal_info || '-' },
            { label: '上架时间', value: formatDateTime(this.app.listed_at) },
            { label: '数据更新', value: formatDateTime(this.app.updated_at) },
        ];
    }

    private screenshots(): ScreenshotInfo[] {
        if (!this.app) {
            return [];
        }
        if (this.app.new_screen_shots && this.app.new_screen_shots.length > 0) {
            return this.app.new_screen_shots;
        }
        return (this.app.screen_shots ?? []).map((url: string) => ({
            url,
            resolution: '',
            rotated: 0,
        } as ScreenshotInfo));
    }

    private async openExternal(uri: string, failureMessage: string): Promise<void> {
        try {
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            await context.startAbility({
                action: 'ohos.want.action.viewData',
                entities: ['entity.system.browsable'],
                uri,
            } as Want);
        } catch (error) {
            console.error('[Dashboard][pages/v3/AppDetailPage][ERROR]', `${failureMessage}: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, failureMessage, 1800, 'V3AppDetail');
        }
    }

    private async openMarket(): Promise<void> {
        if (!this.app) {
            return;
        }
        const id = this.app.app_id || this.app.alliance_app_id || '';
        await this.openExternal(`${HUAWEI_APP_DETAIL_URL_PREFIX}${id}`, '无法打开应用市场详情');
    }

    build() {
        HdsNavDestination() {
            Scroll() {
                Column({ space: 14 }) {
                    if (this.loading && !this.app) {
                        Column({ space: 12 }) {
                            LoadingProgress()
                                .width(42)
                                .height(42)
                                .color($r('app.color.v3_accent_blue'))
                                .accessibilityText('应用详情加载中')
                            Text('正在查找应用并从 API 获取详情…')
                                .fontColor($r('app.color.v3_text_secondary'))
                                .accessibilityText('正在查找应用并从API获取详情')
                        }
                        .height(360)
                        .justifyContent(FlexAlign.Center)
                        .accessibilityGroup(true)
                    } else if (this.errorMessage !== '') {
                        Column({ space: 12 }) {
                            Image($r('app.media.attention'))
                                .width(42)
                                .height(42)
                                .objectFit(ImageFit.Contain)
                                .accessibilityText('加载错误图标')
                            Text(this.errorMessage)
                                .fontColor($r('app.color.v3_accent_red'))
                                .textAlign(TextAlign.Center)
                                .accessibilityText(this.errorMessage)
                            Button('重新加载')
                                .backgroundColor($r('app.color.v3_accent_blue'))
                                .onClick(() => this.load(true))
                                .accessibilityText('重新加载应用详情')
                        }
                        .height(360)
                        .justifyContent(FlexAlign.Center)
                        .accessibilityGroup(true)
                    } else if (this.app) {
                        if (this.fromCache) {
                            Text('网络不佳，当前显示已缓存的应用详情')
                                .fontSize(13)
                                .fontColor($r('app.color.v3_text_primary'))
                                .padding(12)
                                .width('100%')
                                .borderRadius(12)
                                .backgroundColor($r('app.color.v3_warning_bg'))
                                .accessibilityText('网络不佳，当前显示已缓存的应用详情')
                        }

                        Row({ space: 16 }) {
                            Image(this.app.icon_url || $r('app.media.startIcon'))
                                .width(82)
                                .height(82)
                                .borderRadius(18)
                                .objectFit(ImageFit.Cover)
                                .alt($r('app.media.startIcon'))
                                .accessibilityText(`${this.app.name}应用图标`)
                            Column({ space: 5 }) {
                                Text(this.app.name || '未知应用')
                                    .fontSize(24)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .maxLines(2)
                                    .accessibilityText(this.app.name || '未知应用')
                                Text(this.app.developer_name || '未知开发者')
                                    .fontSize(14)
                                    .fontColor($r('app.color.v3_accent_blue'))
                                    .maxLines(1)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    .accessibilityText(`开发者${this.app.developer_name || '未知'}`)
                                Text(this.app.brief_desc || this.app.pkg_name || '')
                                    .fontSize(12)
                                    .fontColor($r('app.color.v3_text_secondary'))
                                    .maxLines(2)
                                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                                    .accessibilityText(this.app.brief_desc || this.app.pkg_name || '')
                            }
                            .alignItems(HorizontalAlign.Start)
                            .layoutWeight(1)
                        }
                        .width('100%')
                        .padding(18)
                        .borderRadius(18)
                        .backgroundColor($r('app.color.v3_surface'))
                        .border({ width: 1, color: $r('app.color.nd_card_border') })
                        .accessibilityGroup(true)
                        .accessibilityText(`${this.app.name}应用概要`)

                        Flex({ wrap: FlexWrap.Wrap }) {
                            Button('在华为应用市场打开')
                                .margin(4)
                                .backgroundColor($r('app.color.v3_accent_blue'))
                                .onClick(() => this.openMarket())
                                .accessibilityText('在华为应用市场打开此应用')
                            Button(this.refreshing ? '更新中…' : '更新数据')
                                .margin(4)
                                .enabled(!this.refreshing)
                                .fontColor($r('app.color.v3_text_primary'))
                                .backgroundColor($r('app.color.v3_surface_alt'))
                                .onClick(() => this.load(true, true))
                                .accessibilityText(this.refreshing ? '应用数据更新中' : '从API更新此应用数据')
                            if (this.app.privacy_url) {
                                Button('隐私政策')
                                    .margin(4)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .backgroundColor($r('app.color.v3_surface_alt'))
                                    .onClick(() => this.openExternal(this.app!.privacy_url!, '无法打开应用隐私政策'))
                                    .accessibilityText(`打开${this.app.name}隐私政策`)
                            }
                        }
                        .width('100%')
                        .accessibilityText('应用详情操作')

                        GridRow({
                            columns: { xs: 4, sm: 8, md: 12 },
                            gutter: { x: 10, y: 10 },
                            breakpoints: {
                                value: [RESPONSIVE_BREAKPOINT_MEDIUM, RESPONSIVE_BREAKPOINT_LARGE],
                                reference: BreakpointsReference.WindowSize,
                            },
                        }) {
                            ForEach(this.fields(), (field: DetailField) => {
                                GridCol({ span: { xs: 4, sm: 4, md: 4 } }) {
                                    Column({ space: 5 }) {
                                        Text(field.label)
                                            .fontSize(12)
                                            .fontColor($r('app.color.v3_text_secondary'))
                                            .accessibilityText(field.label)
                                        Text(field.value)
                                            .fontSize(14)
                                            .fontWeight(FontWeight.Medium)
                                            .fontColor($r('app.color.v3_text_primary'))
                                            .maxLines(2)
                                            .textOverflow({ overflow: TextOverflow.Ellipsis })
                                            .accessibilityText(`${field.label}${field.value}`)
                                    }
                                    .alignItems(HorizontalAlign.Start)
                                    .width('100%')
                                    .padding(14)
                                    .borderRadius(12)
                                    .backgroundColor($r('app.color.v3_surface'))
                                    .accessibilityGroup(true)
                                }
                            }, (field: DetailField) => field.label)
                        }
                        .width('100%')
                        .accessibilityText('应用详细字段')

                        if (this.screenshots().length > 0) {
                            Column({ space: 10 }) {
                                Text('应用截图')
                                    .fontSize(18)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .width('100%')
                                    .accessibilityText('应用截图')
                                Swiper() {
                                    ForEach(this.screenshots(), (shot: ScreenshotInfo, index: number) => {
                                        Image(shot.url)
                                            .width('100%')
                                            .height(360)
                                            .objectFit(ImageFit.Contain)
                                            .alt($r('app.media.startIcon'))
                                            .accessibilityText(`第${index + 1}张应用截图`)
                                    }, (shot: ScreenshotInfo) => shot.url)
                                }
                                .height(380)
                                .indicator(true)
                                .loop(false)
                                .accessibilityText('可左右滑动的应用截图')
                            }
                            .width('100%')
                            .padding(18)
                            .borderRadius(18)
                            .backgroundColor($r('app.color.v3_surface'))
                            .accessibilityGroup(true)
                        }

                        MetricBars({ metrics: this.metrics })

                        Column({ space: 10 }) {
                            Text('应用介绍')
                                .fontSize(18)
                                .fontWeight(FontWeight.Bold)
                                .fontColor($r('app.color.v3_text_primary'))
                                .width('100%')
                                .accessibilityText('应用介绍')
                            Text(this.app.description || '暂无介绍')
                                .fontSize(14)
                                .lineHeight(22)
                                .fontColor($r('app.color.v3_text_primary'))
                                .width('100%')
                                .accessibilityText(this.app.description || '暂无应用介绍')
                            if (this.app.new_features) {
                                Divider().color($r('app.color.v3_chart_grid')).accessibilityText('内容分隔线')
                                Text('新版特性')
                                    .fontSize(16)
                                    .fontWeight(FontWeight.Bold)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .width('100%')
                                    .accessibilityText('新版特性')
                                Text(this.app.new_features)
                                    .fontSize(14)
                                    .lineHeight(22)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .width('100%')
                                    .accessibilityText(this.app.new_features)
                            }
                        }
                        .width('100%')
                        .padding(18)
                        .borderRadius(18)
                        .backgroundColor($r('app.color.v3_surface'))
                        .border({ width: 1, color: $r('app.color.nd_card_border') })
                        .accessibilityGroup(true)
                        .accessibilityText('应用介绍和新版特性')
                    }
                    Blank().height(36)
                }
                .width('100%')
                .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                .padding({ left: 14, right: 14, top: 12 })
                .onAppear(() => {
                    if (!this.started) {
                        this.started = true;
                        this.target = consumeDetailTarget();
                        setTimeout(() => this.load(false), 0);
                    }
                })
            }
            .width('100%')
            .height('100%')
            .backgroundColor($r('app.color.background'))
            .accessibilityText('公用应用详情页')
        }
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
            },
            content: {
                title: { mainTitle: this.app?.name || '应用详情' },
                backIcon: { action: () => this.pageStack.pop() },
            },
        })
        .accessibilityText('应用详情导航页')
    }
}
