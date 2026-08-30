import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType, TitleSize } from '@kit.UIDesignKit';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { vibration } from '../../common/vibration';
import { popPathSafely, pushPathSafely } from '../../common/safeNavigation';

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
    private PromptAction: PromptAction = this.getUIContext().getPromptAction();
    @StorageLink("vibrationON") vibrationON: boolean = true;
    @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
    private updateLogs: UpdateLog[] = [
        {
            version: "V3.0.0",
            date: "2026-8-30",
            type: "release",
            isRelease: true,
            items: [
                "主界面重构为固定标题栏与五个 HdsTabs：S站、首页、搜索、应用总表、我的，取消标签切换位移动画",
                "新增原生首页与同步状态卡片，展示最后更新时间、服务状态和市场核心指标",
                "首页与应用概况合并；图表改为独立并行加载，单项失败不再阻断其余图表",
                "搜索、投稿、更新与系统分享入口合并为唯一 shareAbility；新应用自动 simple 投稿，已有应用自动 query 更新",
                "新增公用原生应用详情模板，统一查询、列表、深链和分享入口的详情展示流程",
                "详情信息改为高密度标签与文字组合，并补齐按钮分享、碰一碰、隔空传送及图标卡片预览",
                "应用总表移除重复搜索，新增20/50/100条分页、多字段升降序排序和指定页数跳转，修复高度受限与无法上下滑动",
                "我的页面恢复旧版栏目、分割线与统一卡片样式；用户名并入设置首项且仅在主动编辑时弹出键盘",
                "清除缓存项恢复说明问号并显示缓存文件总大小",
                "原生主页面和详情页补齐振动反馈，并按页面与滚动位置恢复跨设备接续",
                "全部子页面统一使用 Scroll、MINI 标题模式、TITLE_S 主标题和系统上下安全区忽略配置",
                "恢复首次进入重要提示与各页面教程入口；再次点击当前标签返回顶部，S站返回首页",
                "统一所有API请求的User-Agent，修复S站子资源失败误报与网页显示比例问题",
                "分享卡片改用详细预览并附带32KB以内的应用AppIcon缩略图",
                "移除底部栏自动隐藏设置，恢复根导航渐变模糊与diff_content全局光效",
                "整理 ETS 目录为 main、detail、more 与 charts 分层，并移除已退出编译流程的旧页面和旧分享入口",
                "新增带有效期的 API 磁盘缓存与网络失败回退提示；清除缓存覆盖 API 缓存、ArkWeb 存储和 Cookie",
                "修复缓存写入、点击事件与图表尺寸命名导致的 ArkTS 编译错误，并为文件、窗口、网络、弹窗和设备能力调用补齐异常回退与统一日志",
                "修复导航参数对象、滚动恢复回调和 HdsNavDestination 标题模式的 ArkTS 类型错误，移除 2in1 不可用的视口配置与不兼容设备能力监听",
                "按 600vp 与 840vp 断点完善手机、平板和 2in1 响应式布局，并补充中文无障碍播报标签",
                "版本更新为 3.0.0，构建号更新为 30000005",
            ],
        },
        {
            version: "V2.2.1-beta.1",
            date: "2026-8-16",
            type: "beta",
            items: [
                "新增原生看板，可直接查看应用概览、评分与SDK分布、应用列表等信息",
                "优化原生看板响应式布局，统计与分布卡片会根据屏幕宽度自动调整",
                "优化设置数据的初始化与持久化，提升应用重启后的状态恢复可靠性",
                "隔离查询、投稿与分享表单状态，修复不同入口之间可能出现的内容串扰",
                "改进应用接续、查询与分享页面的状态传递和恢复机制",
            ],
        },
        {
            version: "V2.2.0",
            date: "2026-7-24",
            type: "release",
            isRelease: true,
            items: [
                "更新智感握持动画，现在按钮不会从屏幕中间经过",
                "将教程页面单独分屏显示，并在我的页面内添加教程入口",
                "调整查询应用、投稿/更新应用于联系我们的界面形式",
                "按钮现在会在用户点击的位置出现，并略微调宽侧边点击出现区域的宽度",
                "不支持智感握持的设备讲不再显示相关设置项",
                "优化了主页面的性能，减少卡顿的同时修复了分享可能会导致应用崩溃的问题",
                "修复了应用接续失败或者接续内容错误的问题，同在2.2.0以上版本的设备现在可以进行正常接续",
                // "修复了特殊情况下查询app页面不加载的问题，此为鸿蒙系统问题，请更新设备到6.1.1(API24)以上版本已解决此问题",
                "修复拖动按钮位置时有小概率修改智感握持设置的问题",
                "修复手机端用户界面侧滑返回会直接退出应用的问题，并强化了所有返回逻辑",
                "修复特定平板设备上展开用户界面分栏时内容显示的问题",
                "修复特定设备上用户界面无法打开的问题",
                "修复友情链接界面在特殊情况下打开页面侧滑返回会直接退出应用的问题",
            ],
        },
        {
            version: "V2.1.0",
            date: "2026-5-13",
            type: "release",
            isRelease: true,
            items: [
                "将应用显示名称从Hm应用看板更换至Dashboard应用看板",
                "更新部分UI",
                "更新隐私协议"
            ],
        },
        {
            version: "V2.0.3",
            date: "2026-5-9",
            type: "release",
            isRelease: true,
            items: [
                "修复了特定网络环境下访问不到S站的问题",
                "更新友情链接",
                "修复已知问题，提升应用稳定性"
            ],
        },
        {
            version: "V2.0.2",
            date: "2026-5-1",
            type: "release",
            isRelease: true,
            items: [
                "修复分享到看板查询页面不加载的严重bug",
                "调整了UA",
                "更新隐私协议，增加了对于用户数据访问的声明"
            ],
        },
        {
            version: "V2.0.1",
            date: "2026-4-25",
            type: "release",
            isRelease: true,
            items: [
                "T站已恢复开启",
                "修复查询过程中存在的页面不弹出的问题",
                "将应用显示名称从鸿蒙应用看板更换至Hm应用看板",
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

    aboutToAppear(): void {
        this.updateFilteredLogs();
    }

    toggleFilter(type: "beta" | "rc" | "release"): void {
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
                    Blank().height(40).width('100%')
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
                .margin({ bottom: 20 })
                .width("100%")
                .alignItems(HorizontalAlign.Center)
            }
            .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
            .width("100%")
            .height("100%")
            .backgroundColor($r("app.color.backcolor"))
            .accessibilityText('可滚动的应用更新日志')
        }
        .onBackPressed(() => {
                    if(this.vibrationON) vibration.dotVibration()
            return false;
        })
        .titleMode(HdsNavDestinationTitleMode.MINI)
        .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
        .titleBar({
            style: {
                scrollEffectOpts: {
                    enableScrollEffect: false,
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
                    mainTitleSize: TitleSize.TITLE_S,
                },
                menu: {
                    value: [
                        {
                            content: {
                                label: '教程',
                                icon: $r('sys.symbol.questionmark_circle'),
                                isEnabled: true,
                                action: () => {
                                    if (this.vibrationON) vibration.dotVibration();
                                    pushPathSafely(this.pageStack, 'TutorialPage');
                                },
                            },
                        },
                        {
                            content: {
                                label: "筛选Beta日志",
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
                                label: "筛选RC日志",
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
                                label: "筛选正式版日志",
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
                        popPathSafely(this.pageStack, 'pages/more/appLog')
                    },
                },
            },
        })
        .accessibilityText('应用更新日志导航页');

    }

    private updateFilteredLogs(): void {
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
