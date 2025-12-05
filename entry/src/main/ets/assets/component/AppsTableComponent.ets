// AppsTableComponent.ets
@Component
export struct AppsTableComponent {
  currentPage: number = 1
  searchKeyword: string = ''
  searchKey: string = 'name'
  excludeHuawei: boolean = false
  excludeAtomic: boolean = false
  searchExact: boolean = false

  @State appList: Array<AppItem> = []
  @State isLoading: boolean = true

  build() {
    Column() {
      // 标题和搜索区域
      Column() {
        Row() {
          Text('应用列表 (施工中, 功能可能出现 bug)')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor('#92400e')
        }
        .width('100%')
        .margin({ bottom: 16 })

        // 搜索行
        Row() {
          TextInput({ placeholder: '搜索应用' })
            .width('60%')
            .height(40)
            .padding(8)
            .backgroundColor('#fef3c7')
            .border({ width: 1, color: '#fbbf24' })
            .borderRadius(12)
            .margin({ right: 8 })

          // Picker({ range: ['应用名称', '包名', '应用描述', '应用 ID', '开发者名称', '开发者英文名称', '供应商', '类型名', '标签名', '应用分类', '最小api', '目标api'] })
          //   .width(120)
          //   .height(40)
          //   .margin({ right: 8 })

          Button('搜索', { type: ButtonType.Normal })
            .backgroundColor('#f59e0b')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(8)
        }
        .width('100%')
        .margin({ bottom: 8 })

        // 操作按钮行
        Row() {
          Button('清除搜索', { type: ButtonType.Normal })
            .backgroundColor('#6b7280')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(8)
            .margin({ right: 8 })

          Button('搜索功能帮助', { type: ButtonType.Normal })
            .backgroundColor('#f59e0b')
            .fontColor(Color.White)
            .borderRadius(12)
            .padding(8)
            .margin({ right: 8 })

          Toggle({ type: ToggleType.Checkbox, isOn: false })
            .margin({ right: 4 })
          Text('忽略华为')
            .fontSize(14)
            .fontColor('#92400e')
            .margin({ right: 16 })

          Toggle({ type: ToggleType.Checkbox, isOn: false })
            .margin({ right: 4 })
          Text('忽略元服务')
            .fontSize(14)
            .fontColor('#92400e')
            .margin({ right: 16 })

          Toggle({ type: ToggleType.Checkbox, isOn: false })
            .margin({ right: 4 })
          Text('精确匹配')
            .fontSize(14)
            .fontColor('#92400e')
        }
        .width('100%')
      }
      .width('100%')
      .padding(24)
      .backgroundColor('#fef3c7')
      .borderRadius(16)
      .margin({ bottom: 16 })

      // 表格区域
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
            .color('#f59e0b')
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        List() {
          ForEach(this.appList, (item: AppItem) => {
            ListItem() {
              AppTableRow({ appData: item })
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      }

      // 分页组件
      PaginationComponent()
    }
    .width('100%')
    .padding(24)
    .backgroundColor('#fef3c7')
    .borderRadius(16)
    .shadow({ radius: 8, color: '#000000', offsetX: 2, offsetY: 2 })
  }
}

@Component
export struct AppTableRow {
  appData: AppItem = new AppItem()

  build() {
    Row() {
      // 序号
      Text(this.appData.index.toString())
        .width('10%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 应用名称
      Text(this.appData.name)
        .width('20%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 开发者
      Text(this.appData.developer)
        .width('15%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 分类
      Text(this.appData.category)
        .width('15%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 评分
      Text(this.appData.rating.toString())
        .width('10%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 评分数量
      Text(this.appData.ratingCount.toString())
        .width('10%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 下载量
      Text(this.appData.downloadCount.toString())
        .width('10%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)

      // 大小
      Text(this.appData.size)
        .width('10%')
        .fontSize(14)
        .fontColor('#92400e')
        .textAlign(TextAlign.Start)
    }
    .width('100%')
    .padding(12)
    .border({ width: 1, color: '#fbbf24' })
    .backgroundColor('#fef3c7')
  }
}

@Component
struct PaginationComponent {
  @State currentPage: number = 1
  @State totalPages: number = 10

  build() {
    Row() {
      Button('上一页', { type: ButtonType.Normal })
        .backgroundColor('#f59e0b')
        .fontColor(Color.White)
        .borderRadius(8)
        .padding(8)
        .margin({ right: 8 })
        .enabled(this.currentPage > 1)

      Text(`第 ${this.currentPage} 页 / 共 ${this.totalPages} 页`)
        .fontSize(14)
        .fontColor('#92400e')
        .margin({ right: 8 })

      Button('下一页', { type: ButtonType.Normal })
        .backgroundColor('#f59e0b')
        .fontColor(Color.White)
        .borderRadius(8)
        .padding(8)
        .enabled(this.currentPage < this.totalPages)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: 16 })
  }
}

class AppItem {
  index: number = 0
  name: string = ''
  developer: string = ''
  category: string = ''
  rating: number = 0
  ratingCount: number = 0
  downloadCount: number = 0
  size: string = ''
}