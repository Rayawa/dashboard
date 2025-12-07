// StatsCardsComponent.ets
@Component
export struct StatsCardsComponent {
  @State totalCount: number = 0
  @State appCount: number = 0
  @State atomicServiceCount: number = 0
  @State developerCount: number = 0
  @State substanceCount: number = 0

  build() {
    Grid() {
      // 已爬取总数卡片
      GridItem() {
        StatCardComponent({
          title: '已爬取总数',
          value: this.totalCount.toString(),
          bgColor: '#fdf2f8',
          textColor: '#be185d'
        })
      }

      // 应用总数卡片
      GridItem() {
        StatCardComponent({
          title: '应用总数',
          value: this.appCount.toString(),
          bgColor: '#fff7ed',
          textColor: '#d97706'
        })
      }

      // 元服务总数卡片
      GridItem() {
        StatCardComponent({
          title: '元服务总数',
          value: this.atomicServiceCount.toString(),
          bgColor: '#f0fdf4',
          textColor: '#047857'
        })
      }

      // 开发者总数卡片
      GridItem() {
        StatCardComponent({
          title: '开发者总数',
          value: this.developerCount.toString(),
          bgColor: '#faf5ff',
          textColor: '#3730a3'
        })
      }

      // 已知专题数量卡片
      GridItem() {
        StatCardComponent({
          title: '已知专题数量',
          value: this.substanceCount.toString(),
          bgColor: '#faf5ff',
          textColor: '#7c3aed'
        })
      }
    }
    .columnsTemplate('1fr 1fr 1fr 1fr 1fr')
    .rowsTemplate('1fr')
    .columnsGap(16)
    .rowsGap(16)
    .margin({ bottom: 16 })
  }
}

@Component
export struct StatCardComponent {
  @Prop title: string = ''
  @Prop value: string = ''
  @Prop bgColor: string = '#ffffff'
  @Prop textColor: string = '#000000'

  build() {
    Column() {
      Text(this.title)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.textColor)
        .margin({ bottom: 8 })

      Text(this.value)
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.textColor)
    }
    .width('100%')
    .height(120)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.bgColor)
    .borderRadius(16)
    .shadow({ radius: 8, color: '#000000', offsetX: 2, offsetY: 2 })
  }
}