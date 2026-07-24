import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { settings } from '../component/settings';
import { deviceInfo } from '@kit.BasicServicesKit';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername, } from '../common/profile';
import { contact } from '../component/contact';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { appSubmit } from '../component/appSubmit';
import { appQuery } from '../component/appQuery';
import { vibration } from '../common/vibration';
import { common, Want } from '@kit.AbilityKit';
import { mainPage } from '../common/constants';

@Component
export struct user {
    @Consume('pageStack') pageStack: NavPathStack;
    @StorageLink("isSplitMode") isSplitMode: boolean = false;
    @State private isBackAnimating: boolean = false;
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;
    @StorageLink("vibrationON") vibrationON: boolean = true;

    @StorageLink("showSheet") showSheet: boolean = false;
    @State currentSheet: string = "";
    @State handlePopup: boolean = false;
    @State customPopup: boolean = false;
    @StorageLink("userName") userName: string = "";
    @State deviceName: string = "";
    @StorageLink('winWidth') winWidth: number = 1260;
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
    @Builder
    sheetBuilder() {
        if (this.currentSheet === "query") appQuery()
        if (this.currentSheet === "submit") appSubmit()
        if (this.currentSheet === "contact") contact()
    }

    build() {
        HdsNavDestination() {
            Stack() {
                Scroll() {
                    Column() {
                        Blank().height(40)
                        Text("用户与应用").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
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
                                        if(this.vibrationON) vibration.dotVibration()
                                        this.handlePopup = !this.handlePopup;
                                    })
                                    .bindPopup(this.handlePopup, {
                                        message:
                                        '用于您投稿应用时提交的用户名',
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
                            .height(52)
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
                                    Text("投稿/更新应用")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.currentSheet = "submit";
                                this.showSheet = true;
                                if(this.vibrationON) vibration.dotVibration()
                            })
                            .height(52)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .color($r("app.color.border"))
                                .strokeWidth(0.5)
                                .margin({ left: 16, right: 16 })
                            Row() {
                                Row() {
                                    Image($r("app.media.search"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("查询应用")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.currentSheet = "query";
                                this.showSheet = true;
                                if(this.vibrationON) vibration.dotVibration()
                            })
                            .height(52)
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
                        Text("设置").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
                        settings()
                        Divider()
                            .margin({ top: 20, bottom: 20 })
                            .color($r("app.color.border"))
                        Text("更多").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
                        Column() {
                            OtherItem({
                                icon: $r("app.media.app_icon"),
                                title: "项目网站首页",
                                onClickAction: async () => {
                                    const ui_content = this.getUIContext();
                                    try {
                                        this.PromptAction.showToast({ message: "正在跳转...", duration: 500 });
                                        let context = ui_content.getHostContext() as common.UIAbilityContext;
                                        await context.startAbility({
                                            action: "ohos.want.action.viewData",
                                            entities: ["entity.system.browsable"],
                                            uri: mainPage.toString(),
                                        } as Want);
                                    } catch (error) {
                                        console.error("打开链接失败:", (error as BusinessError).message);
                                        this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
                                    }
                                }
                            })

                            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            OtherItem({
                                icon: $r("app.media.MeoW"),
                                title: "订阅Meow频道",
                                onClickAction: () => {
                                    try {
                                        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                                        context.openLink("https://www.chuckfang.com/MeoW/appLinking?channelId=8bbba7f53bf9458284a41d04f295450b")
                                            .catch((err: BusinessError) => {
                                                this.PromptAction.showToast({ message: "跳转失败: " + err.message });
                                            });
                                    } catch (e) {
                                        this.PromptAction.showToast({ message: "跳转错误" });
                                    }
                                }
                            })

                            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            OtherItem({
                                icon: $r("app.media.tutorial"),
                                title: "查看教程",
                                onClickAction: () => {
                                    this.pageStack.pushPathByName("TutorialPage", null);
                                }
                            })

                            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            OtherItem({
                                icon: $r("app.media.sponsor"),
                                title: "友情链接",
                                onClickAction: () => {
                                    this.pageStack.pushPathByName("FriendPage", null);
                                }
                            })

                            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            OtherItem({
                                icon: $r("app.media.contact"),
                                title: "联系我们",
                                onClickAction: () => {
                                    this.currentSheet = "contact";
                                    this.showSheet = true;
                                }
                            })

                            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            OtherItem({
                                icon: $r("app.media.info"),
                                title: "关于应用",
                                onClickAction: () => {
                                    this.pageStack.pushPathByName("AboutPage", null);
                                }
                            })
                        }
                        .width("90%")
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
                        Blank().height(10)
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)
                    .margin({ top: 30, bottom: 20 })
                }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]).width("100%").height("100%")
            }
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
        }
        .bindSheet($$this.showSheet, this.sheetBuilder(), {
            width: this.getUIContext().px2vp(this.winWidth) > 450 ? 450 : this.getUIContext().px2vp(this.winWidth),
            height: SheetSize.FIT_CONTENT,
            preferType: SheetType.CENTER,
            backgroundColor: $r('app.color.backcolor'),
            blurStyle: BlurStyle.BACKGROUND_ULTRA_THICK,
            borderWidth: 2,
            borderColor: $r("app.color.border"),
            onWillDisappear: () => {
                if(this.vibrationON) vibration.dotVibration()
                this.showSheet = false;
            },
            title: { title: this.currentSheet === "query" ? "查询应用" : this.currentSheet === "submit" ? "投稿/更新应用" : "联系我们" }
        })
        .onWillDisappear(() => {
            if(this.vibrationON) vibration.dotVibration()
            if (this.showSheet) {
                this.showSheet = false;
            }
        })
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
                systemMaterialEffect: this.immersiveTextureON ? {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                } : undefined
            },
            content: {
                title: {
                    mainTitle: "我的",
                },
                backIcon: {
                    action: () => {
                        if(this.vibrationON) vibration.dotVibration()
                        this.pageStack.pop();
                        const hasSplitPage = this.pageStack.getIndexByName("UserPage").length > 0 || this.pageStack.getIndexByName("TutorialPage").length > 0;
                        if (!hasSplitPage) this.isSplitMode = false;
                    },
                },
            },
        });

    }
}

@Builder
export function UserPageBuilder(){
    user()
}

@Component
struct OtherItem {
    @Prop icon: Resource;
    @Prop title: string;
    @StorageProp("vibrationON") vibrationON: boolean = true;

    onClickAction: () => void = () => {};

    build() {
        Column() {
            Row() {
                Row() {
                    Image(this.icon)
                        .height(24)
                        .width(24)
                        .objectFit(ImageFit.Contain)
                    Text(this.title)
                        .fontSize(16)
                        .margin({ left: 12 })
                }

                Image($r("app.media.right"))
                    .height(16)
                    .width(16)
                    .objectFit(ImageFit.Contain)
            }
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
                if (this.vibrationON) {
                    vibration.dotVibration();
                }
                this.onClickAction();
            })
        }
    }
}