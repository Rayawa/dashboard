import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryRowStyle } from '../../common/DiscoveryTheme';
import { DiscoveryEnter } from './DiscoveryEnter';
import { AppIcon } from '../apps/AppIcon';
@Component
export struct AppSummaryRow {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction();
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Prop enterOrder: number = 0;
    @Prop name: string = '';
    @Prop iconUrl: string = '';
    @Prop appId: string = '';
    @Prop packageName: string = '';
    @Prop showIcon: boolean = true;
    @Prop subtitle: string = '';
    @Prop value: string = '';
    @Prop subtitleMaxLines: number = 3;
    onOpen: () => void = (): void => {};
    @Builder
    private body(): void {
        Row({ space: 12 }) {
            if (this.showIcon) {
                AppIcon({ appId: this.appId, packageName: this.packageName, iconUrl: this.iconUrl })
            }
            Column({ space: 5 }) {
                Text(this.name || '未知应用').fontSize(16).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.v3_text_primary')).maxLines(2).width('100%')
                if (this.subtitle) {
                    Text(this.subtitle).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        .maxLines(this.subtitleMaxLines).width('100%')
                }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            if (this.value) {
                Text(this.value).fontSize(13).fontColor($r('app.color.diff_content')).constraintSize({ maxWidth: '32%' })
            }
            Text('›').fontSize(22).fontColor($r('app.color.v3_text_secondary')).accessibilityLevel('no')
        }
        .width('100%').padding(16).borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .attributeModifier(new DiscoveryRowStyle(this.interaction.pressedKey === 'row'))
        .onTouch((event: TouchEvent): void => this.interaction.touch('row', event))
        .onClick((): void => { this.interaction.activate('row'); this.onOpen(); })
        .accessibilityGroup(true).accessibilityText(`${this.name}，${this.subtitle}，${this.value}，点击查看`)
    }
    build() {
        DiscoveryEnter({ order: this.enterOrder, content: (): void => { this.body(); } })
    }
}
