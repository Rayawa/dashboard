import type { MarketApp } from '../../models/types';
import { AppDataSource, AppTableItem } from '../../models/AppDataSource';
import { AppTableRow } from './AppTableRow';
import { contentEnterTransition } from '../../ui/animation/motion';

/** 表格负责行数据源、列宽与内部滚动；页面只提供当前页和导航动作。 */
@Component
export struct AppTable {
    @Prop @Watch('updateAppSource') apps: MarketApp[] = [];
    @Prop @Watch('updateAppSource') rowOffset: number = 0;
    @Prop loading: boolean = false;
    onOpen: (app: MarketApp) => void = (_app: MarketApp): void => {};
    @State private tableViewportWidth: number = 0;
    private appSource: AppDataSource = new AppDataSource();
    private tableScroller: Scroller = new Scroller();

    aboutToAppear(): void { this.updateAppSource(); }

    private updateAppSource(): void {
        this.appSource.replace(this.apps, this.rowOffset);
        this.tableScroller.scrollTo({ xOffset: 0, yOffset: 0 });
    }
    private tableWidth(): number { return Math.max(924, this.tableViewportWidth); }
    private developerWidth(): number { return 150 + Math.max(0, this.tableViewportWidth - 924); }

    build() {
        Stack() {
            Scroll() {
                Column() {
                    Row() {
                        Text('序号').width(44).fontSize(12).textAlign(TextAlign.Center)
                            .fontColor($r('app.color.v3_text_secondary'))
                        Text('应用').width(220).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('开发者').width(this.developerWidth()).fontSize(12)
                            .fontColor($r('app.color.v3_text_secondary'))
                        Text('分类').width(140).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('评分').width(70).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('下载量').width(100).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('大小').width(90).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        Text('更新时间').width(110).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                    }
                    .height(42).width(this.tableWidth()).padding({ left: 8, right: 8 })
                    .backgroundColor($r('app.color.v3_surface_alt')).accessibilityText('应用列表表头')
                    List({ scroller: this.tableScroller }) {
                        LazyForEach(this.appSource, (item: AppTableItem) => {
                            ListItem() {
                                AppTableRow({ item,
                                    tableWidth: this.tableWidth(), developerWidth: this.developerWidth(),
                                    onOpen: (target: MarketApp): void => this.onOpen(target) })
                            }
                        }, (item: AppTableItem) => item.app.app_id)
                    }
                    .width(this.tableWidth()).height(Math.min(10, Math.max(1, this.apps.length)) * 58)
                    .cachedCount(4).scrollBar(BarState.Auto)
                    .nestedScroll({ scrollForward: NestedScrollMode.SELF_FIRST, scrollBackward: NestedScrollMode.SELF_FIRST })
                }.width(this.tableWidth())
            }
            .scrollable(ScrollDirection.Horizontal).scrollBar(BarState.Auto).edgeEffect(EdgeEffect.None)
            .width('100%').accessibilityText('应用列表，窄屏可横向滚动')
            if (this.loading) {
                Column({ space: 8 }) {
                    LoadingProgress().width(32).height(32).color($r('app.color.diff_content'))
                        .accessibilityText('应用列表加载中')
                    Text('正在加载…').fontColor($r('app.color.v3_text_secondary'))
                }.padding(22).borderRadius(14).backgroundColor($r('app.color.v3_surface')).accessibilityGroup(true)
                    .accessibilityText('应用列表加载中')
                    .transition(contentEnterTransition(8))
            }
        }
        .width('100%').borderRadius(16).clip(true).backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .onAreaChange((_oldValue: Area, newValue: Area): void => {
            const width = Number(newValue.width);
            if (width > 0) this.tableViewportWidth = width;
        })
    }
}
