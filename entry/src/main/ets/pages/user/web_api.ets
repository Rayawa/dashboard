import { userWeb } from '../../component/userWeb'

@Entry
@Component
struct web_api {
    build() {
        Column() { userWeb({ url: 'http://shenjack.top:10003/docsm', title: 'API文档说明' }) }.width('100%').height('100%')
    }
}