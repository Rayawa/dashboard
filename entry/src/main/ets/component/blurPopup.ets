import { curves } from "@kit.ArkUI";

@Component
export struct blurPopup {
  @Link isShow: boolean;
  @BuilderParam content: () => void;
  private title: string = "* 点击外部区域或向下滑动关闭页面";

  // 保持原有的过渡动画
  private effect: TransitionEffect = TransitionEffect.OPACITY.combine(
    TransitionEffect.move(TransitionEdge.BOTTOM),
  )
    .combine(TransitionEffect.scale({ x: 0, y: 1 }))
    .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

  build() {
    if (this.isShow) {
      Column() {
        Blank().height(60)
        this.content()
        Blank().height(15)
        Text(this.title)
          .fontSize(14)
          .fontColor(Color.Grey)
          .hitTestBehavior(HitTestMode.None)
      }
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .transition(this.effect)
      .gesture(
        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(() => {
          this.isShow = false;
        })
      )
    }
  }
}