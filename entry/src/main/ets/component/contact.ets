import { PromptAction } from '@kit.ArkUI';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { vibrator } from '@kit.SensorServiceKit';

@Component
export struct contact {
    @StorageLink("vibrationON") vibrationON: boolean = true;
    private triggerVibration(): void {
        if (this.vibrationON) {
            vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
                if (!err && state) {
                    try {
                        vibrator.startVibration(
                            { type: "preset", effectId: "haptic.effect.hard", count: 1, intensity: 50 },
                            { usage: "touch" }
                        );
                    } catch (e) { console.error(e); }
                }
            });
        }
    }

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
            this.triggerVibration();
            await this.copyToClipboard(copyContent, toastLabel);
        })
    }

    build() {
        Column() {
            Text("联系我们")
                .fontSize(24)
                .fontColor($r("app.color.diff_content"))
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

            Column({ space: 10 }) {
                this.ContactItem("👥 主要负责人", "shenjack", "邮箱：3695888@qq.com", "3695888@qq.com", "邮箱")
                this.ContactItem("🌐 T站网页负责人", "tianxiu2b2t", "邮箱：administrator@ttb-network.top", "administrator@ttb-network.top", "邮箱")
                this.ContactItem("📱 鸿蒙应用开发", "清霁·Rayawa", "邮箱：rayawa.work@outlook.com", "rayawa.work@outlook.com", "邮箱")
                this.ContactItem("💬 QQ群", "Harmony Gallery 官方交流群", "群号：757273833", "757273833", "群号")

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
                .onClick(() => {
                    this.triggerVibration();
                    this.openLink();
                })


            }
            .width("100%")
            .margin({ bottom: 20 })

            Column() {
                Divider()
                    .strokeWidth(0.5)
                    .color($r("app.color.border"))
                    .margin({ bottom: 12 })
                    .width("100%")
                Text("我们将尽快回复您的消息")
                    .fontSize(12)
                    .fontColor(Color.Gray)
                    .margin({ bottom: 4 })
                Text("感谢您的支持！")
                    .fontSize(12)
                    .fontColor(Color.Gray)
            }
            .width("100%")
            .margin({ bottom: 20 })
        }
        .width(350)
        .padding({
            top: 20,
            bottom: 20,
            left: 10,
            right: 10,
        })
        .borderRadius(20)
        .backgroundColor($r("app.color.backcolor"))
        .shadow({
            radius: 20,
            color: Color.Gray,
            offsetX: 0,
            offsetY: 4,
        });
    }


    async openLink() {
        const url = "https://afdian.com/a/shenjack";
        const ui_content = this.getUIContext();
        ui_content.showAlertDialog({
            title: "提示",
            message: "即将跳转到爱发电页面",
            primaryButton: { value: "取消", fontColor: Color.Red, action: () => {} },
            secondaryButton: {
                value: "确定",
                fontColor: Color.Blue,
                action: async () => {
                    try {
                        let context = ui_content.getHostContext() as common.UIAbilityContext;
                        await context.startAbility({
                            action: "ohos.want.action.viewData",
                            entities: ["entity.system.browsable"],
                            uri: url,
                        } as Want);
                    } catch (e) {
                        PromptAction.showToast({ message: "跳转失败" });
                    }
                },
            },
        });
    }

    async copyToClipboard(text: string, label: string): Promise<void> {
        try {
            let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
            await pasteboard.getSystemPasteboard().setData(pasteData);
            PromptAction.showToast({ message: `已复制${label}`, duration: 2000 });
        } catch (error) {
            PromptAction.showToast({ message: "复制失败" });
        }
    }
}