import { curves, LengthMetrics, router } from "@kit.ArkUI";
import { vibrator } from "@kit.SensorServiceKit";
import { common, Want } from "@kit.AbilityKit";
import { BusinessError } from "@ohos.base";
import { APP_VERSION } from "../common/constants";
import { deviceInfo } from "@kit.BasicServicesKit";
import {
    getUsername,
    initialize as initializeUserStorage,
    setUsername as setUsername,
} from "../common/profile";
import { tutorial } from "../component/tutorial";
import { contact } from "../component/contact";
import { app_share } from "../component/app_share";
import {
    BlurStrategy,
    hdsEffect,
    HdsNavigation,
    HdsNavigationTitleMode,
    HdsTabs,
    HdsTabsController,
    ScrollEffectType
} from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
@Entry
@Component
export struct user {
    private effect: TransitionEffect = TransitionEffect.OPACITY.combine(
        TransitionEffect.move(TransitionEdge.BOTTOM),
    )
        .combine(TransitionEffect.scale({ x: 0, y: 1 }))
        .animation({ curve: curves.springMotion(0.7, 0.8), duration: 1000 });

    @StorageLink("vibrationON") vibrationON: boolean = true;
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

    @State showTutorial: boolean = false;
    @State showSubmit: boolean = false;
    @State showContact: boolean = false;
    @State handlePopup: boolean = false;
    @State customPopup: boolean = false;
    @StorageLink("userName") userName: string = "";
    @State deviceName: string = "";
    aboutToAppear() {
        this.loadUserName();
    }
    async loadUserName() {
        initializeUserStorage();
        this.userName = await getUsername();
    }

    async saveUserName() {
        await setUsername(this.userName);
    }

    async resetToDeviceName() {
        await setUsername(undefined);
        await this.loadUserName();
    }

    onBackPress(): boolean | void {
        if (this.showTutorial) {
            this.showTutorial = false;
            this.triggerVibration();
            console.info("关闭教程页面");
            return true;
        }
        if (this.showSubmit) {
            this.showSubmit = false;
            this.triggerVibration();
            console.info("关闭投稿页面");
            return true;
        }
        if (this.showContact) {
            this.showContact = false;
            this.triggerVibration();
            console.info("关闭联系我们页面");
            return true;
        } else {
            return false;
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
                            Text("HmDashboard")
                                .fontWeight(600)
                                .fontSize(20)
                                .margin({ top: 10 })
                        }.margin({ top: 40 })
                        Divider()
                            .margin({ top: 20, bottom: 20 })
                            .color($r("app.color.border"))
                        Column() {
                            Row() {
                                Row() {
                                    Image($r("app.media.user"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("用户名")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                        .fontWeight(FontWeight.Medium)
                                }
                                .constraintSize({
                                    minWidth: 50,
                                })
                                TextInput({
                                    text: this.userName,
                                    placeholder: "设置用户名",
                                })
                                    .layoutWeight(1)
                                    .constraintSize({
                                        maxWidth: "80%",
                                    })
                                    .height(40)
                                    .margin({ left: 12 })
                                    .borderRadius(16)
                                    .padding({ left: 12, right: 12 })
                                    .borderWidth(0.5)
                                    .borderColor($r("app.color.border"))
                                    .backgroundColor($r("app.color.diff_background"))
                                    .border({
                                        width: 1,
                                        color: this.userName ? "#007DFF" : "#E5E5E5",
                                        radius: 16,
                                    })
                                    .onChange((value: string) => {
                                        this.userName = value;
                                        this.saveUserName();
                                    })
                                    .onSubmit(() => {
                                        this.saveUserName();
                                    })
                                Image($r("app.media.question"))
                                    .margin({ left: 12 })
                                    .height(24)
                                    .width(24)
                                    .objectFit(ImageFit.Contain)
                                    .onClick(() => {
                                        this.triggerVibration();
                                        this.handlePopup = !this.handlePopup;
                                    })
                                    .bindPopup(this.handlePopup, {
                                        message:
                                            '用于您投稿应用时的默认用户名\n详情见请"使用教程-投稿功能"',
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
                            .alignItems(VerticalAlign.Center)
                            .padding({ top: 2, left: 16, right: 16 })
                            Row() {
                                if (this.userName === this.deviceName) {
                                    Text(`当前使用设备名称: ${deviceInfo.productModel}`)
                                        .fontSize(12)
                                        .fontColor("#666")
                                        .margin({ right: 5 });
                                }
                                Text("已自动保存")
                                    .fontSize(12)
                                    .fontColor("#52C41A")
                                    .opacity(this.userName ? 1 : 0)
                                    .margin({ left: 3 })
                            }
                            .justifyContent(FlexAlign.Center)
                            .margin({ bottom: 8 })
                            Divider()
                                .color($r("app.color.border"))
                                .strokeWidth(0.5)
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.submit"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("投稿/查询应用")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.showSubmit = !this.showSubmit;
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
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
                        Column() {
                            Row() {
                                Row() {
                                    Image($r("app.media.log"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("Web更新日志")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                router.pushUrl({ url: "pages/user/web_log" });
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .color($r("app.color.border"))
                                .strokeWidth(0.5)
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.app_log"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("App更新日志")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                router.pushUrl({ url: "pages/user/app_log" });
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .strokeWidth(0.5)
                                .color($r("app.color.border"))
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.api"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("API文档说明")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                router.pushUrl({ url: "pages/user/web_api" });
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .strokeWidth(0.5)
                                .color($r("app.color.border"))
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.contact"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("联系我们")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.showContact = !this.showContact;
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .color($r("app.color.border"))
                                .strokeWidth(0.5)
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.info"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("使用教程")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.showTutorial = !this.showTutorial;
                                this.triggerVibration();
                            })
                            .height(56)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
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
                        // Divider()
                        //     .margin({ top: 20, bottom: 20 })
                        //     .color($r("app.color.border"))
                        // Text(`Version ${APP_VERSION}`)
                        //     .fontColor("#888")
                        //     .fontSize(12)
                        //     .margin(5)
                        // Text("本应用备案域名：rayawa.top")
                        //     .fontSize(12)
                        //     .fontColor("#888")
                        //     .margin(5)
                        // Column() {
                        //     Text("京ICP备2025153453号")
                        //         .fontSize(12)
                        //         .fontColor($r("app.color.diff_content"))
                        //         .onClick(() => {
                        //             this.triggerVibration();
                        //             this.openLink();
                        //         })
                        // }.margin(5)
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)
                    .margin({ top: 30, bottom: 20 })
                }
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                .width("100%")
                .height("100%")

                if (this.showSubmit) {
                    Stack() {
                        Column() {
                            Text("* 点击外部区域或向下滑动关闭页面")
                                .fontSize(14)
                                .margin({ bottom: 10 })
                                .position({ x: "40%", y: "64%" })
                                .fontColor(Color.Grey)
                        }
                        .backgroundColor(Color.Transparent)
                        .height("300%")
                        .width("300%")
                        .onClick(() => {
                            this.showSubmit = !this.showSubmit;
                        })
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        app_share()
                    }
                    .transition(this.effect)
                    .gesture(
                        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(
                            (move: GestureEvent | undefined) => {
                                if (move) {
                                    this.showSubmit = !this.showSubmit;
                                }
                            },
                        ),
                    )
                    .height("100%")
                    .width("100%");
                }
                if (this.showTutorial) {
                    Stack() {
                        Column() {
                            Text("* 点击外部区域或向下滑动关闭页面")
                                .fontSize(14)
                                .margin({ bottom: 10 })
                                .position({ x: "40%", y: "65.3%" })
                                .fontColor(Color.Grey)
                        }
                        .backgroundColor(Color.Transparent)
                        .height("300%")
                        .width("300%")
                        .onClick(() => {
                            this.showTutorial = !this.showTutorial;
                        })
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        tutorial()
                    }
                    .gesture(
                        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(
                            (move: GestureEvent | undefined) => {
                                if (move) {
                                    this.showTutorial = !this.showTutorial;
                                }
                            },
                        ),
                    )
                    .transition(this.effect)
                    .height("100%")
                    .width("100%");
                }
                if (this.showContact) {
                    Stack() {
                        Column() {
                            Text("* 点击外部区域或向下滑动关闭页面")
                                .fontSize(14)
                                .margin({ bottom: 10 })
                                .position({ x: "40%", y: "65%" })
                                .fontColor(Color.Grey)
                        }
                        .backgroundColor(Color.Transparent)
                        .height("300%")
                        .width("300%")
                        .onClick(() => {
                            this.showContact = !this.showContact;
                        })
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 1000,
                            }),
                        )
                        contact()
                    }
                    .gesture(
                        SwipeGesture({ direction: SwipeDirection.Vertical }).onAction(
                            (move: GestureEvent | undefined) => {
                                if (move) {
                                    this.showContact = !this.showContact;
                                }
                            },
                        ),
                    )
                    .transition(this.effect)
                    .height("100%")
                    .width("100%");
                }
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
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                },
            },
            content: {
                title: {
                    mainTitle: "我的",
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "settings",
                                icon: $r("sys.symbol.gearshape"),
                                isEnabled: true,
                                action: () => {
                                    this.triggerVibration();
                                    router.pushUrl({ url: "pages/user/settings" });
                                },
                            },
                        },
                    ],
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
