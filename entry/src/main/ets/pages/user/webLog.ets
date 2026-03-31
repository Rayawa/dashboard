import { aboutWeb } from '../../component/aboutWeb';

@Component
struct webLog {
  build() {
    Column() { aboutWeb({ url: "https://hmos.txit.top/changelog", title: 'Web更新日志' }) }.width('100%').height('100%')
  }
}
@Builder
export function WebLogBuilder(){
  webLog()
}