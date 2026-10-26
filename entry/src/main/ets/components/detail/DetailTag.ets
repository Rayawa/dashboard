import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

import type { DetailField } from '../../models/detailTypes';

@Component
export struct DetailTag {
    field: DetailField = { label: '', value: '-' };
    @State private pressed: boolean = false;

    build() {
        Row({ space: 7 }) {
            Text(this.field.label)
                .fontSize(11)
                .fontWeight(FontWeight.Medium)
                .fontColor($r('app.color.diff_content'))
                .flexShrink(0)
                .accessibilityText(this.field.label)
            Scroll() {
                Row() {
                    Text(this.field.value)
                        .fontSize(12)
                        .fontColor($r('app.color.v3_text_primary'))
                        .maxLines(1)
                        .textAlign(TextAlign.Start)
                        .accessibilityText(`${this.field.label}${this.field.value}`)
                }
                .constraintSize({ minWidth: '100%' })
                .justifyContent(FlexAlign.Start)
            }
                .layoutWeight(1)
                .height(20)
                .scrollable(ScrollDirection.Horizontal)
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.None)
                .accessibilityText(`${this.field.label}详情，可左右滑动查看`)
        }
        .alignItems(VerticalAlign.Center)
        .padding({ left: 10, right: 10, top: 7, bottom: 7 })
        .width('100%')
        .height(36)
        .borderRadius(14)
        .backgroundColor($r('app.color.v3_surface_alt'))
        .border({ width: 1, color: $r('app.color.v3_chart_grid') })
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
            this.pressed, hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .accessibilityGroup(true)
        .accessibilityText(`${this.field.label}，${this.field.value}`)
    }
}

