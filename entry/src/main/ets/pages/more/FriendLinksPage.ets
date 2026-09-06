import {
  hdsEffect,
  HdsListItemCard,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  IconSize,
  PrefixCustomBuilder,
  PrefixIcon,
  ScrollEffectType,
  SuffixCustomBuilder,
  TitleSize
} from '@kit.UIDesignKit';
import { vibration } from '../../common/vibration';
import { curves, LengthMetrics, PromptAction, TextModifier } from '@kit.ArkUI';
import {
  AGstatisticsURL,
  CONTENT_MAX_WIDTH,
  dztapURL,
  EGUI_URL,
  FANGZHOU_URL,
  GETRACE_URL,
  HapStoreURL,
  LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
  LIST_ITEM_PREFIX_MARGIN,
  LIST_ITEM_SUFFIX_MARGIN,
  LIST_PAGE_HORIZONTAL_PADDING,
  LIST_SECTION_CONTENT_GAP,
  LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
  LIST_SECTION_SPACING,
  LIST_SECTION_TITLE_START_PADDING,
  NEXTStoreURL,
  OpenStoreURL,
  PAPER_TALK_URL,
  PROJECT_HOME_URL,
  ROUTE_WEB_PAGE,
  SBaseURL,
  SUBSCRIPTION_ATOMIC_URL,
  SUBSCRIPTION_URL,
  T_DASHBOARD_URL,
  WEB_PAGE_FRIEND_LINK_TOP_INSET,
} from '../../common/constants';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { common, Want } from '@kit.AbilityKit';
import { popPathSafely, pushPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { cancelStaggerEnterAnimation, pageTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { WebPageParams } from '../web/WebPage';

interface LinkConfig {
  icon: Resource;
  url: string;
  title: string;
  opensExternal: boolean;
  roundedIcon?: boolean;
}

@Component
struct FriendLinksPage {
  @Consume('pageStack') pageStack: NavPathStack;
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  private isExiting: boolean = false;
  @State private warningPressed: boolean = false;
  @State private animStep: number = 0;
  private enterAnimationPlayed: boolean = false;
  private enterAnimationTimers: number[] = [];

  private startPageAnimationOnce(): void {
    if (this.enterAnimationPlayed) return;
    this.enterAnimationPlayed = true;
    this.animStep = 0;
    this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 5, (step: number): void => {
      this.animStep = step;
    });
  }

  aboutToDisappear(): void {
    cancelStaggerEnterAnimation(this.enterAnimationTimers);
    this.enterAnimationTimers = [];
  }

  private async openExternal(site: LinkConfig): Promise<void> {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: site.url,
      } as Want);
    } catch (error) {
      console.error('[Dashboard][pages/more/FriendLinksPage][ERROR]',
        `打开外部链接${site.title}失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, `无法打开${site.title}`, 1800, 'Friend');
    }
  }

  @State private projectSites: LinkConfig[] = [
    { icon: $r('app.media.app_icon'), url: PROJECT_HOME_URL.toString(), title: '项目网站首页', opensExternal: false,
      roundedIcon: true },
    { icon: $r('app.media.app_icon'), url: SBaseURL.toString(), title: 'S站', opensExternal: false,
      roundedIcon: true },
    { icon: $r('app.media.app_icon'), url: EGUI_URL.toString(), title: 'Egui', opensExternal: true,
      roundedIcon: true },
    { icon: $r('app.media.app_icon'), url: T_DASHBOARD_URL.toString(), title: 'T站', opensExternal: false,
      roundedIcon: true },
  ];
  @State private friendApps: LinkConfig[] = [
    { icon: $r('app.media.jide'), url: GETRACE_URL.toString(), title: '迹得', opensExternal: true },
    { icon: $r('app.media.subscription'), url: SUBSCRIPTION_URL.toString(), title: '记得订阅', opensExternal: true },
    { icon: $r('app.media.subscriptionAtomic'), url: SUBSCRIPTION_ATOMIC_URL.toString(),
      title: '记得订阅（元服务）', opensExternal: true },
    { icon: $r('app.media.zhiyu'), url: PAPER_TALK_URL.toString(), title: '纸语', opensExternal: true },
  ];
  @State private friendSites: LinkConfig[] = [
    { icon: $r('app.media.HapStore'), url: HapStoreURL.toString(), title: 'Hap资源站', opensExternal: false },
    { icon: $r('app.media.dztap'), url: dztapURL.toString(), title: '应用荟萃', opensExternal: false },
    { icon: $r('app.media.OpenStore'), url: OpenStoreURL.toString(), title: 'Open Store', opensExternal: false },
    { icon: $r('app.media.NEXTStore'), url: NEXTStoreURL.toString(), title: 'NEXT Store', opensExternal: false },
    { icon: $r('app.media.globe'), url: FANGZHOU_URL.toString(), title: '方舟网', opensExternal: false },
  ];
  @State private otherSites: LinkConfig[] = [
    { icon: $r('app.media.globe'), url: AGstatisticsURL.toString(), title: 'AppGallery统计数据',
      opensExternal: false },
  ];

  @Builder
  private roundedPrefixIcon(icon: Resource): void {
    Image(icon)
      .width(24)
      .height(24)
      .borderRadius(6)
      .objectFit(ImageFit.Cover)
  }

  @Builder
  private rightSuffix(): void {
    Image($r('app.media.right'))
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)
      .accessibilityText('进入')
  }

  @Builder
  private externalSuffix(): void {
    Image($r('app.media.share'))
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)
      .accessibilityText('直接打开外部链接')
  }

  @Builder linkListItem(site: LinkConfig) {
    HdsListItemCard({
      prefixItem: site.roundedIcon ? new PrefixCustomBuilder(() => {
        this.roundedPrefixIcon(site.icon)
      }) : new PrefixIcon({
        iconSize: IconSize.SYSTEM_ICON,
        iconValue: { image: site.icon },
      }),
      textItem: {
        primaryText: {
          text: site.title,
          modifier: new TextModifier()
            .fontSize(16)
            .fontColor($r('app.color.v3_text_primary')),
        },
      },
      suffixItem: site.opensExternal ? new SuffixCustomBuilder(() => {
        this.externalSuffix()
      }) : new SuffixCustomBuilder(() => {
        this.rightSuffix()
      }),
      onClick: () => {
        if (site.opensExternal) {
          this.openExternal(site);
          return;
        }
        if (this.vibrationLevel > 0) vibration.dotVibration();
        const params: WebPageParams = {
          url: site.url,
          title: site.title,
          contentInsetTop: WEB_PAGE_FRIEND_LINK_TOP_INSET,
        };
        pushPathSafely(this.pageStack, ROUTE_WEB_PAGE, params, 'pages/more/FriendLinksPage');
      },
      cardHeight: 54,
      cardBackgroundColor: $r('app.color.v3_surface'),
      cardBorderRadius: 0,
      hoverBorderRadius: 12,
      cardPrefixMargin: LIST_ITEM_PREFIX_MARGIN,
      cardSuffixMargin: LIST_ITEM_SUFFIX_MARGIN,
      accessibilityOptions: {
        accessibilityText: site.opensExternal ? `直接打开外部链接${site.title}` : `预览${site.title}`,
      },
    })
  }

  @Builder
  private linkList(sites: LinkConfig[], label: string): void {
    Column() {
      ForEach(sites, (site: LinkConfig, index: number) => {
        this.linkListItem(site)
        if (index < sites.length - 1) {
          Divider()
            .color($r('app.color.v3_chart_grid'))
            .margin({
              left: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
              right: LIST_ITEM_DIVIDER_HORIZONTAL_MARGIN,
            })
            .accessibilityText(`${label}分隔线`)
        }
      }, (item: LinkConfig) => item.title + item.url)
    }
    .width('100%')
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetY: 2 })
    .clip(true)
    .accessibilityGroup(true)
    .accessibilityText(label)
  }

  @Builder
  private linkSection(title: string, sites: LinkConfig[], enterStep: number): void {
    Column({ space: LIST_SECTION_CONTENT_GAP }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.diff_content'))
        .width('100%')
        .padding({ left: LIST_SECTION_TITLE_START_PADDING })
        .accessibilityText(title)
      this.linkList(sites, title)
    }
    .width('100%')
    .opacity(this.animStep >= enterStep ? 1 : 0)
    .translate({ y: this.animStep >= enterStep ? 0 : 20 })
  }

  build() {
    HdsNavDestination() {
      Scroll(){
        Column({ space: LIST_SECTION_SPACING }) {
          Blank().height(100)
          Column(){
            Text("重要提示：\n您正在访问友情链接")
              .fontWeight(700)
              .fontSize(20)
              .fontColor($r('app.color.v3_accent_red'))
            Text("友情链接内网站展示的任何内容均与应用看板无关；\n" +
              "Harmony Dashboard项目组不负责维护友情链接内容。")
              .fontWeight(600)
              .fontSize(15)
              .margin({ top: 15 })
              .textAlign(TextAlign.Start)
          }.borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.v3_surface"))
          .borderRadius(16)
          .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetX: 0, offsetY: 2 })
          .width("100%")
          .alignItems(HorizontalAlign.Start).padding(15)
          .scale({ x: this.warningPressed ? 0.985 : 1, y: this.warningPressed ? 0.985 : 1 })
          .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
          .visualEffect(pressVisualEffect(
            this.warningPressed, hdsEffect.PointLightIlluminatedType.BORDER))
          .compositingFilter(pressLightFieldFilter(this.warningPressed))
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.warningPressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.warningPressed = false;
          })
          .opacity(this.animStep >= 1 ? 1 : 0)
          .translate({ y: this.animStep >= 1 ? 0 : 20 })

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('重要提示与项目组站点分隔线')

          this.linkSection('Harmony Gallery项目组站点矩阵', this.projectSites, 2)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('项目组站点与友链应用分隔线')

          this.linkSection('使用Harmony Dashboard数据的应用', this.friendApps, 3)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('友链应用与友链站点分隔线')

          this.linkSection('使用Harmony Dashboard数据的站点', this.friendSites, 4)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('友链站点与其他站点分隔线')

          this.linkSection('其他站点', this.otherSites, 5)
          Blank().height(20).width('100%')
        }
        .width('100%')
        .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
        .padding({
          left: LIST_PAGE_HORIZONTAL_PADDING,
          right: LIST_PAGE_HORIZONTAL_PADDING,
          bottom: 30,
        })
      }
      .height("100%")
      .width("100%")
      .backgroundColor($r("app.color.background"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .onAppear((): void => this.startPageAnimationOnce())
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if (this.isExiting) {
        return true;
      }
      if(this.vibrationLevel > 0) vibration.backVibration()
      this.isExiting = true;
      popPathSafely(this.pageStack, 'pages/more/FriendLinksPage');
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
          backgroundStyle: { backgroundColor: Color.Transparent },
          contentStyle: {
            titleStyle: { mainTitleColor: $r("sys.color.font_primary"), subTitleColor: $r("sys.color.font_secondary") },
            menuStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
            backIconStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: { backgroundColor: Color.Transparent },
          contentStyle: {
            titleStyle: { mainTitleColor: $r("sys.color.font_primary"), subTitleColor: $r("sys.color.font_secondary") },
            menuStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
            backIconStyle: { backgroundColor: $r("sys.color.comp_background_tertiary"), iconColor: $r("sys.color.icon_primary") },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: this.immersiveMaterialLevel
        }
      },
      content: {
        title: { mainTitle: "友情链接", mainTitleSize: TitleSize.TITLE_S },
        backIcon: {
          action: () => {
            if (this.isExiting) return;
            if(this.vibrationLevel > 0) vibration.backVibration()
            this.isExiting = true;
            popPathSafely(this.pageStack, 'pages/more/FriendLinksPage');
          },
        },
      },
    })
    .accessibilityText('友情链接导航页');

  }
}

@Builder
export function FriendPageBuilder(){
  FriendLinksPage()
}
