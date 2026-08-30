import { vibration } from '../common/vibration';
import { common } from '@kit.AbilityKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import {
  setButtonPosition,
  setHoldCheckEnabled,
  setImmersiveTexture,
  setTabBarAuto,
  setVibrationEnabled
} from '../common/storage';
import { clearCompleteCache, getCacheSizeBytes } from '../common/CacheService';
import { formatBytes } from '../common/format';
import { showToastSafely } from '../common/safeUi';

@Component
export struct settings {
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("holdCheckON") holdCheckON: boolean = false;
    @StorageLink("buttonPositionRIGHT") buttonPositionRIGHT: boolean = false;
    @StorageLink("tabBarAutoON") tabBarAutoON: boolean = false;
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;

    @State handlePopupTrash: boolean = false;
    @State cacheSize: string = '计算中…';

    async aboutToAppear() {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        this.cacheSize = formatBytes(getCacheSizeBytes(context));
        if(deviceInfo.sdkApiVersion >= 23){
            console.info('[Dashboard][component/settings][INFO]', "settings, api23 true! API: ", deviceInfo.sdkApiVersion)
        } else {
            await setImmersiveTexture(false);
            console.info('[Dashboard][component/settings][INFO]', "settings, api23 false! API: ", deviceInfo.sdkApiVersion)
        }
    }

    private trash() {
        const ui_content = this.getUIContext();
        const prompt = ui_content.getPromptAction();
        try {
            ui_content.showAlertDialog({
                message: "将清除 API 离线缓存、S站网页存储与 Cookie。用户名和设置会保留。",
                primaryButton: { value: "取消", action: () => {} },
                secondaryButton: {
                    value: "继续",
                    action: async () => {
                        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
                        try {
                            await clearCompleteCache(context);
                            showToastSafely(prompt, '缓存已完全清除', 1800, 'Settings');
                        } catch (error) {
                            console.error('[Dashboard][component/settings][ERROR]', `清除缓存失败: ${JSON.stringify(error)}`);
                            showToastSafely(prompt, '部分缓存文件正在使用，请稍后重试', 2200, 'Settings');
                        }
                        this.cacheSize = formatBytes(getCacheSizeBytes(context));
                    },
                },
            });
        } catch (error) {
            console.error('[Dashboard][component/settings][ERROR]', `清除缓存确认窗口显示失败: ${JSON.stringify(error)}`);
            showToastSafely(prompt, '暂时无法打开清除缓存窗口，请稍后重试', 2000, 'Settings');
        }
    }

    build() {
        Column() {
            SettingItem({
                icon: $r("app.media.vibrate"),
                title: "全局振动反馈",
                isOn: this.vibrationON,
                onToggle: async (val) => { await setVibrationEnabled(val); }
            })
            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })


            if(canIUse('SystemCapability.MultimodalAwareness.Motion')){
                SettingItem({
                    icon: $r("app.media.button"),
                    title: "按钮默认位置",
                    isOn: this.buttonPositionRIGHT,
                    both: true,
                    offText: "左",
                    onText: "右",
                    onToggle: async (val) => { await setButtonPosition(val); }
                })
                Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })

                SettingItem({
                    icon: $r("app.media.hand"),
                    title: "按钮智感握持",
                    isOn: this.holdCheckON,
                    promptMsg: "󰗫适人握持󰗫",
                    onToggle: async (val) => { await setHoldCheckEnabled(val); }
                })
                Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })
            }

            SettingItem({
                icon: $r("app.media.autoBar"),
                title: "自动隐藏底部栏",
                isOn: this.tabBarAutoON,
                onToggle: async (val) => { await setTabBarAuto(val); }
            })
            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })


            SettingItem({
                icon: $r("app.media.immersive"),
                title: "使用沉浸式材质",
                isOn: this.immersiveTextureON,
                promptMsg: "开启沉浸式材质将增加应用功耗，\n如遇卡顿建议关闭。",
                onToggle: async (val) => { await setImmersiveTexture(val); }
            })
            Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ left: 16, right: 16 })


            this.TrashItem()

        }
        .width("90%")
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetY: 2 })
        .accessibilityGroup(true)
        .accessibilityText('应用设置')
    }

    @Builder
    TrashItem() {
        Row() {
            Row({ space: 12 }) {
                Image($r("app.media.trash")).height(24).width(24).objectFit(ImageFit.Contain)
                    .accessibilityText('清除缓存图标')
                Text("清除缓存").fontSize(16)
                    .accessibilityText('清除缓存')
            }
            Row({ space: 8 }) {
                Text(this.cacheSize)
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(`缓存文件总大小${this.cacheSize}`)
                Image($r("app.media.question"))
                    .height(24).width(24).objectFit(ImageFit.Contain)
                    .accessibilityText('查看清除缓存说明')
                    .onClick(() => {
                        if (this.vibrationON) vibration.dotVibration();
                        this.handlePopupTrash = !this.handlePopupTrash;
                    })
                    .monopolizeEvents(true)
                    .bindPopup(this.handlePopupTrash, {
                        message: '清除 API 离线缓存、网页存储与 Cookie；用户名和设置不会被删除',
                        onStateChange: (e) => { if (!e.isVisible) this.handlePopupTrash = false }
                    })
            }
        }
        .height(52).width("100%").justifyContent(FlexAlign.SpaceBetween).padding({ left: 16, right: 16 })
        .onClick(() => {
            if (this.vibrationON) vibration.dotVibration();
            this.trash();
        })
        .accessibilityGroup(true)
        .accessibilityText(`清除缓存，当前缓存文件总大小${this.cacheSize}`)
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
    @StorageLink("vibrationON") canVibrate: boolean = true;

    onToggle: (isOn: boolean) => Promise<void> = async () => {};

    build() {
        Column() {
            Row() {
                Row({ space: 12 }) {
                    Image(this.icon).height(24).width(24).objectFit(ImageFit.Contain)
                        .accessibilityText(`${this.title}图标`)
                    Text(this.title).fontSize(16)
                        .accessibilityText(this.title)
                }
                Row({ space: 8 }) {
                    Text(this.offText).fontSize(14).fontColor($r('app.color.v3_text_secondary')).width(24).textAlign(TextAlign.Center)
                    Toggle({ type: ToggleType.Switch, isOn: this.isOn })
                        .selectedColor($r("app.color.diff_content"))
                        .switchStyle({
                            unselectedColor: this.both? $r("app.color.diff_content") : undefined
                        })
                        .accessibilityText(`${this.title}开关，当前${this.isOn ? this.onText : this.offText}`)
                        .onChange(async (checked: boolean) => {
                            if (this.canVibrate) vibration.dotVibration();
                            await this.onToggle(checked);
                            if (checked && this.promptMsg !== "") {
                                this.getUIContext().getPromptAction().showToast({
                                    message: this.promptMsg,
                                    duration: 1000
                                });
                            }
                        })
                    Text(this.onText).fontSize(14).fontColor($r('app.color.v3_text_secondary')).width(24).textAlign(TextAlign.Center)
                }
            }
            .height(52)
            .width("100%")
            .justifyContent(FlexAlign.SpaceBetween)
            .padding({ left: 16, right: 16 })
            .accessibilityGroup(true)
            .accessibilityText(`${this.title}设置`)

        }
    }
}
