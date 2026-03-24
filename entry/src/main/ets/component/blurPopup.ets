import { curves } from "@kit.ArkUI";

@Component
export struct blurPopup {
  @Link isShow: boolean;
  @BuilderParam content: () => void;
  private title: string = "* 点击外部区域或向下滑动关闭页面";
  private effect: TransitionEffect = TransitionEffect.OPACITY.combine(
    TransitionEffect.move(TransitionEdge.BOTTOM),
  )
    .combine(TransitionEffect.scale({ x: 0, y: 1 }))
    .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

  build() {
    if (this.isShow) {
      Stack({ alignContent: Alignment.Top }) {
        Column()
          .width('300%')
          .height('300%')
          .backgroundColor(Color.Transparent)
          .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
          .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
          .onClick(() => {
            this.isShow = false;
          })

        Column() {
          Blank().height(70)
          this.content()
          Blank().height(15)
          Text(this.title)
            .fontSize(14)
            .fontColor(Color.Grey)
            .hitTestBehavior(HitTestMode.None)
        }
        .width('100%')
        .height('100%')
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
      .transition(this.effect)
      .gesture(
        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(() => {
          this.isShow = false;
        })
      )
    }
  }
}