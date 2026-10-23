import { vibration } from '../../common/vibration';
import { DiscoveryEnter } from './DiscoveryEnter';
import { getContinuationState, setContinuationView } from '../../common/appState';
import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType, HdsNavigationMenuItemOptions } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';
import { CONTENT_MAX_WIDTH } from '../../common/constants';
import { pageTransition } from '../../common/motion';
import { scrollByAxis } from '../../common/scroll';
import { HDS_MATERIAL_LEVEL_GENTLE, HDS_MATERIAL_TYPE_ADAPTIVE, HDS_TITLE_SIZE_SMALL, SUPPORTS_HARMONY_API_23 } from '../../common/platformCompatibility';

@Builder
function emptyContent(): void {}

@Component
export struct MarketPageFrame {
    @Prop title: string = '';
    @Prop subtitle: string = '';
    @Prop busy: boolean = false;
    menuProvider: (busy: boolean) => HdsNavigationMenuItemOptions[] =
        (_busy: boolean): HdsNavigationMenuItemOptions[] => [];
    @Prop @Watch('resetScroll') resetKey: string = '';
    @BuilderParam content: () => void = emptyContent;
    onShown: () => void = (): void => {};
    @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
    private scroller: Scroller = new Scroller();
    private resetScroll(): void {
        try { this.scroller.scrollTo({ xOffset: 0, yOffset: 0 }); }
        catch (_) { /* 首次布局前没有可滚动内容。 */ }
    }
    build() {
        HdsNavDestination() {
            Scroll(this.scroller) {
                Column({ space: 14 }) {
                    Blank().height(100)
                    DiscoveryEnter({ speed: 2, content: (): void => { this.content(); } })
                    Blank().height(40)
                }
                .width('100%').constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
                .padding({ left: 14, right: 14 })
            }
            .width('100%').height('100%').align(Alignment.Top).scrollBar(BarState.Auto)
            .backgroundColor($r('app.color.background'))
            .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
        }
        .onShown((): void => {
            setContinuationView(getContinuationState().mainTab, 0);
            this.onShown();
        })
        .titleBar({
          style: {
            scrollEffectOpts: {
              enableScrollEffect: false,
              scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
              blurEffectiveStartOffset: LengthMetrics.vp(0),
              blurEffectiveEndOffset: LengthMetrics.vp(20),
            },
            originalStyle: {
              backgroundStyle: {
                backgroundColor: Color.Transparent,
              },
              contentStyle: {
                titleStyle: {
                  mainTitleColor: $r('app.color.v3_text_primary'),
                },
                menuStyle: {
                  backgroundColor: $r('sys.color.comp_background_tertiary'),
                  iconColor: $r('sys.color.icon_primary'),
                },
              },
            },
            scrollEffectStyle: {
              backgroundStyle: {
                backgroundColor: Color.Transparent,
              },
              contentStyle: {
                titleStyle: {
                  mainTitleColor: $r('app.color.v3_text_primary'),
                },
                menuStyle: {
                  backgroundColor: $r('sys.color.comp_background_tertiary'),
                  iconColor: $r('sys.color.icon_primary'),
                },
              },
            },
            systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
              materialType: HDS_MATERIAL_TYPE_ADAPTIVE,
              materialLevel: this.immersiveMaterialLevel,
            } : undefined,
          },
          content: {
            title: {
              mainTitle: this.title,
              subTitle: this.subtitle,
              mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
            },
            menu: { value: this.menuProvider(this.busy) },
          },
        })
        .onBackPressed((): boolean => { vibration.backVibration(); return false; })
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .transition(pageTransition(2))
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])

    }
}
