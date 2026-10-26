import { DiscoveryInteraction } from '../../ui/interaction/DiscoveryInteraction';
import { DiscoveryRowStyle } from '../../ui/theme/DiscoveryTheme';
import { DiscoveryEnter } from './DiscoveryEnter';
import { AppIcon } from '../apps/AppIcon';
@Component
export struct AppSummaryRow {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Prop enterOrder: number = 0;
    @Prop enterSpeed: number = 1;
    @Prop name: string = '';
    @Prop iconUrl: string = '';
    @Prop appId: string = '';
    @Prop packageName: string = '';
    @Prop showIcon: boolean = true;
    @Prop subtitle: string = '';
    @Prop value: string = '';
    @Prop subtitleMaxLines: number = 3;
    @Prop compact: boolean = false;
    @Prop showArrow: boolean = true;
    @Prop actionLabel: string = '点击查看';
    onOpen: () => void = (): void => {};
    @Builder
    private body(): void {
        Row({ space: 12 }) {
            if (this.showIcon) {
                AppIcon({ appId: this.appId, packageName: this.packageName, iconUrl: this.iconUrl,
                    iconSize: this.compact ? 36 : 44 })
            }
            Column({ space: 5 }) {
                Text(this.name || '未知应用').fontSize(this.compact ? 15 : 16).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.v3_text_primary')).maxLines(this.compact ? 1 : 2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%')
                if (this.subtitle) {
                    Text(this.subtitle).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        .maxLines(this.subtitleMaxLines).width('100%')
                }
            }.layoutWeight(1).alignItems(HorizontalAlign.Start)
            if (this.value) {
                Text(this.value).fontSize(13).fontColor($r('app.color.diff_content')).constraintSize({ maxWidth: '32%' })
            }
            if (this.showArrow) {
                Text('›').fontSize(22).fontColor($r('app.color.v3_text_secondary')).accessibilityLevel('no')
            }
        }
        .width('100%').padding(this.compact ? 10 : 16).borderRadius(16)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .attributeModifier(new DiscoveryRowStyle(this.interaction.pressedKey === 'row'))
        .onTouch((event: TouchEvent): void => this.interaction.touch('row', event))
        .onClick((): void => { this.interaction.activate('row'); this.onOpen(); })
        .accessibilityRole(AccessibilityRoleType.BUTTON)
        .accessibilityGroup(true).accessibilityText(`${this.name}，${this.subtitle}，${this.value}，${this.actionLabel}`)
    }
    build() {
        DiscoveryEnter({ order: this.enterOrder, speed: this.enterSpeed, content: (): void => { this.body(); } })
    }
}
