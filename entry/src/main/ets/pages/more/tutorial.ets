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
        description: '你可以在这里直接浏览 S站。想看最新内容时下拉刷新，想快速回到开头时使用标题栏按钮。',
        items: [
          '登录状态和浏览记录会保留下来，下次打开不用从头开始。',
          '再次点一下已经选中的“S站”标签，就能回到 S站首页。',
          '网络暂时不可用时，页面会给出明确提示，不会让零散的图片加载失败打断浏览。',
        ],
      },
      {
        title: '首页',
        description: '首页汇总了应用市场规模、开发者数量、专题数量、服务状态和最近收录的应用。',
        items: [
          '进入页面时，主要数字会用滚动效果更新到最新数值。',
          '在页面顶部下拉，可以重新获取市场状态和最近收录内容。',
          '没有网络时仍会尽量显示上次成功加载的数据，并标明这些内容来自缓存。',
        ],
      },
      {
        title: '应用搜索',
        description: '想找一款应用时，可以输入应用名称、包名、App ID，也可以直接粘贴应用市场链接。',
        items: [
          '搜索前会显示最近使用过的关键词和推荐应用，历史记录可以随时清空。',
          '搜索结果会根据手机或平板的宽度自动排版。',
          '找到已有应用后会顺便更新资料；如果还未收录，可以提交收录请求。',
          '应用列表向下滚动后，标题栏会出现搜索入口，方便随时开始新的查询。',
        ],
      },
      {
        title: '应用概况与列表',
        description: '在顶部切换“应用概况”和“应用列表”，可以从整体趋势一路查看到某一款应用的详细资料。',
        items: [
          '概况里可以查看评分分布、最低与目标 SDK 分布，以及各 Harmony API 版本占比的变化。',
          '点一下图表即可查看具体数据；折线较密时，可以双指放大，再左右拖动。',
          '列表可以按应用类型、分类、标签和开发者等条件筛选，也能切换排序方式。',
          '每页可以显示 20、50 或 100 条数据，并支持翻页和直接跳到指定页。',
          '窄屏上可以左右滑动表格，查看暂时没有显示出来的字段。',
          '点开应用后，可以查看版本、开发者、下载量、评分、SDK、截图、更新记录和应用介绍。',
        ],
      },
      {
        title: '我的',
        description: '这里可以修改用户名、振动反馈和沉浸式材质，也可以清理缓存或查看项目相关信息。',
        items: [
          '清理缓存会删除接口缓存、网页缓存和 Cookie，但用户名与设置会保留。',
          '项目网站、接口文档、更新日志、隐私政策和问题反馈都可以从这里进入。',
          '右上角的问号可以随时重新打开这份教程。',
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
            Text('这是一款用来浏览鸿蒙应用市场数据的看板。你可以查看市场概况、搜索应用、比较趋势，也可以从列表进入每款应用的详细页面。')
              .fontSize(14)
              .lineHeight(21)
              .fontColor($r('app.color.v3_text_primary'))
              .width('100%')
              .accessibilityText('可以查看市场概况、搜索应用、比较趋势并打开应用详情')
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
            Text('在应用页面顶部输入名称、包名或 App ID 即可搜索；从应用市场分享过来的链接也能直接识别。找到应用后可以打开详情，如果尚未收录，也可以提交收录请求。')
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
                Text('2. 在应用详情顶部直接查询')
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
            Text('无论从首页、搜索结果还是应用列表进入，都会打开同一种详情页面。下拉可以更新资料，右上角可以把这款应用的 S站详情卡片分享出去。')
              .fontSize(14)
              .lineHeight(21)
              .fontColor($r('app.color.v3_text_primary'))
              .width('100%')
              .accessibilityText('所有入口统一进入原生应用详情模板')
            Text('碰一碰与隔空传送可以在应用详情页使用。')
              .fontSize(13)
              .fontColor($r('app.color.v3_text_secondary'))
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
            Text('使用隔空传送时，先在应用详情页打开分享，再选择附近设备，即可发送带应用图标的 S站详情卡片。')
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
      .accessibilityText('可滚动的应用使用教程')
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
