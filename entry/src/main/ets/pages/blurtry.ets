interface WebOnScrollEvent {
  xOffset: number;
  yOffset: number;
}

@Entry
@Component
export struct blurTry {
  @State showBlur: boolean = false;
  private webController: WebController = new WebController();

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Web({ src: 'http://shenjack.top:10003/dashboard', controller: this.webController })
        .onScroll((event: WebOnScrollEvent) => {
          const scrollY = event.yOffset;
          this.showBlur = scrollY > 40;
        })
        .height('100%')
        .width('100%');

      if (this.showBlur) {
        Rect()
          .height(40)
          .width("100%")
          .backgroundColor(Color.White)
          .opacity(0.15)
          .blur(20)
          .position({ x: 0, y: 0 });
      }
    }
    .height('100%')
    .width('100%');
  }
}
