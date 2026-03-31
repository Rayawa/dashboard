@Component
export struct warn {
    build() {
        Column() {
            Text("重要提示")
                .fontSize(24)
                .fontColor(Color.Red)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })
        }
        .width(350)
        .padding({
            top: 20,
            bottom: 20,
            left: 10,
            right: 10,
        })
        .borderRadius(20)
        .backgroundColor($r("app.color.backcolor"))
        .shadow({
            radius: 20,
            color: Color.Gray,
            offsetX: 0,
            offsetY: 4,
        });
    }
}