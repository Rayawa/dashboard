import { AppInfo, NaturalLanguageExtractor } from '../common/NaturalLanguageExtract';
import { hdsEffect } from '@kit.UIDesignKit';
import { common } from '@kit.AbilityKit';
import { submitButtons } from '../component/submitButtons';
import { vibration } from '../common/vibration'
import { FormData } from '../common/types';
import { PromptAction } from '@kit.ArkUI';

interface ShareParams {
    shareAppId: string;
    shareUrl: string;
}

@Entry
@Component
struct complexSubmit {
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
    @StorageLink("userName") userName: string = "";
    @StorageLink("inputText") inputText: string = "";
    @StorageLink("formData") formData: FormData = {
        appLink: "",
        packageName: "",
        appId: "",
        remark: "",
    };

    @StorageProp("shareParams") shareParams: ShareParams = { shareAppId: "", shareUrl: "" };
    @StorageLink("vibrationON") vibrationON: boolean = true;

    @State extractedApps: AppInfo[] = [];
    @State isProcessing: boolean = false;

    private debounceTimer: number | null = null;
    private readonly DEBOUNCE_DELAY: number = 800;

    aboutToAppear() {
        console.log("complexSubmit接受取到的所有参数:", JSON.stringify(this.shareParams));
        this.inputText = this.shareParams.shareUrl;
        this.formData.appLink = this.shareParams.shareUrl.replace(
            /&channelId=SHARE&source=appshare$/,
            "",
        );
        this.formData.packageName = this.shareParams.shareAppId;
    }

    onPageHide(): void {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        context.terminateSelf().then(() => {
            console.info('Ability 销毁指令发送成功');
        }).catch((err: BusinessError) => {
            console.error(`销毁失败: ${err.code}`);
        });
    }

    @State firstBackTime: number = 0;
    private readonly waitTime: number = 2000;
    private closePage() {
        const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        context.terminateSelf().then(() => {
            console.info('Ability 销毁指令发送成功');
        }).catch((err: BusinessError) => {
            console.error(`销毁失败: ${err.code}`);
        });
    }
    onBackPress(): boolean | void {
        const currentTime = new Date().getTime();
        if (currentTime - this.firstBackTime > this.waitTime) {
            this.firstBackTime = currentTime;
            this.PromptAction.showToast({ message: "再按一次退出", duration: this.waitTime });
            if(this.vibrationON) vibration.dotVibration()
            return true;
        } else {
            if(this.vibrationON) vibration.dotVibration()
            this.closePage()
            return false;
        }
    }

    build() {
        Stack() {
            Column()
                .width("100%")
                .height("100%")
                .backgroundColor($r("app.color.backcolor"))
                .backgroundBlurStyle(BlurStyle.BACKGROUND_THIN)
                .onClick(() => {
                            if(this.vibrationON) vibration.dotVibration()
                    this.closePage();
                })
            Column() {
                // 标题
                Row() {
                    Row({ space: 8 }) {
                        Image($r("app.media.submit"))
                            .height(25)
                            .width(25)
                        Text("投稿/更新应用至看板")
                            .fontSize(21)
                            .fontWeight(FontWeight.Bold)
                    }
                    Blank().layoutWeight(1)
                    Image($r("app.media.close"))
                        .height(26)
                        .width(26)
                        .margin({ right: 10 })
                        .onClick(() => {
                                    if(this.vibrationON) vibration.dotVibration()
                            this.closePage();
                        })
                }
                .width("100%")
                .justifyContent(FlexAlign.SpaceBetween)
                .alignItems(VerticalAlign.Center)
                .padding({ bottom: 16 })

                Text("填写应用信息投稿至数据库：\n已有应用将同步更新，新应用将新增至数据库。").width("95%").fontSize(14).fontColor($r('app.color.diff_content')).margin({ bottom:10 })

                // 智能提取
                Column({ space: 6 }) {
                    Row({ space: 20 }) {
                        Row() {
                            Text("AI智能提取")
                                .fontSize(16)
                                .fontWeight(FontWeight.Bold)
                                .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                        }
                        .linearGradient({
                            direction: GradientDirection.LeftBottom,
                            colors: [
                                [$r("app.color.gradient_start_color"), 0.0],
                                [$r("app.color.gradient_end_color"), 1],
                            ],
                        })
                        .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
                        Row({ space: 5 }) {
                            if (this.extractedApps.length > 0) {
                                LoadingProgress().width(21).height(21).color(Color.Green);
                            } else {
                                Row() {
                                    LoadingProgress()
                                        .width(21)
                                        .height(21)
                                        .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                                }
                                .linearGradient({
                                    direction: GradientDirection.RightBottom,
                                    colors: [
                                        [$r("app.color.gradient_start_color"), 0.0],
                                        [$r("app.color.gradient_end_color"), 1],
                                    ],
                                })
                                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN);
                            }
                            if (this.inputText.trim().length > 0) {
                                if (this.isProcessing) {
                                    Row() {
                                        Text("正在分析文本内容...")
                                            .fontSize(14)
                                            .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                                    }
                                    .linearGradient({
                                        direction: GradientDirection.RightBottom,
                                        colors: [
                                            [$r("app.color.gradient_start_color"), 0.0],
                                            [$r("app.color.gradient_end_color"), 1],
                                        ],
                                    })
                                    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN);
                                } else if (this.extractedApps.length > 0) {
                                    Row() {
                                        Text("分析完成！信息已填充")
                                            .fontSize(14)
                                            .fontColor(Color.Green)
                                    };
                                } else if (!this.isProcessing) {
                                    Row() {
                                        Text("输入完成，等待分析...")
                                            .fontSize(14)
                                            .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                                    }
                                    .linearGradient({
                                        direction: GradientDirection.RightBottom,
                                        colors: [
                                            [$r("app.color.gradient_start_color"), 0.0],
                                            [$r("app.color.gradient_end_color"), 1],
                                        ],
                                    })
                                    .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN);
                                }
                            } else {
                                Row() {
                                    Text("置入应用信息以自动提取")
                                        .fontSize(14)
                                        .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                                }
                                .linearGradient({
                                    direction: GradientDirection.RightBottom,
                                    colors: [
                                        [$r("app.color.gradient_start_color"), 0.0],
                                        [$r("app.color.gradient_end_color"), 1],
                                    ],
                                })
                                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN);
                            }
                        }
                        .width("80%")
                        .justifyContent(FlexAlign.Start)
                        .alignItems(VerticalAlign.Center)
                    }
                    TextInput({
                        placeholder: "粘贴或输入应用信息",
                        text: this.inputText,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.inputText = value;
                            if (this.debounceTimer !== null) {
                                clearTimeout(this.debounceTimer);
                            }
                            if (!value.trim()) {
                                this.extractedApps = [];
                                return;
                            }
                            this.debounceTimer = setTimeout(() => {
                                this.handleAutoExtract();
                                this.debounceTimer = null;
                            }, this.DEBOUNCE_DELAY);
                        })
                }
                .width("100%")
                .height(100)
                .padding(16)
                .borderRadius(16)
                .visualEffect(
                    new hdsEffect.HdsEffectBuilder()
                        .shaderEffect({
                            effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
                            animation: {
                                duration: 9000,
                                iterations: -1,
                                autoPlay: true,
                                onFinish: () => {
                                    console.info("Succeeded in finishing");
                                },
                            },
                            controller: this.controller,
                            params: {
                                firstEdgeFlowLight: {
                                    startPos: 0,
                                    endPos: 1.0,
                                    color: "#1AD0F1",
                                },
                                secondEdgeFlowLight: {
                                    startPos: 0.5,
                                    endPos: 1.5,
                                    color: "#FFA4E5",
                                },
                            },
                        })
                        .buildEffect(),
                )

                // 应用详情页链接（可选）
                Column({ space: 6 }) {
                    Row({ space: 4 }) {
                        Text("应用详情页链接")
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                        Text("(可选)")
                            .fontSize(14)
                            .fontColor($r("app.color.diff_content"))
                    }
                    .width("100%")
                    .justifyContent(FlexAlign.Start)
                    TextInput({
                        placeholder: "请输入应用详情页链接",
                        text: this.formData.appLink,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.formData.appLink = value;
                        })
                }
                .width("100%")
                .padding(12)
                // 包名
                Column({ space: 6 }) {
                    Text("包名")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .width("100%")
                    TextInput({
                        placeholder: "例如：com.example.app",
                        text: this.formData.packageName,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.formData.packageName = value;
                        })
                }
                .width("100%")
                .padding(12)
                // AppID
                Column({ space: 6 }) {
                    Text("AppID")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .width("100%")
                    TextInput({
                        placeholder: "例如：C123456",
                        text: this.formData.appId,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.formData.appId = value;
                        })
                }
                .width("100%")
                .padding(12)
                // 用户名
                Column({ space: 6 }) {
                    Text("用户名")
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .width("100%")
                    TextInput({
                        placeholder: this.userName,
                        text: this.userName,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.userName = value;
                        })
                }
                .width("100%")
                .padding(12)
                // 备注（可选）
                Column({ space: 6 }) {
                    Row({ space: 4 }) {
                        Text("备注")
                            .fontSize(16)
                            .fontWeight(FontWeight.Bold)
                        Text("(可选)")
                            .fontSize(14)
                            .fontColor($r("app.color.diff_content"))
                    }
                    .width("100%")
                    .justifyContent(FlexAlign.Start)
                    TextInput({
                        placeholder: "请输入备注信息",
                        text: this.formData.remark,
                    })
                        .width("100%")
                        .height(40)
                        .margin({ left: 12 })
                        .borderRadius(16)
                        .padding({ left: 12, right: 12 })
                        .borderWidth(0.5)
                        .borderColor($r("app.color.border"))
                        .backgroundColor($r("app.color.diff_background"))
                        .onChange((value: string) => {
                            this.formData.remark = value;
                        })
                }
                .width("100%")
                .padding(12)
                // 按钮区域
                submitButtons()
            }
            .width("90%")
            .padding({ top: 20, bottom: 10, left: 10, right: 10 })
            .borderRadius(20)
            .backgroundColor($r("app.color.backcolor"))
            .shadow({
                radius: 20,
                color: Color.Gray,
                offsetX: 0,
                offsetY: 4,
            })
        }
        .height("100%")
        .width("100%");
    }

    // 处理提取信息
    private async handleAutoExtract() {
        // 1. 增加检查：如果输入为空，或正在处理，直接返回
        if (this.isProcessing || !this.inputText.trim()) {
            console.log("跳过提取：状态为处理中或输入为空");
            return;
        }

        // 2. 设置处理状态，清空旧结果
        this.isProcessing = true;
        this.extractedApps = [];

        try {
            console.log("开始自动提取，文本长度：", this.inputText.length);
            // 3. 调用自然语言提取器
            const apps = await NaturalLanguageExtractor.extractAppInfoFromText(this.inputText);
            this.extractedApps = apps;
            console.log("自动提取完成，找到应用数：", apps.length);

            // 4. 自动填充到表单
            if (this.extractedApps.length > 0) {
                if(this.vibrationON){
                    vibration.waveVibration()
                }
                this.autoFillForm();
            }
        } catch (error) {
            console.error("自动提取失败:", error);
        } finally {
            // 5. 确保无论成功失败，都重置处理状态
            this.isProcessing = false;
        }
    }
    // 自动填充表单（提取到信息后自动调用）
    private autoFillForm() {
        if (this.extractedApps.length === 0) {
            return;
        }
        // 获取第一个应用信息
        const app = this.extractedApps[0];

        // 填充链接
        if (app.link && !this.formData.appLink) {
            this.formData.appLink = app.link;
        }

        // 填充包名
        if (app.packageName && !this.formData.packageName) {
            this.formData.packageName = app.packageName;
        }

        // 填充AppID
        if (app.appID && !this.formData.appId) {
            this.formData.appId = app.appID;
        }

        // 填充备注（如果有日期信息）
        if (app.date && !this.formData.remark?.includes(app.date)) {
            if (this.formData.remark) {
                this.formData.remark = `提取日期: ${app.date}\n${this.formData.remark}`;
            } else {
                this.formData.remark = `提取日期: ${app.date}`;
            }
        }
    }
}
