import { PromptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { vibration } from '../common/vibration';

@Component
export struct contact {
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("vibrationON") vibrationON: boolean = true;

    @Builder ContactItem(title: string, name: string, detail: string, copyContent: string, toastLabel: string) {
        Column({ space: 4 }) {
            Text(title).fontSize(17).fontWeight(FontWeight.Bold)
            Text(name).fontSize(14).fontColor($r("app.color.diff_content"))
            Text(detail).fontSize(13).fontColor(Color.Gray).opacity(0.8)
        }
        .alignItems(HorizontalAlign.Center)
        .width("93%")
        .backgroundColor($r("app.color.background"))
        .padding(14)
        .borderRadius(16)
        .onClick(async () => {
            if(this.vibrationON) vibration.dotVibration()
            await this.copyToClipboard(copyContent, toastLabel);
        })
    }

    build() {
        Column({ space: 10 }) {
            this.ContactItem("👥 主要负责人", "shenjack", "邮箱：3695888@qq.com", "3695888@qq.com", "邮箱")
            this.ContactItem("🌐 T站网页负责人", "tianxiu2b2t", "邮箱：administrator@ttb-network.top", "administrator@ttb-network.top", "邮箱")
            this.ContactItem("📱 鸿蒙应用开发", "清霁·Rayawa", "邮箱：rayawa.work@outlook.com", "rayawa.work@outlook.com", "邮箱")
            this.ContactItem("💬 QQ群", "Harmony Dashboard官方交流群", "群号：757273833", "757273833", "群号")

            Column({ space: 4 }) {
                Text("❤️ 赞助我们").fontSize(17).fontWeight(FontWeight.Bold)
                Text("支持项目发展").fontSize(14).fontColor($r("app.color.diff_content"))
                Text("点击跳转到爱发电赞助页面").fontSize(13).fontColor(Color.Gray).opacity(0.8)
            }
            .alignItems(HorizontalAlign.Center)
            .width("93%")
            .backgroundColor($r("app.color.background"))
            .padding(14)
            .borderRadius(16)
            .onClick(async () => {
                if(this.vibrationON) vibration.dotVibration()
                const url = "https://afdian.com/a/shenjack";
                const ui_content = this.getUIContext();
                try {
                    let context = ui_content.getHostContext() as common.UIAbilityContext;
                    await context.startAbility({
                        action: "ohos.want.action.viewData",
                        entities: ["entity.system.browsable"],
                        uri: url,
                    } as Want);
                } catch (e) {
                    this.PromptAction.showToast({ message: "跳转失败" });
                }
            })


        }.width("100%").padding(5).margin({ bottom: 20 })
    }

    async copyToClipboard(text: string, label: string): Promise<void> {
        try {
            let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
            await pasteboard.getSystemPasteboard().setData(pasteData);
            this.PromptAction.showToast({ message: `已复制${label}`, duration: 2000 });
        } catch (error) {
            this.PromptAction.showToast({ message: "复制失败" });
        }
    }
}