import { deviceInfo } from '@kit.BasicServicesKit';
import { hdsEffect, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';
import { curves } from '@kit.ArkUI';

/**
 * 基于 HdsTabs 迷你栏材质的通用按钮承载层。
 * 保留独立组件，方便后续重新接入智感握持位置策略。
 */
@Component
export struct HdsMiniBarButton {
  @Prop barWidth: number = 240;
  @Prop barHeight: number = 52;
  @StorageLink('immersiveMaterialLevel') materialLevel: number = 2;
  @Prop materialType: number = 100;
  @BuilderParam buttonContent: () => void = this.defaultContent;
  public onButtonClick: (() => void) | undefined = undefined;
  private controller: HdsTabsController = new HdsTabsController();
  @State private pressed: boolean = false;

  @Builder
  private defaultContent(): void {
    Blank()
  }

  @Builder
  private miniBarContent(): void {
    Stack({ alignContent: Alignment.Center }) {
      this.buttonContent()
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.barHeight / 2)
    .clip(true)
    .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(new hdsEffect.HdsEffectBuilder()
      .pointLight({
        sourceType: hdsEffect.PointLightSourceType.BRIGHT,
        illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
        options: { color: $r('app.color.diff_content'), intensity: 6, height: 96 },
      })
      .buildEffect())
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
      }
    })
    .onClick(() => {
      if (this.onButtonClick) {
        this.onButtonClick();
      }
    })
    .accessibilityText('切换应用概况和应用列表')
  }

  build() {
    Column() {
      if (deviceInfo.distributionOSApiVersion >= 60100) {
        HdsTabs({ controller: this.controller }) {
          TabContent()
            .backgroundColor(Color.Transparent)
        }
        .height(this.barHeight - 12)
        .barWidth(this.barWidth)
        .barHeight(this.barHeight - 12)
        .barOverlap(true)
        .barPosition(BarPosition.End)
        .backgroundColor(Color.Transparent)
        .barFloatingStyle({
          barWidth: {
            smallWidth: this.barWidth,
            mediumWidth: this.barWidth,
            largeWidth: this.barWidth,
          },
          gradientMask: { maskColor: Color.Transparent },
          barBottomMargin: 0,
          barSideMargin: 0,
          lightColor: $r('app.color.light_color'),
          systemMaterialEffect: {
            materialType: this.materialType,
            materialLevel: this.materialLevel,
          },
          miniBar: {
            miniBarBuilder: () => {
              this.miniBarContent()
            },
            miniBarStyle: 1,
          },
        })
      } else {
        Row() {
          this.miniBarContent()
        }
        .width(this.barWidth)
        .height(this.barHeight - 12)
        .borderRadius(this.barHeight / 2)
        .backgroundColor($r('app.color.v3_surface'))
      }
    }
    .width(this.barWidth)
    .height(this.barHeight)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent)
    .accessibilityText('应用概况和应用列表分段控件')
  }
}
