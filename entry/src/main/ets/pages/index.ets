import { AppsTableComponent } from '../component/index/AppsTableComponent'
import {
  ChartsAreaComponent,
  NonHuaweiDownloadChartComponent,
  TopDownloadChartComponent
} from '../component/index/ChartsAreaComponent'
import { HeaderComponent } from '../component/index/HeaderComponent'
import { StatsCardsComponent } from '../component/index/StatsCardsComponent'

@Entry
@Component
struct Index {
  @State currentPage: number = 1
  @State searchKeyword: string = ''
  @State searchKey: string = 'name'
  @State excludeHuawei: boolean = false
  @State excludeAtomic: boolean = false
  @State searchExact: boolean = false
  @State showHelpModal: boolean = false
  @State showContactModal: boolean = false
  @State showSubmitModal: boolean = false
  @State showChangelogModal: boolean = false

  build() {
    Column(){
      Stack(){
        Scroll(){
          Column() {
            Text('施工中页面')
              .fontSize(30)
              .fontWeight(900)
              .margin({bottom:50})
            HeaderComponent()
            StatsCardsComponent()
            TopDownloadChartComponent()
            ChartsAreaComponent()
            NonHuaweiDownloadChartComponent()
            AppsTableComponent({
              currentPage: this.currentPage,
              searchKeyword: this.searchKeyword,
              searchKey: this.searchKey,
              excludeHuawei: this.excludeHuawei,
              excludeAtomic: this.excludeAtomic,
              searchExact: this.searchExact
            })
          }
          .margin({top:100,bottom:20})
          .alignItems(HorizontalAlign.Center)
          .width('100%')
          .padding(16)
        }
        .width('100%')
        .height('100%')


      }
      .backgroundColor($r('app.color.backcolor'))
    }
    .width('100%')
    .height('100%')
  }
}