import KnockShareGuideCard, { CardRes } from './KnockShareGuideCard';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
@Component
export struct tutorial {
    @StorageLink("vibrationON") vibrationON: boolean = true;
    private triggerVibration(): void {
        if (this.vibrationON) {
            vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
                if (err) {
                    console.error(
                        `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
                    );
                    return;
                }
                console.info("Succeed in querying effect");
                if (state) {
                    try {
                        vibrator.startVibration(
                            {
                                type: "preset",
                                effectId: "haptic.effect.hard",
                                count: 1,
                                intensity: 50,
                            },
                            { usage: "touch" },
                            (error: BusinessError) => {
                                if (error) {
                                    console.error(
                                        `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                                    );
                                } else {
                                    console.info("Succeed in starting vibration");
                                }
                            },
                        );
                    } catch (tryError) {
                        console.error(`An unexpected error occurred in try block: ${tryError}`);
                    }
                }
            });
        }
    }

    @State handlePopupShareMenu: boolean = false;
    @State handlePopupSwitch: boolean = false;
    @State handlePopupUser: boolean = false;
    @State handlePopupShareShare: boolean = false;
    @State handlePopupTop: boolean = false;
    @State handlePopupRefresh: boolean = false;
    private currentIndex: number = 0;
    private readonly cardSwiperResourcesPhone: CardRes[] = [
        {
            text: "对方手机需HarmonyOS 5及以上版本。",
            rawfilePrefix: "knock_share_guide/knock_share_guide_phone_",
            framesCount: 128,
            startDelay: 50,
            stopDelay: 500,
        },
    ];

    build() {
        Swiper() {
            // 欢迎页面
            Column() {
                Text("欢迎来到应用看板")
                    .fontSize(24)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text(
                    "本应用收集华为应用市场的公开数据，转化为直观的图表与报告。简单来说，您能在这里查看几乎所有鸿蒙应用的动态。\n\n" +
                        " 1. 数据总览与图表分析：\n   通过榜单、饼图与折线图，直观查看应用下载量、评分趋势与市场分布。\n\n" +
                        " 2. 搜索应用与查看详情：\n   支持按名称、评分等条件搜索排序，点击可查看应用详情与独立趋势图。\n\n" +
                        " 3. 数据定时自动更新：\n    后台每30分钟同步一次应用市场，确保您始终获取最新数据。\n\n" +
                        " 4. 交互式操作与分享：\n    点击图表可进行数据筛选，点击应用可进入详情页；您也可通过链接、隔空抓取或鸿蒙碰一碰便捷分享应用页面。\n\n" +
                        " 5. 投稿更新应用信息：\n    您可通过应用市场分享与“我的”页面向应用看板投稿，协助投稿新应用或更新应用信息。\n\n",
                )
                    .fontSize(14)
                    .margin({ bottom: 10 })
                Text(
                    "重要提示：\n本应用的所有数据均来源于华为应用市场的公开信息，数据仅供参考，不保证来源的准确性、完整性和真实性。",
                )
                    .fontSize(16)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Medium)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 主界面部分
            Column() {
                Text("主界面部分")
                    .fontSize(24)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text("🚀 主要功能\n")
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                Column() {
                    Text(
                        "• 数据统计 - 展示应用总数、元服务总数、开发者总数等关键指标的统计数据。\n",
                    ).fontSize(14)
                    Text(
                        "• 下载榜 - 提供下载量排名前20的应用列表，以及排除华为系应用后的下载量排名。\n",
                    ).fontSize(14)
                    Text(
                        "• 应用详情 - 点击任意应用相关图标查看应用的详细信息，包括下载量、评分、支持设备、版本信息等。\n",
                    ).fontSize(14)
                    Text("• 趋势分析 - 展示应用下载量的变化趋势和增量趋势图表。\n").fontSize(14)
                    Text("• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选功能。\n").fontSize(14)
                }.alignItems(HorizontalAlign.Start)
                Text("📝 使用说明\n")
                    .fontSize(18)
                    .fontWeight(FontWeight.Bold)
                Column() {
                    Text("• 刷新数据 - 点击“刷新数据”按钮获取最新数据").fontSize(14)
                    Text("• 搜索应用 - 支持按名称、包名、开发者等搜索").fontSize(14)
                    Text("• 快速筛选 - 点击组件可快速查看对应应用").fontSize(14)
                    Text("• 排序功能 - 按评分、下载量、大小等排序").fontSize(14)
                    Text("• 查看详情 - 点击应用行查看详细信息").fontSize(14)
                    Text("• 过滤选项 - 可排除华为/元服务应用").fontSize(14)
                }.alignItems(HorizontalAlign.Start)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 分享功能与友情链接
            Column() {
                Text("友情链接与分享功能")
                    .fontSize(24)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text("  您可以在主界面访问友情链接。友情链接页面内点击地球仪图标可以在浏览器内访问页面。\n").fontSize(14)
                Text("  友情链接内网站展示的任何内容均与鸿蒙应用看板无关，Harmony Gallery项目组不负责维护友情链接内容。").fontSize(14).fontColor(Color.Red).margin({ bottom: 20 })
                Text("  1. 链接分享：在主界面或任意应用详情页点击分享按钮分享当前页面链接。\n\n").fontSize(14)
                Text("  2. 碰一碰分享：在任意界面使用碰一碰分享将当前页面链接分享给其他HarmonyOS设备。\n",).fontSize(14)
                KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
                    .margin({ bottom: 20 })
                Text("  3. 隔空传送：在任意界面隔空传送将当前页面链接分享给其他HarmonyOS设备。\n")
                    .fontSize(14)
                Image($r("app.media.grasp"))
                    .width("70%")
                    .height(150)
                    .borderRadius(16)
                    .margin({ bottom: 10 })
                    .borderWidth(1)
                    .borderColor($r("app.color.border"))
                Text("    * 使用前，请确保两台设备均在设置中开启“隔空传送”功能。\n").fontSize(10).fontColor(Color.Grey)
            }
            .height("90%")
            .width("95%")
            .borderRadius(16)
            .padding(20)

            // 投稿与查询功能
            Column() {
                Text("投稿与查询功能")
                    .fontSize(24)
                    .fontColor($r("app.color.diff_content"))
                    .fontWeight(FontWeight.Bold)
                    .margin({ bottom: 20 })
                Text(
                    "  投稿功能可以触发应用抓取与更新，您可以通过【App内投稿】或【在应用市场中分享应用至看板】以投稿新的App或更新App信息。\n\n  在【查询页面】输入应用信息可以查询应用的具体数据，您还可以在应用市场里【分享应用链接至看板】查询信息！",
                ).fontSize(14).margin({ bottom: 10 })

                Row() {
                    Text("  投稿与查询功能支持AI智能提取，将应用信息输入或粘贴进文本框即可自动提取！\n").fontSize(14).blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)
                }
                .linearGradient({
                    direction: GradientDirection.LeftBottom,
                    colors: [
                        [$r("app.color.gradient_start_color"), 0.0],
                        [$r("app.color.gradient_end_color"), 1],
                    ],
                })
                .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
                Row() {
                    Column() {
                        Text(
                            "1. 应用商店投稿与查询：\n" +
                                "  在任意App详情页点击分享并选择应用看板进行投稿与查询。\n",
                        )
                            .fontSize(14)
                            .width("100%")
                        Image($r("app.media.submit_store"))
                            .objectFit(ImageFit.Contain)
                            .borderRadius(16)
                            .margin({ bottom: 10 })
                            .borderWidth(1)
                            .borderColor($r("app.color.border"))
                    }
                    .width("50%")
                    .padding(10)
                    Column() {
                        Text("2. 应用内投稿与查询：\n" + '  在"我的"界面内投稿与查询。\n\n')
                            .fontSize(14)
                            .width("100%")
                        Image($r("app.media.submit_app"))
                            .objectFit(ImageFit.Contain)
                            .borderRadius(16)
                            .margin({ bottom: 10 })
                            .borderWidth(1)
                            .borderColor($r("app.color.border"))
                    }
                    .width("48%")
                    .padding(10)
                }
                .width("100%")
                .height("44%")
                .justifyContent(FlexAlign.SpaceBetween)
            }
            .width("95%")
            .borderRadius(16)
            .padding(20)
        }
        .shadow({
            radius: 20,
            color: Color.Gray,
            offsetX: 0,
            offsetY: 4,
        })
        .loop(false)
        .height(650)
        .effectMode(EdgeEffect.Spring)
        .width(339)
        .borderRadius(20)
        .backgroundColor($r("app.color.backcolor"))
        .indicator(
            new DotIndicator()
                .itemWidth(6)
                .itemHeight(6)
                .selectedItemWidth(12)
                .selectedItemHeight(6)
                .color($r("sys.color.comp_background_secondary"))
                .selectedColor($r("sys.color.comp_background_emphasize")),
        )
        .index(this.currentIndex);
    }
}
