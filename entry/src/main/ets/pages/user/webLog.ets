import { userWeb } from '../../component/userWeb'

@Component
struct webLog {
    @Consume('pageStack') pageStack: NavPathStack;
    build() {
        NavDestination(){
            Column() { userWeb({ url: "https://hmos.txit.top/changelog", title: 'Web更新日志' }) }.width('100%').height('100%')
        }
    }
}
@Builder
export function WebLogBuilder(){
    webLog()
}