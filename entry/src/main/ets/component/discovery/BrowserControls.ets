import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
@Component
export struct BrowserStatus {
    @Prop loading: boolean = false;
    @Prop error: string = '';
    @Prop stale: boolean = false;
    @Prop empty: boolean = false;
    @Prop emptyText: string = '暂无数据';
    onRetry: () => void = (): void => {};
    build() {
        Column({ space: 10 }) {
            if (this.loading) { LoadingProgress().width(32).height(32).color($r('app.color.diff_content')) }
            if (this.error) {
                Text(this.error).fontColor($r('app.color.v3_accent_red')).fontSize(14)
                Button('重试').attributeModifier(new DiscoveryButtonStyle()).onClick((): void => this.onRetry())
            } else if (this.empty && !this.loading) {
                Text(this.emptyText).fontSize(14).fontColor($r('app.color.v3_text_secondary'))
            }
            if (this.stale) {
                Text('网络不可用，当前显示离线缓存').fontSize(12).fontColor($r('app.color.v3_text_secondary'))
            }
        }.width('100%')
    }
}
@Component
export struct BrowserPagination {
    @Prop page: number = 1;
    @Prop total: number = 0;
    @Prop pageSize: number = 20;
    @Prop loading: boolean = false;
    onPage: (page: number) => void = (): void => {};
    build() {
        Row({ space: 12 }) {
            Button('上一页').attributeModifier(new DiscoveryButtonStyle()).enabled(!this.loading && this.page > 1)
                .onClick((): void => this.onPage(this.page - 1))
            Text(`${this.page} / ${Math.max(1, Math.ceil(this.total / this.pageSize))} 页 · 共 ${this.total} 条`)
                .fontSize(12).fontColor($r('app.color.v3_text_secondary')).layoutWeight(1).textAlign(TextAlign.Center)
            Button('下一页').attributeModifier(new DiscoveryButtonStyle()).enabled(!this.loading && this.page * this.pageSize < this.total)
                .onClick((): void => this.onPage(this.page + 1))
        }.width('100%')
    }
}
