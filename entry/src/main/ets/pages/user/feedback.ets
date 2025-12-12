import { router } from '@kit.ArkUI';

interface GeneratedObjectLiteralInterface_1 {
  type: string;
  description: string;
  mediaCount: number;
  timestamp: string;
}

@Entry
@Component
struct IssueView {
  @State issueType: string = "";
  @State description: string = "";
  @State mediaList: Array<string> = [];
  @State submitting: boolean = false;
  @State result: string = "";

  build() {
    Navigation() {
      Scroll() {
        Column({ space: 20 }) {
          // 问题类型选择
          Text("开发中页面")
            .fontSize(20)
            .fontWeight(FontWeight.Bold);

          Select([
            { value: "功能异常" },
            { value: "内容错误" },
            { value: "使用建议" },
            { value: "界面问题" },
            { value: "其他" }
          ])
            .value(this.issueType)
            .onSelect((index: number, value: string) => {
              this.issueType = value;
            })
            .margin({ bottom: 10 });

          // 问题描述
          Text("问题描述 / 建议")
            .fontSize(20)
            .fontWeight(FontWeight.Bold);

          TextArea({ placeholder: "请详细描述你的问题或建议…" })
            .height(160)
            .onChange((value: string) => {
              this.description = value;
            });

          // 上传资源
          Text("上传图片或视频")
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .margin({ top: 10 });

          // 展示已上传资源
          if (this.mediaList.length > 0) {
            Column({ space: 8 }) {
              ForEach(this.mediaList, (item: string, index: number) => {
                Row({ space: 10 }) {
                  Text(`文件${index + 1}: ${item}`)
                    .fontSize(14)
                    .layoutWeight(1)
                    .textAlign(TextAlign.Start);

                  Button("删除")
                    .type(ButtonType.Normal)
                    .fontSize(12)
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .onClick(() => {
                      const newList = [...this.mediaList];
                      newList.splice(index, 1);
                      this.mediaList = newList;
                    });
                }
                .padding(10)
                .border({ width: 1, color: Color.Grey })
                .borderRadius(8)
                .width('100%');
              });
            }
            .width('100%');
          }

          // 上传按钮
          Button("选择图片 / 视频")
            .width('100%')
            .margin({ top: 10 })
            .onClick(() => {
              this.pickMedia();
            });

          // 提交按钮
          Button(this.submitting ? "提交中…" : "提交")
            .type(ButtonType.Capsule)
            .margin({ top: 30, bottom: 20 })
            .width('80%')
            .height(45)
            .onClick(() => {
              this.submitIssue();
            })
            .enabled(!this.submitting && this.issueType !== "" && this.description !== "");

          // 提交结果
          if (this.result !== "") {
            Text(this.result)
              .fontSize(16)
              .fontColor(this.result.includes("失败") ? Color.Red : Color.Green)
              .margin({ top: 10, bottom: 30 })
              .textAlign(TextAlign.Center)
              .width('100%');
          }
        }
        .padding(20)
        .width('100%');
      }
      .scrollBar(BarState.Off)
    }
    .title("问题反馈")
    .hideBackButton(false)
  }

  // 模拟选择媒体文件
  pickMedia(): void {
    if (this.mediaList.length >= 5) {
      this.result = "最多只能上传5个文件";
      setTimeout(() => {
        this.result = "";
      }, 3000);
      return;
    }

    const types = ["截图", "照片", "录屏"];
    const randomType = types[Math.floor(Math.random() * types.length)];
    const fakePath = `${randomType}_${this.mediaList.length + 1}.${randomType === '录屏' ? 'mp4' : 'jpg'}`;

    this.mediaList = [...this.mediaList, fakePath];
  }

  // 提交问题
  submitIssue(): void {
    // 验证输入
    if (this.issueType === "") {
      this.result = "请选择问题类型";
      return;
    }

    if (this.description.trim() === "") {
      this.result = "请输入问题描述";
      return;
    }

    // 设置提交状态
    this.submitting = true;
    this.result = "";

    // 模拟网络请求延迟
    setTimeout(() => {
      // 构造提交数据
      const issueData: GeneratedObjectLiteralInterface_1 = {
        type: this.issueType,
        description: this.description,
        mediaCount: this.mediaList.length,
        timestamp: new Date().toLocaleString()
      };

      console.info("提交的问题数据:", JSON.stringify(issueData));

      // 模拟请求结果（这里随机模拟成功/失败）
      const isSuccess = Math.random() > 0.2; // 80%成功率

      if (isSuccess) {
        this.result = "问题提交成功！我们会尽快处理。";

        // 3秒后清空表单并返回
        setTimeout(() => {
          // 清空表单
          this.issueType = "";
          this.description = "";
          this.mediaList = [];
          this.result = "";

          // 返回上一页
          router.back();
        }, 3000);
      } else {
        this.result = "提交失败，请检查网络后重试";
      }

      // 重置提交状态
      this.submitting = false;
    }, 2000);
  }
  // async submitIssue() {
  //   let data = {
  //     type: this.issueType,
  //     desc: this.description,
  //     medias: this.mediaList
  //   }
  //
  //   const res = await fetch("https://你的服务器/api/issue", {
  //     method: "POST",
  //     headers: { "Content-Type": "application/json" },
  //     body: JSON.stringify(data)
  //   })
  //   console.info("服务器返回：", JSON.stringify(await res.json()))
  // }

}
