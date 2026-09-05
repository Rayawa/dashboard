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
  SBaseURL,
  SUBSCRIPTION_ATOMIC_URL,
  SUBSCRIPTION_URL,
  T_DASHBOARD_URL,
} from '../../common/constants';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { common, Want } from '@kit.AbilityKit';
import { popPathSafely, pushPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { pageTransition } from '../../common/motion';

interface FriendWebParams {
  url: string;
  title: string;
}

interface LinkConfig {
  icon: Resource;
  url: string;
  title: string;
  opensExternal: boolean;
  roundedIcon?: boolean;
}

@Component
struct friend {
  @Consume('pageStack') pageStack: NavPathStack;
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  private isExiting: boolean = false;
  @State private warningPressed: boolean = false;

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
      console.error('[Dashboard][pages/more/friend][ERROR]',
        `打开外部链接${site.title}失败: ${JSON.stringify(error)}`);
      showToastSafely(this.PromptAction, `无法打开${site.title}`, 1800, 'Friend');
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
  private RoundedPrefixIcon(icon: Resource): void {
    Image(icon)
      .width(24)
      .height(24)
      .borderRadius(6)
      .objectFit(ImageFit.Cover)
  }

  @Builder
  private RightSuffix(): void {
    Image($r('app.media.right'))
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)
      .accessibilityText('进入')
  }

  @Builder
  private ExternalSuffix(): void {
    Image($r('app.media.share'))
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)
      .accessibilityText('直接打开外部链接')
  }

  @Builder linkListItem(site: LinkConfig) {
    HdsListItemCard({
      prefixItem: site.roundedIcon ? new PrefixCustomBuilder(() => {
        this.RoundedPrefixIcon(site.icon)
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
        this.ExternalSuffix()
      }) : new SuffixCustomBuilder(() => {
        this.RightSuffix()
      }),
      onClick: () => {
        if (site.opensExternal) {
          this.openExternal(site);
          return;
        }
        if (this.vibrationLevel > 0) vibration.dotVibration();
        const params: FriendWebParams = { url: site.url, title: site.title };
        pushPathSafely(this.pageStack, "FriendPageWeb", params, 'pages/more/friend');
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
  private LinkList(sites: LinkConfig[], label: string): void {
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
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetY: 2 })
    .clip(true)
    .accessibilityGroup(true)
    .accessibilityText(label)
  }

  @Builder
  private LinkSection(title: string, sites: LinkConfig[]): void {
    Column({ space: LIST_SECTION_CONTENT_GAP }) {
      Text(title)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.diff_content'))
        .width('100%')
        .padding({ left: LIST_SECTION_TITLE_START_PADDING })
        .accessibilityText(title)
      this.LinkList(sites, title)
    }
    .width('100%')
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
          .visualEffect(new hdsEffect.HdsEffectBuilder()
            .pointLight({
              sourceType: hdsEffect.PointLightSourceType.BRIGHT,
              illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
              options: { color: $r('app.color.diff_content'), intensity: 6, height: 110 },
            })
            .buildEffect())
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.warningPressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.warningPressed = false;
          })

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('重要提示与项目组站点分隔线')

          this.LinkSection('Harmony Gallery项目组站点矩阵', this.projectSites)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('项目组站点与友链应用分隔线')

          this.LinkSection('使用Harmony Dashboard数据的应用', this.friendApps)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('友链应用与友链站点分隔线')

          this.LinkSection('使用Harmony Dashboard数据的站点', this.friendSites)

          Divider()
            .margin({
              top: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
              bottom: LIST_SECTION_DIVIDER_VERTICAL_MARGIN,
            })
            .color($r("app.color.border"))
            .accessibilityText('友链站点与其他站点分隔线')

          this.LinkSection('其他站点', this.otherSites)
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
      popPathSafely(this.pageStack, 'pages/more/friend');
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
            popPathSafely(this.pageStack, 'pages/more/friend');
          },
        },
      },
    })
    .accessibilityText('友情链接导航页');

  }
}

@Builder
export function FriendPageBuilder(){
  friend()
}
