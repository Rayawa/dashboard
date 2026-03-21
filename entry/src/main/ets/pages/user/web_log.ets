import { arkWeb } from '../../component/arkWeb'

@Entry
@Component
struct web_log {
    build() {
        Column() { arkWeb({ url: "https://hmos.txit.top/changelog", title: 'Web更新日志' }) }.width('100%').height('100%')
    }
}