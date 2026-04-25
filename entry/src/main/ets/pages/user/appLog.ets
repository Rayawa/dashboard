import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';

interface UpdateLog {
    version: string;
    date: string;
    type: "beta" | "rc" | "release";
    isRelease?: boolean;
    items: string[];
}


@Component
struct appLog {
    @Consume('pageStack') pageStack: NavPathStack;
    PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;
    private updateLogs: UpdateLog[] = [
        {
            version: "V2.0.1",
            date: "2026-4-25",
            type: "release",
            isRelease: true,
            items: [
                "T站已恢复开启",
                "修复查询过程中存在的页面不弹出的问题"
            ],
        },
        {
            version: "V2.0.0",
            date: "2026-4-14",
            type: "release",
            isRelease: true,
            items: [
                "大幅重构我的页面逻辑，增加众多页面",
                "改变使用说明逻辑，增加首次启动提示",
                "增加控制器与错误处理，优化主页面体验",
                "增加了项目网站首页链接",
                "为平板、PC与折叠屏适配了分栏显示",
                "修复了分享和投稿页面在退出之后残留在用户后台的问题",
                "修复了App查询返回逻辑不一致的问题",
            ],
        },
        {
            version: "V2.0.0-rc.1",
            date: "2026-3-30",
            type: "rc",
            items: [
                "上线了查询功能，现在可以在app内查询页面输入信息查询应用信息或在应用商店分享到看板查询应用信息！",
                "优化投稿页面和查询页面，增加了侧滑缓冲逻辑与加载页面",
                "将设置弹出逻辑改为半模态",
                "增加了友情链接",
                "重新设置弹出页面统一体验",
                "修改页面导航逻辑，注册路由表",
                "统一震感反馈，修复设置在部分页面不生效的问题。",
                "统一界面操作逻辑，统一悬浮按钮与顶部栏设计",
                "修复了分享页面唤起应用的列表不显示文字的问题",
                "将应用显示名称从HmDashboard更换至鸿蒙应用看板",
            ],
        },
        {
            version: "V2.0.0-beta.1",
            date: "2026-3-20",
            type: "beta",
            items: [
                "增加底部栏与新的站点，适配沉浸式材质效果",
                "增加了新的设置项设置底部栏的自动隐藏",
                "增加用户设置用户名的提示",
                "修复了applog正式版图标不生效的问题",
                "修复了平板与pc设备分享失效的问题",
                "修复了碰一碰卡片的格式问题",
                "修复了顶部栏图标深色模式适配异常的问题",
            ],
        },
        {
            version: "V1.1.2",
            date: "2026-3-16",
            type: "release",
            isRelease: true,
            items: [
                "修复设置不生效的bug",
                "为主界面按钮添加光感",
                "将应用显示名称从应用看板更换至HmDashboard",
                "为主界面按钮添加弹出动画以适应设置",
            ],
        },
        {
            version: "V1.1.1",
            date: "2026-3-4",
            type: "release",
            isRelease: true,
            items: [
                "更改我的页面结构"
            ],
        },
        {
            version: "V1.1.0",
            date: "2026-2-5",
            type: "release",
            isRelease: true,
            items: [
                // "为主界面按钮添加拖动动画，并修复了动画弹出屏幕的问题",
                "新增四个设置项：包括默认站点、振动开关、智感握姿开关和默认按钮位置",
                "新增主题功能，但是暂未开放",
                "App更新日志界面支持筛选功能，可以按发布类型进行筛选",
                "恢复在数个版本前消失的加载进度条",
                "补全了部分丢失的振动反馈，并增加了错误处理",
                "优化提交和查询应用的API，修复返回类型并添加请求选项接口",
                "修复了主界面缩放的问题",
                "修复投稿文本框在页面关闭之后不会清空的问题",
                "修复了切换深色模式按钮颜色不随之变化的问题",
            ],
        },
        {
            version: "V1.1.0-rc.1",
            date: "2025-12-13",
            type: "rc",
            items: [
                "重新设计所有页面顶部条，添加渐变模糊效果",
                "为主界面按钮添加了显示/隐藏和拖动改变位置功能并简化主界面按钮",
                "为所有页面添加了返回逻辑",
                "投稿页面按钮新增波纹动效",
                "为所有页面的交互添加了振动",
                "修复了应用商店“填写信息投稿”自动填充识别功能的异常",
                "为“填写信息投稿”增加了自动关闭的功能",
                "新增设置页面，但是没有实际效果",
            ],
        },
        {
            version: "V1.1.0-beta.4",
            date: "2025-12-9",
            type: "beta",
            items: [
                "为投稿应用功能增加AI识别能力",
                "完善了应用市场填写信息分享功能",
                "增加了主界面的按钮，并可以基于左右手判断",
                "更新了教程页面的文字与图片",
            ],
        },
        {
            version: "v1.1.0-beta.3",
            date: "2025-12-7",
            type: "beta",
            items: [
                "完成按已有信息投稿到看板",
                "在user页面用户名边增加弹窗信息",
                "增加投稿应用功能，并增加蒙版动画",
                "将联系我们界面写为弹窗",
                "修复文本错误与更新图表",
                "删除问题反馈界面并与重写的联系我们合并",
                "修复v2底部与web_log底部存在文字遮挡问题",
                "制作教程界面",
            ],
        },
        {
            version: "V1.1.0-beta.2",
            date: "2025-12-7",
            type: "beta",
            items: [
                "增加shareAbility接口，现在可以通过应用市场投稿app添加信息",
                "网页页面支持一键分享链接",
                "现在可以在任意界面发起分隔空抓取或碰一碰给其他鸿蒙设备",
                "统一了所有web界面UA",
                "在我的界面增加了用户名，App更新日志，问题与反馈与使用教程界面",
                "将V1与V2页面合并，并重新设计导航条与按钮逻辑，优化多处界面",
                "融入原生API组件",
            ],
        },
        {
            version: "V1.0.0",
            date: "2025-12-1",
            type: "release",
            isRelease: true,
            items: ["为备案链接跳转添加了弹窗二次提示", "增加备案信息"],
        },

        {
            version: "V1.0.0-rc1",
            date: "2025-11-29",
            type: "rc",
            items: [
                "#9 fixed，链接现在可以以正常字体大小显示并成功跳转。考虑在rc2添加确认跳转弹窗",
                "#8 fixed，统一了全部页面的margin，新增加color.json重制并统一所有颜色",
                "修改同步版本与版本号",
                "更新UA&删除不必要文件@shenjackyuanjie",
                "重新修改了原user界面至settings界面使其更加美观",
                "对于TopNavBar的图标进行重新排列和更改，删除了原user内ArkWeb页面的非必要MenuItem",
                "新增数据同步功能",
            ],
        },
        {
            version: "V1.0.0-beta.1",
            date: "2025-11-29",
            type: "beta",
            items: ["添加V1与V2的web界面", "添加了user界面", "添加了顶部导航条和menu"],
        },
    ];
    @State private showBeta: boolean = true;
    @State private showRc: boolean = true;
    @State private showRelease: boolean = true;
    @State private filteredLogs: UpdateLog[] = [];

    aboutToAppear() {
        this.updateFilteredLogs();
    }

    toggleFilter(type: "beta" | "rc" | "release") {
                if(this.vibrationON) vibration.dotVibration()
        switch (type) {
            case "beta":
                this.showBeta = !this.showBeta;
                break;
            case "rc":
                this.showRc = !this.showRc;
                break;
            case "release":
                this.showRelease = !this.showRelease;
                break;
        }
        this.updateFilteredLogs();
    }

    build() {
        HdsNavDestination() {
            Scroll() {
                Column() {
                    Column() {
                        ForEach(this.filteredLogs, (log: UpdateLog) => {
                            Column() {
                                Row() {
                                    Column() {
                                        Row() {
                                            Text(log.version)
                                                .fontSize(18)
                                                .fontWeight(FontWeight.Medium)
                                            if (log.isRelease) {
                                                Text("正式版")
                                                    .fontSize(12)
                                                    .padding({
                                                        left: 6,
                                                        right: 6,
                                                        top: 2,
                                                        bottom: 2,
                                                    })
                                                    .backgroundColor("#FF6A39")
                                                    .fontColor("#fff")
                                                    .borderRadius(6)
                                                    .margin({ left: 8 });
                                            }
                                        }
                                        Text(log.date)
                                            .fontSize(13)
                                            .fontColor("#999")
                                            .margin({ top: 4 })
                                    }
                                }
                                Column({ space: 5 }) {
                                    ForEach(log.items, (item: string) => {
                                        Row() {
                                            Text("•")
                                                .fontSize(16)
                                                .fontWeight(600)
                                                .fontColor("#666")
                                            Text(item)
                                                .margin({ left: 5 })
                                                .fontSize(15)
                                                .lineHeight(20)
                                                .flexShrink(1)
                                        }
                                        .justifyContent(FlexAlign.Start)
                                        .width("100%")
                                        .padding({ right: 5 });
                                    })
                                }
                                .margin({ top: 10 })
                            }
                            .padding(16)
                            .borderRadius(16)
                            .backgroundColor($r("app.color.background"))
                            .shadow({
                                radius: 8,
                                color: "#1a000000",
                                offsetX: 0,
                                offsetY: 2,
                            })
                            .width("90%")
                            .margin({ bottom: 16 });
                        })
                    }
                    .width("100%")
                    .alignItems(HorizontalAlign.Center)

                    if (this.filteredLogs.length === 0) {
                        Column() {
                            Image($r("app.media.empty"))
                                .borderRadius($r("sys.float.corner_radius_level6"))
                            Text("暂无符合条件的日志")
                                .fontWeight(800)
                                .fontSize(30)
                                .margin({ top: 10 })
                                .fontColor($r("app.color.diff_content"))
                        }
                        .width("100%")
                        .justifyContent(FlexAlign.Center)
                        .alignItems(HorizontalAlign.Center);
                    }
                }
                .margin({ top: 60, bottom: 20 })
                .width("100%")
                .alignItems(HorizontalAlign.Center)
            }
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
            .backgroundColor($r("app.color.backcolor"))
        }
        .onBackPressed(() => {
                    if(this.vibrationON) vibration.dotVibration()
            return false;
        })
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: true,
                    scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
                    blurEffectiveStartOffset: LengthMetrics.vp(0),
                    blurEffectiveEndOffset: LengthMetrics.vp(20),
                },
                originalStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
                scrollEffectStyle: {
                    backgroundStyle: {
                        backgroundColor: $r("sys.color.ohos_id_color_background_transparent"),
                    },
                    contentStyle: {
                        titleStyle: {
                            mainTitleColor: $r("sys.color.font_primary"),
                            subTitleColor: $r("sys.color.font_secondary"),
                        },
                        menuStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                        backIconStyle: {
                            backgroundColor: $r("sys.color.comp_background_tertiary"),
                            iconColor: $r("sys.color.icon_primary"),
                        },
                    },
                },
                systemMaterialEffect: this.immersiveTextureON ? {
                    materialType: hdsMaterial.MaterialType.IMMERSIVE,
                    materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
                } : undefined
            },
            content: {
                title: {
                    mainTitle: "App更新日志",
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: "beta",
                                icon: this.showBeta ? $r("app.media.betaON") : $r("app.media.beta"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("beta");
                                    this.PromptAction.showToast({
                                        message: this.showBeta
                                            ? "打开Beta版本日志"
                                            : "关闭Beta版本日志",
                                        duration: 500,
                                    });
                                },
                            },
                        },
                        {
                            content: {
                                label: "rc",
                                icon: this.showRc ? $r("app.media.rcON") : $r("app.media.rc"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("rc");
                                    this.PromptAction.showToast({
                                        message: this.showRc
                                            ? "打开ReleaseCandidate版本日志"
                                            : "关闭ReleaseCandidate版本日志",
                                        duration: 500,
                                    });
                                },
                            },
                        },
                        {
                            content: {
                                label: "release",
                                icon: this.showRelease
                                    ? $r("app.media.releaseON")
                                    : $r("app.media.release"),
                                isEnabled: true,
                                action: () => {
                                    this.toggleFilter("release");
                                    this.PromptAction.showToast({
                                        message: this.showRelease
                                            ? "打开正式版日志"
                                            : "关闭正式版日志",
                                        duration: 500,
                                    });
                                },
                            },
                        },
                    ],
                },
                backIcon: {
                    action: () => {
                                if(this.vibrationON) vibration.dotVibration()
                        this.pageStack.pop()
                    },
                },
            },
        });

    }

    private updateFilteredLogs() {
        this.filteredLogs = this.updateLogs.filter((log) => {
            switch (log.type) {
                case "beta":
                    return this.showBeta;
                case "rc":
                    return this.showRc;
                case "release":
                    return this.showRelease;
                default:
                    return true;
            }
        });
    }
}

@Builder
export function AppLogBuilder(){
    appLog()
}
