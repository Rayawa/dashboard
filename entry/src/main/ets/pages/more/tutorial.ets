import KnockShareGuideCard, { CardRes } from '../../component/KnockShareGuideCard';
import { vibration } from '../../common/vibration';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { mainPage } from '../../common/constants';
import {
  hdsMaterial,
  HdsNavDestination,
  HdsNavigationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { popPathSafely } from '../../common/safeNavigation';

@Component
export struct tutorial {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
  PromptAction: PromptAction = this.getUIContext().getPromptAction();
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
    HdsNavDestination() {

      Scroll() {
        Column({ space: 16 }) {
          Blank().height(30)
          // 欢迎页面
          Column({ space: 10 }) {
            Text("欢迎来到Dashboard应用看板")
              .fontSize(24)
              .fontColor($r("app.color.diff_content"))
              .fontWeight(FontWeight.Bold)
            Text("详情请查看：项目总网页")
              .fontSize(14)
              .fontColor(Color.Blue)
              .decoration({
                type: TextDecorationType.Underline,
                color: Color.Blue
              })
              .onClick(async () => {
                if (this.vibrationON) vibration.dotVibration();
                const ui_content = this.getUIContext();
                try {
                  this.PromptAction.showToast({
                    message: "正在跳转...",
                    duration: 500
                  });
                  let context = ui_content.getHostContext() as common.UIAbilityContext;
                  await context.startAbility({
                    action: "ohos.want.action.viewData",
                    entities: ["entity.system.browsable"],
                    uri: mainPage.toString(),
                  } as Want);
                } catch (error) {
                  console.error('[Dashboard][pages/tutorial][ERROR]', "打开链接失败:", (error as BusinessError).message);
                  this.PromptAction.showToast({
                    message: "打开链接失败",
                    duration: 1000
                  });
                }
              })
            Text(
              "本应用是由Harmony Dashboard项目组直接参与编写的鸿蒙应用。应用收集华为应用市场的公开数据，转化为直观的图表与报告。\n\n" +
                "1. 数据总览与图表分析：\n   通过榜单、饼图与折线图，直观查看应用评分趋势与市场分布。\n\n" +
                "2. 搜索应用与查看详情：\n   支持按名称、评分等条件搜索排序、应用内搜索应用、分享链接搜索应用。\n\n" +
                "3. 数据定时自动更新：\n   后台每30分钟同步一次数据。\n\n" +
                "4. 交互式操作与分享：\n   点击图表可进行数据筛选，也可以通过链接、隔空抓取或碰一碰分享。\n\n" +
                "5. 投稿更新应用信息：\n   可以通过应用市场分享与我的页面投稿。"
            )
              .fontSize(14)
            Text(
              "重要提示：\n本应用的所有数据均来源于华为应用市场的公开信息，数据仅供参考，不保证来源的准确性、完整性和真实性。"
            )
              .fontSize(14)
              .fontColor(Color.Red)
              .fontWeight(FontWeight.Medium)
          }
          .alignItems(HorizontalAlign.Start)
          .width("100%")
          .borderRadius(16)
          .padding(16)
          .backgroundColor($r("sys.color.comp_background_primary"))
          // 主界面
          Column({ space: 12 }) {
            Text("主界面")
              .fontSize(20)
              .fontColor($r("app.color.diff_content"))
              .fontWeight(FontWeight.Bold)
            Text("🚀 主要功能")
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Text("• 数据统计 - 展示应用总数、元服务总数、开发者总数等关键指标。")
              .fontSize(14)
            Text("• 应用榜单 - 提供多维度的应用数据概览。")
              .fontSize(14)
            Text("• 应用详情 - 查看评分、支持设备、版本信息等。")
              .fontSize(14)
            Text("• 趋势分析 - 展示应用评分变化趋势。")
              .fontSize(14)
            Text("• 应用列表 - 支持搜索、排序、筛选。")
              .fontSize(14)
            Text("📝 使用说明")
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
            Text("• 刷新数据 - 获取最新数据")
              .fontSize(14)
            Text("• 搜索应用 - 支持名称、包名、开发者搜索")
              .fontSize(14)
            Text("• 查看详情 - 点击应用查看详细信息")
              .fontSize(14)
          }
          .alignItems(HorizontalAlign.Start)
          .width("100%")
          .borderRadius(16)
          .padding(16)
          .backgroundColor($r("sys.color.comp_background_primary"))
          // 投稿功能
          Column({ space: 12 }) {
            Text("投稿与查询功能")
              .fontSize(20)
              .fontColor($r("app.color.diff_content"))
              .fontWeight(FontWeight.Bold)
            Text(
              "投稿功能可以触发应用抓取与更新，您可以通过App内【投稿应用】或应用市场分享进行投稿。\n\n" +
                "在【查询应用】输入应用信息可以查询应用数据。"
            )
              .fontSize(14)
            Text("投稿与查询功能支持AI智能提取，将文本输入即可自动提取。")
              .fontSize(14)
              .fontColor($r("app.color.gradient_start_color"))
            Flex({
              wrap: FlexWrap.Wrap,
              justifyContent: FlexAlign.Center,
              alignItems: ItemAlign.Center
            }) {
              Column({ space:8 }) {
                Text("1. 应用商店投稿与查询")
                  .fontSize(13)
                Image($r("app.media.submit_store"))
                  .width(320)
                  .height(520)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(7)
                  .borderWidth(1)
                  .borderColor($r("app.color.border"))
              }
              Column({ space:8 }) {
                Text("2. 应用内投稿与查询")
                  .fontSize(13)
                Image($r("app.media.submit_app"))
                  .width(320)
                  .height(520)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(7)
                  .borderWidth(1)
                  .borderColor($r("app.color.border"))
              }
            }
            .width("100%")
          }
          .alignItems(HorizontalAlign.Start)
          .width("100%")
          .borderRadius(16)
          .padding(16)
          .backgroundColor($r("sys.color.comp_background_primary"))
          // 分享功能
          Column({ space:10 }) {
            Text("友情链接与分享功能")
              .fontSize(20)
              .fontColor($r("app.color.diff_content"))
              .fontWeight(FontWeight.Bold)
            Text("您可以在主界面访问友情链接。友情链接页面内点击地球仪图标可以在浏览器访问页面。")
              .fontSize(14)
            Text("1. 链接分享：在主界面或应用详情页点击分享按钮分享当前页面链接。")
              .fontSize(14)
            Text("2. 碰一碰分享：在任意界面使用碰一碰分享当前页面链接。")
              .fontSize(14)
            KnockShareGuideCard({
              cardSwiperResources: this.cardSwiperResourcesPhone
            })
            Text("3. 隔空传送：在任意界面隔空传送分享页面链接。")
              .fontSize(14)
            Image($r("app.media.grasp"))
              .width(350)
              .height(200)
              .objectFit(ImageFit.Contain)
              .borderRadius(16)
              .borderWidth(1)
              .borderColor($r("app.color.border"))
            Text("* 使用前，请确保两台设备均在设置中开启“隔空传送”功能。")
              .fontSize(11)
              .fontColor(Color.Grey)
          }
          .alignItems(HorizontalAlign.Start)
          .width("100%")
          .borderRadius(16)
          .padding(16)
          .backgroundColor($r("sys.color.comp_background_primary"))
        }
        .padding(16)
        .width("100%")
      }
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width("100%")
      .height("100%")

    }
    .titleMode(HdsNavigationTitleMode.MINI)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onWillDisappear(() => {
      if (this.vibrationON) vibration.dotVibration();
    })
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: false,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20),
        },
        originalStyle: {
          backgroundStyle: { backgroundColor: $r("sys.color.ohos_id_color_background") },
          contentStyle: {
            titleStyle: { mainTitleColor: $r("sys.color.font_primary"), subTitleColor: $r("sys.color.font_secondary") },
            menuStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
            backIconStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: { backgroundColor: $r("sys.color.ohos_id_color_background_transparent") },
          contentStyle: {
            titleStyle: { mainTitleColor: $r("sys.color.font_primary"), subTitleColor: $r("sys.color.font_secondary") },
            menuStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
            backIconStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
          },
        },
        systemMaterialEffect: this.immersiveTextureON ? {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        } : { }
      },
      content: {
        title: {
          mainTitle: "教程页面",
          mainTitleSize: TitleSize.TITLE_S,
        },
        backIcon: {
          action: () => {
            if(this.vibrationON) vibration.dotVibration()
            popPathSafely(this.pageStack, 'pages/more/tutorial');
          },
        },
      },
    });
  }
}

@Builder
export function TutorialPageBuilder(){
  tutorial()
}
