import {V1} from '../pages/V1'
import {V2} from '../pages/V2'
@Extend(Text)
function barStyle(color:Color){
  .backgroundColor(color).width('100%').height('100%').fontColor(Color.White)
  .fontSize(50).textAlign(TextAlign.Center)
}
@Entry
@Component
struct tab {
  @State currentIndex: number = 0;
  private tabsController: TabsController = new TabsController();

  @Builder
  TabBuilder(title: string, index: number, selectedImg: Resource, normalImg: Resource) {
    Column() {
      Image(this.currentIndex === index ? selectedImg : normalImg).width(25).height(25)
      Text(title).margin({ top: 4 }).fontSize(10)
        .fontColor(this.currentIndex === index ? "#1698CE" : "#6B6B6B")
    }
    .justifyContent(FlexAlign.Center)
    .height(56).width('100%')
    .onClick(() => {
      this.currentIndex = index;
      this.tabsController.changeIndex(this.currentIndex);
    })
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      controller: this.tabsController
    }) {
      TabContent() {V2()}.tabBar(this.TabBuilder('V2', 1, $r('app.media.V2_selected'), $r('app.media.V2')))
      TabContent() {V1()}.tabBar(this.TabBuilder('V1', 0, $r('app.media.V1_selected'), $r('app.media.V1')))
    }
    .width('100%')
    .backgroundColor(Color.White)
    .barHeight(58)
    .barMode(BarMode.Fixed)
    .onChange((index: number) => {
      this.currentIndex = index;
    })
  }
}