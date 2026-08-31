import { common, Want } from '@kit.AbilityKit';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import {
    hdsMaterial,
    HdsNavDestination,
    HdsNavDestinationTitleMode,
    ScrollEffectType,
    TitleSize,
} from '@kit.UIDesignKit';
import {
    BACKGROUND_REFRESH_DELAY_MS,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_DETAIL,
    HUAWEI_APP_DETAIL_URL_PREFIX,
    S_SITE_PUBLIC_BASE_URL,
    S_SITE_APP_DETAIL_QUERY,
} from '../../common/constants';
import {
    consumeDetailTarget,
    getContinuationState,
    setContinuationView,
} from '../../common/appState';
import { fetchAppById, fetchAppByPackage, fetchAppMetrics, fetchAppRatingHistory } from '../../common/MarketApi';
import { formatBytes, formatCount, formatDateTime } from '../../common/format';
import { showToastSafely } from '../../common/safeUi';
import { WebShareManager } from '../../common/shareControl';
import { vibration } from '../../common/vibration';
import type {
    ApiDataResult,
    AppDetailPayload,
    AppMetric,
    AppRatingHistory,
    AppRouteTarget,
    BaseAPIResponse,
    MarketApp,
    ScreenshotInfo,
} from '../../common/types';
import { InteractiveLineChart } from '../../component/charts/InteractiveLineChart';
import type { LineChartPoint } from '../../component/charts/InteractiveLineChart';

interface DetailField {
    label: string;
    value: string;
}

@Component
struct DetailTag {
    field: DetailField = { label: '', value: '-' };

    build() {
        Row({ space: 7 }) {
            Text(this.field.label)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.diff_content'))
                .accessibilityText(this.field.label)
            Text(this.field.value)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`${this.field.label}${this.field.value}`)
        }
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .margin(4)
        .borderRadius(14)
        .backgroundColor($r('app.color.v3_surface_alt'))
        .border({ width: 1, color: $r('app.color.v3_chart_grid') })
        .accessibilityGroup(true)
        .accessibilityText(`${this.field.label}，${this.field.value}`)
    }
}


@Component
export struct AppDetailPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private scroller: Scroller = new Scroller();
    private shareManager?: WebShareManager;
    private target: AppRouteTarget = {};
    @State private app: MarketApp | undefined = undefined;
    @State private metrics: AppMetric[] = [];
    @State private ratingHistory: AppRatingHistory[] = [];
    @State private loading: boolean = true;
    @State private refreshing: boolean = false;
    @State private fromCache: boolean = false;
    @State private errorMessage: string = '';
    @State private started: boolean = false;
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    @StorageLink('immersiveTextureON') private immersiveTexture: boolean = false;

    private vibrate(): void {
        if (this.vibrationEnabled) {
            vibration.dotVibration();
        }
    }

    private shareUrl(): string {
        if (!this.app) {
            return S_SITE_PUBLIC_BASE_URL;
        }
        return `${S_SITE_PUBLIC_BASE_URL}${S_SITE_APP_DETAIL_QUERY}${encodeURIComponent(this.app.app_id)}`;
    }

    private syncShareData(): void {
        if (!this.app) {
            return;
        }
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.shareManager = WebShareManager.getInstance(context);
        this.shareManager.updateShareData(
            this.shareUrl(),
            `${this.app.name}｜Dashboard应用看板`,
            `${this.app.developer_name || '未知开发者'} · ${this.app.pkg_name}`,
        );
        this.shareManager.enablePassiveShare();
    }

    private showShare(): void {
        this.vibrate();
        if (!this.app) {
            showToastSafely(this.prompt, '详情加载完成后才能分享', 1500, 'V3AppDetail');
            return;
        }
        this.syncShareData();
        this.shareManager?.showSystemShare(this.shareUrl());
    }

    private closePage(): void {
        this.vibrate();
        const continuation = getContinuationState();
        setContinuationView(continuation.mainTab, 0);
        try {
            this.pageStack.pop();
        } catch (error) {
            console.error('[Dashboard][pages/detail/AppDetailPage][ERROR]', `关闭详情页失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法返回，请重试', 1600, 'AppDetailPage');
        }
    }

    private request(force: boolean): Promise<ApiDataResult<BaseAPIResponse<AppDetailPayload>>> {
        if (this.target.appId) {
            return fetchAppById(this.target.appId, force);
        }
        if (this.target.packageName) {
            return fetchAppByPackage(this.target.packageName, force);
        }
        return Promise.reject(new Error('缺少应用标识'));
    }

    private load(force: boolean, background: boolean = false, showRefreshing: boolean = false): void {
        if (showRefreshing) {
            this.refreshing = true;
        }
        if (!background) {
            this.loading = true;
            this.errorMessage = '';
        }
        this.request(force).then((result) => {
            if (!result.data.success || !result.data.data?.full_info) {
                throw new Error('未找到该应用');
            }
            this.app = result.data.data.full_info;
            this.fromCache = result.stale;
            this.syncShareData();
            if (this.app.pkg_name) {
                fetchAppMetrics(this.app.pkg_name, force).then((metricResult) => {
                    if (metricResult.data.success) {
                        this.metrics = metricResult.data.data ?? [];
                    }
                }).catch((error: Error) => console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]', `指标加载失败: ${error.message}`));
                fetchAppRatingHistory(this.app.pkg_name, force).then((ratingResult) => {
                    if (ratingResult.data.success) {
                        this.ratingHistory = ratingResult.data.data ?? [];
                    }
                }).catch((error: Error) => console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]', `评分趋势加载失败: ${error.message}`));
            }
            if (!force && !this.target.backgroundRefreshHandled) {
                setTimeout((): void => {
                    this.load(true, true);
                }, BACKGROUND_REFRESH_DELAY_MS);
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

    private downloadPoints(): LineChartPoint[] {
        return this.metrics.slice().sort((left: AppMetric, right: AppMetric) =>
            new Date(left.created_at).getTime() - new Date(right.created_at).getTime()).map((metric: AppMetric) => ({
                label: formatDateTime(metric.created_at).split(' ')[0],
                value: Number(metric.download_count ?? 0),
                detail: `${formatDateTime(metric.created_at)} · 下载量 ${formatCount(metric.download_count)} · 版本 ${metric.version || '-'}`,
            } as LineChartPoint));
    }

    private ratingPoints(): LineChartPoint[] {
        return this.ratingHistory.slice().sort((left: AppRatingHistory, right: AppRatingHistory) =>
            new Date(left.report_date).getTime() - new Date(right.report_date).getTime()).map((rating: AppRatingHistory) => {
                const value = Number(rating.cumulative_avg_rating_high_prec ?? rating.cumulative_avg_rating_origin ?? 0);
                return {
                    label: rating.report_date,
                    value,
                    detail: `${rating.report_date} · 平均评分 ${value.toFixed(2)} · 累计 ${formatCount(rating.cumulative_total_count)} 条评分`,
                } as LineChartPoint;
            });
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
            console.error('[Dashboard][pages/detail/AppDetailPage][ERROR]', `${failureMessage}: ${JSON.stringify(error)}`);
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

    aboutToDisappear(): void {
        this.shareManager?.disablePassiveShare();
    }

    build() {
        HdsNavDestination() {
          Refresh({ refreshing: $$this.refreshing }) {
            Scroll(this.scroller) {
                Column({ space: 14 }) {
                    Blank().height(100).width('100%')
                    if (this.loading && !this.app) {
                        Column({ space: 12 }) {
                            LoadingProgress()
                                .width(42)
                                .height(42)
                                .color($r('app.color.diff_content'))
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
                                .backgroundColor($r('app.color.diff_content'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.load(true);
                                })
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
                                    .fontColor($r('app.color.diff_content'))
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
                                .backgroundColor($r('app.color.diff_content'))
                                .onClick(() => {
                                    this.vibrate();
                                    this.openMarket();
                                })
                                .accessibilityText('在华为应用市场打开此应用')
                            if (this.app.privacy_url) {
                                Button('隐私政策')
                                    .margin(4)
                                    .fontColor($r('app.color.v3_text_primary'))
                                    .backgroundColor($r('app.color.v3_surface_alt'))
                                    .onClick(() => {
                                        this.vibrate();
                                        this.openExternal(this.app!.privacy_url!, '无法打开应用隐私政策');
                                    })
                                    .accessibilityText(`打开${this.app.name}隐私政策`)
                            }
                        }
                        .width('100%')
                        .accessibilityText('应用详情操作')

                        Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Start, alignItems: ItemAlign.Start }) {
                            ForEach(this.fields(), (field: DetailField) => {
                                DetailTag({ field })
                            }, (field: DetailField) => field.label)
                        }
                        .width('100%')
                        .padding(12)
                        .borderRadius(16)
                        .backgroundColor($r('app.color.v3_surface'))
                        .border({ width: 1, color: $r('app.color.nd_card_border') })
                        .accessibilityText('以标签形式展示的应用详细字段')

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

                        InteractiveLineChart({
                            title: '下载量趋势',
                            unit: '次',
                            points: this.downloadPoints(),
                            lineColor: $r('app.color.diff_content'),
                        })

                        InteractiveLineChart({
                            title: '评分趋势',
                            unit: '分',
                            points: this.ratingPoints(),
                            lineColor: $r('app.color.v3_accent_orange'),
                        })

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
                        const continuation = getContinuationState();
                        setContinuationView(
                            continuation.mainTab,
                            0,
                            CONTINUATION_ROUTE_DETAIL,
                            this.target,
                            this.shareUrl(),
                        );
                        setTimeout((): void => {
                            this.load(false);
                        }, 0);
                        if (continuation.routeName === CONTINUATION_ROUTE_DETAIL && continuation.scrollDistance > 0) {
                            setTimeout((): void => {
                                try {
                                    this.scroller.scrollTo({
                                        xOffset: 0,
                                        yOffset: continuation.scrollDistance,
                                        animation: { duration: 0 },
                                    });
                                } catch (error) {
                                    console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]',
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
                    const continuation = getContinuationState();
                    setContinuationView(
                        continuation.mainTab,
                        this.scroller.currentOffset().yOffset,
                        CONTINUATION_ROUTE_DETAIL,
                        this.target,
                        this.shareUrl(),
                    );
                } catch (error) {
                    console.warn('[Dashboard][pages/detail/AppDetailPage][WARN]',
                        `保存详情页滚动位置失败: ${JSON.stringify(error)}`);
                }
            })
            .backgroundColor($r('app.color.background'))
            .accessibilityText('可下拉刷新的公用应用详情页')
          }
          .width('100%').height('100%')
          .onRefreshing((): void => {
              this.vibrate();
              this.load(true, true, true);
          })
        }
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: false,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary'),
                        },
                    },
                },
                systemMaterialEffect: this.immersiveTexture ? {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE,
                } : undefined,
            },
            content: {
                title: {
                    mainTitle: this.app?.name || '应用详情',
                    mainTitleSize: TitleSize.TITLE_S,
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: '分享应用详情',
                                icon: $r('sys.symbol.share'),
                                isEnabled: this.app !== undefined,
                                action: () => this.showShare(),
                            },
                        },
                    ],
                },
                backIcon: {
                    action: () => this.closePage(),
                },
            },
        })
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .onBackPressed(() => {
            this.closePage();
            return true;
        })
        .accessibilityText('应用详情导航页')
    }
}
