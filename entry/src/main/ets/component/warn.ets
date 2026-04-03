import { confirmButtons } from "./confirmButtons";

@Component
export struct warn {
    private limitations: string[] = [
        "1. 架构限制：数据内容仅覆盖HarmonyOS 5以上核心环境，不包含如侧载、企业定制版之类的应用",
        "2. 更新延迟：数据采集与分析存在滞后，项目组不保证信息的即时性"
    ]

    private disclaimers: string[] = [
        "1. 权属说明：本数据由第三方通过公开技术接口独立测算，不代表华为官方立场",
        "2. 免责申明：项目组不对数据来源的准确性、完整性与真实性作任何形式的法律担保",
        "3. 损益承担：用户因采信本统计结果而产生的直接或间接经济损失，本应用不承担赔偿责任",
        "4. 知识产权：本项统计算法为原创内容，未经授权严禁商用",
        "5. 动态调整：为优化准确度，我们保留在不预先通知的情况下修正统计链路与算法逻辑的权利"
    ]

    @Builder
    itemText(content: string) {
        Text(content)
            .fontSize(14)
            .lineHeight(20)
            .margin({ bottom: 5 })
    }

    build() {
        Column() {
            Text("重要提示")
                .fontSize(24)
                .fontColor(Color.Red)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 5 })

            Column() {
                Text("Harmony Gallery数据来源于网络\n不保证来源准确性、完整性和真实性，仅供参考")
                    .fontSize(14)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 12 })

                Text("【数据局限性】")
                    .fontSize(16)
                    .fontColor($r('app.color.diff_content'))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 8 })

                ForEach(this.limitations, (item: string) => {
                    this.itemText(item)
                })

                Divider().margin({ top: 10, bottom: 10 }).color("#EEEEEE")

                Text("【法律声明】")
                    .fontSize(16)
                    .fontColor($r('app.color.diff_content'))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 8 })

                ForEach(this.disclaimers, (item: string) => {
                    this.itemText(item)
                })

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