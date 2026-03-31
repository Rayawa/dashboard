import { curves } from '@kit.ArkUI';
import { vibration } from '../common/vibration';

@Component
export struct blurPopup {
  @Link isShow: boolean;
  @BuilderParam content: () => void;

  @StorageLink("vibrationON") vibrationON: boolean = true;
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibration.dotVibration()
    }
  }

  private effect: TransitionEffect = TransitionEffect.OPACITY.combine(
    TransitionEffect.move(TransitionEdge.BOTTOM),
  )
    .combine(TransitionEffect.scale({ x: 0, y: 1 }))
    .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

  build() {
    if (this.isShow) {
      Column() {
        Blank().height(60).onClick(() => { this.triggerVibration(); this.isShow = false })
        this.content()
        Blank().height(15).onClick(() => { this.triggerVibration(); this.isShow = false })
        Text("* 点击外部区域或向下滑动关闭页面")
          .fontSize(14)
          .fontColor(Color.Grey)
          .hitTestBehavior(HitTestMode.None)
          .onClick(() => { this.triggerVibration(); this.isShow = false })
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .transition(this.effect)
      .gesture(
        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(() => {
          this.triggerVibration(); this.isShow = false;
        })
      )
    }
  }
}