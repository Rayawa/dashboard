import { userWeb } from '../../component/userWeb';

@Component
struct webApi {
    @Consume('pageStack') pageStack: NavPathStack;
    build() {
        NavDestination(){
            Column() { userWeb({ url: 'http://shenjack.top:10003/docs', title: 'API文档说明' }) }.width('100%').height('100%')
        }
    }
}

@Builder
export function WebApiBuilder(){
    webApi()
}