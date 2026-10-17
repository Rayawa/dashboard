import { AppIcon } from '../apps/AppIcon';
@Component
export struct AppSummaryRow {
    @Prop name: string = '';
    @Prop iconUrl: string = '';
    @Prop appId: string = '';
    @Prop packageName: string = '';
    @Prop showIcon: boolean = true;
    @Prop subtitle: string = '';
    @Prop value: string = '';
    onOpen: () => void = (): void => {};
    build() {
        Row({ space: 12 }) {
            if (this.showIcon) {
                AppIcon({ appId: this.appId, packageName: this.packageName, iconUrl: this.iconUrl })
            }
            Column({ space: 5 }) {
                Text(this.name || '未知应用').fontSize(16).fontWeight(FontWeight.Medium)
                    .fontColor($r('app.color.v3_text_primary')).maxLines(2).width('100%')
                if (this.subtitle) {
                    Text(this.subtitle).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
                        .maxLines(3).width('100%')
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
        .onClick((): void => this.onOpen())
        .accessibilityGroup(true).accessibilityText(`${this.name}，${this.subtitle}，${this.value}，点击查看`)
    }
}
