import { vibration } from '../common/vibration';
import { PromptAction } from '@kit.ArkUI';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { setFirstLaunch, getFirstLaunch } from '../common/storage';
import { privacyManager } from '@kit.StoreKit';
import { showToastSafely } from '../common/safeUi';

@Component
export struct confirmButtons {
    @Link isShow: boolean;
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink('vibrationLevel') vibrationLevel: number = 2;
    @State countDown: number = 3;
    @State isConfirmEnabled: boolean = false;
    @State isExiting: boolean = false;
    @State isProcessing: boolean = false;
    private timerId: number = -1;

    aboutToAppear(): void {
        this.startCountDown();
    }

    aboutToDisappear(): void {
        if (this.timerId !== -1) {
            clearInterval(this.timerId);
        }
    }

    private async startCountDown(): Promise<void> {
        try {
            let isFirstLaunch = await getFirstLaunch();

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
            console.error('[Dashboard][component/confirmButtons][ERROR]', "Index", "检查失败", JSON.stringify(error));
            this.isConfirmEnabled = true;
        }
    }

    private async handleCancel(): Promise<void> {
        this.isExiting = true;
        showToastSafely(this.PromptAction, '退出应用…', 2000, 'PrivacyConfirm');
        try {
            await setFirstLaunch(true);

            console.info('[Dashboard][component/confirmButtons][INFO]', "Index", "用户点击取消，标记位重置为true。");
        } catch (err) {
            console.error('[Dashboard][component/confirmButtons][ERROR]', "获取失败");
        }
        setTimeout(() => {
            try {
                privacyManager.disableService();
                const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                context.terminateSelf().then(() => {
                    console.info('[Dashboard][component/confirmButtons][INFO]', 'Ability 销毁指令发送成功');
                }).catch((err: BusinessError) => {
                    console.error('[Dashboard][component/confirmButtons][ERROR]', `销毁失败: ${err.code}`);
                });
            } catch (err) {
                console.error('[Dashboard][component/confirmButtons][ERROR]', `撤回隐私协议失败: ${err.code}`);
            }
        }, 500);
    }

    private async handleConfirm(): Promise<void> {
        if (!this.isConfirmEnabled) return;
        try {
            await setFirstLaunch(false);

            this.isShow = false;
            console.info('[Dashboard][component/confirmButtons][INFO]', "Index", "用户已同意协议，标记位已更新。");
        } catch (error) {
            console.error('[Dashboard][component/confirmButtons][ERROR]',
                `保存重要提示同意状态失败: ${JSON.stringify(error)}`);
            showToastSafely(this.PromptAction, '保存同意状态失败，请重试', 2000, 'PrivacyConfirm');
            return;
        }
        this.isProcessing = true;
        this.isShow = false;
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
                .backgroundColor($r('app.color.v3_accent_green'))
                .borderRadius(this.BORDER_RADIUS)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                .onClick(() => {
                    if(this.vibrationLevel > 0) vibration.dotVibration()
                    this.handleCancel();
                })
                .accessibilityText(this.isExiting ? '正在退出应用' : '取消重要提示并退出应用')

            Button(
                this.isProcessing ? "处理中..." : (this.isConfirmEnabled ? "确定且不再显示" : `确定(${this.countDown}s)`),
                { type: ButtonType.Normal }
            )
                .margin(2)
                .width('45%')
                .height(this.BUTTON_HEIGHT)
                .backgroundColor(this.isConfirmEnabled ? $r('app.color.v3_accent_red') : $r('app.color.v3_text_secondary'))
                .borderRadius(this.BORDER_RADIUS)
                .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                .onClick(() => {
                    if(this.vibrationLevel > 0) vibration.dotVibration()
                    this.handleConfirm();
                })
                .accessibilityText(this.isConfirmEnabled ? '同意重要提示且不再显示' : `请等待${this.countDown}秒后同意`)
        }
        .width("100%")
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 15 })
        .accessibilityGroup(true)
        .accessibilityText('重要提示确认按钮');
    }
}
