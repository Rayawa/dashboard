import { vibration } from '../common/vibration';
import { confirmButtons } from './confirmButtons';
import { PromptAction } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { mainPage } from '../common/constants';

@Component
export struct warn {
    @StorageLink("vibrationON") vibrationON: boolean = true;
    PromptAction: PromptAction = this.getUIContext().getPromptAction();

    build() {
        Column() {
            Text("重要提示").fontSize(24).fontColor(Color.Red).fontWeight(FontWeight.Bold).margin({ bottom: 5 })

            Column() {
                Text("Harmony Gallery数据来源于网络。\n不保证来源准确性、完整性和真实性，仅供参考。").fontSize(14).fontColor(Color.Red).fontWeight(FontWeight.Medium).margin({ bottom: 12 })
                Text("详情查看：项目总网页").fontSize(14).decoration({ type: TextDecorationType.Underline, color: Color.Blue }).fontColor(Color.Blue).margin({ left: 5 , top: 10 ,bottom: 20 })
                    .onClick(async () => {
                        if(this.vibrationON) vibration.dotVibration()
                        const ui_content = this.getUIContext();
                        try {
                            this.PromptAction.showToast({ message: "正在跳转...", duration: 500 });
                            let context = ui_content.getHostContext() as common.UIAbilityContext;
                            await context.startAbility({
                                action: "ohos.want.action.viewData",
                                entities: ["entity.system.browsable"],
                                uri: mainPage.toString(),
                            } as Want);
                        } catch (error) {
                            console.error("打开链接失败:", (error as BusinessError).message);
                            this.PromptAction.showToast({ message: "打开链接失败", duration: 1000 });
                        }
                    })

                Text("【架构限制】").fontSize(15).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
                Text("数据内容仅覆盖HarmonyOS 5+核心环境，不含侧载或企业定制版应用。").fontSize(13).margin({ bottom: 5 })
                Text("【更新延迟】").fontSize(15).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
                Text("数据存在滞后性，同步质量受限于用户网络稳定性，项目组不保证信息的即时性。").fontSize(13)

                Divider().color($r("app.color.border")).strokeWidth(0.5).margin({ top: 15, bottom: 15 })

                Text("【免责申明】").fontSize(15).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
                Text("所有数据由第三方测算，不代表华为官方立场！").fontColor(Color.Red).fontWeight(FontWeight.Bold).fontSize(15).margin({ bottom: 5 })
                Text("项目组不对数据来源的准确性、完整性与真实性做任何法律担保，不承担用户因采信结果产生的任何损失。").fontSize(13).margin({ bottom: 5 })
                Text("【知识产权】").fontSize(15).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
                Text("算法原创，严禁商用。使用API对接数据库前请先与我们取得联系。").fontSize(13).margin({ bottom: 5 })
                Text("【动态调整】").fontSize(15).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 8 })
                Text("本项目组拥有对本统计方法论及数据口径的最终解释权，保留在不预先通知的情况下修正算法逻辑的权利").fontSize(13)
            }
            .padding(10)
            .alignItems(HorizontalAlign.Start)

            confirmButtons()

        }
        .width(350)
        .padding({
            top: 20,
            bottom: 20,
            left: 10,
            right: 10,
        })
        .borderRadius(20)
        .backgroundColor($r("app.color.backcolor"))
        .shadow({
            radius: 20,
            color: Color.Gray,
            offsetX: 0,
            offsetY: 4,
        });
    }
}