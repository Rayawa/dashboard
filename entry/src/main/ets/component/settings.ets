import { vibration } from '../common/vibration';
import { common } from '@kit.AbilityKit';
import {
    setImmersiveMaterialLevel, setUsername, setVibrationLevel
} from '../common/storage';
import { clearCompleteCache, getCacheSizeBytes } from '../common/CacheService';
import { formatBytes } from '../common/format';
import { showToastSafely } from '../common/safeUi';
import {
    HdsListItemCard, IconSize, PrefixIcon
} from '@kit.UIDesignKit';
import {
    LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
    LIST_ITEM_PREFIX_MARGIN,
    LIST_ITEM_SUFFIX_MARGIN,
} from '../common/constants';

@Component
export struct settings {
    @StorageLink('vibrationLevel') vibrationLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: number = 1;
    @StorageLink('username') username: string = '';

    @State handlePopupTrash: boolean = false;
    @State cacheSize: string = '计算中…';
    @State showUsernameHelp: boolean = false;
    @State private contentWidth: number = 0;

    private vibrationPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.vibrate') },
    });

    private materialPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.immersive') },
    });

    private usernamePrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.user') },
    });

    private trashPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.trash') },
    });

    aboutToAppear(): void {
        const context =
            this.getUIContext().getHostContext() as common.UIAbilityContext;

        this.cacheSize = formatBytes(getCacheSizeBytes(context));
    }

    private trash(): void {
        const uiContent = this.getUIContext();
        const prompt = uiContent.getPromptAction();

        try {
            uiContent.showAlertDialog({
                message: '将清除 API 离线缓存、S站网页存储与 Cookie。用户名和设置会保留。',
                primaryButton: {
                    value: '取消',
                    action: () => {
                    }
                },
                secondaryButton: {
                    value: '继续',
                    action: async () => {
                        const context =
                            this.getUIContext().getHostContext() as common.UIAbilityContext;

                        try {
                            await clearCompleteCache(context);

                            showToastSafely(
                                prompt,
                                '缓存已完全清除',
                                1800,
                                'Settings'
                            );
                        } catch (error) {
                            console.error(
                                '[Dashboard][component/settings][ERROR]',
                                `清除缓存失败: ${JSON.stringify(error)}`
                            );

                            showToastSafely(
                                prompt,
                                '部分缓存文件正在使用，请稍后重试',
                                2200,
                                'Settings'
                            );
                        }

                        this.cacheSize =
                            formatBytes(getCacheSizeBytes(context));
                    },
                },
            });
        } catch (error) {
            console.error(
                '[Dashboard][component/settings][ERROR]',
                `清除缓存确认窗口显示失败: ${JSON.stringify(error)}`
            );

            showToastSafely(
                prompt,
                '暂时无法打开清除缓存窗口，请稍后重试',
                2000,
                'Settings'
            );
        }
    }

    build() {
        Column() {
            this.UsernameItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            this.VibrationLevelItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            this.MaterialLevelItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            this.TrashItem()
        }
        .width('100%')
        .backgroundColor($r('app.color.v3_surface'))
        .borderRadius(16)
        .borderWidth(0.5)
        .borderColor($r('app.color.border'))
        .shadow({
            radius: 8,
            color: $r('app.color.v3_shadow'),
            offsetY: 2
        })
        .clip(true)
        .onAreaChange((_oldValue: Area, newValue: Area): void => {
            this.contentWidth = Number(newValue.width);
        })
        .accessibilityGroup(true)
        .accessibilityText('应用设置')
    }

    private isNarrowSettings(): boolean {
        return this.contentWidth > 0 && this.contentWidth < 330;
    }

    private vibrationLevelName(): string {
        if (this.vibrationLevel === 0) {
            return '关闭';
        }

        if (this.vibrationLevel === 1) {
            return '灵动';
        }

        return '硬朗';
    }

    @Builder
    VibrationLevelItem() {
        HdsListItemCard({
            prefixItem: this.vibrationPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.VibrationLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `振动强度设置`,
            },
        })
    }

    @Builder
    VibrationLevelContent() {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('振动强度')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('振动强度')

            Column({ space: 1 }) {
                Slider({
                    value: $$this.vibrationLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(200)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode) => {
                        const nextLevel = Math.round(value);

                        if (mode === SliderChangeMode.Click ||
                            mode === SliderChangeMode.End) {
                            vibration.dotVibration();

                            setVibrationLevel(nextLevel).catch((error: Error) => {
                                console.error(
                                    '[Dashboard][component/settings][ERROR]',
                                    `保存振动强度失败: ${error.message}`
                                );
                            });
                        }
                    })
                    .accessibilityText(
                        `振动强度，当前${this.vibrationLevelName()}，共三档`
                    )

                Row() {
                    this.VibrationLevelLabel('关闭', 0)
                    this.VibrationLevelLabel('灵动', 1)
                    this.VibrationLevelLabel('硬朗', 2)
                }
                .width(200)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(200)
            .margin({
                top: this.isNarrowSettings() ? 4 : 0
            })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(
            `振动强度，当前${this.vibrationLevelName()}`
        )
    }

    @Builder
    VibrationLevelLabel(label: string, level: number) {
        Text(label)
            .fontSize(12)
            .fontWeight(
                this.vibrationLevel === level ?
                    FontWeight.Medium :
                    FontWeight.Regular
            )
            .fontColor(
                this.vibrationLevel === level ?
                    $r('app.color.diff_content') :
                    $r('app.color.v3_text_secondary')
            )
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(
                `${label}振动${this.vibrationLevel === level ? '，已选择' : ''}`
            )
    }

    private materialLevelName(): string {
        if (this.immersiveMaterialLevel === 2) {
            return '流畅';
        }

        if (this.immersiveMaterialLevel === 1) {
            return '轻柔';
        }

        return '精美';
    }

    @Builder
    MaterialLevelItem() {
        HdsListItemCard({
            prefixItem: this.materialPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.MaterialLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `材质等级设置`,
            },
        })
    }

    @Builder
    MaterialLevelContent() {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('材质等级')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('材质等级')

            Column({ space: 1 }) {
                Slider({
                    value: 2 - this.immersiveMaterialLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(200)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode) => {
                        const nextLevel = 2 - Math.round(value);

                        if (mode === SliderChangeMode.Click ||
                            mode === SliderChangeMode.End) {
                            this.immersiveMaterialLevel = nextLevel;

                            vibration.dotVibration();

                            setImmersiveMaterialLevel(nextLevel).catch((error: Error) => {
                                console.error(
                                    '[Dashboard][component/settings][ERROR]',
                                    `保存材质等级失败: ${error.message}`
                                );
                            });
                        }
                    })
                    .accessibilityText(
                        `材质等级，当前${this.materialLevelName()}，共三档`
                    )

                Row() {
                    this.MaterialLevelLabel('流畅', 2)
                    this.MaterialLevelLabel('轻柔', 1)
                    this.MaterialLevelLabel('精美', 0)
                }
                .width(200)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(200)
            .margin({
                top: this.isNarrowSettings() ? 4 : 0
            })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(
            `材质等级，当前${this.materialLevelName()}`
        )
    }

    @Builder
    MaterialLevelLabel(label: string, level: number) {
        Text(label)
            .fontSize(12)
            .fontWeight(
                this.immersiveMaterialLevel === level ?
                    FontWeight.Medium :
                    FontWeight.Regular
            )
            .fontColor(
                this.immersiveMaterialLevel === level ?
                    $r('app.color.diff_content') :
                    $r('app.color.v3_text_secondary')
            )
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(
                `${label}材质${
                this.immersiveMaterialLevel === level ?
                    '，已选择' :
                    ''
                }`
            )
    }

    @Builder
    UsernameItem() {
        HdsListItemCard({
            prefixItem: this.usernamePrefixItem,
            textItem: {
                customBuilder: () => {
                    this.UsernameContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 108 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `用户名设置，当前${this.username || 'HarmonyOS用户'}`,
            },
        })
    }

    @Builder
    UsernameContent() {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('用户名')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('用户名')

            Row({ space: 8 }) {
                TextInput({
                    text: this.username,
                    placeholder: 'HarmonyOS用户'
                })
                    .layoutWeight(1)
                    .constraintSize({
                        minWidth: 120
                    })
                    .height(40)
                    .enableKeyboardOnFocus(false)
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .onChange((value: string) => {
                        this.username = value;

                        setUsername(value.trim())
                            .catch((error: Error) => {
                                console.error(
                                    '[Dashboard][component/settings][ERROR]',
                                    `自动保存用户名失败: ${error.message}`
                                );
                            });
                    })
                    .accessibilityText(
                        `用户名输入框，当前用户名为${this.username || 'HarmonyOS用户'}`
                    )

                Image($r('app.media.question'))
                    .height(22)
                    .width(22)
                    .objectFit(ImageFit.Contain)
                    .clickEffect({
                        level: ClickEffectLevel.LIGHT,
                        scale: 0.9
                    })
                    .onClick(() => {
                        vibration.dotVibration();
                        this.showUsernameHelp = !this.showUsernameHelp;
                    })
                    .bindPopup(this.showUsernameHelp, {
                        message:
                        '此用户名会随投稿与更新请求提交；留空时显示为设备名称',
                        onStateChange: (event) => {
                            if (!event.isVisible) {
                                this.showUsernameHelp = false;
                            }
                        },
                    })
                    .accessibilityText('查看用户名说明')
            }
            .width(this.isNarrowSettings() ? '100%' : 204)
            .margin({
                top: this.isNarrowSettings() ? 4 : 0
            })
        }
        .padding({ right: 7 })
        .width('100%')
        .accessibilityGroup(true)
        .accessibilityText(
            `用户名设置，当前${this.username || 'HarmonyOS用户'}`
        )
    }

    @Builder
    TrashItem() {
        HdsListItemCard({
            prefixItem: this.trashPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.TrashContent()
                },
            },
            onClick: () => {
                vibration.dotVibration();
                this.trash();
            },
            cardHeight: 52,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText:
                `清除缓存，当前缓存文件总大小：${this.cacheSize}`,
            },
        })
    }

    @Builder
    TrashContent() {
        Flex({
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('清除缓存')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .accessibilityText('清除缓存')

            Row({ space: 8 }) {
                Text(`缓存文件总大小：${this.cacheSize}`)
                    .fontSize(13)
                    .fontColor($r('app.color.v3_text_secondary'))
                    .accessibilityText(
                        `缓存文件总大小${this.cacheSize}`
                    )

                Image($r('app.media.question'))
                    .height(24)
                    .width(24)
                    .objectFit(ImageFit.Contain)
                    .accessibilityText('查看清除缓存说明')
                    .clickEffect({
                        level: ClickEffectLevel.LIGHT,
                        scale: 0.9
                    })
                    .onClick(() => {
                        if (this.vibrationLevel > 0) {
                            vibration.dotVibration();
                        }

                        this.handlePopupTrash =
                            !this.handlePopupTrash;
                    })
                    .monopolizeEvents(true)
                    .bindPopup(this.handlePopupTrash, {
                        message:
                        '清除 API 离线缓存、网页存储与 Cookie；用户名和设置不会被删除',
                        onStateChange: (event) => {
                            if (!event.isVisible) {
                                this.handlePopupTrash = false;
                            }
                        }
                    })
            }
        }
        .width('100%')
        .padding({ right: 7 })
        .accessibilityGroup(true)
        .accessibilityText(
            `清除缓存，当前缓存文件总大小${this.cacheSize}`
        )
    }
}