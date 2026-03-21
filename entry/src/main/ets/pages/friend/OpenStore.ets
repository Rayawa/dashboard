import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct OpenStore {
  build() {
    Column() {
      arkWeb({
        url: 'https://next.betahub.tech/',
        title: 'Open Store'
      }) }.width('100%').height('100%')
  }
}