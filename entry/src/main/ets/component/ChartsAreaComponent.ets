@Component
export struct TopDownloadChartComponent {
  build() {
    Column() {
      Row() {
        Text('总下载榜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1e40af')
      }
      .width('100%')
      .padding(16)
      .border({ width: 1, color: '#dbeafe' })
      .borderRadius(16)
      .backgroundColor('#f0f9ff')

      // 图表容器
      Column() {
        //图表组件
        Text('图表区域 - 总下载榜')
          .fontSize(16)
          .fontColor('#374151')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(300)
      .padding(8)
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
}

@Component
export struct ChartsAreaComponent {
  build() {
    Grid() {
      GridItem() {
        ChartCardComponent({
          title: '总应用评分分布',
          bgColor: '#faf5ff',
          textColor: '#6d28d9'
        })
      }

      GridItem() {
        ChartCardComponent({
          title: '应用目标sdk分布',
          bgColor: '#faf5ff',
          textColor: '#6d28d9'
        })
      }

      GridItem() {
        ChartCardComponent({
          title: '应用最小sdk分布',
          bgColor: '#faf5ff',
          textColor: '#6d28d9'
        })
      }
    }
    .columnsTemplate('1fr 1fr 1fr')
    .rowsTemplate('1fr')
    .columnsGap(16)
    .rowsGap(16)
    .margin({ bottom: 16 })
  }
}

@Component
export struct NonHuaweiDownloadChartComponent {
  build() {
    Column() {
      Row() {
        Text('非华为应用/内置应用下载榜')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#0f766e')
      }
      .width('100%')
      .padding(16)
      .border({ width: 1, color: '#a7f3d0' })
      .borderRadius(16)
      .backgroundColor('#f0fdfa')

      // 图表容器
      Column() {
        Text('图表区域 - 非华为应用下载榜')
          .fontSize(16)
          .fontColor('#374151')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(300)
      .padding(8)
      .backgroundColor(Color.White)
      .borderRadius(8)
    }
    .width('100%')
    .margin({ bottom: 16 })
  }
}

@Component
struct ChartCardComponent {
  @Prop title: string = '';
  @Prop bgColor: string = '#ffffff';
  @Prop textColor: string = '#000000';

  build() {
    Column() {
      Row() {
        Text(this.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.textColor)
      }
      .width('100%')
      .padding(16)
      .border({ width: 1, color: '#e9d5ff' })
      .backgroundColor(this.bgColor)

      // 图表内容
      Column() {
        Text('图表内容')
          .fontSize(14)
          .fontColor('#6b7280')
          .textAlign(TextAlign.Center)
      }
      .width('100%')
      .height(200)
      .padding(8)
      .backgroundColor(Color.White)
    }
    .borderRadius(16)
    .shadow({ radius: 4, color: '#000000', offsetX: 1, offsetY: 1 })
  }
}