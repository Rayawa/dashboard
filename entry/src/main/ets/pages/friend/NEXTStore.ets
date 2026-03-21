import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct NEXTStore {
  build() {
    Column() {
      arkWeb({
        url: 'https://next.vcck.cn/#/',
        title: 'NEXT Store'
      }) }.width('100%').height('100%')
  }
}