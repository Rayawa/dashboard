import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct AG {
  build() {
    Column() {
      arkWeb({
        url: 'https://appgallery.info/index.html',
        title: 'AppGallery 统计数据'
      }) }.width('100%').height('100%')
  }
}