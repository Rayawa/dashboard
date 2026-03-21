import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct dztap {
  build() {
    Column() {
      arkWeb({
        url: 'https://dztap.com/app.htmlm',
        title: '小刘的站点'
      }) }.width('100%').height('100%')
  }
}