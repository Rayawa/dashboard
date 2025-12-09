import { NaturalLanguageExtractor, AppInfo } from '../../ability/NaturalLanguageExtract';
import { prompt } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';

interface FormData {
  appLink: string;
  packageName: string;
  appId: string;
  remark: string;
}

@Entry
@Component
export struct submit {
  @State controller: hdsEffect.ShaderEffectController = new hdsEffect.ShaderEffectController();
  @State formData: FormData = {
    appLink: '',
    packageName: '',
    appId: '',
    remark: ''
  };
  @State inputText: string = '';
  @State extractedApps: AppInfo[] = [];
  @State isProcessing: boolean = false;

  private debounceTimer: number | null = null;
  private readonly DEBOUNCE_DELAY: number = 800;

  clearForm(): void {
    this.formData = {
      appLink: '',
      packageName: '',
      appId: '',
      remark: ''
    };
    this.inputText = ''
    prompt.showToast({
      message: '表单已清空',
      duration: 1500
    });
  }
  queryForm(): void {
    prompt.showToast({
      message: '敬请期待！',
      duration: 1500
    });
    // if (!this.formData.packageName && !this.formData.appId) {
    //   prompt.showToast({
    //     message: '请输入包名或app_id进行查询',
    //     duration: 2000
    //   });
    //   return;
    // }
    // ->查询逻辑
    // console.log('查询数据:', this.formData);
    //
    // // ->查询结果
    // prompt.showToast({
    //   message: `查询到应用: ${this.formData.packageName || this.formData.appId}`,
    //   duration: 2000
    // });
  }
  submitForm(): void {
    if (!this.formData.packageName.trim()) {
      prompt.showToast({
        message: '请输入包名',
        duration: 2000
      });
      return;
    }

    if (!this.formData.appId.trim()) {
      prompt.showToast({
        message: '请输入AppID',
        duration: 2000
      });
      return;
    }

    // ->提交逻辑，如调用API等
    console.log('提交数据:', this.formData);
    prompt.showToast({
      message: '提交成功，感谢您的投稿！',
      duration: 3000
    });
    this.inputText=''
    this.formData = {
        appLink: '',
        packageName: '',
        appId: '',
        remark: ''
    };

  }

  build() {
    Column() {
      // 标题
      Row({ space: 8 }) {
        Image($r('app.media.submit'))
          .height(25)
          .width(25)
        Text('投稿/查询应用')
          .fontSize(21)
          .fontWeight(FontWeight.Bold)
      }.width('100%').justifyContent(FlexAlign.Start).alignItems(VerticalAlign.Center).padding({ bottom: 16 })
      // 智能提取
      Column({ space: 6 }) {
        Row({ space: 20 }){
          Row(){
            Text('AI智能提取')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
          }
          .linearGradient({
            direction: GradientDirection.LeftBottom,
            colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
          })
          .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

          Row({ space:5 }) {
            if (this.extractedApps.length > 0) {
              LoadingProgress()
                .width(21)
                .height(21)
                .color(Color.Green)
            } else {
              Row(){
                LoadingProgress()
                  .width(21)
                  .height(21)
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.RightBottom,
                colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

            }
            if (this.inputText.trim().length > 0) {
              if (this.isProcessing) {
                Row(){
                  Text('正在分析文本内容...')
                    .fontSize(14)
                    .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                }
                .linearGradient({
                  direction: GradientDirection.RightBottom,
                  colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
                })
                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

              } else if (this.extractedApps.length > 0) {
                Row(){
                  Text('分析完成！信息已填充')
                    .fontSize(14)
                    .fontColor(Color.Green)
                }

              } else if (!this.isProcessing) {
                Row(){
                  Text('输入完成，等待分析...')
                    .fontSize(14)
                    .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                }
                .linearGradient({
                  direction: GradientDirection.RightBottom,
                  colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
                })
                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

              }
            } else {
              Row(){
                Text('置入应用信息以自动提取')
                  .fontSize(14)
                  .blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
              }
              .linearGradient({
                direction: GradientDirection.RightBottom,
                colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
              })
              .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)

            }
          }.width('80%').justifyContent(FlexAlign.Start).alignItems(VerticalAlign.Center)

        }
        TextInput({
          placeholder: '粘贴或输入应用信息',
          text: this.inputText
        })
          .width('100%')
          .height(40)
          .margin({ left: 12 })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .borderWidth(0.5)
          .borderColor($r('app.color.border'))
          .backgroundColor($r('app.color.diff_background'))
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
      }.width('100%').height(100).padding(16).borderRadius(16)
      .visualEffect(new hdsEffect.HdsEffectBuilder()
        .shaderEffect({
          effectType: hdsEffect.EffectType.DUAL_EDGE_FLOW_LIGHT,
          animation: {
            duration: 9000,
            iterations: -1,
            autoPlay: true,
            onFinish: () => {
              console.info('Succeeded in finishing');
            }
          },
          controller: this.controller,
          params: {
            firstEdgeFlowLight: {
              startPos: 0,
              endPos: 1.0,
              color: '#1AD0F1',
            },
            secondEdgeFlowLight: {
              startPos: 0.5,
              endPos: 1.5,
              color: '#FFA4E5',
            }
          }
        })
        .buildEffect())

      // 应用详情页链接（可选）
      Column({ space: 6 }) {
        Row({ space: 4 }) {
          Text('应用详情页链接')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)

          Text('(可选)')
            .fontSize(14)
            .fontColor($r('app.color.diff_content'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        TextInput({
          placeholder: '请输入应用详情页链接',
          text: this.formData.appLink
        })
          .width('100%')
          .height(40)
          .margin({ left: 12 })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .borderWidth(0.5)
          .borderColor($r('app.color.border'))
          .backgroundColor($r('app.color.diff_background'))
          .onChange((value: string) => {
            this.formData.appLink = value
          })
      }.width('100%').padding(12)
      // 包名
      Column({ space: 6 }) {
        Text('包名')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        TextInput({
          placeholder: '例如：com.example.app',
          text: this.formData.packageName
        })
          .width('100%')
          .height(40)
          .margin({ left: 12 })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .borderWidth(0.5)
          .borderColor($r('app.color.border'))
          .backgroundColor($r('app.color.diff_background'))
          .onChange((value: string) => {
            this.formData.packageName = value
          })
      }.width('100%').padding(12)
      // app_id
      Column({ space: 6 }) {
        Text('AppID')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .width('100%')

        TextInput({
          placeholder: '例如：C123456',
          text: this.formData.appId
        })
          .width('100%')
          .height(40)
          .margin({ left: 12 })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .borderWidth(0.5)
          .borderColor($r('app.color.border'))
          .backgroundColor($r('app.color.diff_background'))
          .onChange((value: string) => {
            this.formData.appId = value
          })
      }.width('100%').padding(12)
      // 备注（可选）
      Column({ space: 6 }) {
        Row({ space: 4 }) {
          Text('备注')
            .fontSize(16)
            .fontWeight(FontWeight.Bold)

          Text('(可选)')
            .fontSize(14)
            .fontColor($r('app.color.diff_content'))
        }
        .width('100%')
        .justifyContent(FlexAlign.Start)

        TextInput({
          placeholder: '请输入备注信息',
          text: this.formData.remark
        })
          .width('100%')
          .height(40)
          .margin({ left: 12 })
          .borderRadius(16)
          .padding({ left: 12, right: 12 })
          .borderWidth(0.5)
          .borderColor($r('app.color.border'))
          .backgroundColor($r('app.color.diff_background'))
          .onChange((value: string) => {
            this.formData.remark = value
          })
      }.width('100%').padding(12)
      // 按钮区域
      Row() {
        // 清空按钮
        Button('清空', { type: ButtonType.Normal })
          .margin(2)
          .width('25%')
          .height(44)
          .backgroundColor(Color.Green)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(22)
          .onClick(() => {
            this.clearForm()
          })

        // 查询按钮
        Button('查询', { type: ButtonType.Normal })
          .margin(2)
          .width('25%')
          .height(44)
          .backgroundColor(Color.Blue)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(22)
          .onClick(() => {
            this.queryForm()
          })

        // 提交按钮
        Button('提交投稿', { type: ButtonType.Capsule })
          .margin(2)
          .width('40%')
          .height(44)
          .backgroundColor(Color.Red)
          .fontSize(16)
          .borderRadius(22)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.submitForm()
          })
      }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 15 })
    }
    .width('90%')
    .padding({top:20,bottom:20,left:10,right:10})
    .borderRadius(20)
    .backgroundColor($r('app.color.backcolor'))
    .shadow({
      radius: 20,
      color: Color.Gray,
      offsetX: 0,
      offsetY: 4
    })
  }

  // 处理提取信息
  private async handleAutoExtract() {
    // 如果正在处理中或输入为空，则不执行
    if (this.isProcessing || !this.inputText.trim()) {
      return;
    }

    this.isProcessing = true;
    this.extractedApps = []; // 清空之前的提取结果

    try {
      // 调用自然语言提取器
      const apps = await NaturalLanguageExtractor.extractAppInfoFromText(this.inputText);
      this.extractedApps = apps;

      // 自动填充到表单
      if (this.extractedApps.length > 0) {
        this.autoFillForm();
      }
    } catch (error) {
      console.error('自动提取失败:', error);
    } finally {
      this.isProcessing = false;
    }
  }
  // 自动填充表单（提取到信息后自动调用）

  // 修改 autoFillForm 方法
  private autoFillForm() {
    if (this.extractedApps.length === 0) {
      return;
    }

    const app = this.extractedApps[0];

    // 如果有新提取的值，就覆盖（无论之前是否有值）
    if (app.link !== undefined && app.link !== null) {
      this.formData.appLink = app.link;
    }

    if (app.packageName !== undefined && app.packageName !== null) {
      this.formData.packageName = app.packageName;
    }

    if (app.appID !== undefined && app.appID !== null) {
      this.formData.appId = app.appID;
    }

    // 智能处理备注
    if (app.date) {
      // 移除旧的提取日期（如果有的话）
      const oldRemark = this.formData.remark;
      const datePattern = /提取日期:\s*\d{4}-\d{2}-\d{2}[\r\n]*/;

      if (oldRemark && datePattern.test(oldRemark)) {
        // 移除旧日期，保留其他备注
        const otherRemark = oldRemark.replace(datePattern, '').trim();
        this.formData.remark = otherRemark ?
          `提取日期: ${app.date}\n${otherRemark}` :
          `提取日期: ${app.date}`;
      } else if (oldRemark) {
        // 保留原有备注并添加新日期
        this.formData.remark = `提取日期: ${app.date}\n${oldRemark}`;
      } else {
        // 只有提取日期
        this.formData.remark = `提取日期: ${app.date}`;
      }
    }
  }
}