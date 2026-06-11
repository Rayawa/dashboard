import { vibration } from '../common/vibration';
import { PromptAction } from '@kit.ArkUI';
import type { AppDetailInfo, BaseAPIResponse, CommentInfo, FormData, SubmitAppBody } from '../common/types';
import { SAPIBaseURL, SUBMIT_PLATFORM,  } from '../common/constants';
import URL from '../common/url';
import { http } from '@kit.NetworkKit';

interface Scale {
    x: number;
    y: number;
}

interface ButtonAnimationState {
    immediatelyOpacity: number;
    immediatelyScale: Scale;
    delayOpacity: number;
    delayScale: Scale;
}

export async function submit_app(
    data: SubmitAppBody,
): Promise<BaseAPIResponse<AppDetailInfo> | null> {
    const final_comment: CommentInfo = {
        user: data.comment?.user,
        note: data.comment?.note,
        platform: SUBMIT_PLATFORM,
    };
    const final_data: SubmitAppBody = {
        app_id: data.app_id,
        pkg_name: data.pkg_name,
        comment: final_comment,
    };
    console.log("submit data:", JSON.stringify(final_data));
    const path = new URL("submit", SAPIBaseURL);
    const request = http.createHttp();
    try {
        const response = await request.request(path.toString(), {
            method: http.RequestMethod.POST,
            expectDataType: http.HttpDataType.OBJECT,
            usingCache: false,
            header: {
                "Content-Type": "application/json",
            },
            extraData: final_data,
        });
        console.info(`request response code: ${response.responseCode}`);
        const res: object =
            typeof response.result === "string" ? JSON.parse(response.result) : response.result;
        try {
            return res as BaseAPIResponse<AppDetailInfo>;
        } catch (e) {
            return null;
        }
    } catch (e) {
        console.warn(`error ${e}`);
    } finally {
        request.destroy();
    }
    return null;
}

@Component
export struct submitButtons {
    PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @State appId: string = '';
    @State isLoading: boolean = false;

    @StorageLink("userName") userName: string = "";
    @StorageLink("inputText") inputText: string = "";
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("formData") formData: FormData = {
        appLink: "",
        packageName: "",
        appId: "",
        remark: "",
    };


    async clearForm(): Promise<void> {
        if (this.isCleaning) {
            return;
        }
        this.isCleaning = true;
        this.startCleanRippleLoop();

        this.formData = {
            appLink: "",
            packageName: "",
            appId: "",
            remark: "",
        };
        this.inputText = "";

        setTimeout(() => {
            this.isCleaning = false;
            this.stopCleanRippleLoop();
            if(this.vibrationON){
                vibration.waveVibration()
            }
            this.PromptAction.showToast({
                message: "表单已清空",
                duration: 1500,
            });
        }, 700);
    }

    async submitForm(): Promise<void> {
        if (this.isSubmitting) {
            return;
        }

        if (!this.formData.packageName.trim()) {
            this.PromptAction.showToast({
                message: "请输入包名",
                duration: 2000,
            });
            return;
        }

        this.isSubmitting = true;
        this.startSubmitRippleLoop();

        try {
            const origin_pkg = this.formData.packageName.trim();
            const origin_app_id = this.formData.appId.trim();
            const pkg_name = !!origin_pkg ? origin_pkg : undefined;
            const app_id = !!origin_app_id && pkg_name == undefined ? origin_app_id : undefined;

            await submit_app({
                pkg_name,
                app_id,
                comment: {
                    user: this.userName,
                    note: this.formData.remark?.trim() || undefined,
                },
            });
            if(this.vibrationON){
                vibration.waveVibration()
            }
            this.PromptAction.showToast({
                message: "提交成功，感谢您的投稿！",
                duration: 1500,
            });

            this.formData = {
                appLink: "",
                packageName: "",
                appId: "",
                remark: "",
            };
            this.inputText = "";
        } catch (error) {
            console.error("提交失败:", error);
            if(this.vibrationON){
                vibration.errorVibration()
            }
            this.PromptAction.showToast({
                message: "提交失败，请稍后重试",
                duration: 2000,
            });
        } finally {
            setTimeout(() => {
                this.isSubmitting = false;
                this.stopSubmitRippleLoop();
            }, 700);
        }
    }


    @State isCleaning: boolean = false;
    @State isSubmitting: boolean = false;
    private readonly BUTTON_WIDTH: string = "35%";
    private readonly BUTTON_HEIGHT: number = 44;
    private readonly BUTTON_CLICK_SCALE: number = 0.8;
    private readonly ANIMATION_DURATION: number = 1300;
    private readonly BORDER_RADIUS: number = 22;
    private readonly CLICK_INTERVAL = 800;
    private _cleanAnimationCompleted: boolean = false;
    private _submitAnimationCompleted: boolean = false;

    @Styles
    ripplesStyleClean() {
        .width(this.BUTTON_WIDTH)
        .height(this.BUTTON_HEIGHT)
        .borderRadius(this.BORDER_RADIUS)
        .backgroundColor(Color.Green);
    }

    @Styles
    ripplesStyleSubmit() {
        .width(this.BUTTON_WIDTH)
        .height(this.BUTTON_HEIGHT)
        .borderRadius(this.BORDER_RADIUS)
        .backgroundColor(Color.Red);
    }

    @State cleanAnimation: ButtonAnimationState = {
        immediatelyOpacity: 0.8,
        immediatelyScale: { x: 1, y: 1 },
        delayOpacity: 0.4,
        delayScale: { x: 1, y: 1 },
    };

    @State submitAnimation: ButtonAnimationState = {
        immediatelyOpacity: 0.8,
        immediatelyScale: { x: 1, y: 1 },
        delayOpacity: 0.4,
        delayScale: { x: 1, y: 1 },
    };
    private _cleanLoopRunning: boolean = false;
    private _submitLoopRunning: boolean = false;
    private _cleanLastClick: number = 0;
    private _submitLastClick: number = 0;

    private startCleanRippleLoop() {
        if (this._cleanLoopRunning) {
            return;
        }
        this._cleanLoopRunning = true;
        this._cleanAnimationCompleted = false;

        const loop = () => {
            if (!this._cleanLoopRunning) {
                return;
            }

            this.getUIContext().animateTo(
                {
                    duration: this.ANIMATION_DURATION,
                    curve: Curve.EaseInOut,
                },
                () => {
                    this.cleanAnimation.immediatelyOpacity = 0;
                    this.cleanAnimation.immediatelyScale = { x: 4, y: 4 };
                },
            );

            this.getUIContext().animateTo(
                {
                    duration: this.ANIMATION_DURATION,
                    delay: 200,
                    curve: Curve.EaseInOut,
                },
                () => {
                    this.cleanAnimation.delayOpacity = 0;
                    this.cleanAnimation.delayScale = { x: 4, y: 4 };
                },
            );

            const total = this.ANIMATION_DURATION + 200 + 40;

            setTimeout(() => {
                this._cleanAnimationCompleted = true;

                if (!this._cleanLoopRunning) {
                    this.cleanAnimation.immediatelyOpacity = 0.8;
                    this.cleanAnimation.delayOpacity = 0.8;
                    this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
                    this.cleanAnimation.delayScale = { x: 1, y: 1 };
                    return;
                }

                this.cleanAnimation.immediatelyOpacity = 0.8;
                this.cleanAnimation.delayOpacity = 0.8;
                this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
                this.cleanAnimation.delayScale = { x: 1, y: 1 };

                loop();
            }, total);
        };

        loop();
    }

    private stopCleanRippleLoop() {
        if (!this._cleanAnimationCompleted) {
            setTimeout(() => {
                this._cleanLoopRunning = false;
                this.cleanAnimation.immediatelyOpacity = 0.8;
                this.cleanAnimation.delayOpacity = 0.8;
                this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
                this.cleanAnimation.delayScale = { x: 1, y: 1 };
            }, 700);
        } else {
            this._cleanLoopRunning = false;
            this.cleanAnimation.immediatelyOpacity = 0.8;
            this.cleanAnimation.delayOpacity = 0.8;
            this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
            this.cleanAnimation.delayScale = { x: 1, y: 1 };
        }
    }

    private startSubmitRippleLoop() {
        if (this._submitLoopRunning) {
            return;
        }
        this._submitLoopRunning = true;
        this._submitAnimationCompleted = false;

        const loop = () => {
            if (!this._submitLoopRunning) {
                return;
            }

            this.getUIContext().animateTo(
                {
                    duration: this.ANIMATION_DURATION,
                    curve: Curve.EaseInOut,
                },
                () => {
                    this.submitAnimation.immediatelyOpacity = 0;
                    this.submitAnimation.immediatelyScale = { x: 4, y: 4 };
                },
            );

            this.getUIContext().animateTo(
                {
                    duration: this.ANIMATION_DURATION,
                    delay: 200,
                    curve: Curve.EaseInOut,
                },
                () => {
                    this.submitAnimation.delayOpacity = 0;
                    this.submitAnimation.delayScale = { x: 4, y: 4 };
                },
            );

            const total = this.ANIMATION_DURATION + 200 + 40;

            setTimeout(() => {
                this._submitAnimationCompleted = true;

                if (!this._submitLoopRunning) {
                    this.submitAnimation.immediatelyOpacity = 0.8;
                    this.submitAnimation.delayOpacity = 0.8;
                    this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
                    this.submitAnimation.delayScale = { x: 1, y: 1 };
                    return;
                }

                this.submitAnimation.immediatelyOpacity = 0.8;
                this.submitAnimation.delayOpacity = 0.8;
                this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
                this.submitAnimation.delayScale = { x: 1, y: 1 };

                loop();
            }, total);
        };

        loop();
    }

    private stopSubmitRippleLoop() {
        if (!this._submitAnimationCompleted) {
            setTimeout(() => {
                this._submitLoopRunning = false;
                this.submitAnimation.immediatelyOpacity = 0.8;
                this.submitAnimation.delayOpacity = 0.8;
                this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
                this.submitAnimation.delayScale = { x: 1, y: 1 };
            }, 700);
        } else {
            this._submitLoopRunning = false;
            this.submitAnimation.immediatelyOpacity = 0.8;
            this.submitAnimation.delayOpacity = 0.8;
            this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
            this.submitAnimation.delayScale = { x: 1, y: 1 };
        }
    }

    build() {
        Row() {
            // 清空按钮
            Stack() {
                Stack()
                    .ripplesStyleClean()
                    .opacity(this.cleanAnimation.immediatelyOpacity)
                    .scale(this.cleanAnimation.immediatelyScale)
                Stack()
                    .ripplesStyleClean()
                    .opacity(this.cleanAnimation.delayOpacity)
                    .scale(this.cleanAnimation.delayScale)
                Button(this.isCleaning ? "清空中..." : "清空", { type: ButtonType.Normal })
                    .margin(2)
                    .width(this.BUTTON_WIDTH)
                    .height(this.BUTTON_HEIGHT)
                    .backgroundColor(Color.Green)
                    .borderRadius(this.BORDER_RADIUS)
                    .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                    .onClick(() => {
                        const now = Date.now();
                        if (now - this._cleanLastClick < this.CLICK_INTERVAL) {
                            return;
                        }
                        this._cleanLastClick = now;
                        if(this.vibrationON) vibration.dotVibration()
                        this.clearForm();
                    })
            }
            // 提交按钮
            Stack() {
                Stack()
                    .ripplesStyleSubmit()
                    .opacity(this.submitAnimation.immediatelyOpacity)
                    .scale(this.submitAnimation.immediatelyScale)
                Stack()
                    .ripplesStyleSubmit()
                    .opacity(this.submitAnimation.delayOpacity)
                    .scale(this.submitAnimation.delayScale)
                Button(this.isSubmitting ? "提交中..." : "提交投稿", { type: ButtonType.Normal })
                    .margin(2)
                    .width(this.BUTTON_WIDTH)
                    .height(this.BUTTON_HEIGHT)
                    .backgroundColor(Color.Red)
                    .borderRadius(this.BORDER_RADIUS)
                    .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
                    .onClick(() => {
                        const now = Date.now();
                        if (now - this._submitLastClick < this.CLICK_INTERVAL) {
                            return;
                        }
                        this._submitLastClick = now;
                        if(this.vibrationON) vibration.dotVibration()
                        this.submitForm();
                    })
            }
        }
        .width("100%")
        .justifyContent(FlexAlign.SpaceEvenly)
        .margin({ top: 15 });
    }
}
