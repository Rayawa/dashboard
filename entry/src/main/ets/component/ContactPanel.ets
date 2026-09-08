import { curves, PromptAction } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pasteboard } from '@kit.BasicServicesKit';
import { common, Want } from '@kit.AbilityKit';
import { vibration } from '../common/vibration';
import { showToastSafely } from '../common/safeUi';
import { pressLightFieldFilter, pressVisualEffect } from '../common/visualEffects';
import { cancelStaggerEnterAnimation, startStaggerEnterAnimation } from '../common/motion';

@Component
export struct ContactPanel {
    private prompt: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') vibrationLevel: number = 1;
    @State private pressedItem: string = '';
    @State private animStep: number = 0;
    private enterAnimationTimers: number[] = [];

    private startEnterAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    private updatePressed(item: string, pressed: boolean): void {
        this.pressedItem = pressed ? item : '';
    }

    @Builder private contactItem(title: string, name: string, detail: string, copyContent: string,
        toastLabel: string, enterStep: number): void {
        Column({ space: 4 }) {
            Text(title).fontSize(17).fontWeight(FontWeight.Bold)
            Text(name).fontSize(14).fontColor($r("app.color.diff_content"))
            Text(detail).fontSize(13).fontColor($r('app.color.v3_text_secondary')).opacity(0.8)
        }
        .alignItems(HorizontalAlign.Center)
        .width("93%")
        .backgroundColor($r("app.color.background"))
        .padding(14)
        .borderRadius(16)
        .scale({ x: this.pressedItem === title ? 0.97 : 1, y: this.pressedItem === title ? 0.97 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(
            this.pressedItem === title, hdsEffect.PointLightIlluminatedType.BORDER, 6, 100))
        .compositingFilter(pressLightFieldFilter(this.pressedItem === title))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.updatePressed(title, true);
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updatePressed(title, false);
        })
        .onClick(async () => {
            if(this.vibrationLevel > 0) vibration.dotVibration()
            await this.copyToClipboard(copyContent, toastLabel);
        })
        .opacity(this.animStep >= enterStep ? 1 : 0)
        .translate({ y: this.animStep >= enterStep ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText(`${title}，${name}，${detail}，点击复制${toastLabel}`)
    }

    build() {
        Column({ space: 10 }) {
            this.contactItem("👥 主要负责人", "shenjack", "邮箱：3695888@qq.com", "3695888@qq.com", "邮箱", 1)
            this.contactItem("🌐 T站网页负责人", "tianxiu2b2t", "邮箱：administrator@ttb-network.top", "administrator@ttb-network.top", "邮箱", 2)
            this.contactItem("📱 鸿蒙应用开发", "清霁·Rayawa", "邮箱：rayawa.work@outlook.com", "rayawa.work@outlook.com", "邮箱", 3)
            this.contactItem("💬 QQ群", "Harmony Dashboard官方交流群", "群号：757273833", "757273833", "群号", 4)

            Column({ space: 4 }) {
                Text("❤️ 赞助我们").fontSize(17).fontWeight(FontWeight.Bold)
                Text("支持项目发展").fontSize(14).fontColor($r("app.color.diff_content"))
                Text("点击跳转到爱发电赞助页面").fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary')).opacity(0.8)
            }
            .alignItems(HorizontalAlign.Center)
            .width("93%")
            .backgroundColor($r("app.color.background"))
            .padding(14)
            .borderRadius(16)
            .scale({ x: this.pressedItem === 'sponsor' ? 0.97 : 1,
                y: this.pressedItem === 'sponsor' ? 0.97 : 1 })
            .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(
                this.pressedItem === 'sponsor', hdsEffect.PointLightIlluminatedType.BORDER, 6, 100))
            .compositingFilter(pressLightFieldFilter(this.pressedItem === 'sponsor'))
            .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) this.updatePressed('sponsor', true);
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.updatePressed('sponsor', false);
                }
            })
            .onClick(async () => {
                if(this.vibrationLevel > 0) vibration.dotVibration()
                const url = "https://afdian.com/a/shenjack";
                const uiContext = this.getUIContext();
                try {
                    const context = uiContext.getHostContext() as common.UIAbilityContext;
                    await context.startAbility({
                        action: "ohos.want.action.viewData",
                        entities: ["entity.system.browsable"],
                        uri: url,
                    } as Want);
                } catch (e) {
                    console.error('[Dashboard][component/ContactPanel][ERROR]', `赞助页面跳转失败: ${JSON.stringify(e)}`);
                    showToastSafely(this.prompt, '跳转失败', 2000, 'Contact');
                }
            })
            .opacity(this.animStep >= 5 ? 1 : 0)
            .translate({ y: this.animStep >= 5 ? 0 : 20 })
            .accessibilityGroup(true)
            .accessibilityText('赞助我们，点击打开爱发电赞助页面')


        }
        .width("100%")
        .padding(5)
        .margin({ bottom: 20 })
        .onAppear((): void => this.startEnterAnimation())
        .accessibilityGroup(true)
        .accessibilityText('联系我们')
    }

    private async copyToClipboard(text: string, label: string): Promise<void> {
        try {
            let pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
            await pasteboard.getSystemPasteboard().setData(pasteData);
            showToastSafely(this.prompt, `已复制${label}`, 2000, 'Contact');
        } catch (error) {
            console.error('[Dashboard][component/ContactPanel][ERROR]', `复制${label}失败: ${JSON.stringify(error)}`);
            showToastSafely(this.prompt, '复制失败', 2000, 'Contact');
        }
    }
}
