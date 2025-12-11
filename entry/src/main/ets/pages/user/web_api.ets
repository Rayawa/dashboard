import { webview } from "@kit.ArkWeb";
import { HdsActionBar, ActionBarButton, ActionBarStyle, ExtendBarMode, HdsNavigationTitleMode } from '@kit.UIDesignKit'
import { curves, prompt, router } from "@kit.ArkUI";
import { APP_UA } from "../../common/constants";
import window from '@ohos.window';
import { motion } from '@kit.MultimodalAwarenessKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HdsNavigation, HdsNavigationAttribute, ScrollEffectType } from '@kit.UIDesignKit';
import { LengthMetrics } from '@kit.ArkUI';

@Entry
@Component
struct web_api {
    @State url: string = 'http://shenjack.top:10003/docs';
    private win: window.Window | null = null;
    scroller: Scroller = new Scroller();
    private web_controller: webview.WebviewController = new webview.WebviewController();
    @State scrollMode: NestedScrollMode = NestedScrollMode.PARENT_FIRST;
    @State mode: WebDarkMode = WebDarkMode.Auto;
    @State isLoading: boolean = false;

    // async aboutToAppear() {
    //   const customUA = webview.WebviewController.getDefaultUserAgent() + " Hm_dashboard";
    //   webview.WebviewController.setAppCustomUserAgent(customUA);
    // }
    async onPageShow(): Promise<void> {
        this.win = await window.getLastWindow(getContext());
        const isDark = this.mode === WebDarkMode.On;
        this.win.setWindowSystemBarProperties({
            statusBarColor: '#00000000',
            statusBarContentColor: isDark ? '#FFFFFF' : '#000000'
        });
    }

    build() {
        HdsNavigation() {
            Stack() {
                Scroll(this.scroller) {
                    Column() {
                        Blank()
                            .height(60)
                            .width('100%')
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                        Web({ src: this.url, controller: this.web_controller, renderMode: RenderMode.SYNC_RENDER })
                            .layoutMode(WebLayoutMode.FIT_CONTENT)
                            .nestedScroll({
                                scrollForward: NestedScrollMode.SELF_FIRST,
                                scrollBackward: NestedScrollMode.SELF_FIRST
                            })
                            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                            .domStorageAccess(true)
                            .darkMode(this.mode)
                            .forceDarkAccess(true)
                            .width('100%')
                            .backgroundColor($r('app.color.backcolor'))
                            .onPageBegin(() => this.isLoading = true)
                            .onPageEnd(() => this.isLoading = false)
                            .onControllerAttached(() => {
                                try {
                                    this.web_controller.setCustomUserAgent(APP_UA);
                                } catch {
                                }
                            });

                    }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
                }.expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])

            }
            .backgroundColor($r('app.color.backcolor'))
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
        }
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
                    mainTitle: 'API文档说明',
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: 'refresh',
                                icon: this.isLoading ? $r('sys.symbol.xmark_circle') : $r('sys.symbol.arrow_clockwise'),
                                isEnabled: true,
                                action: () => {
                                    if (this.isLoading) {
                                        this.web_controller.stop();
                                        this.isLoading = false;
                                        vibrator.isSupportEffect('haptic.effect.hard',
                                            (err: BusinessError, state: boolean) => {
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
                                        prompt.showToast({
                                            message: '已停止加载',
                                            duration: 1000
                                        });
                                    } else {
                                        this.web_controller.refresh();
                                        this.isLoading = true;
                                        vibrator.isSupportEffect('haptic.effect.hard',
                                            (err: BusinessError, state: boolean) => {
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
                                        prompt.showToast({
                                            message: '刷新中...',
                                            duration: 1000
                                        });

                                        setTimeout(() => {
                                            if (this.isLoading) {
                                                this.isLoading = false;
                                            }
                                        }, 3000);
                                    }
                                },
                            }
                        },
                        {
                            content: {
                                label: 'top',
                                icon: $r('sys.symbol.arrow_up_to_line'),
                                isEnabled: true,
                                action: () => {
                                    this.scroller.scrollTo({
                                        xOffset: 0,
                                        yOffset: 0,
                                        animation: { duration: 300, curve: Curve.Ease }
                                    })
                                    vibrator.isSupportEffect('haptic.effect.hard',
                                        (err: BusinessError, state: boolean) => {
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
                                    prompt.showToast({
                                        message: '回到顶部',
                                        duration: 500
                                    });
                                },
                            }
                        },
                    ]
                },
                backIcon: {
                    action: () => {
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
                        router.back();
                    }
                }
            }
        })
    }
}