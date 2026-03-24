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
          .fontSize(20)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.backcolor'))
  }
}