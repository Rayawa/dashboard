// NotFoundContent.ets
import router from '@ohos.router';
@Component
export struct NotFoundContent {
  build() {
    Column() {
      // 404数字
      Text('404')
        .fontSize(144)
        .fontWeight(FontWeight.Bold)
        .fontColor('#e5e7eb')
        .margin({ bottom: 16 })

      // 标题
      Text('页面未找到')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1f2937')
        .margin({ bottom: 8 })

      // 描述信息
      Text('抱歉，您访问的页面不存在。可能路径有误，或者页面已被移除。')
        .fontSize(16)
        .fontColor('#6b7280')
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 32 })
        .padding({ left: 40, right: 40 })

      // 返回按钮
      Button('返回仪表板', { type: ButtonType.Normal })
        .backgroundColor('#2563eb')
        .fontColor(Color.White)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .borderRadius(12)
        .padding({
          left: 24,
          right: 24,
          top: 12,
          bottom: 12
        })
        .onClick(() => {
          // 这里添加导航回仪表板的逻辑
          router.back()
        })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}