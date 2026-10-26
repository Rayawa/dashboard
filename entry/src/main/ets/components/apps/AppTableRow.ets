import { AppTableItem } from '../../models/AppDataSource';
import { formatBytes, formatDateTime, formatDownloadCount } from '../../utils/format/format';
import type { MarketApp } from '../../models/types';
import { vibration } from '../../utils/device/vibration';

/** 单条应用数据的表格展示与交互，列表页只负责查询、筛选和分页。 */
@Component
export struct AppTableRow {
    @State item: AppTableItem = new AppTableItem({} as MarketApp, 0);
    @Prop tableWidth: number = 924;
    @Prop developerWidth: number = 150;
    onOpen: (app: MarketApp) => void = () => {};
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @State private pressed: boolean = false;

    private rating(): string {
        const value = Number(this.item.app.average_rating ?? 0);
        return value > 0 ? String(value) : '-';
    }

    build() {
        Row() {
            Text(String(this.item.index)).width(44).fontSize(12).textAlign(TextAlign.Center)
                .fontColor($r('app.color.v3_text_secondary')).accessibilityText(`序号${this.item.index}`)
            Row({ space: 8 }) {
                Stack() {
                    Image(this.item.app.icon_url || $r('app.media.startIcon'))
                        .width('100%').height('100%').objectFit(ImageFit.Cover)
                        .borderRadius(8).clip(true)
                        .alt($r('app.media.startIcon'))
                        .accessibilityText(`${this.item.app.name || '未知应用'}图标`)
                }
                    .width(34).height(34).borderRadius(8).clip(true)
                Column({ space: 2 }) {
                    Text(this.item.app.name || '未知应用').fontSize(13).fontWeight(FontWeight.Medium)
                        .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.item.app.pkg_name || this.item.app.app_id).fontSize(10)
                        .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                }.alignItems(HorizontalAlign.Start)
            }.width(220)
            Text(this.item.app.developer_name || '-').width(this.developerWidth).fontSize(12)
                .fontColor($r('app.color.diff_content')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`开发者${this.item.app.developer_name || '未知'}`)
            Text(`${this.item.app.kind_type_name || '-'} · ${this.item.app.kind_name || '-'}`).width(140).fontSize(12)
                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(`分类${this.item.app.kind_type_name || ''}${this.item.app.kind_name || ''}`)
            Text(this.rating()).width(70).fontSize(12).fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`评分${this.rating()}`)
            Text(formatDownloadCount(this.item.app.download_count)).width(100).fontSize(12)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText(`下载量${formatDownloadCount(this.item.app.download_count)}`)
            Text(formatBytes(this.item.app.size_bytes)).width(90).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`应用大小${formatBytes(this.item.app.size_bytes)}`)
            Text(formatDateTime(this.item.app.updated_at).split(' ')[0]).width(110).fontSize(12)
                .fontColor($r('app.color.v3_text_secondary'))
                .accessibilityText(`更新时间${formatDateTime(this.item.app.updated_at)}`)
        }
        .width(this.tableWidth).height(58).padding({ left: 8, right: 8 })
        .border({ width: { bottom: 1 }, color: $r('app.color.v3_chart_grid') })
        .backgroundColor(this.item.index % 2 === 0 ? $r('app.color.v3_surface_alt') : $r('app.color.v3_surface'))
        .scale({ x: this.pressed ? 0.99 : 1, y: this.pressed ? 0.99 : 1 })
        .animation({ curve: Curve.EaseOut, duration: 120 })
        .onTouch((event: TouchEvent) => {
            if (event.type === TouchType.Down) {
                this.pressed = true;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressed = false;
            }
        })
        .onClick(() => {
            if (this.vibrationLevel > 0) vibration.dotVibration();
            this.onOpen(this.item.app);
        })
        .accessibilityGroup(true)
        .accessibilityText(`序号${this.item.index}，${this.item.app.name || '未知应用'}，开发者${this.item.app.developer_name || '未知'}，分类${this.item.app.kind_type_name || ''}${this.item.app.kind_name || ''}，评分${this.rating()}，下载量${formatDownloadCount(this.item.app.download_count)}，点击打开详情`)
    }
}
