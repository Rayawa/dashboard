import { AppsTableComponent } from '../component/AppsTableComponent'
import { TopDownloadChartComponent, NonHuaweiDownloadChartComponent, ChartsAreaComponent } from '../component/ChartsAreaComponent'
import { HeaderComponent } from '../component/HeaderComponent'
import { HelpModal, HelpSection } from '../component/ModalComponents'
import { StatsCardsComponent } from '../component/StatsCardsComponent'
import { router } from '@kit.ArkUI'

@Entry
@Component
struct Dashboard {
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

        Column() {
          Column() { Text('\n').fontSize(14) }
          Row() {
            Text('原生API')
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20 })

            Image($r('app.media.arrow_back'))
              .height(28)
              .width(28)
              .margin({ right: 25 })
              .onClick(() => router.back())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .height(55)

          Rect()
            .width('100%')
            .height(0.5)
            .fill($r('app.color.border'))
            .position({ x: 0, y: 87 })

        }
        .backgroundBlurStyle(BlurStyle.Thin)
        .position({ x: 0, y: 0 })
        .width('100%')

      }
      .backgroundColor($r('app.color.backcolor'))
    }
    .width('100%')
    .height('100%')
  }
}