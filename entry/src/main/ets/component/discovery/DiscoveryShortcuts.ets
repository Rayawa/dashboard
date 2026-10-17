import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { openAppCollection, openMarketRanking, openMarketTopic } from '../../common/discoveryNavigation';
import { LengthMetrics } from '@kit.ArkUI';
import { DISCOVERY_PRESETS } from '../../common/DiscoveryQuery';
import type { DiscoveryPreset } from '../../common/DiscoveryQuery';

@Component
export struct DiscoveryShortcuts {
    @Consume('pageStack') private pageStack: NavPathStack;
    build() {
        Column({ space: 12 }) {
            Text('发现应用').fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(10) } }) {
                ForEach(DISCOVERY_PRESETS, (preset: DiscoveryPreset) => {
                    Button(preset.title).attributeModifier(new DiscoveryButtonStyle()).fontSize(13)
                        .onClick((): void => {
                            openAppCollection(this.pageStack, { title: preset.title, preset: preset.key });
                        })
                }, (preset: DiscoveryPreset) => preset.key)
                Button('全部榜单').attributeModifier(new DiscoveryButtonStyle()).fontSize(13).onClick((): void => {
                    openMarketRanking(this.pageStack, { kind: 'downloads' });
                })
                Button('分类增长').attributeModifier(new DiscoveryButtonStyle()).fontSize(13).onClick((): void => {
                    openMarketRanking(this.pageStack, { kind: 'category' });
                })
                Button('专题浏览').attributeModifier(new DiscoveryButtonStyle()).fontSize(13).onClick((): void => { openMarketTopic(this.pageStack); })
            }.width('100%')
        }.width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
    }
}
