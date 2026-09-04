import {
  ColorMetrics,
  LengthMetrics,
  SegmentButtonV2Items,
  TabSegmentButtonV2,
} from '@kit.ArkUI';

/** 固定在 HdsNavigation 标题栏中的概况/列表切换栏。 */
@Component
export struct HdsTitleBarSegment {
  @Require items: SegmentButtonV2Items;
  @Link selectedIndexes: number[];
  @Prop maxFontScale: number = 2;
  @Prop segmentHeight: number = 48;
  @Prop normalWidth: Length = '100%';
  @Prop experimentalWidth: Length = '100%';
  @Prop experimentalHeight: number = 52;
  onItemClicked?: (index: number) => void;
  @StorageLink('immersiveTextureON') private immersiveTexture: boolean = false;

  private selectedIndex(): number {
    return this.selectedIndexes.length > 0 ? this.selectedIndexes[0] : 0;
  }

  private selectedBackgroundColor(): ColorMetrics {
    try {
      return ColorMetrics.resourceColor($r('sys.color.segment_button_v2_tab_selected_item_background'));
    } catch (error) {
      console.warn('[Dashboard][component/HdsTitleBarSegment][WARN]',
        `读取切换项背景色失败: ${JSON.stringify(error)}`);
      return ColorMetrics.rgba(255, 255, 255, 0.92);
    }
  }

  private buttonBackgroundColor(): ColorMetrics {
    if (this.immersiveTexture) return ColorMetrics.rgba(0, 0, 0, 0);
    try {
      return ColorMetrics.resourceColor($r('app.color.v3_surface_alt'));
    } catch (error) {
      console.warn('[Dashboard][component/HdsTitleBarSegment][WARN]',
        `读取切换栏背景色失败: ${JSON.stringify(error)}`);
      return ColorMetrics.rgba(128, 128, 128, 0.14);
    }
  }

  build() {
    Column() {
      TabSegmentButtonV2({
        items: this.items,
        selectedIndex: this.selectedIndex(),
        $selectedIndex: (index: number): void => {
          this.selectedIndexes = [index];
        },
        onItemClicked: this.onItemClicked,
        itemMaxFontScale: this.maxFontScale,
        itemSelectedBackgroundColor: this.selectedBackgroundColor(),
        itemMinHeight: LengthMetrics.vp(32),
        buttonBackgroundColor: this.buttonBackgroundColor(),
        buttonMinHeight: LengthMetrics.vp(40),
        buttonPadding: LengthMetrics.vp(4),
        enableStateAnimation: true,
      })
    }
    .width(this.normalWidth)
    .height(this.segmentHeight)
    .justifyContent(FlexAlign.Center)
    .padding(4)
    .borderRadius(this.segmentHeight / 2)
    .clip(true)
    .backgroundColor(this.immersiveTexture ? 0x18FFFFFF : Color.Transparent)
    .backgroundBlurStyle(this.immersiveTexture ? BlurStyle.Thin : BlurStyle.NONE)
    .borderWidth(0)
    .shadow({ radius: 0, color: Color.Transparent })
    .accessibilityText(this.selectedIndex() === 0 ?
      '当前显示应用概况，可切换到应用列表' : '当前显示应用列表，可切换到应用概况')
  }
}
