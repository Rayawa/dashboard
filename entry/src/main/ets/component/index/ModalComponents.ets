
@Component
export struct HelpModal {
  @Link isVisible: boolean

  build() {
    if (this.isVisible) {
      Column() {
        // 模态框内容
        Column() {
          // 标题栏
          Row() {
            Text('帮助信息 - 华为应用市场看板使用说明')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1e1b4b')

            Button('×', { type: ButtonType.Normal })
              .backgroundColor(Color.Transparent)
              .fontColor('#6366f1')
              .fontSize(20)
              .onClick(() => {
                this.isVisible = false
              })
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .padding(16)
          .backgroundColor('#e0e7ff')
          .borderRadius(12)

          // 帮助内容
          Scroll() {
            Column() {
              // 数据来源说明
              HelpSection({
                title: '📊 数据来源说明',
                content: '本看板数据收集自华为应用市场（AppGallery）公开API，数据仅供参考，不保证来源的准确性、完整性和真实性。',
                bgColor: '#dbeafe',
                textColor: '#1e40af'
              })

              // 主要功能
              HelpSection({
                title: '🚀 主要功能',
                content: '• 数据概览 - 显示已爬取总数、应用总数、元服务总数、开发者总数\n• 总下载榜 - 展示应用下载量排行榜\n• 评分分布 - 显示应用评分的分布情况\n• 非华为应用下载榜 - 展示非华为应用和内置应用的下载排行\n• 应用列表 - 详细的应用信息表格，支持搜索、排序和快速筛选',
                bgColor: '#d1fae5',
                textColor: '#047857'
              })

              // 使用说明
              HelpSection({
                title: '📝 使用说明',
                content: '• 刷新数据 - 点击"刷新数据"按钮获取最新数据\n• 搜索应用 - 在应用列表上方的搜索框中输入关键词\n• 快速筛选 - 点击开发者名称可快速搜索该开发者的所有应用\n• 排序功能 - 点击表格标题进行排序\n• 查看详情 - 点击应用行查看详细的应用信息',
                bgColor: '#fef3c7',
                textColor: '#92400e'
              })

              // 注意事项
              HelpSection({
                title: '⚠️ 注意事项',
                content: '• 部分功能仍在开发中，可能会出现bug或数据不完整的情况\n• 数据更新可能存在延迟，请以官方数据为准\n• 应用详情页面仍在施工中，部分数据可能显示不正确',
                bgColor: '#fecdd3',
                textColor: '#be123c'
              })
            }
            .width('100%')
            .padding(16)
          }
          .layoutWeight(1)

          // 底部按钮
          Button('关闭', { type: ButtonType.Normal })
            .backgroundColor('#4f46e5')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(16)
            .margin({ top: 16 })
            .onClick(() => {
              this.isVisible = false
            })
        }
        .width('90%')
        .height('80%')
        .backgroundColor(Color.White)
        .borderRadius(16)
        .shadow({ radius: 20, color: '#000000', offsetX: 0, offsetY: 0 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor('#00000080') // 半透明背景
    }
  }
}

@Component
export struct HelpSection {
  @Prop title: string = ''
  @Prop content: string = ''
  @Prop bgColor: string = '#ffffff'
  @Prop textColor: string = '#000000'

  build() {
    Column() {
      Text(this.title)
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
        .margin({ bottom: 8 })

      Text(this.content)
        .fontSize(14)
        .fontColor(this.textColor)
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(16)
    .backgroundColor(this.bgColor)
    .borderRadius(12)
    .margin({ bottom: 16 })
  }
}