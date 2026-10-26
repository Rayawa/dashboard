@Component
export struct AppDescription {
    @Prop description: string = '';
    @Prop newFeatures: string = '';
    @Link descriptionExpanded: boolean;
    @Link featuresExpanded: boolean;

    build() {
        Column({ space: 10 }) {
            Text('应用介绍')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText('应用介绍')
            Text(this.description || '暂无介绍')
                .maxLines(this.descriptionExpanded ? 10000 : 8)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
                .fontSize(14)
                .lineHeight(22)
                .fontColor($r('app.color.v3_text_primary'))
                .width('100%')
                .accessibilityText(this.description || '暂无应用介绍')
            if (this.description.length > 240) {
                Button(this.descriptionExpanded ? '收起介绍' : '展开完整介绍')
                    .onClick((): void => { this.descriptionExpanded = !this.descriptionExpanded; })
            }
            if (this.newFeatures) {
                Divider().color($r('app.color.v3_chart_grid')).accessibilityText('内容分隔线')
                Text('新版特性')
                    .fontSize(16)
                    .fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText('新版特性')
                Text(this.newFeatures)
                    .maxLines(this.featuresExpanded ? 10000 : 6)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .fontSize(14)
                    .lineHeight(22)
                    .fontColor($r('app.color.v3_text_primary'))
                    .width('100%')
                    .accessibilityText(this.newFeatures)
                if (this.newFeatures.length > 180) {
                    Button(this.featuresExpanded ? '收起新版特性' : '展开新版特性')
                        .onClick((): void => { this.featuresExpanded = !this.featuresExpanded; })
                }
            }
        }
        .width('100%')
        .padding(18)
        .borderRadius(18)
        .backgroundColor($r('app.color.v3_surface'))
        .border({ width: 1, color: $r('app.color.nd_card_border') })
        .accessibilityGroup(false).accessibilityLevel('no')
        .accessibilityText('应用介绍和新版特性')
    }
}
