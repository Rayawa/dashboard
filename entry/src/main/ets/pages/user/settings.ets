import { LengthMetrics, prompt, router } from "@kit.ArkUI";
import { vibrator } from "@kit.SensorServiceKit";
import { common, Want } from "@kit.AbilityKit";
import { BusinessError } from "@ohos.base";
import { APP_VERSION, isTSiteDev } from "../../common/constants";
import {
    getButtonPosition,
    getDefaultSite,
    getHoldCheckEnabled,
    getThemeColor,
    getVibrationEnabled,
    initializeSettings,
    setButtonPosition,
    setDefaultSite,
    setHoldCheckEnabled,
    setVibrationEnabled,
    setTDev,
    getTDev,
} from "../../common/SettingsStorage";
import {
    HdsNavigation,
    HdsNavigationTitleMode,
    ScrollEffectType,
    HdsNavigationAttribute,
} from "@kit.UIDesignKit";
@Entry
@Component
export struct settings {
    private triggerVibration(): void {
        if (this.vibrationON) {
            vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
                if (err) {
                    console.error(
                        `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
                    );
                    return;
                }
                console.info("Succeed in querying effect");
                if (state) {
                    try {
                        vibrator.startVibration(
                            {
                                type: "preset",
                                effectId: "haptic.effect.hard",
                                count: 1,
                                intensity: 50,
                            },
                            { usage: "touch" },
                            (error: BusinessError) => {
                                if (error) {
                                    console.error(
                                        `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                                    );
                                } else {
                                    console.info("Succeed in starting vibration");
                                }
                            },
                        );
                    } catch (tryError) {
                        console.error(`An unexpected error occurred in try block: ${tryError}`);
                    }
                }
            });
        }
    }

    async openLink() {
        const url = "https://beian.miit.gov.cn/#/Integrated/index";
        const ui_content = this.getUIContext();
        const prompt_action = ui_content.getPromptAction();
        ui_content.showAlertDialog({
            title: "是否跳转到浏览器",
            message: "即将访问\nICP/IP地址/域名信息备案管理系统",
            primaryButton: {
                value: "取消",
                fontColor: Color.Red,
                action: () => {
                    console.log("点击了取消按钮");
                },
            },
            secondaryButton: {
                value: "确定",
                fontColor: Color.Blue,
                action: async (): Promise<void> => {
                    try {
                        prompt_action.showToast({ message: "正在跳转...", duration: 500 });
                        let context = ui_content.getHostContext() as common.UIAbilityContext;
                        await context.startAbility({
                            action: "ohos.want.action.viewData",
                            entities: ["entity.system.browsable"],
                            uri: url,
                        } as Want);
                    } catch (error) {
                        console.error("打开链接失败:", (error as BusinessError).message);
                        prompt_action.showToast({ message: "打开链接失败", duration: 1000 });
                    }
                },
            },
        });
    }

    @State handlePopup: boolean = false;
    @StorageLink("defaultSiteT") defaultSiteT: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = true;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
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

    private async saveTDev(val: boolean) {
        try {
            await setTDev(val);
        } catch (error) {
            console.error("保存按钮位置设置失败:", error);
        }
    }

    build() {
        HdsNavigation() {
            Stack() {
                Scroll() {
                    Column() {
                        Column() {
                            Image($r("app.media.app_icon"))
                                .height(100)
                                .width(100)
                                .borderRadius($r("sys.float.corner_radius_level6"))
                            Text("应用看板")
                                .fontWeight(800)
                                .fontSize(30)
                                .margin({ top: 20 })
                                .fontColor($r("app.color.diff_content"))
                            Text("Gallery Dashboard")
                                .fontWeight(600)
                                .fontSize(20)
                                .margin({ top: 10 })
                        }
                        Divider()
                            .margin({ top: 20, bottom: 20 })
                            .color($r("app.color.border"))
                        Column() {
                            Row() {
                                Row({ space: 12 }) {
                                    Image($r("app.media.default"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("默认站点").fontSize(16)
                                }
                                //.fontColor('#888')
                                Row({ space: 8 }) {
                                    Text("S站")
                                        .fontSize(14)
                                        .fontColor("#888")
                                        .width(24)
                                        .textAlign(TextAlign.Center)
                                    Toggle({ type: ToggleType.Switch, isOn: this.defaultSiteT })
                                        .selectedColor($r("app.color.diff_content"))
                                        .switchStyle({ unselectedColor: "#888" })
                                        .onChange(async (isOn: boolean) => {
                                            await this.saveDefaultSite(isOn);
                                            this.triggerVibration();
                                        })
                                    Text("T站")
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
                        Divider()
                            .margin({ top: 20, bottom: 20 })
                            .color($r("app.color.border"))
                        Text(`Version ${APP_VERSION}`)
                            .fontColor("#888")
                            .fontSize(12)
                            .margin(5)
                        Text("本应用备案域名：rayawa.top")
                            .fontSize(12)
                            .fontColor("#888")
                            .margin(5)
                        Column() {
                            Text("京ICP备2025153453号")
                                .fontSize(12)
                                .fontColor($r("app.color.diff_content"))
                                .onClick(() => {
                                    this.triggerVibration();
                                    this.openLink();
                                })
                        }.margin(5)
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)
                    .margin({ top: 60, bottom: 20 })
                }
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                .width("100%")
                .height("100%")
            }
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
        }
        .navBarWidth("100%")
        .titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background_transparent"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
            },
            content: {
                title: {
                    mainTitle: "设置",
                },
                backIcon: {
                    action: () => {
                        this.triggerVibration();
                        router.back();
                    },
                },
            },
        });
    }
}
