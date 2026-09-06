import {
  ColorMetrics,
  LengthMetrics,
  SegmentButtonV2Items,
  TabSegmentButtonV2,
} from '@kit.ArkUI';
import { HdsMiniBarButton } from './HdsMiniBarButton';

/** 固定在 HdsNavigation 标题栏中的概况/总表切换栏。 */
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
  @State private measuredWidth: number = 0;

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

  private materialSelectedBackgroundColor(): ColorMetrics {
    try {
      return ColorMetrics.resourceColor($r('app.color.segmented_color_selected'));
    } catch (error) {
      console.warn('[Dashboard][component/HdsTitleBarSegment][WARN]',
        `读取材质切换项背景色失败: ${JSON.stringify(error)}`);
      return ColorMetrics.rgba(102, 102, 102, 0.13);
    }
  }

  @Builder
  private segmentContent(): void {
    Column() {
      TabSegmentButtonV2({
        items: this.items,
        selectedIndex: this.selectedIndex(),
        $selectedIndex: (index: number): void => {
          this.selectedIndexes = [index];
        },
        onItemClicked: this.onItemClicked,
        itemMaxFontScale: this.maxFontScale,
        itemSelectedBackgroundColor: this.materialSelectedBackgroundColor(),
        itemMinHeight: LengthMetrics.vp(32),
        buttonBackgroundColor: ColorMetrics.rgba(0, 0, 0, 0),
        buttonMinHeight: LengthMetrics.vp(40),
        buttonPadding: LengthMetrics.vp(4),
        enableStateAnimation: true,
      })
    }
    .width('100%')
    .height(this.segmentHeight)
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Stack({ alignContent: Alignment.Center }) {
      if (this.measuredWidth > 0) {
        HdsMiniBarButton({
          barWidth: this.measuredWidth,
          barHeight: this.experimentalHeight,
        }) {
          this.segmentContent()
        }
      }
    }
    .width(this.experimentalWidth)
    .height(this.experimentalHeight)
    .onAreaChange((_, area) => {
      if (typeof area.width === 'number' && area.width > 0 && this.measuredWidth !== area.width) {
        this.measuredWidth = area.width;
      }
    })
    .margin({ top: -8 })
    .accessibilityText(this.selectedIndex() === 0 ?
      '当前显示概况，可切换到总表' : '当前显示总表，可切换到概况')
  }
}
