import {
  hdsEffect,
  HdsListItemCard,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  IconSize,
  PrefixIcon,
  ScrollEffectType,
  SuffixArrow,
  SuffixCustomBuilder,
  TitleSize
} from '@kit.UIDesignKit';
import { vibration } from '../../common/vibration';
import { curves, LengthMetrics, PromptAction, TextModifier } from '@kit.ArkUI';
import {
  AGstatisticsURL,
  dztapURL,
  EGUI_URL,
  FANGZHOU_URL,
  GETRACE_URL,
  HapStoreURL,
  NEXTStoreURL,
  OpenStoreURL,
  PAPER_TALK_URL,
  PROJECT_HOME_URL,
  S_DASHBOARD_URL,
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
}

@Component
struct friend {
  @Consume('pageStack') pageStack: NavPathStack;
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink('vibrationLevel') vibrationLevel: number = 0;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.SMOOTH;
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
    { icon: $r('app.media.app_icon'), url: PROJECT_HOME_URL.toString(), title: '项目网站首页', opensExternal: false },
    { icon: $r('app.media.app_icon'), url: S_DASHBOARD_URL.toString(), title: 'S站', opensExternal: false },
    { icon: $r('app.media.app_icon'), url: EGUI_URL.toString(), title: 'Egui', opensExternal: true },
    { icon: $r('app.media.app_icon'), url: T_DASHBOARD_URL.toString(), title: 'T站', opensExternal: false },
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
  private ExternalSuffix(): void {
    Image($r('app.media.share'))
      .width(20)
      .height(20)
      .objectFit(ImageFit.Contain)
      .accessibilityText('直接打开外部链接')
  }

  @Builder linkListItem(site: LinkConfig) {
    HdsListItemCard({
      prefixItem: new PrefixIcon({
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
      }) : new SuffixArrow({ color: $r('sys.color.icon_secondary') }),
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
      cardPrefixMargin: 8,
      cardSuffixMargin: 12,
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
            .margin({ left: 16, right: 16 })
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
  build() {
    HdsNavDestination() {
      Scroll(){
        Column() {
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
              sourceType: this.warningPressed ? hdsEffect.PointLightSourceType.BRIGHT :
                hdsEffect.PointLightSourceType.NONE,
              illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
              options: { color: $r('app.color.diff_content'), intensity: 6, height: 110 },
            })
            .pressShadow(this.warningPressed ? hdsEffect.PressShadowType.BLEND_GRADIENT :
              hdsEffect.PressShadowType.NONE)
            .buildEffect())
          .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.warningPressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.warningPressed = false;
          })

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("Harmony Gallery项目组站点矩阵").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          this.LinkList(this.projectSites, 'Harmony Gallery项目组站点矩阵')

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的应用").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          this.LinkList(this.friendApps, '使用Harmony Dashboard数据的应用')

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的站点").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          this.LinkList(this.friendSites, '使用Harmony Dashboard数据的站点')

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("其他站点").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          this.LinkList(this.otherSites, '其他站点')
        }
        .width('100%')
        .constraintSize({ maxWidth: 900 })
        .padding({ left: 14, right: 14, bottom: 30 })
      }
      .height("100%")
      .width("100%")
      .backgroundColor($r("app.color.backcolor"))
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
