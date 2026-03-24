@Entry
@Component
struct loading {
  build() {
    Stack() {
      Column({ space: 12 }) {
        LoadingProgress()
          .width(48)
          .height(48)
          .color($r('app.color.diff_content'))

        Text('正在与数据库建立通信...')
          .fontSize(18)
          .fontColor($r('app.color.diff_content'))
          .margin({ top: 10 })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.backcolor'))
  }
}