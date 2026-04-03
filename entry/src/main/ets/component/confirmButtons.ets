import { vibration } from '../common/vibration';
import { PromptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';

@Component
export struct confirmButtons {
    @StorageLink("IS_FIRST_LAUNCH_KEY") IS_FIRST_LAUNCH_KEY: string = "isFirstLaunch";
    @StorageLink("showWarn") showWarn: boolean = false;
    PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("vibrationON") vibrationON: boolean = true;

    private triggerVibration(): void {
        if (this.vibrationON) {
            vibration.dotVibration()
        }
    }

    @State countDown: number = 5;
    @State isConfirmEnabled: boolean = false;
    @State isExiting: boolean = false;
    @State isProcessing: boolean = false;
    private timerId: number = -1;

    aboutToAppear() {
        this.startCountDown();
    }

    aboutToDisappear() {
        if (this.timerId !== -1) {
            clearInterval(this.timerId);
        }
    }

    private async startCountDown() {
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let prefs = await preferences.getPreferences(context, "myAppSettings");
            let isFirstLaunch = await prefs.get(this.IS_FIRST_LAUNCH_KEY, true);

            if (isFirstLaunch === true) {
                // 情况 A：首次启动，执行倒计时逻辑
                this.timerId = setInterval(() => {
                    if (this.countDown > 0) {
                        this.countDown--;
                    } else {
                        this.isConfirmEnabled = true;
                        clearInterval(this.timerId);
                    }
                }, 1000);
            } else {
                // 情况 B：非首次启动（后续查看），直接启用确定按钮，不开启定时器
                this.isConfirmEnabled = true;
            }
        } catch (err) {
            let error = err as BusinessError;
            console.error("Index", "检查失败", JSON.stringify(error));
            // 兜底方案：如果读取失败，为了保险起见建议默认开启确认按钮
            this.isConfirmEnabled = true;
        }
    }

    private async handleCancel() {
        this.isExiting = true;
        this.PromptAction.showToast({ message: "退出应用..." });
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let prefs = await preferences.getPreferences(context, "myAppSettings");

            await prefs.put(this.IS_FIRST_LAUNCH_KEY, true);
            await prefs.flush();

            console.info("Index", "用户点击取消，标记位重置为true。");
        } catch (err) {
        }

        setTimeout(() => {
            const context = getContext(this) as common.UIAbilityContext;
            context.terminateSelf().then(() => {
                console.info('Ability 销毁指令发送成功');
            }).catch((err: BusinessError) => {
                console.error(`销毁失败: ${err.code}`);
            });
        }, 500);
    }

    private async handleConfirm() {
        if (!this.isConfirmEnabled) return;
        try {
            let context = getContext(this) as common.UIAbilityContext;
            let prefs = await preferences.getPreferences(context, "myAppSettings");

            await prefs.put(this.IS_FIRST_LAUNCH_KEY, false);
            await prefs.flush();

            this.showWarn = false;
            console.info("Index", "用户已同意协议，标记位已更新。");
        } catch (err) {
        }
        this.isProcessing = true;
        this.showWarn = false;
    }

    private readonly BUTTON_HEIGHT: number = 44;
    private readonly BUTTON_CLICK_SCALE: number = 0.8;
    private readonly BORDER_RADIUS: number = 22;

    build() {
        Row() {
            Button(this.isExiting ? "退出中..." : "取消并退出", { type: ButtonType.Normal })
                .margin(2)
                .width('35%')
                .height(this.BUTTON_HEIGHT)
                .backgroundColor(Color.Green)
                .borderRadius(this.BORDER_RADIUS)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                .onClick(() => {
                    this.triggerVibration();
                    this.handleCancel();
                })

            Button(
                this.isProcessing ? "处理中..." : (this.isConfirmEnabled ? "确定且不再显示" : `确定(${this.countDown}s)`),
                { type: ButtonType.Normal }
            )
                .margin(2)
                .width('45%')
                .height(this.BUTTON_HEIGHT)
                .backgroundColor(this.isConfirmEnabled ? Color.Red : "#888")
                .borderRadius(this.BORDER_RADIUS)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                .onClick(() => {
                    this.triggerVibration();
                    this.handleConfirm();
                })
        }
        .width("100%")
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 15 });
    }
}