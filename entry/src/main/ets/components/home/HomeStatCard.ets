import type { HomeStat } from '../../models/homeTypes';
import { RollingNumber } from './RollingNumber';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

@Component
export struct HomeStatCard {
    @Prop stat: HomeStat = { label: '', value: 0, color: $r('app.color.diff_content') };
    @State private pressed: boolean = false;
    onOpen: () => void = (): void => {};

    build() {
        Column({ space: 8 }) {
            Text(this.stat.label)
                .fontSize(13)
                .fontColor($r('app.color.v3_text_secondary'))
                .maxLines(1)
                .accessibilityText(this.stat.label)
            RollingNumber({
                value: this.stat.value,
                fontSize: 24,
                color: this.stat.color,
                accessibilityLabel: this.stat.label,
            })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .shadow({ radius: 12, color: $r('app.color.v3_shadow'), offsetY: 3 })
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
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
        .accessibilityGroup(true)
        .onClick((): void => this.onOpen())
        .accessibilityText(`${this.stat.label}，${this.stat.value}，点击查看全部`)
    }
}
