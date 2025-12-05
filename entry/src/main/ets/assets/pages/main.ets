import { AppsTableComponent } from '../component/AppsTableComponent'
import { TopDownloadChartComponent, NonHuaweiDownloadChartComponent, ChartsAreaComponent } from  '../component/ChartsAreaComponent'
import { HeaderComponent } from '../component/HeaderComponent'
import { HelpModal, HelpSection } from '../component/ModalComponents'
import { StatsCardsComponent } from '../component/StatsCardsComponent'

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
    Scroll(){ Column() {
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
    .width('100%')
    .padding(16)
    .backgroundColor('#EEF6FE')
  }}
}