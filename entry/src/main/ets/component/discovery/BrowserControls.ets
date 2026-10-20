import { DiscoveryEnter } from './DiscoveryEnter';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
@Component
export struct BrowserStatus {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @Prop loading: boolean = false;
    @Prop error: string = '';
    @Prop stale: boolean = false;
    @Prop empty: boolean = false;
    @Prop emptyText: string = '暂无数据';
    onRetry: () => void = (): void => {};
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Builder
    private body(): void {
        Column({ space: 10 }) {
            if (this.loading) { LoadingProgress().width(32).height(32).color($r('app.color.diff_content')) }
            if (this.error) {
                Text(this.error).fontColor($r('app.color.v3_accent_red')).fontSize(14)
                Button('重试', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-0'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-0', event)).onClick((): void => { this.interaction.activate('discovery-0'); this.onRetry(); })
            } else if (this.empty && !this.loading) {
                Text(this.emptyText).fontSize(14).fontColor($r('app.color.v3_text_secondary'))
            }
            if (this.stale) {
                Text('网络不可用，当前显示离线缓存').fontSize(12).fontColor($r('app.color.v3_text_secondary'))
            }
        }.width('100%')
    }
    build() {
        DiscoveryEnter({ order: 0, content: (): void => { this.body(); } })
    }
}
@Component
export struct BrowserPagination {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    @Prop page: number = 1;
    @Prop total: number = 0;
    @Prop pageSize: number = 20;
    @Prop loading: boolean = false;
    onPage: (page: number) => void = (): void => {};
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Builder
    private body(): void {
        Row({ space: 12 }) {
            Button('上一页', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-1'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-1', event)).enabled(!this.loading && this.page > 1)
                .onClick((): void => { this.interaction.activate('discovery-1'); this.onPage(this.page - 1); })
            Text(`${this.page} / ${Math.max(1, Math.ceil(this.total / this.pageSize))} 页 · 共 ${this.total} 条`)
                .fontSize(12).fontColor($r('app.color.v3_text_secondary')).layoutWeight(1).textAlign(TextAlign.Center)
            Button('下一页', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-2'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-2', event)).enabled(!this.loading && this.page * this.pageSize < this.total)
                .onClick((): void => { this.interaction.activate('discovery-2'); this.onPage(this.page + 1); })
        }.width('100%')
    }
    build() {
        DiscoveryEnter({ order: 0, content: (): void => { this.body(); } })
    }
}
