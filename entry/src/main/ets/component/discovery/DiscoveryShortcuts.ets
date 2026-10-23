import { DiscoveryEnter } from './DiscoveryEnter';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { openAppCollection, openMarketRanking, openMarketTopic } from '../../common/discoveryNavigation';
import { LengthMetrics } from '@kit.ArkUI';
import { DISCOVERY_PRESETS } from '../../common/DiscoveryQuery';
import type { DiscoveryPreset } from '../../common/DiscoveryQuery';

@Component
export struct DiscoveryShortcuts {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    @Consume('pageStack') private pageStack: NavPathStack;
    aboutToDisappear(): void { this.interaction.dispose(); }
    @Builder
    private body(): void {
        Column({ space: 12 }) {
            Text('发现应用').fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            Flex({ wrap: FlexWrap.Wrap, space: { main: LengthMetrics.vp(8), cross: LengthMetrics.vp(10) } }) {
                ForEach(DISCOVERY_PRESETS, (preset: DiscoveryPreset) => {
                    Button(preset.title, { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === ('preset-' + preset.key)))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('preset-' + preset.key, event)).fontSize(13)
                        .onClick((): void => { this.interaction.activate('preset-' + preset.key);
                            openAppCollection(this.pageStack, { title: preset.title, preset: preset.key });
                        })
                }, (preset: DiscoveryPreset) => preset.key)
                Button('全部榜单', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-1'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-1', event)).fontSize(13).onClick((): void => { this.interaction.activate('discovery-1');
                    openMarketRanking(this.pageStack, { kind: 'downloads' });
                })
                Button('分类增长', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-2'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-2', event)).fontSize(13).onClick((): void => { this.interaction.activate('discovery-2');
                    openMarketRanking(this.pageStack, { kind: 'category' });
                })
                Button('专题浏览', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === 'discovery-3'))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('discovery-3', event)).fontSize(13).onClick((): void => { this.interaction.activate('discovery-3'); openMarketTopic(this.pageStack); })
            }.width('100%')
        }.width('100%').padding(18).borderRadius(18).backgroundColor($r('app.color.v3_surface'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
    }
    build() {
        DiscoveryEnter({ order: 0, content: (): void => { this.body(); } })
    }
}
