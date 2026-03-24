import { userWeb } from '../../component/userWeb'

@Entry
@Component
struct webLog {
    build() {
        Column() { userWeb({ url: "https://hmos.txit.top/changelog", title: 'Web更新日志' }) }.width('100%').height('100%')
    }
}