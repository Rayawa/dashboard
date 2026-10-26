import type { MarketApp } from '../../models/types';
import { hdsEffect } from '@kit.UIDesignKit';
import { DiscoveryInteraction } from '../../ui/interaction/DiscoveryInteraction';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

@Component
export struct AppIdentity {
    @Prop app: MarketApp | undefined = undefined;
    onOpenDeveloper: () => void = (): void => {};
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());

    aboutToDisappear(): void { this.interaction.dispose(); }

    build() {
        Column({ space: 8 }) {
            Image(this.app?.icon_url || $r('app.media.startIcon'))
                .width(100)
                .height(100)
                .borderRadius(22)
                .objectFit(ImageFit.Cover)
                .alt($r('app.media.startIcon'))
                .accessibilityText(`${this.app?.name || '未知应用'}应用图标`)
                .margin({ bottom: 10 })
            Text(this.app?.name || '未知应用')
                .fontSize(30)
                .fontWeight(800)
                .fontColor($r('app.color.diff_content'))
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .accessibilityText(this.app?.name || '未知应用')
            Text(this.app?.developer_name || '未知开发者')
                .fontSize(20)
                .fontWeight(600)
                .fontColor($r('app.color.v3_text_secondary'))
                .textAlign(TextAlign.Center)
                .maxLines(2)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .scale({ x: this.interaction.pressedKey === 'developer-link' ? 0.97 : 1,
                    y: this.interaction.pressedKey === 'developer-link' ? 0.97 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.interaction.pressedKey === 'developer-link',
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 5, 84))
                .compositingFilter(pressLightFieldFilter(this.interaction.pressedKey === 'developer-link'))
                .onTouch((event: TouchEvent): void => this.interaction.touch('developer-link', event))
                .onClick((): void => { this.interaction.activate('developer-link'); this.onOpenDeveloper(); })
                .accessibilityText(`开发公司${this.app?.developer_name || '未知'}，点击查看全部应用`)
        }
        .width('100%')
        .padding({ top: 18, bottom: 18, left: 12, right: 12 })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText(`${this.app?.name || '未知应用'}的图标、名称和开发公司`)
    }
}
