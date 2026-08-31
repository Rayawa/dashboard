import {
  ColorMetrics,
  LengthMetrics,
  SegmentButtonV2Items,
  TabSegmentButtonV2,
} from '@kit.ArkUI';
import { HdsMiniBarButton } from './HdsMiniBarButton';

/** 应用详情主标签中的悬浮二选一切换栏。 */
@Component
export struct HdsTitleBarSegment {
  @Require items: SegmentButtonV2Items;
  @Link selectedIndexes: number[];
  @Prop maxFontScale: number = 2;
  @Prop segmentHeight: number = 48;
  @Prop barWidth: number = 280;
  onItemClicked?: (index: number) => void;

  private selectedIndex(): number {
    return this.selectedIndexes.length > 0 ? this.selectedIndexes[0] : 0;
  }

  private selectedBackgroundColor(): ColorMetrics {
    try {
      return ColorMetrics.resourceColor($r('app.color.diff_content'));
    } catch (error) {
      console.warn('[Dashboard][component/HdsTitleBarSegment][WARN]',
        `无法读取切换栏高亮色，使用内置回退颜色: ${JSON.stringify(error)}`);
      return ColorMetrics.rgba(30, 111, 205);
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
        itemSelectedBackgroundColor: this.selectedBackgroundColor(),
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
    Column() {
      HdsMiniBarButton({
        barWidth: this.barWidth,
        barHeight: this.segmentHeight + 4,
      }) {
        this.segmentContent()
      }
    }
    .accessibilityText(this.selectedIndex() === 0 ? '当前显示应用概况，可切换到应用列表' : '当前显示应用列表，可切换到应用概况')
  }
}
