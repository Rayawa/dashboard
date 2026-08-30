import { PromptAction } from '@kit.ArkUI';
import {
    APP_LIST_PAGE_SIZE,
    CONTENT_MAX_WIDTH,
    CONTINUATION_ROUTE_MAIN,
    MAIN_TAB_APPS,
} from '../../common/constants';
import { getContinuationState, setContinuationView, setDetailTarget } from '../../common/appState';
import { fetchAppsPage } from '../../common/MarketApi';
import { formatBytes, formatCount, formatDateTime } from '../../common/format';
import type { BaseAPIResponse, MarketApp, PageInfo } from '../../common/types';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';

interface SortChoice {
    label: string;
    field: string;
}

@Component
struct AppTableRow {
    app: MarketApp = {} as MarketApp;
    index: number = 0;
    onOpen: (app: MarketApp) => void = () => {};
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    private rating(): string {
        const value = Number(this.app.average_rating ?? 0);
        return value > 0 ? value.toFixed(1) : '-';
    }

    build() {
        Row() {
            Text(String(this.index))
                .width(44)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`序号${this.index}`)
            Row({ space: 8 }) {
                Image(this.app.icon_url || $r('app.media.startIcon'))
                    .width(34)
                    .height(34)
                    .borderRadius(8)
                    .objectFit(ImageFit.Cover)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${this.app.name || '未知应用'}图标`)
                Column({ space: 2 }) {
                    Text(this.app.name || '未知应用')
                        .fontSize(13)
                        .fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.v3_text_primary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .accessibilityText(this.app.name || '未知应用')
                    Text(this.app.pkg_name || this.app.app_id)
                        .fontSize(10)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                        .accessibilityText(this.app.pkg_name || this.app.app_id)
                }
                .alignItems(HorizontalAlign.Start)
            }
            .width(220)
            Text(this.app.developer_name || '-')
                .width(150)
                .fontSize(12)
                .fontColor($r('app.color.v3_accent_blue'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`开发者${this.app.developer_name || '未知'}`)
            Text(`${this.app.kind_type_name || '-'} · ${this.app.kind_name || '-'}`)
                .width(140)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`分类${this.app.kind_type_name || ''}${this.app.kind_name || ''}`)
            Text(this.rating())
                .width(70)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`评分${this.rating()}`)
            Text(formatCount(this.app.download_count))
                .width(100)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`下载量${formatCount(this.app.download_count)}`)
            Text(formatBytes(this.app.size_bytes))
                .width(90)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`应用大小${formatBytes(this.app.size_bytes)}`)
            Text(formatDateTime(this.app.updated_at).split(' ')[0])
                .width(110)
                .fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`更新时间${formatDateTime(this.app.updated_at)}`)
        }
        .width(924)
        .height(58)
        .padding({ left: 8, right: 8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.v3_chart_grid') })
        .backgroundColor(this.index % 2 === 0 ? $r('app.color.v3_surface_alt') : $r('app.color.v3_surface'))
        .onClick(() => {
            if (this.vibrationEnabled) vibration.dotVibration();
            this.onOpen(this.app);
        })
        .accessibilityGroup(true)
        .accessibilityText(`打开${this.app.name || '未知应用'}详情`)
    }
}

@Component
export struct AppsPage {
    @Consume('pageStack') private pageStack: NavPathStack;
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    private pageScroller: Scroller = new Scroller();
    @State private apps: MarketApp[] = [];
    @State private page: number = 1;
    @State private total: number = 0;
    @State private loading: boolean = false;
    @State private loaded: boolean = false;
    @State private fromCache: boolean = false;
    @State private sortIndex: number = 0;
    @State private descending: boolean = true;
    @State private jumpText: string = '';
    @State private quickSearch: string = '';
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;
    private restoredScroll: boolean = false;

    private vibrate(): void {
        if (this.vibrationEnabled) vibration.dotVibration();
    }

    private sortChoices(): SortChoice[] {
        return [
            { label: '更新时间', field: 'updated_at' },
            { label: '下载量', field: 'download_count' },
            { label: '评分数量', field: 'total_star_rating_count' },
            { label: '应用大小', field: 'size_bytes' },
            { label: '上架时间', field: 'listed_at' },
        ];
    }

    private sortOptions(): SelectOption[] {
        return this.sortChoices().map((choice: SortChoice) => ({ value: choice.label } as SelectOption));
    }

    private totalPages(): number {
        return Math.max(1, Math.ceil(this.total / APP_LIST_PAGE_SIZE));
    }

    private load(force: boolean = false): void {
        if (this.loading) {
            return;
        }
        this.loading = true;
        const sort = this.sortChoices()[this.sortIndex].field;
        fetchAppsPage(
            this.page,
            APP_LIST_PAGE_SIZE,
            sort,
            this.descending,
            this.quickSearch.trim() ? 'name' : undefined,
            this.quickSearch.trim() || undefined,
            false,
            force,
        ).then((result) => {
            const response = result.data as BaseAPIResponse<PageInfo<MarketApp>>;
            if (!response.success || !response.data) {
                throw new Error('应用总表数据不可用');
            }
            this.apps = response.data.data ?? [];
            this.total = response.data.total_count ?? 0;
            this.fromCache = result.stale;
            this.loaded = true;
        }).catch((error: Error) => {
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `应用总表加载失败: ${error.message}`);
            showToastSafely(this.prompt, `应用总表加载失败：${error.message}`, 2500, 'V3Apps');
        }).finally(() => this.loading = false);
    }

    private jump(): void {
        this.vibrate();
        const target = Number(this.jumpText);
        if (!Number.isInteger(target) || target < 1 || target > this.totalPages()) {
            showToastSafely(this.prompt, `请输入 1 到 ${this.totalPages()} 之间的页码`, 1800, 'V3Apps');
            return;
        }
        this.page = target;
        this.load(false);
    }

    private openDetail(app: MarketApp): void {
        setDetailTarget({ appId: app.app_id, packageName: app.pkg_name });
        try {
            this.pageStack.pushPathByName('AppDetailPage', null);
        } catch (error) {
            console.error('[Dashboard][pages/main/AppsPage][ERROR]', `打开应用详情失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '暂时无法打开应用详情，请重试', 1800, 'AppsPage');
        }
    }

    build() {
        Scroll(this.pageScroller) {
          Column({ space: 12 }) {
            Row() {
                Column({ space: 4 }) {
                    Text('应用总表')
                        .fontSize(26)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                        .accessibilityText('应用总表')
                    Text(`共 ${formatCount(this.total)} 条应用数据`)
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .accessibilityText(`共${formatCount(this.total)}条应用数据`)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)
                Button('刷新')
                    .backgroundColor($r('app.color.v3_accent_blue'))
                    .enabled(!this.loading)
                    .onClick(() => {
                        this.vibrate();
                        this.load(true);
                    })
                    .accessibilityText('刷新应用总表')
            }
            .width('100%')
            .padding({ top: 20, left: 4, right: 4 })

            Flex({ wrap: FlexWrap.Wrap }) {
                Search({ value: this.quickSearch, placeholder: '按应用名称快速筛选' })
                    .width(260)
                    .height(42)
                    .margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .searchButton('筛选')
                    .onChange((value: string) => this.quickSearch = value)
                    .onSubmit(() => {
                        this.vibrate();
                        this.page = 1;
                        this.load(false);
                    })
                    .accessibilityText('按应用名称快速筛选总表')
                Select(this.sortOptions())
                    .selected(this.sortIndex)
                    .value(this.sortChoices()[this.sortIndex].label)
                    .height(42)
                    .margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .onSelect((index: number) => {
                        this.vibrate();
                        this.sortIndex = index;
                        this.page = 1;
                        this.load(false);
                    })
                    .accessibilityText('选择应用总表排序字段')
                Button(this.descending ? '降序 ↓' : '升序 ↑')
                    .height(42)
                    .margin(4)
                    .fontColor($r('app.color.v3_accent_blue'))
                    .backgroundColor($r('app.color.v3_surface'))
                    .onClick(() => {
                        this.vibrate();
                        this.descending = !this.descending;
                        this.page = 1;
                        this.load(false);
                    })
                    .accessibilityText(this.descending ? '当前降序，点击改为升序' : '当前升序，点击改为降序')
            }
            .width('100%')
            .accessibilityText('总表筛选与排序控件')

            if (this.fromCache) {
                Text('当前列表来自本地缓存；恢复网络后点击刷新可获取最新数据')
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_primary'))
                    .padding(10)
                    .width('100%')
                    .borderRadius(10)
                    .backgroundColor($r('app.color.v3_warning_bg'))
                    .accessibilityText('当前应用总表来自本地缓存')
            }

            Stack() {
                Scroll() {
                    Column() {
                        Row() {
                            Text('序号').width(44).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('应用').width(220).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('开发者').width(150).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('分类').width(140).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('评分').width(70).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('下载量').width(100).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('大小').width(90).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                            Text('更新时间').width(110).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        }
                        .height(42)
                        .width(924)
                        .padding({ left: 8, right: 8 })
                        .backgroundColor($r('app.color.v3_surface_alt'))
                        .accessibilityText('应用总表表头')
                        ForEach(this.apps, (app: MarketApp, index: number) => {
                            AppTableRow({
                                app,
                                index: (this.page - 1) * APP_LIST_PAGE_SIZE + index + 1,
                                onOpen: (target: MarketApp) => this.openDetail(target),
                            })
                        }, (app: MarketApp) => `${app.app_id}-${app.updated_at}`)
                    }
                    .width(924)
                }
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Auto)
                .edgeEffect(EdgeEffect.None)
                .width('100%')
                .accessibilityText('可横向滚动的应用总表')

                if (this.loading) {
                    Column({ space: 8 }) {
                        LoadingProgress()
                            .width(32)
                            .height(32)
                            .color($r('app.color.v3_accent_blue'))
                            .accessibilityText('应用总表加载中')
                        Text('正在加载…')
                            .fontColor($r('app.color.v3_text_secondary'))
                            .accessibilityText('正在加载应用总表')
                    }
                    .padding(22)
                    .borderRadius(14)
                    .backgroundColor($r('app.color.v3_surface'))
                    .accessibilityGroup(true)
                }
            }
            .width('100%')
            .borderRadius(16)
            .clip(true)
            .backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })

            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
                Button('上一页')
                    .margin(4)
                    .enabled(this.page > 1 && !this.loading)
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .fontColor($r('app.color.v3_text_primary'))
                    .onClick(() => {
                        this.vibrate();
                        this.page--;
                        this.load(false);
                    })
                    .accessibilityText('上一页')
                Text(`第 ${this.page} / ${this.totalPages()} 页`)
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .margin(8)
                    .accessibilityText(`第${this.page}页，共${this.totalPages()}页`)
                Button('下一页')
                    .margin(4)
                    .enabled(this.page < this.totalPages() && !this.loading)
                    .backgroundColor($r('app.color.v3_accent_blue'))
                    .onClick(() => {
                        this.vibrate();
                        this.page++;
                        this.load(false);
                    })
                    .accessibilityText('下一页')
                TextInput({ text: this.jumpText, placeholder: '页码' })
                    .type(InputType.Number)
                    .width(84)
                    .height(40)
                    .margin(4)
                    .backgroundColor($r('app.color.v3_surface'))
                    .onChange((value: string) => this.jumpText = value)
                    .onSubmit(() => this.jump())
                    .accessibilityText('输入要跳转的页码')
                Button('跳转')
                    .margin(4)
                    .height(40)
                    .backgroundColor($r('app.color.v3_accent_cyan'))
                    .onClick(() => this.jump())
                    .accessibilityText('跳转到指定页')
            }
            .width('100%')
            .padding({ bottom: 110 })
            .accessibilityText('应用总表分页控件')
          }
          .width('100%')
          .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
          .padding({ left: 14, right: 14 })
          .backgroundColor($r('app.color.background'))
          .onAppear(() => {
              if (!this.loaded) {
                  this.load(false);
              }
              if (!this.restoredScroll) {
                  this.restoredScroll = true;
                  const continuation = getContinuationState();
                  if (continuation.mainTab === MAIN_TAB_APPS && continuation.routeName === CONTINUATION_ROUTE_MAIN &&
                      continuation.scrollDistance > 0) {
                      setTimeout(() => this.pageScroller.scrollTo({
                          xOffset: 0,
                          yOffset: continuation.scrollDistance,
                          animation: { duration: 0 },
                      }), 80);
                  }
              }
          })
          .accessibilityText('应用总表页面')
        }
        .width('100%')
        .height('100%')
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .onDidScroll(() => setContinuationView(MAIN_TAB_APPS, this.pageScroller.currentOffset().yOffset))
        .backgroundColor($r('app.color.background'))
        .accessibilityText('可上下滚动的应用总表页面')
    }
}
