import type { MarketApp } from '../../models/types';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { formatDateTime, formatDownloadCount } from '../../utils/format/format';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

@Component
export struct SearchRecommendationCard {
    @Prop app: MarketApp = {} as MarketApp;
    onOpen: (app: MarketApp) => void = (_app: MarketApp): void => {};
    @State private pressed: boolean = false;

    build() {
        Column({ space: 5 }) {
            Stack() {
                Image(this.app.icon_url || $r('app.media.startIcon'))
                    .width('100%').height('100%').objectFit(ImageFit.Cover)
                    .borderRadius(10).clip(true)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${this.app.name || '未知应用'}图标`)
            }
                .width(42).height(42).borderRadius(10).clip(true)
            Text(this.app.name || '未知应用').fontSize(13).fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.app.developer_name || '未知开发者').fontSize(11)
                .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('48%').height(104).padding({ top: 12, bottom: 10 }).borderRadius(14)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .margin({ bottom: 10 })
        .scale({ x: this.pressed ? 0.97 : 1,
            y: this.pressed ? 0.97 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressed,
            hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .onClick(() => this.onOpen(this.app))
        .accessibilityGroup(true)
        .accessibilityText(`推荐应用${this.app.name || '未知应用'}，开发者${this.app.developer_name || '未知'}`)
    }
}

@Component
export struct SearchResultCard {
    @Prop app: MarketApp = {} as MarketApp;
    onOpen: (app: MarketApp) => void = (_app: MarketApp): void => {};
    @State private pressed: boolean = false;

    build() {
        Row({ space: 12 }) {
            Stack() {
                Image(this.app.icon_url || $r('app.media.startIcon'))
                    .width('100%').height('100%').objectFit(ImageFit.Cover)
                    .borderRadius(14).clip(true)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${this.app.name || '未知应用'}应用图标`)
            }
                .width(58).height(58).borderRadius(14).clip(true)
            Column({ space: 4 }) {
                Text(this.app.name || '未知应用').fontSize(17).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary')).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(this.app.developer_name || '未知开发者').fontSize(12).fontColor($r('app.color.diff_content'))
                    .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.app.pkg_name} · ${formatDownloadCount(this.app.download_count)} 下载`).fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary')).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`更新：${formatDateTime(this.app.updated_at)}`).fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)
            Text('›').fontSize(26).fontColor($r('app.color.v3_text_secondary')).accessibilityText('进入详情')
        }
        .width('100%').height(96).padding(14).borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .scale({ x: this.pressed ? 0.975 : 1,
            y: this.pressed ? 0.975 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressed,
            hdsEffect.PointLightIlluminatedType.BORDER_CONTENT))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .onClick(() => this.onOpen(this.app))
        .accessibilityGroup(true).accessibilityText(`打开${this.app.name || '未知应用'}详情`)
    }
}
