import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct Hap {
  build() {
    Column() {
      arkWeb({
        url: 'https://hdc.osbdf.com/',
        title: 'HAP 资源站'
      }) }.width('100%').height('100%')
  }
}