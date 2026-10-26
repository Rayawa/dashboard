import { CollectionList } from '../../components/collection/CollectionList';
import { BrowserStatus } from '../../components/discovery/BrowserControls';
import { getLocalCollection } from '../../services/storage/storage';
import { CONTENT_MAX_WIDTH } from '../../config/constants';
import { scrollByAxis } from '../../ui/interaction/scroll';
import type { SavedApp, FollowedDeveloper } from '../../models/types';

@Component
export struct CollectionPage {
    @Link @Watch('resetScroll') selectedIndexes: number[];
    @Prop @Watch('onActiveChanged') active: boolean = false;
    @Prop @Watch('scrollToTop') scrollToTopVersion: number = 0;
    @State private apps: SavedApp[] = [];
    @State private developers: FollowedDeveloper[] = [];
    @State private loading: boolean = false;
    @State private error: string = '';
    private scroller: Scroller = new Scroller();
    private token: number = 0;
    private alive: boolean = false;

    aboutToAppear(): void {
        this.alive = true;
        if (this.active) this.load();
    }
    aboutToDisappear(): void { this.alive = false; this.token++; }
    private onActiveChanged(): void { if (this.active && this.alive) this.load(); }
    private resetScroll(): void {
        try { this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); }
        catch (_) { /* 首次布局前没有可滚动内容。 */ }
    }
    private scrollToTop(): void {
        if (this.active) this.scroller.scrollTo({ xOffset: 0, yOffset: 0, animation: { duration: 300 } });
    }
    private async load(): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = '';
        try {
            const saved = await getLocalCollection();
            if (!this.alive || token !== this.token) return;
            this.apps = saved.apps; this.developers = saved.developers;
        } catch (_) {
            if (this.alive && token === this.token) this.error = '无法读取收藏，请重试';
        } finally { if (this.alive && token === this.token) this.loading = false; }
    }
    build() {
        Scroll(this.scroller) {
            Column({ space: 14 }) {
                Blank().height(100)
                Text('收藏保存在本机，打开应用或开发者时获取最新数据。')
                    .fontSize(13).fontColor($r('app.color.v3_text_secondary')).width('100%')
                BrowserStatus({ enterSpeed: 2, loading: this.loading, error: this.error,
                    empty: this.selectedIndexes[0] === 1 ? this.developers.length === 0 : this.apps.length === 0,
                    emptyText: this.selectedIndexes[0] === 1 ?
                        '还没有收藏的开发者。点击开发者应用页标题栏的星星即可收藏。' :
                        '还没有收藏的应用。点击应用详情标题栏的星星即可收藏。',
                    onRetry: (): void => { this.load(); } })
                CollectionList({ apps: this.apps, developers: this.developers,
                    selectedIndex: this.selectedIndexes[0] ?? 0 })
                Blank().height(112)
            }
            .width('100%').constraintSize({ maxWidth: CONTENT_MAX_WIDTH }).padding({ left: 14, right: 14 })
        }
        .width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Auto)
        .backgroundColor($r('app.color.background'))
        .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
        .accessibilityText(this.selectedIndexes[0] === 1 ? '收藏的开发者页面' : '收藏的应用页面')
    }
}
