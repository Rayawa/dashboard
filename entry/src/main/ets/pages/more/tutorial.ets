import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import {
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { APP_VERSION, mainPage } from '../../common/constants';
import { popPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';
import KnockShareGuideCard, { CardRes } from '../../component/KnockShareGuideCard';

interface TutorialSection {
  title: string;
  description: string;
  items: string[];
}

@Component
export struct tutorial {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('vibrationON') vibrationON: boolean = true;
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  private readonly cardSwiperResourcesPhone: CardRes[] = [{
    text: '对方手机需支持相应的 HarmonyOS 分享能力。',
    rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
    framesCount: 128,
    startDelay: 50,
    stopDelay: 500,
  }];

  private sections(): TutorialSection[] {
    return [
      {
        title: 'S站',
        description: '以 ArkWeb 打开项目网页，标题栏提供刷新和回到顶部。再次点击已选中的“S站”标签会返回 S站首页。',
        items: [
          '网页使用应用专用 User-Agent，并保留站点登录、缓存和网页导航能力。',
          '仅主页面加载失败时显示网络提示，单个图片或脚本失败不会遮挡整个网页。',
        ],
      },
      {
        title: '首页',
        description: '集中展示欢迎信息、更新时间、服务状态、精确市场统计和最近收录应用。',
        items: [
          '右上角刷新会更新市场状态与最近收录应用。',
          '网络不可用时优先显示仍可用的本地缓存，并明确标注缓存状态。',
        ],
      },
      {
        title: '搜索',
        description: '统一处理应用名称、包名、App ID、应用市场链接和系统分享内容。',
        items: [
          '名称搜索显示全部匹配结果，每列 20 个，横向滚动可查看后续列。',
          '已有应用在结果加载后静默执行一次后台更新；新应用自动投稿并提示。',
          '进入页面不会自动弹出键盘，只有用户主动点击输入框时才输入。',
        ],
      },
      {
        title: '应用详情',
        description: '上方二选一切换应用概况与应用列表；列表支持排序、分页并进入统一详情模板。',
        items: [
          '应用概况提供评分、SDK 分布和 Harmony API 历史图表。',
          '每页可选择 20、50 或 100 条数据。',
          '表格可横向查看完整字段，页面可纵向滚动。',
          '支持升降序切换、上一页、下一页和输入页码跳转。',
        ],
      },
      {
        title: '我的',
        description: '管理用户名、振动、缓存和界面设置，并访问项目网站、API 文档、日志、隐私政策等入口。',
        items: [
          '清除缓存会删除 API 缓存、ArkWeb 缓存和 Cookie，但保留用户名与设置。',
          '右上角问号可随时重新打开本教程。',
        ],
      },
    ];
  }

  private async openProjectSite(): Promise<void> {
    if (this.vibrationON) vibration.dotVibration();
    try {
      showToastSafely(this.prompt, '正在跳转…', 500, 'Tutorial');
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: mainPage.toString(),
      } as Want);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error('[Dashboard][pages/more/tutorial][ERROR]', `打开项目网站失败: ${businessError.message}`);
      showToastSafely(this.prompt, '打开项目网站失败', 1000, 'Tutorial');
    }
  }

  @Builder
  sectionCard(section: TutorialSection): void {
    Column({ space: 10 }) {
      Text(section.title)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.diff_content'))
        .width('100%')
        .accessibilityText(section.title)
      Text(section.description)
        .fontSize(14)
        .lineHeight(21)
        .fontColor($r('app.color.v3_text_primary'))
        .width('100%')
        .accessibilityText(section.description)
      ForEach(section.items, (item: string) => {
        Row({ space: 8 }) {
          Text('•')
            .fontSize(16)
            .fontColor($r('app.color.diff_content'))
          Text(item)
            .fontSize(13)
            .lineHeight(20)
            .fontColor($r('app.color.v3_text_secondary'))
            .layoutWeight(1)
            .accessibilityText(item)
        }
        .width('100%')
        .alignItems(VerticalAlign.Top)
      }, (item: string) => `${section.title}-${item}`)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .accessibilityGroup(true)
    .accessibilityText(`${section.title}使用说明`)
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 16 }) {
          Blank().height(100).width('100%')

          Column({ space: 10 }) {
            Text('Dashboard 应用看板使用教程')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.diff_content'))
              .width('100%')
              .accessibilityText('Dashboard应用看板使用教程')
            Text(`版本 ${APP_VERSION}`)
              .fontSize(13)
              .fontColor($r('app.color.v3_text_secondary'))
              .width('100%')
              .accessibilityText(`版本${APP_VERSION}`)
            Text('应用采用五个固定标签页与统一原生详情页。页面右上角的问号可以重新进入教程。')
              .fontSize(14)
              .lineHeight(21)
              .fontColor($r('app.color.v3_text_primary'))
              .width('100%')
              .accessibilityText('应用采用五个固定标签页与统一原生详情页')
            Text('打开项目网站')
              .fontSize(14)
              .fontColor($r('app.color.diff_content'))
              .decoration({ type: TextDecorationType.Underline, color: $r('app.color.diff_content') })
              .onClick(() => this.openProjectSite())
              .accessibilityText('打开Dashboard项目网站')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.v3_surface'))
          .border({ width: 1, color: $r('app.color.nd_card_border') })
          .accessibilityGroup(true)

          ForEach(this.sections(), (section: TutorialSection) => {
            this.sectionCard(section)
          }, (section: TutorialSection) => section.title)

          Column({ space: 12 }) {
            Text('搜索、投稿与查询')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.diff_content'))
              .width('100%')
            Text('搜索页统一接收应用名称、包名、App ID、应用市场链接以及系统分享内容。已有应用静默更新，新应用自动执行 simple 投稿。')
              .fontSize(14)
              .lineHeight(21)
              .fontColor($r('app.color.v3_text_primary'))
              .width('100%')
            Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center, alignItems: ItemAlign.Center }) {
              Column({ space: 8 }) {
                Text('1. 从应用市场分享查询')
                  .fontSize(13)
                  .fontColor($r('app.color.v3_text_secondary'))
                Image($r('app.media.submit_store'))
                  .width(300)
                  .height(500)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(8)
                  .border({ width: 1, color: $r('app.color.border') })
                  .accessibilityText('从应用市场分享查询示意图')
              }
              .margin(6)
              Column({ space: 8 }) {
                Text('2. 在搜索页直接查询')
                  .fontSize(13)
                  .fontColor($r('app.color.v3_text_secondary'))
                Image($r('app.media.submit_app'))
                  .width(300)
                  .height(500)
                  .objectFit(ImageFit.Contain)
                  .borderRadius(8)
                  .border({ width: 1, color: $r('app.color.border') })
                  .accessibilityText('应用内搜索查询示意图')
              }
              .margin(6)
            }
            .width('100%')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.v3_surface'))
          .border({ width: 1, color: $r('app.color.nd_card_border') })
          .accessibilityGroup(true)
          .accessibilityText('搜索投稿与查询教程')

          Column({ space: 10 }) {
            Text('应用详情与分享')
              .fontSize(20)
              .fontWeight(FontWeight.Bold)
              .fontColor($r('app.color.diff_content'))
              .width('100%')
            Text('所有查询、列表、分享和深链最终都进入同一个原生应用详情模板。详情页右上角可更新数据或分享 S站链接卡片。')
              .fontSize(14)
              .lineHeight(21)
              .fontColor($r('app.color.v3_text_primary'))
              .width('100%')
              .accessibilityText('所有入口统一进入原生应用详情模板')
            Text('碰一碰与隔空传送仅在应用详情页启用。')
              .fontSize(13)
              .fontColor($r('app.color.v3_text_secondary'))
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
            Text('隔空传送：在应用详情页调出分享后，可使用系统隔空传送能力发送带图标的 S站详情卡片。')
              .fontSize(13)
              .lineHeight(20)
              .fontColor($r('app.color.v3_text_secondary'))
            Image($r('app.media.grasp'))
              .width('100%')
              .height(210)
              .objectFit(ImageFit.Contain)
              .borderRadius(12)
              .border({ width: 1, color: $r('app.color.border') })
              .accessibilityText('隔空传送操作示意图')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.v3_surface'))
          .border({ width: 1, color: $r('app.color.nd_card_border') })
          .accessibilityGroup(true)

          Text('重要提示：应用展示的市场数据来自公开网络信息，仅供参考，不保证来源的即时性、完整性或准确性。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor($r('app.color.v3_accent_red'))
            .padding(16)
            .width('100%')
            .borderRadius(16)
            .backgroundColor($r('app.color.v3_warning_bg'))
            .accessibilityText('应用数据来源重要提示')

          Blank().height(32)
        }
        .padding({ left: 16, right: 16 })
        .width('100%')
      }
      .backgroundColor($r('app.color.backcolor'))
      .width('100%')
      .height('100%')
      .accessibilityText('可滚动的最新架构教程')
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if (this.vibrationON) vibration.dotVibration();
      popPathSafely(this.pageStack, 'pages/more/tutorial');
      return true;
    })
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: false,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20),
        },
      },
      content: {
        title: {
          mainTitle: '教程',
          mainTitleSize: TitleSize.TITLE_S,
        },
        backIcon: {
          action: () => {
            if (this.vibrationON) vibration.dotVibration();
            popPathSafely(this.pageStack, 'pages/more/tutorial');
          },
        },
      },
    })
    .accessibilityText('教程导航页')
  }
}

@Builder
export function TutorialPageBuilder(): void {
  tutorial()
}
