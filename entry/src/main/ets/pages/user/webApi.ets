import { aboutWeb } from '../../component/aboutWeb';

@Component
struct webApi {
  build() {
    Column() { aboutWeb({ url: 'http://shenjack.top:10003/docs', title: 'API文档说明' }) }.width('100%').height('100%')
  }
}

@Builder
export function WebApiBuilder(){
  webApi()
}