import type { MarketApp } from '../../models/types';
import { formatDateTime } from '../../utils/format/format';
import { vibration } from '../../utils/device/vibration';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

@Component
export struct RecentAppCard {
    @Prop app: MarketApp = {} as MarketApp;
    onOpen: (app: MarketApp) => void = () => {};
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;
    @State private pressed: boolean = false;

    build() {
        Row({ space: 12 }) {
            Stack() {
                Image(this.app.icon_url || $r('app.media.startIcon'))
                    .width('100%')
                    .height('100%')
                    .objectFit(ImageFit.Cover)
                    .borderRadius(12)
                    .clip(true)
                    .alt($r('app.media.startIcon'))
                    .accessibilityText(`${this.app.name || '未知应用'}图标`)
            }
                .width(48)
                .height(48)
                .borderRadius(12)
                .clip(true)
            Column({ space: 4 }) {
                Text(this.app.name || '未知应用')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.v3_text_primary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`${this.app.developer_name || '未知开发者'} · ${this.app.version || '未知版本'}`)
                    .fontSize(12)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(`收录于 ${formatDateTime(this.app.listed_at)}`)
                    .fontSize(11)
                    .fontColor($r('app.color.v3_text_secondary'))
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)
            Image($r('app.media.right'))
                .width(18)
                .height(18)
                .fillColor($r('app.color.v3_text_secondary'))
                .accessibilityText('打开详情')
        }
        .width('100%')
        .padding(14)
        .borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .scale({ x: this.pressed ? 0.975 : 1, y: this.pressed ? 0.975 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) {
                this.pressed = true;
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                this.pressed = false;
            }
        })
        .onClick(() => {
            if (this.vibrationLevel > 0) vibration.dotVibration();
            this.onOpen(this.app);
        })
        .accessibilityGroup(true)
        .accessibilityText(`新收录应用${this.app.name || '未知应用'}，点击查看详情`)
    }
}
