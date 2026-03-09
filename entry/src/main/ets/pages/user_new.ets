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
    HdsNavigation,
    HdsNavigationTitleMode,
    ScrollEffectType,
    HdsNavigationAttribute,
} from "@kit.UIDesignKit";

@Entry
@Component
export struct UserPage {
    // 材质转场动画
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


    // 1. API 23 风格卡片容器
    @Builder
    CardWrapper(content: CustomBuilder) {
        Column() {
            // content()
        }
        .width("92%")
        .backgroundBlurStyle(BlurStyle.COMPONENT_ULTRA_THIN, {
            colorMode: ThemeColorMode.SYSTEM,
            adaptiveColor: AdaptiveColor.AVERAGE
        })
        .backgroundColor('rgba(255, 255, 255, 0.6)') // 即使在暗色模式下也会通过材质自适应
        .borderRadius(24)
        .borderWidth(0.5)
        .borderColor('rgba(255, 255, 255, 0.2)')
        .margin({ top: 16 })
        .shadow({
            radius: 20,
            color: 'rgba(0, 0, 0, 0.05)',
            offsetY: 8
        })
    }

    // 2. 通用列表项
    @Builder
    MenuItem(icon: Resource, title: string, action: () => void, showDivider: boolean = true) {
        Column() {
            Row() {
                Row() {
                    Image(icon).height(22).width(22).objectFit(ImageFit.Contain)
                    Text(title).fontSize(16).margin({ left: 14 }).fontWeight(FontWeight.Medium)
                }
                Image($r("app.media.right")).height(14).width(14).opacity(0.4)
            }
            .width("100%")
            .height(56)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
                this.triggerVibration();
                action();
            })

            if (showDivider) {
                Divider()
                    .color('rgba(0,0,0,0.05)')
                    .strokeWidth(0.5)
                    .margin({ left: 52, right: 16 })
            }
        }
    }

    // 3. 弹窗背景材质层
    @Builder
    OverlayLayer(title: string, closeAction: () => void) {
        Stack() {
            Column() {
                Text("* 向下滑动或点击空白关闭")
                    .fontSize(12)
                    .fontColor(Color.Gray)
                    .margin({ bottom: 20 })
            }
            .width('100%')
            .height('100%')
            .justifyContent(FlexAlign.End)
            .backgroundBlurStyle(BlurStyle.COMPONENT_THICK) // 背景深度模糊
            .onClick(closeAction)
        }
        .width('100%')
        .height('100%')
    }

    build() {
        HdsNavigation() {
            Stack() {
                Scroll() {
                    Column() {
                        // 用户设置卡片
                        this.CardWrapper(() => {
                            Column() {
                                Row() {
                                    Image($r("app.media.user")).height(22).width(22)
                                    TextInput({ text: this.userName, placeholder: "设置用户名" })
                                        .layoutWeight(1)
                                        .margin({ left: 12 })
                                        .backgroundColor(Color.Transparent)
                                        .onChange((v) => { this.userName = v; setUsername(v); })

                                    Image($r("app.media.question")).height(20).width(20)
                                        .onClick(() => { this.handlePopup = !this.handlePopup })
                                        .bindPopup(this.handlePopup, {
                                            message: "用于投稿时的默认名称",
                                            onStateChange: (e) => { if (!e.isVisible) this.handlePopup = false }
                                        })
                                }
                                .height(64)
                                .padding({ left: 16, right: 16 })

                                Row() {
                                    Text("已自动保存").fontSize(11).fontColor("#52C41A").opacity(this.userName ? 0.8 : 0)
                                }
                                .width('100%').justifyContent(FlexAlign.End).padding({ right: 16, bottom: 8 })

                                Divider().color('rgba(0,0,0,0.05)').margin({ left: 16, right: 16 })

                                this.MenuItem($r("app.media.submit"), "投稿/查询应用", () => { this.showSubmit = true }, false)
                            }
                        })

                        // 菜单列表卡片
                        this.CardWrapper(() => {
                            Column() {
                                this.MenuItem($r("app.media.log"), "Web更新日志", () => { router.pushUrl({ url: "pages/user/web_log" }) })
                                this.MenuItem($r("app.media.app_log"), "App更新日志", () => { router.pushUrl({ url: "pages/user/app_log" }) })
                                this.MenuItem($r("app.media.api"), "API文档说明", () => { router.pushUrl({ url: "pages/user/web_api" }) })
                                this.MenuItem($r("app.media.contact"), "联系我们", () => { this.showContact = true })
                                this.MenuItem($r("app.media.info"), "使用教程", () => { this.showTutorial = true })
                                this.MenuItem($r("app.media.settings"), "设置", () => { router.pushUrl({ url: "pages/user/settings" }) }, false)
                            }
                        })

                        Text(`Version ${APP_VERSION}`).fontSize(12).fontColor(Color.Gray).margin({ top: 30, bottom: 20 }).opacity(0.5)
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)
                }
                .edgeEffect(EdgeEffect.Spring)

                // 动态叠加层 (投稿/教程/联系)
                if (this.showSubmit || this.showTutorial || this.showContact) {
                    Stack() {
                        if (this.showSubmit) {
                            this.OverlayLayer("投稿", () => { this.showSubmit = false })
                            app_share()
                        } else if (this.showTutorial) {
                            this.OverlayLayer("教程", () => { this.showTutorial = false })
                            tutorial()
                        } else if (this.showContact) {
                            this.OverlayLayer("联系", () => { this.showContact = false })
                            contact()
                        }
                    }
                    .transition(this.effect)
                    .zIndex(10)
                }
            }
            .backgroundColor($r("sys.color.ohos_id_color_sub_background")) // API 23 推荐的沉浸式背景色
            .width("100%")
            .height("100%")
        }
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
                    mainTitle: "我的",
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "settings",
                                icon: $r("app.media.settings"),
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