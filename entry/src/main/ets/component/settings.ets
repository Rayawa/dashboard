import { vibration } from '../common/vibration';
import { webview } from '@kit.ArkWeb';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import {
    initializeSettings,
    setButtonPosition,
    setHoldCheckEnabled,
    setImmersiveTexture,
    setTabBarAuto,
    setVibrationEnabled
} from '../common/SettingsStorage';
import { deviceInfo } from "@kit.BasicServicesKit";

@Component
export struct settings {
    private context = getContext(this) as common.UIAbilityContext;

    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = false;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @StorageLink("tabBarAutoON") tabBarAutoON: boolean = true;
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;

    @State handlePopupTrash: boolean = false;

    async aboutToAppear() {
        initializeSettings();
        if(deviceInfo.sdkApiVersion >= 23){
            console.info("settings, api23 true! API: ", deviceInfo.sdkApiVersion)
        } else {
            this.immersiveTextureON = false;
            console.info("settings, api23 false! API: ", deviceInfo.sdkApiVersion)
        }
    }

    private trash() {
        const ui_content = this.getUIContext();
        ui_content.showAlertDialog({
            message: "此操作会关闭应用",
            primaryButton: { value: "取消", action: () => {} },
            secondaryButton: {
                value: "继续",
                action: async () => {
                    try {
                        webview.WebStorage.deleteAllData();
                        webview.WebCookieManager.deleteEntireCookie();
                        this.context.terminateSelf();
                    } catch (error) {
                        const err = error as BusinessError;
                        console.error(`ErrorCode: ${err.code}, Message: ${err.message}`);
                    }
                },
            },
        });
    }

    build() {
        Column() {
            SettingItem({
                icon: $r("app.media.vibrate"),
                title: "全局振动反馈",
                isOn: this.vibrationON,
                onToggle: async (val) => { await setVibrationEnabled(val); this.vibrationON = val; }
            })

            SettingItem({
                icon: $r("app.media.button"),
                title: "按钮默认位置",
                isOn: this.buttonPositionRIGHT,
                both: true,
                offText: "左",
                onText: "右",
                onToggle: async (val) => { await setButtonPosition(val); this.buttonPositionRIGHT = val; }
            })

            SettingItem({
                icon: $r("app.media.hand"),
                title: "按钮智感握持",
                isOn: this.holdCheckON,
                promptMsg: "󰗫适人握持󰗫",
                onToggle: async (val) => { await setHoldCheckEnabled(val); this.holdCheckON = val; }
            })

            SettingItem({
                icon: $r("app.media.autoBar"),
                title: "自动隐藏底部栏",
                isOn: this.tabBarAutoON,
                onToggle: async (val) => { await setTabBarAuto(val); this.tabBarAutoON = val; }
            })

            if(deviceInfo.sdkApiVersion >= 23){
                SettingItem({
                    icon: $r("app.media.immersive"),
                    title: "使用沉浸式材质",
                    isOn: this.immersiveTextureON,
                    promptMsg: "开启沉浸式材质将增加应用功耗，\n如遇卡顿建议关闭。",
                    onToggle: async (val) => { await setImmersiveTexture(val); this.immersiveTextureON = val; }
                })

            }

            this.TrashItem()

        }
        .width("90%")
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .shadow({ radius: 8, color: "#1a000000", offsetY: 2 })
    }

    @Builder
    TrashItem() {
        Row() {
            Row({ space: 12 }) {
                Image($r("app.media.trash")).height(24).width(24).objectFit(ImageFit.Contain)
                Text("清除缓存").fontSize(16)
            }
            Image($r("app.media.question"))
                .height(24).width(24).objectFit(ImageFit.Contain)
                .onClick(() => {
                    if (this.vibrationON) vibration.dotVibration();
                    this.handlePopupTrash = !this.handlePopupTrash;
                })
                .bindPopup(this.handlePopupTrash, {
                    message: '如遇页面加载失败时可尝试清除缓存',
                    onStateChange: (e) => { if (!e.isVisible) this.handlePopupTrash = false }
                })
        }
        .height(52).width("100%").justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })
        .onClick(() => {
            if (this.vibrationON) vibration.dotVibration();
            this.trash();
        })
    }
}

@Component
struct SettingItem {
    @Prop icon: Resource;
    @Prop title: string;
    @Prop isOn: boolean;
    @Prop both: boolean;
    @Prop onText: string = "开";
    @Prop offText: string = "关";
    @Prop promptMsg: string = "";
    @StorageProp("vibrationON") canVibrate: boolean = true;

    onToggle: (isOn: boolean) => Promise<void> = async () => {};

    build() {
        Column() {
            Row() {
                Row({ space: 12 }) {
                    Image(this.icon).height(24).width(24).objectFit(ImageFit.Contain)
                    Text(this.title).fontSize(16)
                }
                Row({ space: 8 }) {
                    Text(this.offText).fontSize(14).fontColor("#888").width(24).textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
                        .selectedColor($r("app.color.diff_content"))
                        .switchStyle({
                            unselectedColor: this.both? $r("app.color.diff_content") : undefined
                        })
                        .onChange(async (checked: boolean) => {
                            if (this.canVibrate) vibration.dotVibration();
                            await this.onToggle(checked);
                            if (checked && this.promptMsg !== "") {
                                promptAction.showToast({
                                    message: this.promptMsg,
                                    duration: 1000
                                });
                            }
                        })
                    Text(this.onText).fontSize(14).fontColor("#888").width(24).textAlign(TextAlign.Center)
                }
            }
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })

            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })
        }
    }
}