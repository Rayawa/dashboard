import { userWeb } from '../../component/userWeb';

@Component
struct webLog {
  build() {
    Column() { userWeb({ url: "https://hmos.txit.top/changelog", title: 'Web更新日志' }) }.width('100%').height('100%')

  }
}
@Builder
export function WebLogBuilder(){
  webLog()
}