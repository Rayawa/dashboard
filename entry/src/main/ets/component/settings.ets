import { vibration } from '../common/vibration';
import { isTSiteDev } from '../common/constants';
import {
    getButtonPosition,
    getDefaultSite,
    getHoldCheckEnabled,
    getTabBarAuto,
    getTDev,
    getThemeColor,
    getVibrationEnabled,
    initializeSettings,
    setButtonPosition,
    setDefaultSite,
    setHoldCheckEnabled,
    setTabBarAuto,
    setTDev,
    setVibrationEnabled,
} from '../common/SettingsStorage';

@Component
export struct settings {
    private triggerVibration(): void {
        if (this.vibrationON){
            vibration.dotVibration()
        }
    }

    @State handlePopup: boolean = false;
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @StorageLink("tabBarAuto") tabBarAuto: boolean = true;
    @StorageLink("TSiteDev") siteTDev: boolean = false;
    @State isTDev: boolean = false;
    @State themeColor: string = "blue";

    // 页面显示时加载设置
    async aboutToAppear() {
        initializeSettings();
        await this.loadSettings();
        isTSiteDev().then((val) => {
            if (!val) {
                return;
            }
            this.isTDev = true;
        });
    }

    // 加载所有设置
    private async loadSettings() {
        try {
            this.defaultSiteT = await getDefaultSite();
            this.vibrationON = await getVibrationEnabled();
            this.holdCheckON = await getHoldCheckEnabled();
            this.buttonPositionRIGHT = await getButtonPosition();
            this.tabBarAuto = await getTabBarAuto();
            this.themeColor = await getThemeColor();
            this.siteTDev = await getTDev();
        } catch (error) {
            console.error("加载设置失败:", error);
        }
    }

    // 保存默认站点设置
    private async saveDefaultSite(isT: boolean) {
        try {
            await setDefaultSite(isT);
            this.defaultSiteT = isT;
        } catch (error) {
            console.error("保存默认站点设置失败:", error);
        }
    }

    // 保存震感反馈设置
    private async saveVibrationEnabled(enabled: boolean) {
        try {
            await setVibrationEnabled(enabled);
            this.vibrationON = enabled;
        } catch (error) {
            console.error("保存震感反馈设置失败:", error);
        }
    }

    // 保存智感握持设置
    private async saveHoldCheckEnabled(enabled: boolean) {
        try {
            await setHoldCheckEnabled(enabled);
            this.holdCheckON = enabled;
        } catch (error) {
            console.error("保存智感握持设置失败:", error);
        }
    }

    // 保存按钮位置设置
    private async saveButtonPosition(isRight: boolean) {
        try {
            await setButtonPosition(isRight);
            this.buttonPositionRIGHT = isRight;
        } catch (error) {
            console.error("保存按钮位置设置失败:", error);
        }
    }

    // 保存自动底部栏设置
    private async saveTabBarAuto(enabled: boolean) {
        try {
            await setTabBarAuto(enabled);
            this.tabBarAuto = enabled;
        } catch (error) {
            console.error("保存自动底部栏设置失败:", error);
        }
    }

    private async saveTDev(val: boolean) {
        try {
            await setTDev(val);
        } catch (error) {
            console.error("保存按钮位置设置失败:", error);
        }
    }

    build() {
        Column() {
            // Row() {
            //     Row({ space: 12 }) {
            //         Image($r("app.media.default"))
            //             .height(24)
            //             .width(24)
            //             .objectFit(ImageFit.Contain)
            //         Text("默认站点").fontSize(16)
            //     }
            //     //.fontColor('#888')
            //     Row({ space: 8 }) {
            //         Text("S站")
            //             .fontSize(14)
            //             .fontColor("#888")
            //             .width(24)
            //             .textAlign(TextAlign.Center)
            //         Toggle({ type: ToggleType.Switch, isOn: this.defaultSiteT })
            //             .selectedColor($r("app.color.diff_content"))
            //             .switchStyle({
            //                 unselectedColor: $r("app.color.diff_content"),
            //             })
            //             .onChange(async (isOn: boolean) => {
            //                 await this.saveDefaultSite(isOn);
            //                 PromptAction.showToast({
            //                     message: "重启应用后生效",
            //                     duration: 500,
            //                 });
            //                 this.triggerVibration();
            //             })
            //         Text("T站")
            //             .fontSize(14)
            //             .fontColor("#888")
            //             .width(24)
            //             .textAlign(TextAlign.Center)
            //     }
            // }
            // .height(56)
            // .width("100%")
            // .justifyContent(FlexAlign.SpaceBetween)
            // .padding({ left: 16, right: 16 })
            // Divider()
            //     .color($r("app.color.border"))
            //     .strokeWidth(0.5)
            //     .margin({ left: 16, right: 16 })
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.vibrate"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("震感反馈").fontSize(16)
                }

                Row({ space: 8 }) {
                    Text("关")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.vibrationON })
                        .selectedColor($r("app.color.diff_content"))
                        .onChange(async (isOn: boolean) => {
                            await this.saveVibrationEnabled(isOn);
                            this.triggerVibration();
                        })
                    Text("开")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                }
            }
            .height(56)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider()
                .color($r("app.color.border"))
                .strokeWidth(0.5)
                .margin({ left: 16, right: 16 })
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.hand"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("智感握持").fontSize(16)
                }

                Row({ space: 8 }) {
                    Text("关")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.holdCheckON })
                        .selectedColor($r("app.color.diff_content"))
                        .onChange(async (isOn: boolean) => {
                            await this.saveHoldCheckEnabled(isOn);
                            this.triggerVibration();
                        })
                    Text("开")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                }
            }
            .height(56)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider()
                .color($r("app.color.border"))
                .strokeWidth(0.5)
                .margin({ left: 16, right: 16 })
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.button"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("按钮默认位置").fontSize(16)
                }

                Row({ space: 8 }) {
                    Text("左")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                    Toggle({
                        type: ToggleType.Switch,
                        isOn: this.buttonPositionRIGHT,
                    })
                        .selectedColor($r("app.color.diff_content"))
                        .switchStyle({
                            unselectedColor: $r("app.color.diff_content"),
                        })
                        .onChange(async (isOn: boolean) => {
                            await this.saveButtonPosition(isOn);
                            this.triggerVibration();
                        })
                    Text("右")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)

                }
            }
            .height(56)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider()
                .color($r("app.color.border"))
                .strokeWidth(0.5)
                .margin({ left: 16, right: 16 })
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.autoBar"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("自动隐藏底部栏").fontSize(16)
                }

                Row({ space: 8 }) {
                    Text("关")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.tabBarAuto })
                        .selectedColor($r("app.color.diff_content"))
                        .onChange(async (isOn: boolean) => {
                            await this.saveTabBarAuto(isOn);
                            this.triggerVibration();
                        })
                    Text("开")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                }
            }
            .height(56)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider()
                .color($r("app.color.border"))
                .strokeWidth(0.5)
                .margin({ left: 16, right: 16 })
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.theme"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("主题").fontSize(16)
                }

                Rect()
                    .width(24)
                    .height(24)
                    .fill($r("app.color.diff_content"))
                    .borderRadius(16)
                    .borderWidth(0.5)
                    .onClick(() => {
                        this.triggerVibration();
                        this.handlePopup = !this.handlePopup;
                    })
                    .bindPopup(this.handlePopup, {
                        message: "蓝",
                        placement: Placement.Top,
                        showInSubWindow: false,
                        onStateChange: (e) => {
                            if (!e.isVisible) {
                                this.handlePopup = false;
                            }
                        },
                        transition: TransitionEffect.asymmetric(
                            TransitionEffect.OPACITY.animation({
                                duration: 500,
                                curve: Curve.Ease,
                            }).combine(TransitionEffect.translate({ x: 0, y: 12 })),

                            TransitionEffect.OPACITY.animation({
                                duration: 300,
                                curve: Curve.EaseOut,
                            }).combine(TransitionEffect.translate({ x: 0, y: 12 })),
                        ),
                    })
            }
            .height(56)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            ///

            Divider()
                .color($r("app.color.border"))
                .strokeWidth(0.5)
                .margin({ left: 16, right: 16 })
                .visibility(this.isTDev ? Visibility.Visible : Visibility.Hidden)
                .height(this.isTDev ? undefined : 0)
            Row() {
                Row({ space: 12 }) {
                    Image($r("app.media.theme"))
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text("T站开发").fontSize(16)
                }

                Row({ space: 8 }) {
                    Text("关")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.siteTDev })
                        .selectedColor($r("app.color.diff_content"))
                        .onChange(async (isOn: boolean) => {
                            await this.saveTDev(isOn);
                            // this.triggerVibration();
                        })
                    Text("开")
                        .fontSize(14)
                        .fontColor("#888")
                        .width(24)
                        .textAlign(TextAlign.Center)
                }
            }
            .height(this.isTDev ? 56 : 0)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            .visibility(this.isTDev ? Visibility.Visible : Visibility.Hidden)
        }
        .borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .shadow({
            radius: 8,
            color: "#1a000000",
            offsetX: 0,
            offsetY: 2,
        })
        .width("90%")
        .alignItems(HorizontalAlign.Center)
    }
}
