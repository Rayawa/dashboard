// HeaderComponent.ets
@Component
export struct HeaderComponent {
  @State lastUpdate: string = '-'
  @State syncStatus: string = ''

  build() {
    Column() {
      // 标题卡片
      Column() {
        Text('华为应用市场看板 数据收集自 AppGallery api 不保证来源的准确性、完整性和真实性 仅供参考')
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1e3a8a')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 12 })

        // 按钮行
        Row() {
          // 刷新按钮
          Button('刷新数据', { type: ButtonType.Normal })
            .backgroundColor('#06b6d4')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // 帮助按钮
          Button('帮助信息', { type: ButtonType.Normal })
            .backgroundColor('#10b981')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // API文档按钮
          Button('API 文档', { type: ButtonType.Normal })
            .backgroundColor('#3b82f6')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // 更新日志按钮
          Button('查看更新日志', { type: ButtonType.Normal })
            .backgroundColor('#ef4444')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // 问题反馈按钮
          Button('问题反馈&交流', { type: ButtonType.Normal })
            .backgroundColor('#8b5cf6')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // 投稿按钮
          Button('投稿', { type: ButtonType.Normal })
            .backgroundColor('#f59e0b')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ right: 8 })

          // 打开v2站按钮
          Button('打开 v2 站', { type: ButtonType.Normal })
            .backgroundColor('#10b981')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        // 状态信息行
        Row() {
          Text(`最后更新: ${this.lastUpdate}`)
            .fontSize(14)
            .fontColor('#6b7280')
            .margin({ right: 16 })

          Text(`同步状态: ${this.syncStatus}`)
            .fontSize(14)
            .fontColor('#6b7280')
        }
        .width('100%')
        .margin({ top: 16 })
        .justifyContent(FlexAlign.End)
      }
      .width('100%')
      .padding(20)
      .backgroundColor('#f8fafc')
      .borderRadius(16)
      .border({ width: 1, color: '#dbeafe' })
      .margin({ bottom: 16 })
    }
  }
}