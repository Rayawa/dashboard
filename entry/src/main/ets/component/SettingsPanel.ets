import { vibration } from '../common/vibration';
import { common } from '@kit.AbilityKit';
import {
    setImmersiveMaterialLevel, setLightFieldLevel, setUsername, setVibrationLevel
} from '../common/storage';
import { isHdrLightFieldSupported } from '../common/visualEffects';
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
struct UsernameEditor {
    @Prop @Watch('onInitialUsernameChanged') initialUsername: string = '';
    @Prop narrow: boolean = false;
    onCommit?: (value: string) => void;
    @StorageLink('vibrationLevel') vibrationLevel: number = 1;
    @State private draftUsername: string = '';
    @State private showHelp: boolean = false;
    private editing: boolean = false;
    private lastCommittedUsername: string = '';

    aboutToAppear(): void {
        this.draftUsername = this.initialUsername;
        this.lastCommittedUsername = this.initialUsername.trim();
    }

    aboutToDisappear(): void {
        this.commitDraft();
    }

    private onInitialUsernameChanged(): void {
        if (this.editing) return;
        this.draftUsername = this.initialUsername;
        this.lastCommittedUsername = this.initialUsername.trim();
    }

    private commitDraft(): void {
        const username = this.draftUsername.trim();
        if (this.draftUsername !== username) this.draftUsername = username;
        if (username === this.lastCommittedUsername) return;
        this.lastCommittedUsername = username;
        if (this.onCommit) this.onCommit(username);
    }

    build() {
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
                    text: this.draftUsername,
                    placeholder: 'HarmonyOS用户'
                })
                    .layoutWeight(1)
                    .constraintSize({ minWidth: 120 })
                    .height(40)
                    .enableKeyboardOnFocus(false)
                    .backgroundColor($r('app.color.v3_surface_alt'))
                    .onChange((value: string): void => {
                        this.draftUsername = value;
                    })
                    .onEditChange((isEditing: boolean): void => {
                        this.editing = isEditing;
                        if (!isEditing) this.commitDraft();
                    })
                    .onSubmit((): void => this.commitDraft())
                    .accessibilityText(
                        `用户名输入框，当前用户名为${this.draftUsername || 'HarmonyOS用户'}`
                    )

                Image($r('app.media.question'))
                    .height(22)
                    .width(22)
                    .objectFit(ImageFit.Contain)
                    .clickEffect({ level: ClickEffectLevel.LIGHT, scale: 0.9 })
                    .onClick((): void => {
                        if (this.vibrationLevel > 0) vibration.dotVibration();
                        this.showHelp = !this.showHelp;
                    })
                    .bindPopup(this.showHelp, {
                        message: '此用户名会随投稿与更新请求提交；留空时显示为设备名称',
                        onStateChange: (event): void => {
                            if (!event.isVisible) this.showHelp = false;
                        },
                    })
                    .accessibilityText('查看用户名说明')
            }
            .width(this.narrow ? '100%' : 204)
            .margin({ top: this.narrow ? 4 : 0 })
        }
        .padding({ right: 7 })
        .width('100%')
        .accessibilityGroup(true)
        .accessibilityText(`用户名设置，当前${this.draftUsername || 'HarmonyOS用户'}`)
    }
}

@Component
export struct SettingsPanel {
    @Prop @Watch('onActiveChanged') active: boolean = false;
    @StorageLink('vibrationLevel') vibrationLevel: number = 1;
    @StorageLink('lightFieldLevel') lightFieldLevel: number = 1;
    @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: number = 1;
    @StorageLink('username') username: string = '';

    @State handlePopupTrash: boolean = false;
    @State cacheSize: string = '计算中…';
    @State private contentWidth: number = 0;
    private readonly vibrationSupported: boolean = vibration.isSupported();
    private attemptedUnsupportedHighLight: boolean = false;
    private cacheSizeTimer: number = -1;

    private vibrationPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.vibrate') },
    });

    private materialPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.immersive') },
    });

    private lightFieldPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.light') },
    });

    private usernamePrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.user') },
    });

    private trashPrefixItem: PrefixIcon = new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: $r('app.media.trash') },
    });

    private onActiveChanged(): void {
        if (this.active) this.scheduleCacheSizeRefresh();
    }

    private scheduleCacheSizeRefresh(): void {
        if (this.cacheSizeTimer >= 0) clearTimeout(this.cacheSizeTimer);
        this.cacheSizeTimer = setTimeout((): void => {
            this.cacheSizeTimer = -1;
            const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
            this.cacheSize = formatBytes(getCacheSizeBytes(context));
        }, 0);
    }

    aboutToDisappear(): void {
        if (this.cacheSizeTimer >= 0) {
            clearTimeout(this.cacheSizeTimer);
            this.cacheSizeTimer = -1;
        }
    }

    private persistUsername(username: string): void {
        setUsername(username).catch((error: Error) => {
            console.error('[Dashboard][component/SettingsPanel][ERROR]',
                `保存用户名失败: ${error.message}`);
        });
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
                        if (this.vibrationLevel > 0) {
                            vibration.dotVibration();
                        }
                    }
                },
                secondaryButton: {
                    value: '继续',
                    action: async () => {
                        if (this.vibrationLevel > 0) {
                            vibration.dotVibration();
                        }
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
                                '[Dashboard][component/SettingsPanel][ERROR]',
                                `清除缓存失败: ${JSON.stringify(error)}`
                            );

                            showToastSafely(
                                prompt,
                                '部分缓存文件正在使用，请稍后重试',
                                2190,
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
                '[Dashboard][component/SettingsPanel][ERROR]',
                `清除缓存确认窗口显示失败: ${JSON.stringify(error)}`
            );

            showToastSafely(
                prompt,
                '暂时无法打开清除缓存窗口，请稍后重试',
                1900,
                'Settings'
            );
        }
    }

    build() {
        Column() {
            this.usernameItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            if (this.vibrationSupported) {
                this.vibrationLevelItem()

                Divider()
                    .color($r('app.color.border'))
                    .strokeWidth(0.5)
                    .margin({
                        left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                        right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    })
            }

            // this.lightFieldLevelItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            this.materialLevelItem()

            Divider()
                .color($r('app.color.border'))
                .strokeWidth(0.5)
                .margin({
                    left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                    right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
                })

            this.trashItem()
        }
        .width('100%')
        .backgroundColor($r('app.color.v3_surface'))
        .borderRadius(16)
        .shadow({
            radius: 8,
            color: $r('app.color.v3_shadow'),
            offsetY: 2
        })
        .clip(true)
        .onAppear((): void => {
            if (this.active) this.scheduleCacheSizeRefresh();
        })
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
    private vibrationLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.vibrationPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.vibrationLevelContent()
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
    private vibrationLevelContent(): void {
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
                    .width(190)
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
                                    '[Dashboard][component/SettingsPanel][ERROR]',
                                    `保存振动强度失败: ${error.message}`
                                );
                            });
                        }
                    })
                    .accessibilityText(
                        `振动强度，当前${this.vibrationLevelName()}，共三档`
                    )

                Row() {
                    this.vibrationLevelLabel('关闭', 0)
                    this.vibrationLevelLabel('灵动', 1)
                    this.vibrationLevelLabel('硬朗', 2)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
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
    private vibrationLevelLabel(label: string, level: number): void {
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

    private lightFieldLevelName(): string {
        if (this.lightFieldLevel === 0) {
            return '暗淡';
        }
        if (this.lightFieldLevel === 2) {
            return '高亮';
        }
        return '明亮';
    }

    private persistLightFieldLevel(level: number): void {
        setLightFieldLevel(level).catch((error: Error) => {
            console.error('[Dashboard][component/SettingsPanel][ERROR]',
                `保存光场视效失败: ${error.message}`);
        });
    }

    private showLightFieldPrompt(message: string): void {
        showToastSafely(this.getUIContext().getPromptAction(), message, 4000, 'Settings');
    }

    private onLightFieldLevelChange(value: number, mode: SliderChangeMode): void {
        const nextLevel = Math.round(value);
        if (mode === SliderChangeMode.Begin) {
            this.attemptedUnsupportedHighLight = false;
            return;
        }

        if (!isHdrLightFieldSupported() && nextLevel === 2) {
            this.attemptedUnsupportedHighLight = true;
        }

        if (mode !== SliderChangeMode.Click && mode !== SliderChangeMode.End) {
            return;
        }

        vibration.dotVibration();
        if (!isHdrLightFieldSupported() &&
            (nextLevel === 2 || this.attemptedUnsupportedHighLight)) {
            this.lightFieldLevel = 1;
            this.persistLightFieldLevel(1);
            this.showLightFieldPrompt('当前设备不支持全局HDR功能');
            this.attemptedUnsupportedHighLight = false;
            return;
        }

        this.lightFieldLevel = nextLevel;
        this.persistLightFieldLevel(nextLevel);
        if (nextLevel === 2) {
            this.showLightFieldPrompt('光场视效将以HDR显示，该功能会显著提升亮度与功耗，部分设备不支持');
        }
        this.attemptedUnsupportedHighLight = false;
    }

    @Builder
    private lightFieldLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.lightFieldPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.lightFieldLevelContent()
                },
            },
            cardHeight: this.isNarrowSettings() ? 116 : 68,
            cardBackgroundColor: $r('app.color.v3_surface'),
            cardBorderRadius: 0,
            hoverBorderRadius: 12,
            cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
            cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
            accessibilityOptions: {
                accessibilityText: '光场视效设置',
            },
        })
    }

    @Builder
    private lightFieldLevelContent(): void {
        Flex({
            wrap: FlexWrap.Wrap,
            justifyContent: FlexAlign.SpaceBetween,
            alignItems: ItemAlign.Center
        }) {
            Text('光场视效')
                .fontSize(16)
                .fontColor($r('app.color.v3_text_primary'))
                .maxLines(2)
                .accessibilityText('光场视效')

            Column({ space: 1 }) {
                Slider({
                    value: $$this.lightFieldLevel,
                    min: 0,
                    max: 2,
                    step: 1,
                    style: SliderStyle.InSet,
                })
                    .width(190)
                    .selectedColor($r('app.color.diff_content'))
                    .trackColor($r('app.color.v3_surface_alt'))
                    .blockBorderColor($r('app.color.v3_surface'))
                    .showSteps(true)
                    .showTips(false)
                    .onChange((value: number, mode: SliderChangeMode): void => {
                        this.onLightFieldLevelChange(value, mode);
                    })
                    .accessibilityText(`光场视效，当前${this.lightFieldLevelName()}，共三档`)

                Row() {
                    this.lightFieldLevelLabel('暗淡', 0)
                    this.lightFieldLevelLabel('明亮', 1)
                    this.lightFieldLevelLabel('高亮', 2)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
            .margin({ top: this.isNarrowSettings() ? 4 : 0 })
        }
        .width('100%')
        .padding({ right: 2 })
        .accessibilityGroup(true)
        .accessibilityText(`光场视效，当前${this.lightFieldLevelName()}`)
    }

    @Builder
    private lightFieldLevelLabel(label: string, level: number): void {
        Text(label)
            .fontSize(12)
            .fontWeight(this.lightFieldLevel === level ? FontWeight.Medium : FontWeight.Regular)
            .fontColor(level === 2 && !isHdrLightFieldSupported() ?
                $r('app.color.v3_text_secondary') :
                this.lightFieldLevel === level ?
                    $r('app.color.diff_content') : $r('app.color.v3_text_secondary'))
            .opacity(level === 2 && !isHdrLightFieldSupported() ? 0.55 : 1)
            .decoration({
                type: level === 2 && !isHdrLightFieldSupported() ?
                    TextDecorationType.LineThrough : TextDecorationType.None,
                color: $r('app.color.v3_text_secondary'),
            })
            .width(40)
            .textAlign(TextAlign.Center)
            .accessibilityText(`${label}光场${this.lightFieldLevel === level ? '，已选择' : ''}${
                level === 2 && !isHdrLightFieldSupported() ? '，当前设备不支持' : ''}`)
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
    private materialLevelItem(): void {
        HdsListItemCard({
            prefixItem: this.materialPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.materialLevelContent()
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
    private materialLevelContent(): void {
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
                    .width(190)
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
                                    '[Dashboard][component/SettingsPanel][ERROR]',
                                    `保存材质等级失败: ${error.message}`
                                );
                            });
                        }
                    })
                    .accessibilityText(
                        `材质等级，当前${this.materialLevelName()}，共三档`
                    )

                Row() {
                    this.materialLevelLabel('流畅', 2)
                    this.materialLevelLabel('轻柔', 1)
                    this.materialLevelLabel('精美', 0)
                }
                .width(190)
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width(190)
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
    private materialLevelLabel(label: string, level: number): void {
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
    private usernameItem(): void {
        HdsListItemCard({
            prefixItem: this.usernamePrefixItem,
            textItem: {
                customBuilder: () => {
                    this.usernameContent()
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
    private usernameContent(): void {
        UsernameEditor({
            initialUsername: this.username,
            narrow: this.isNarrowSettings(),
            onCommit: (value: string): void => this.persistUsername(value),
        })
    }

    @Builder
    private trashItem(): void {
        HdsListItemCard({
            prefixItem: this.trashPrefixItem,
            textItem: {
                customBuilder: () => {
                    this.trashContent()
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
    private trashContent(): void {
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
