import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { curves, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import {
  hdsEffect,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { APP_VERSION, mainPage } from '../../common/constants';
import { popPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';
import { pageTransition } from '../../common/motion';
import { pressVisualEffect } from '../../common/visualEffects';
import KnockShareGuideCard, { CardRes } from '../../component/KnockShareGuideCard';

interface TutorialSection {
  title: string;
  description: string;
  items: string[];
}

@Component
export struct tutorial {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  @State private pressedCard: string = '';
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
        description: 'S站会直接显示在应用里，适合阅读站内文章、查看动态，或者继续上次没有看完的内容。',
        items: [
          '登录状态、Cookie 和浏览记录会保留下来，下次打开通常不需要重新登录。',
          '应用启动时会提前加载S站，首次切换到这里时通常可以直接浏览。',
          '网页使用独立滚动区域，应用详情等悬浮窗口会直接显示在当前视图中。',
          '打开站内应用详情后，可以使用系统返回键或侧滑返回关闭详情窗口。',
          '加载过程中会显示进度，遇到网络问题也会给出提示。',
          '标题栏右上角可以分享当前网页，也支持通过碰一碰或隔空传送发送当前页面。',
          '再次点一下已经选中的“S站”标签，就能回到 S站首页。',
          '页面滚动位置会被记录，从其他栏目切回来时可以继续阅读。',
          '网页内链接仍在当前页面打开，系统能够处理的外部链接则会交给对应应用。',
          '网络暂时不可用时，页面会给出明确提示，不会让零散的图片加载失败打断浏览。',
        ],
      },
      {
        title: '首页',
        description: '首页汇总了应用市场规模、开发者数量、专题数量、服务状态和最近收录的应用。',
        items: [
          '进入页面时，主要数字会用滚动效果更新到最新数值。',
          '在页面顶部下拉，可以重新获取市场状态和最近收录内容。',
          '点一下“最近收录”中的应用，可以直接打开对应的原生详情页。',
          '平板和宽屏设备采用左右分栏：左边固定显示市场概览，右边可以单独滚动最近收录。',
          '手机上所有内容保持纵向排列，直接上下滑动即可浏览。',
          '没有网络时仍会尽量显示上次成功加载的数据，并标明这些内容来自缓存。',
        ],
      },
      {
        title: '应用概况',
        description: '进入“应用详情”栏目后，顶部的“应用概况”和“应用列表”切换条始终固定，向下浏览时也能随时换页。',
        items: [
          '三个饼图分别展示目标 SDK、最低 SDK 和应用评分分布，版本与星级按从高到低排列。',
          '在窄屏上，两个 SDK 图各自带有图例；屏幕较宽时，它们会放进同一个卡片并共用图例。',
          '点一下饼图扇区或图例，可以高亮对应项目并查看数量和占比。',
          'SDK 版本较多时会先合并成灰色“其他”；标题行的“展开全部”用于查看完整版本，点“其他”或隐藏图标可以隐藏、恢复这部分扇区。',
          'Harmony API 占比历史把所有 API 版本画在同一张折线图上，便于比较版本迁移。',
          '折线图可以点选数据、双指缩放；放大后用单指左右拖动查看不同日期。',
        ],
      },
      {
        title: '应用列表',
        description: '应用列表适合从市场数据中筛选应用，也可以按常用指标重新排序。',
        items: [
          '先选择全部类型、鸿蒙应用或元服务，再按应用名称、分类、标签、开发者等字段筛选。',
          '排序字段和升降序可以组合使用，例如优先查看下载量最高或最近更新的应用。',
          '切换筛选条件后点“筛选”；想回到完整列表时使用“清除筛选”。',
          '每页可以显示 20、50 或 100 条数据，并支持翻页和直接跳到指定页。',
          '窄屏上可以左右滑动表格，查看暂时没有显示出来的字段。',
          '平板和宽屏会利用多出的空间显示开发者等字段，手机布局不会被强行压缩。',
          '点任意应用行即可进入详情；返回列表后，原来的筛选条件和滚动位置会尽量保留。',
        ],
      },
      {
        title: '搜索、查询与收录',
        description: '顶部搜索栏支持应用名称、包名、App ID 和应用市场链接，不需要记住固定格式。',
        items: [
          '搜索栏不会自动弹出键盘，需要搜索时再点一下输入框即可。',
          '没有输入内容时会显示搜索历史和推荐应用；历史记录可以逐条使用，也可以一次清空。',
          '结果较多时会继续分批加载，并根据手机或平板宽度自动调整排列方式。',
          '查到已经收录的应用时会打开详情，并尝试更新市场资料。',
          '查不到应用时，可以按页面提示提交收录；从应用市场分享链接过来，也会进入同一套查询流程。',
          '包名、App ID 或市场链接通常比简称更准确，遇到同名应用时可以优先使用这些信息。',
        ],
      },
      {
        title: '应用详情',
        description: '从首页、搜索结果和应用列表进入的都是同一种原生详情页，资料和操作位置保持一致。',
        items: [
          '页面顶部会显示应用图标、名称、开发者、版本和主要指标，继续下滑可以查看完整字段。',
          '详情字段包括包名、App ID、SDK、Harmony API、下载量、评分、大小、备案与上架时间等信息。',
          '截图区域可以左右滑动；下方还会显示下载量趋势、评分趋势、应用介绍和新版特性。',
          '点“应用市场”可以交给系统打开对应商店页面。',
          '详情暂时加载失败时可以重试；显示缓存内容时，页面会明确标出数据可能不是最新。',
          '下拉刷新会重新查询当前应用，不需要返回列表再次搜索。',
        ],
      },
      {
        title: '分享应用',
        description: 'S站与应用详情右上角都提供分享入口，可以把当前网页或应用详情发送给其他设备与应用。',
        items: [
          '在S站分享时，应用会实时读取当前网页地址，普通系统分享、碰一碰和隔空传送都会发送这个页面。',
          '在应用详情页分享时，分享内容会指向同一款应用，并附带应用图标。',
          '分享应用详情前需要先等待资料加载完成，避免发送缺少名称或图标的卡片。',
          '碰一碰需要双方设备和系统版本支持对应能力，并按系统提示靠近设备。',
          '隔空传送时选择附近设备，接收方确认后即可打开详情链接。',
          '从应用市场把链接分享给本应用时，则用于查询、更新或提交收录，不是转发详情卡片。',
        ],
      },
      {
        title: '我的',
        description: '这里可以修改用户名、振动强度和材质等级，也可以清理缓存或查看项目相关信息。',
        items: [
          '用户名会用于首页问候；修改后无需重新启动应用。',
          '振动强度会同时作用于主要按钮、返回和图表选择，可选择关闭、灵动或硬朗。',
          '材质等级会同步作用于支持的导航栏和切换栏，可按设备性能选择流畅、轻柔或精美。',
          '清理缓存会删除接口缓存、网页缓存和 Cookie，但用户名与设置会保留。',
          '缓存项旁会显示当前占用空间；清理后，S站可能需要重新登录，数据页面也需要重新联网加载。',
          '项目网站、接口文档、更新日志、隐私政策和问题反馈都可以从这里进入。',
          '右上角的问号可以随时重新打开这份教程。',
        ],
      },
      {
        title: '刷新、离线与接续',
        description: '应用会尽量保留正在看的内容，但网络数据和设备接续各有自己的更新规则。',
        items: [
          '首页、应用概况、应用列表和详情页都支持重新加载；下拉刷新时请等待顶部进度结束。',
          '网络中断后，如果本机有缓存，会继续展示上次成功获取的数据，并在页面上标明缓存状态。',
          '缓存只用于临时浏览，市场数量、评分和版本占比仍以恢复联网后的刷新结果为准。',
          '跨设备接续会恢复主栏目、应用详情子页面和已经记录的滚动位置。',
          '接续设备需要安装兼容版本；目标设备无法恢复某项内容时，会回到最接近的可用页面。',
        ],
      },
    ];
  }

  private async openProjectSite(): Promise<void> {
    if (this.vibrationLevel > 0) vibration.dotVibration();
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
    .scale({ x: this.pressedCard === section.title ? 0.985 : 1,
      y: this.pressedCard === section.title ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(
      this.pressedCard === section.title, hdsEffect.PointLightIlluminatedType.BORDER))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.pressedCard = section.title;
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
    })
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
              .padding({ left: 4, right: 4, top: 3, bottom: 3 })
              .borderRadius(8)
              .scale({ x: this.pressedCard === 'project-link' ? 0.96 : 1,
                y: this.pressedCard === 'project-link' ? 0.96 : 1 })
              .animation({ duration: 120, curve: Curve.EaseOut })
              .visualEffect(pressVisualEffect(this.pressedCard === 'project-link',
                hdsEffect.PointLightIlluminatedType.BORDER, 5, 84))
              .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) this.pressedCard = 'project-link';
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
              })
              .onClick(() => this.openProjectSite())
              .accessibilityText('打开Dashboard项目网站')
          }
          .alignItems(HorizontalAlign.Start)
          .width('100%')
          .padding(16)
          .borderRadius(16)
          .backgroundColor($r('app.color.v3_surface'))
          .border({ width: 1, color: $r('app.color.nd_card_border') })
          .scale({ x: this.pressedCard === 'intro' ? 0.985 : 1,
            y: this.pressedCard === 'intro' ? 0.985 : 1 })
          .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.pressedCard === 'intro', hdsEffect.PointLightIlluminatedType.BORDER))
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressedCard = 'intro';
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
          })
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
          .scale({ x: this.pressedCard === 'search-guide' ? 0.985 : 1,
            y: this.pressedCard === 'search-guide' ? 0.985 : 1 })
          .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.pressedCard === 'search-guide', hdsEffect.PointLightIlluminatedType.BORDER))
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressedCard = 'search-guide';
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
          })
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
            Text('碰一碰与隔空传送可以在S站和应用详情页使用。')
              .fontSize(13)
              .fontColor($r('app.color.v3_text_secondary'))
            KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
            Text('使用隔空传送时，可在S站发送当前网页，也可在应用详情页发送带应用图标的详情卡片。')
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
          .scale({ x: this.pressedCard === 'share-guide' ? 0.985 : 1,
            y: this.pressedCard === 'share-guide' ? 0.985 : 1 })
          .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.pressedCard === 'share-guide', hdsEffect.PointLightIlluminatedType.BORDER))
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressedCard = 'share-guide';
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
          })
          .accessibilityGroup(true)

          Text('重要提示：应用展示的市场数据来自公开网络信息，仅供参考，不保证来源的即时性、完整性或准确性。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor($r('app.color.v3_accent_red'))
            .padding(16)
            .width('100%')
            .borderRadius(16)
            .backgroundColor($r('app.color.v3_warning_bg'))
            .scale({ x: this.pressedCard === 'notice' ? 0.985 : 1,
              y: this.pressedCard === 'notice' ? 0.985 : 1 })
            .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
            .visualEffect(pressVisualEffect(
              this.pressedCard === 'notice', hdsEffect.PointLightIlluminatedType.BORDER))
            .onTouch((event: TouchEvent): void => {
              if (event.type === TouchType.Down) this.pressedCard = 'notice';
              else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedCard = '';
            })
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
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if (this.vibrationLevel > 0) vibration.backVibration();
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
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
              subTitleColor: $r('sys.color.font_secondary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
              subTitleColor: $r('sys.color.font_secondary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: this.immersiveMaterialLevel,
        },
      },
      content: {
        title: {
          mainTitle: '教程',
          mainTitleSize: TitleSize.TITLE_S,
        },
        backIcon: {
          action: () => {
            if (this.vibrationLevel > 0) vibration.backVibration();
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
