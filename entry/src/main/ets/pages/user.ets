import { curves, display, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { settings } from '../component/settings';
import { deviceInfo } from '@kit.BasicServicesKit';
import { getUsername, initialize as initializeUserStorage, setUsername as setUsername, } from '../common/profile';
import { contact } from '../component/contact';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { appSubmit } from '../component/appSubmit';
import { appQuery } from '../component/appQuery';
import { vibration } from '../common/vibration';
import { blurPopup } from '../component/blurPopup';

@Component
export struct user {
    @Consume('pageStack') pageStack: NavPathStack;
    onCloseSplit?: () => void;
    PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("vibrationON") vibrationON: boolean = true;
    private triggerVibration(): void {
        if (this.vibrationON) {
            vibration.dotVibration()
        }
    }

    @State showQuery: boolean = false;
    @State showSubmit: boolean = false;
    @State showContact: boolean = false;
    @State handlePopup: boolean = false;
    @State customPopup: boolean = false;
    @StorageLink("userName") userName: string = "";
    @State deviceName: string = "";

    @State WVp: number = 376;
    @State HVp: number = 376;
    aboutToAppear() {
        this.loadUserName();
        //获取屏幕尺寸
        const displayInfo = display.getDefaultDisplaySync();
        const screenWidthVp = px2vp(displayInfo.width);
        const screenHeightVp = px2vp(displayInfo.height);
        this.WVp = screenWidthVp;
        this.HVp = screenHeightVp;
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


    build() {
        HdsNavDestination() {
            Stack() {
                Scroll() {
                    Column() {
                        Blank().height(40)
                        Text("用户与应用").margin({ left: 15, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
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
                                        this.triggerVibration();
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
                                this.showSubmit = !this.showSubmit;
                                this.triggerVibration();
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
                                this.showQuery = !this.showQuery;
                                this.triggerVibration();
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
                        Text("设置").margin({ left: 15, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
                        settings()
                        Divider()
                            .margin({ top: 20, bottom: 20 })
                            .color($r("app.color.border"))
                        Text("更多").margin({ left: 15, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
                        Column() {
                            Row() {
                                Row() {
                                    Image($r("app.media.menu"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("友情链接")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.triggerVibration();
                                this.pageStack.pushPathByName("FriendPage", null)
                            })
                            .height(52)
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
                                this.showContact = true;
                                this.triggerVibration();
                            })
                            .height(52)
                            .width("100%")
                            .justifyContent(FlexAlign.SpaceBetween)
                            .padding({ left: 16, right: 16 })
                            Divider()
                                .strokeWidth(0.5)
                                .color($r("app.color.border"))
                                .margin({ left: 16, right: 16 })

                            Row() {
                                Row() {
                                    Image($r("app.media.info"))
                                        .height(24)
                                        .width(24)
                                        .objectFit(ImageFit.Contain)
                                    Text("关于应用")
                                        .fontSize(16)
                                        .margin({ left: 12 })
                                }
                                Image($r("app.media.right"))
                                    .height(16)
                                    .width(16)
                                    .objectFit(ImageFit.Contain)
                            }
                            .onClick(() => {
                                this.pageStack.pushPathByName("AboutPage", null)
                                this.triggerVibration();
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
                        Blank().height(20)
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)
                    .margin({ top: 30, bottom: 20 })
                }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM]).width("100%").height("100%")
                if (this.showSubmit || this.showQuery || this.showContact) {
                    Column()
                        .onClick(() => {
                            this.showSubmit = false;
                            this.showQuery = false;
                            this.showContact = false;
                            this.triggerVibration();
                        })
                        .width('100%')
                        .height('100%')
                        .backgroundColor(Color.Transparent)
                        .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        .transition(
                            TransitionEffect.OPACITY.animation({
                                curve: curves.springMotion(0, 1),
                                duration: 800,
                            }),
                        )
                }
                blurPopup({ isShow: $showSubmit }) { appSubmit() }
                blurPopup({ isShow: $showQuery }) { appQuery() }
                blurPopup({ isShow: $showContact }) { contact() }
            }
            .backgroundColor($r("app.color.backcolor"))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
        }
        .onBackPressed(() => {
            this.triggerVibration();
            if (this.showQuery || this.showSubmit || this.showContact) {
                this.showSubmit = false;
                this.showQuery = false;
                this.showContact = false;
                return true;
            } else {
                if (this.onCloseSplit) {
                    this.onCloseSplit();
                }
                return false;
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
                systemMaterialEffect: {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                },
            },
            content: {
                title: {
                    mainTitle: "我的",
                },
                backIcon: {
                    action: () => {
                        this.triggerVibration();
                        if (this.onCloseSplit) {
                            this.onCloseSplit();
                        }
                        this.pageStack.pop();
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
