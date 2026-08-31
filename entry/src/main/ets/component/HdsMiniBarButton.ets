import { deviceInfo } from '@kit.BasicServicesKit';
import { hdsEffect, HdsTabs, HdsTabsController } from '@kit.UIDesignKit';

/**
 * 基于 HdsTabs 迷你栏材质的通用按钮承载层。
 * 保留独立组件，方便后续重新接入智感握持位置策略。
 */
@Component
export struct HdsMiniBarButton {
  @Prop barWidth: number = 240;
  @Prop barHeight: number = 52;
  @Prop materialLevel: number = 10;
  @Prop materialType: number = 100;
  @BuilderParam buttonContent: () => void = this.defaultContent;
  public onButtonClick: (() => void) | undefined = undefined;
  private controller: HdsTabsController = new HdsTabsController();
  @State private pressed: boolean = false;
  @State private pointLight: hdsEffect.PointLightSourceType = hdsEffect.PointLightSourceType.NONE;

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
    .scale({ x: this.pressed ? 0.97 : 1, y: this.pressed ? 0.97 : 1 })
    .animation({ curve: Curve.EaseOut, duration: 150 })
    .visualEffect(new hdsEffect.HdsEffectBuilder()
      .pointLight({
        sourceType: this.pointLight,
        illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
        options: {
          color: $r('app.color.diff_content'),
          intensity: 10,
          height: 150,
        },
      })
      .buildEffect())
    .onTouch((event: TouchEvent) => {
      if (event.type === TouchType.Down) {
        this.pressed = true;
        this.pointLight = hdsEffect.PointLightSourceType.BRIGHT;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.pressed = false;
        this.pointLight = hdsEffect.PointLightSourceType.NONE;
      }
    })
    .onClick(() => {
      if (this.onButtonClick) {
        this.onButtonClick();
      }
    })
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
