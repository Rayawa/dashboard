import { curves, LengthMetrics, router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@ohos.base';
import { APP_VERSION } from '../../common/constants';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType, HdsNavigationAttribute } from '@kit.UIDesignKit';
import { preferences } from '@kit.ArkData';

@Entry
@Component
export struct settings {
    private triggerVibration(): void {
        vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
            if (err) {
                console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
                return;
            }
            console.info('Succeed in querying effect');
            if (state) {
                try {
                    vibrator.startVibration({
                        type: 'preset',
                        effectId: 'haptic.effect.hard',
                        count: 1,
                        intensity: 50,
                    }, { usage: 'touch' }, (error: BusinessError) => {
                        if (error) {
                            console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
                        } else {
                            console.info('Succeed in starting vibration');
                        }
                    });
                } catch (tryError) {
                    console.error(`An unexpected error occurred in try block: ${tryError}`);
                }
            }
        });
    }
    async openLink() {
        const url = 'https://beian.miit.gov.cn/#/Integrated/index';
        const ui_content = this.getUIContext();
        const prompt_action = ui_content.getPromptAction();
        ui_content.showAlertDialog({
            title: '是否跳转到浏览器',
            message: '即将访问\nICP/IP地址/域名信息备案管理系统',
            primaryButton: {
                value: '取消',
                fontColor: Color.Red,
                action: () => {
                    console.log('点击了取消按钮');
                },
            },
            secondaryButton: {
                value: '确定',
                fontColor: Color.Blue,
                action: async (): Promise<void> => {
                    try {
                        prompt_action.showToast({ message: '正在跳转...', duration: 500 });
                        let context = ui_content.getHostContext() as common.UIAbilityContext;
                        await context.startAbility({
                            action: "ohos.want.action.viewData",
                            entities: ["entity.system.browsable"],
                            uri: url
                        } as Want);
                    } catch (error) {
                        console.error('打开链接失败:', (error as BusinessError).message);
                        prompt_action.showToast({ message: '打开链接失败', duration: 1000 });
                    }
                }
            },
        })
    }
    @StorageLink('defaultSiteT') defaultSiteT: boolean = false;
    @StorageLink('holdCheckOn') holdCheckOn: boolean = true;
    @StorageLink('buttonPositionRight') buttonPositionRight: boolean = false;
    build() {
        HdsNavigation() {
            Stack() {
                Scroll() {
                    Column() {
                        Column() {
                            Text('页面施工中')
                                .fontSize(30)
                                .fontWeight(900)
                                .margin({bottom:40})
                            Image($r('app.media.app_icon'))
                                .height(100)
                                .width(100)
                                .borderRadius($r('sys.float.corner_radius_level6'))
                            Text('应用看板')
                                .fontWeight(800)
                                .fontSize(30)
                                .margin({ top: 20 })
                                .fontColor($r('app.color.diff_content'))
                            Text('Gallery Dashboard').fontWeight(600).fontSize(20).margin({ top: 10 })
                        }

                        Divider().margin({ top: 20, bottom: 20 }).color($r('app.color.border'))

                        Column() {
                            Row() {
                                Row({ space:12 }) {
                                    Image($r('app.media.default')).height(24).width(24).objectFit(ImageFit.Contain)
                                    Text('默认站点').fontSize(16)
                                }
                                Row({ space:8 }){
                                    Text('S站').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                    Toggle({ type: ToggleType.Switch, isOn: false })
                                        .selectedColor($r('app.color.diff_content'))
                                        .switchStyle({unselectedColor:$r('app.color.diff_content')})
                                        .onChange(async (isOn: boolean) => {
                                            if (isOn) {
                                                this.defaultSiteT = true;
                                                this.triggerVibration();

                                            } else {
                                                this.defaultSiteT = false;
                                                this.triggerVibration();

                                            }
                                        })
                                    Text('T站').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                }
                            }.height(56).width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })

                            Divider().color($r('app.color.border')).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            Row() {
                                Row({ space:12 }) {
                                    Image($r('app.media.vibrate')).height(24).width(24).objectFit(ImageFit.Contain)
                                    Text('震感反馈').fontSize(16)
                                }
                                Row({ space:8 }){
                                    Text('关').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                    Toggle({ type: ToggleType.Switch, isOn:true })
                                        .selectedColor($r('app.color.diff_content'))
                                        .onChange(async (isOn: boolean) => {
                                            if (isOn) {
                                                this.holdCheckOn = false;
                                                this.triggerVibration();
                                            } else {
                                                this.holdCheckOn = true;
                                                this.triggerVibration();
                                            }
                                        })
                                    Text('开').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                }
                            }.height(56).width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })

                            Divider().color($r('app.color.border')).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            Row() {
                                Row({ space:12 }) {
                                    Image($r('app.media.hand')).height(24).width(24).objectFit(ImageFit.Contain)
                                    Text('智感握持').fontSize(16)
                                }
                                Row({ space:8 }){
                                    Text('关').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                    Toggle({ type: ToggleType.Switch, isOn:true })
                                        .selectedColor($r('app.color.diff_content'))
                                        .onChange(async (isOn: boolean) => {
                                            if (isOn) {
                                                this.holdCheckOn = false;
                                                this.triggerVibration();
                                            } else {
                                                this.holdCheckOn = true;
                                                this.triggerVibration();
                                            }
                                        })
                                    Text('开').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                }
                            }.height(56).width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })

                            Divider().color($r('app.color.border')).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            Row() {
                                Row({ space:12 }) {
                                    Image($r('app.media.button')).height(24).width(24).objectFit(ImageFit.Contain)
                                    Text('按钮默认位置').fontSize(16)
                                }
                                Row({ space:8 }){
                                    Text('左').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                    Toggle({ type: ToggleType.Switch, isOn: true })
                                        .selectedColor($r('app.color.diff_content'))
                                        .switchStyle({unselectedColor:$r('app.color.diff_content')})
                                        .onChange(async (isOn: boolean) => {
                                            if (isOn) {
                                                this.buttonPositionRight = false;
                                                this.triggerVibration();
                                            } else {
                                                this.buttonPositionRight = true;
                                                this.triggerVibration();
                                            }
                                        })
                                    Text('右').fontSize(14).fontColor('#888').width(24).textAlign(TextAlign.Center)
                                }
                            }.height(56).width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })

                            Divider().color($r('app.color.border')).strokeWidth(0.5).margin({ left: 16, right: 16 })

                            Row() {
                                Row({ space:12 }) {
                                    Image($r('app.media.theme')).height(24).width(24).objectFit(ImageFit.Contain)
                                    Text('主题').fontSize(16)
                                }
                            }.height(56).width('100%').justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })
                        }
                        .borderWidth(0.5)
                        .borderColor($r('app.color.border'))
                        .backgroundColor($r('app.color.background'))
                        .borderRadius(16)
                        .shadow({
                            radius: 8,
                            color: '#1a000000',
                            offsetX: 0,
                            offsetY: 2
                        })
                        .width('90%')

                        Divider().margin({ top: 20, bottom: 20 }).color($r('app.color.border'))



                        Text(`Version ${APP_VERSION}`)
                            .fontColor('#888')
                            .fontSize(12)
                            .margin(5)
                        Text('本应用备案域名：rayawa.top').fontSize(12).fontColor('#888').margin(5)
                        Column() {
                            Text('京ICP备2025153453号')
                                .fontSize(12)
                                .fontColor($r('app.color.diff_content'))
                                .onClick(() => {
                                    this.triggerVibration();
                                    this.openLink();
                                })
                        }
                        .margin(5)
                    }
                    .width('100%')
                    .alignItems(HorizontalAlign.Center)
                    .margin({ top: 60, bottom: 20 })
                }
                .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                .width('100%')
                .height('100%')

            }
            .backgroundColor($r('app.color.backcolor'))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width('100%')
            .height('100%')
        }
        .navBarWidth('100%')
        .titleMode(HdsNavigationTitleMode.MINI)
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20)
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                            subTitleColor: $r('sys.color.font_secondary')
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        },
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        }
                    }
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r('sys.color.font_primary'),
                            subTitleColor: $r('sys.color.font_secondary')
                        },
                        menuStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        },
                        backIconStyle: {
                            backgroundColor: $r('sys.color.comp_background_tertiary'),
                            iconColor: $r('sys.color.icon_primary')
                        }
                    }
                }
            },
            content: {
                title: {
                    mainTitle: '设置',
                },
                backIcon: {
                    action: () => {
                        this.triggerVibration();
                        router.back();
                    }
                }
            }
        })

    }
}