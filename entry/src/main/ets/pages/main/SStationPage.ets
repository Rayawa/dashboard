import { webview } from '@kit.ArkWeb';
import { customUserAgent, SBaseURL } from '../../common/constants';
import { vibration } from '../../common/vibration';

@Component
export struct SStationPage {
    private controller: webview.WebviewController = new webview.WebviewController();
    @State private progress: number = 0;
    @State private loading: boolean = true;
    @State private errorMessage: string = '';
    @StorageLink('vibrationON') private vibrationEnabled: boolean = true;

    build() {
        Stack({ alignContent: Alignment.Top }) {
            Web({
                src: SBaseURL.toString(),
                controller: this.controller,
            })
                .width('100%')
                .height('100%')
                .backgroundColor($r('app.color.backcolor'))
                .domStorageAccess(true)
                .darkMode(WebDarkMode.Auto)
                .forceDarkAccess(true)
                .onControllerAttached(() => {
                    try {
                        this.controller.setCustomUserAgent(customUserAgent);
                    } catch (error) {
                        console.warn('[Dashboard][pages/main/SStationPage][WARN]', `设置 User-Agent 失败: ${JSON.stringify(error)}`);
                    }
                })
                .onPageBegin(() => {
                    this.loading = true;
                    this.errorMessage = '';
                })
                .onPageEnd(() => {
                    this.loading = false;
                })
                .onErrorReceive(() => {
                    this.loading = false;
                    this.errorMessage = '网页加载失败，请检查网络连接后重试';
                })
                .onProgressChange((event) => {
                    this.progress = event.newProgress;
                })
                .accessibilityText('S站网页内容')

            if (this.loading) {
                Progress({ value: this.progress, total: 100 })
                    .width('100%')
                    .height(4)
                    .color($r('app.color.v3_accent_blue'))
                    .accessibilityText(`S站加载进度百分之${this.progress}`)
            }

            if (this.errorMessage !== '') {
                Column({ space: 12 }) {
                    Text('S站暂时无法连接')
                        .fontSize(18)
                        .fontWeight(FontWeight.Bold)
                        .fontColor($r('app.color.v3_text_primary'))
                        .accessibilityText('S站暂时无法连接')
                    Text(this.errorMessage)
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .textAlign(TextAlign.Center)
                        .accessibilityText(this.errorMessage)
                    Button('重新加载')
                        .backgroundColor($r('app.color.v3_accent_blue'))
                        .onClick(() => {
                            if (this.vibrationEnabled) vibration.dotVibration();
                            this.errorMessage = '';
                            this.controller.refresh();
                        })
                        .accessibilityText('重新加载S站')
                }
                .padding(24)
                .borderRadius(20)
                .backgroundColor($r('app.color.v3_surface'))
                .position({ x: '10%', y: '35%' })
                .width('80%')
                .accessibilityGroup(true)
                .accessibilityText('S站网络错误提示')
            }
        }
        .width('100%')
        .height('100%')
        .backgroundColor($r('app.color.backcolor'))
        .accessibilityGroup(true)
        .accessibilityText('S站页面')
    }
}
