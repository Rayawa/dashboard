import { AppInfo, NaturalLanguageExtractor } from '../common/NaturalLanguageExtract';
import { hdsEffect } from '@kit.UIDesignKit';
import { vibration } from '../common/vibration';
import { queryButtons } from './queryButtons';

import type { FormData } from '../common/types';
import { FORM_DEBOUNCE_DELAY_MS } from '../common/constants';

@Component
export struct appQuery {
  @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @Link showSheet: boolean;
  @Link inputText: string;
  @Link formData: FormData;
  @State extractedApps: AppInfo[] = [];
  @State isProcessing: boolean = false;
  private debounceTimer: number | null = null;
  private readonly DEBOUNCE_DELAY: number = FORM_DEBOUNCE_DELAY_MS;

  build() {
    Column() {
      Text("填写应用信息以查询数据库信息。").width("95%").fontSize(14).fontColor($r('app.color.diff_content')).margin({ bottom:10 })

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
      .alignItems(HorizontalAlign.End)
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
      // 应用名称
      Column({ space: 6 }) {
        Row({ space: 4 }) {
          Text("应用名称")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
        }
        .width("100%")
        .justifyContent(FlexAlign.Start)
        TextInput({
          placeholder: "请输入应用名称",
          text: this.formData.appName,
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
            this.formData.appName = value;
          })
      }
      .width("100%")
      .padding(12)

      // 应用详情页链接
      Column({ space: 6 }) {
        Row({ space: 4 }) {
          Text("应用详情页链接")
            .fontSize(16)
            .fontWeight(FontWeight.Bold)
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

      // app_id
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


      // 按钮区域
      queryButtons({ showSheet: this.showSheet, inputText: this.inputText, formData: this.formData })
    }
    .width("100%").padding(10).margin({ bottom: 20 })
  }

  // 处理提取信息
  private async handleAutoExtract() {
    if (this.isProcessing || !this.inputText.trim()) {
      return;
    }

    this.isProcessing = true;
    this.extractedApps = [];

    try {
      const apps = await NaturalLanguageExtractor.extractAppInfoFromText(this.inputText);
      this.extractedApps = apps;

      if (this.extractedApps.length > 0) {
        if(this.vibrationON){
          vibration.waveVibration()
        }
        this.autoFillForm();
      }
    } catch (error) {
      console.error("自动提取失败:", error);
    } finally {
      this.isProcessing = false;
    }
  }

  private autoFillForm() {
    if (this.extractedApps.length === 0) {
      return;
    }

    const app = this.extractedApps[0];

    if (app.link !== undefined && app.link !== null) {
      this.formData.appLink = app.link;
    }

    if (app.packageName !== undefined && app.packageName !== null) {
      this.formData.packageName = app.packageName;
    }

    if (app.appID !== undefined && app.appID !== null) {
      this.formData.appId = app.appID;
    }

    if (app.date) {
      const oldRemark = this.formData.remark;
      const datePattern = /提取日期:\s*\d{4}-\d{2}-\d{2}[\r\n]*/;

      if (oldRemark && datePattern.test(oldRemark)) {
        const otherRemark = oldRemark.replace(datePattern, "").trim();
        this.formData.remark = otherRemark
          ? `提取日期: ${app.date}\n${otherRemark}`
          : `提取日期: ${app.date}`;
      } else if (oldRemark) {
        this.formData.remark = `提取日期: ${app.date}\n${oldRemark}`;
      } else {
        this.formData.remark = `提取日期: ${app.date}`;
      }
    }
  }
}
