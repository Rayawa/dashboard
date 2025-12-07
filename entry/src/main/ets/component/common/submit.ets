// @Component
// export struct submit{
//   build() {
//     Column({ space: 20 }) {
//       Row() {
//         Row({ space: 8 }) {
//           Image($r('app.media.submit'))
//             .height(25)
//             .width(25)
//
//           Text('投稿应用')
//             .fontSize(21)
//             .fontWeight(FontWeight.Bold)
//         }
//
//         Blank()
//           .layoutWeight(1)
//         Image($r('app.media.close'))
//           .height(26)
//           .width(26)
//           .onClick(() => {
//             this.isPresent = !this.isPresent;
//           })
//       }
//       .width('100%')
//       .justifyContent(FlexAlign.SpaceBetween)
//       .alignItems(VerticalAlign.Center)
//       .padding({ bottom: 16 })
//
//       // 应用详情页链接（可选）
//       Column({ space: 6 }) {
//         Row({ space: 4 }) {
//           Text('应用详情页链接')
//             .fontSize(16)
//             .fontWeight(FontWeight.Bold)
//
//           Text('(可选)')
//             .fontSize(14)
//             .fontColor($r('app.color.diff_content'))
//         }
//         .width('100%')
//         .justifyContent(FlexAlign.Start)
//
//         TextInput({
//           placeholder: '请输入应用详情页链接',
//           text: this.formData.appLink
//         })
//           .width('100%')
//           .height(40)
//           .margin({ left: 12 })
//           .borderRadius(16)
//           .padding({ left: 12, right: 12 })
//           .borderWidth(0.5)
//           .borderColor($r('app.color.border'))
//           .backgroundColor($r('app.color.diff_background'))
//           .onChange((value: string) => {
//             this.formData.appLink = value
//           })
//       }
//
//       // 包名
//       Column({ space: 6 }) {
//         Text('包名')
//           .fontSize(16)
//           .fontWeight(FontWeight.Bold)
//           .width('100%')
//
//         TextInput({
//           placeholder: '例如：com.example.app',
//           text: this.formData.packageName
//         })
//           .width('100%')
//           .height(40)
//           .margin({ left: 12 })
//           .borderRadius(16)
//           .padding({ left: 12, right: 12 })
//           .borderWidth(0.5)
//           .borderColor($r('app.color.border'))
//           .backgroundColor($r('app.color.diff_background'))
//           .onChange((value: string) => {
//             this.formData.packageName = value
//           })
//       }
//
//       // app_id
//       Column({ space: 6 }) {
//         Text('app_id')
//           .fontSize(16)
//           .fontWeight(FontWeight.Bold)
//           .width('100%')
//
//         TextInput({
//           placeholder: '例如：123456',
//           text: this.formData.appId
//         })
//           .width('100%')
//           .height(40)
//           .margin({ left: 12 })
//           .borderRadius(16)
//           .padding({ left: 12, right: 12 })
//           .borderWidth(0.5)
//           .borderColor($r('app.color.border'))
//           .backgroundColor($r('app.color.diff_background'))
//           .onChange((value: string) => {
//             this.formData.appId = value
//           })
//       }
//
//
//       // 备注（可选）
//       Column({ space: 6 }) {
//         Row({ space: 4 }) {
//           Text('备注')
//             .fontSize(16)
//             .fontWeight(FontWeight.Bold)
//
//           Text('(可选)')
//             .fontSize(14)
//             .fontColor($r('app.color.diff_content'))
//         }
//         .width('100%')
//         .justifyContent(FlexAlign.Start)
//
//         TextInput({
//           placeholder: '请输入备注信息',
//           text: this.formData.remark
//         })
//           .width('100%')
//           .height(40)
//           .margin({ left: 12 })
//           .borderRadius(16)
//           .padding({ left: 12, right: 12 })
//           .borderWidth(0.5)
//           .borderColor($r('app.color.border'))
//           .backgroundColor($r('app.color.diff_background'))
//           .onChange((value: string) => {
//             this.formData.remark = value
//           })
//       }
//
//       // 按钮区域
//       Row() {
//         // 清空按钮
//         Button('清空', { type: ButtonType.Normal })
//           .margin(2)
//           .width('25%')
//           .height(44)
//           .backgroundColor(Color.Green)
//           .fontSize(16)
//           .fontWeight(FontWeight.Medium)
//           .borderRadius(22)
//           .onClick(() => {
//             this.clearForm()
//           })
//
//         // 查询按钮
//         Button('查询', { type: ButtonType.Normal })
//           .margin(2)
//           .width('25%')
//           .height(44)
//           .backgroundColor(Color.Blue)
//           .fontSize(16)
//           .fontWeight(FontWeight.Medium)
//           .borderRadius(22)
//           .onClick(() => {
//             this.queryForm()
//           })
//
//         // 提交按钮
//         Button('提交投稿', { type: ButtonType.Capsule })
//           .margin(2)
//           .width('40%')
//           .height(44)
//           .backgroundColor(Color.Red)
//           .fontColor(Color.White)
//           .fontSize(16)
//           .fontWeight(FontWeight.Medium)
//           .onClick(() => {
//             this.submitForm()
//           })
//       }
//       .width('100%')
//       .justifyContent(FlexAlign.SpaceBetween)
//       .margin({ top: 15 })
//     }
//     .width('90%')
//     .padding({
//       top: 20,
//       bottom: 20,
//       left: 15,
//       right: 25
//     })
//     .borderRadius(20)
//     .backgroundColor($r('app.color.backcolor'))
//     .shadow({
//       radius: 20,
//       color: Color.Gray,
//       offsetX: 0,
//       offsetY: 4
//     })
//   }
// }