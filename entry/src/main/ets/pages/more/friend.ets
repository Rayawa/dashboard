import { HdsNavDestination, HdsNavDestinationTitleMode, ScrollEffectType, TitleSize } from '@kit.UIDesignKit';
import { vibration } from '../../common/vibration';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { AGstatisticsURL, dztapURL, HapStoreURL, NEXTStoreURL, OpenStoreURL } from '../../common/constants';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { common, Want } from '@kit.AbilityKit';
import { popPathSafely, pushPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';

interface FriendWebParams {
  url: string;
  title: string;
}

interface SiteConfig {
  icon: Resource;
  url: string;
  title: string;
}

interface AppConfig {
  icon: Resource;
  title: string;
  appID: string;
}

@Component
struct friend {
  @Consume('pageStack') pageStack: NavPathStack;
  private PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink("vibrationON") vibrationON: boolean = true;
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = false;
  private isExiting: boolean = false;

  private jumpToMarket(appId: string): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: `store://appgallery.huawei.com/app/detail?id=${appId}`
    };

    try {
      context.startAbility(want).then(() => {
        console.info('[Dashboard][pages/more/friend][INFO]', `queryResult [Market] 跳转成功: ${appId}`);
      }).catch((err: Error) => {
        console.error('[Dashboard][pages/more/friend][ERROR]', `queryResult [Market] 跳转失败: ${err.message}`);
        showToastSafely(this.PromptAction, '无法打开应用市场', 1800, 'Friend');
      });
    } catch (error) {
      console.error('[Dashboard][pages/more/friend][ERROR]',
        `启动应用市场调用失败: ${JSON.stringify(error)}`);
      showToastSafely(this.PromptAction, '无法打开应用市场', 1800, 'Friend');
    }
  }


  @State private friendSites: SiteConfig[] = [
    { icon: $r('app.media.HapStore'), url: HapStoreURL.toString(), title: 'Hap资源站' },
    { icon: $r('app.media.NEXTStore'), url: NEXTStoreURL.toString(), title: 'NEXT Store' },
    { icon: $r('app.media.OpenStore'), url: OpenStoreURL.toString(), title: 'Open Store' },
    { icon: $r('app.media.dztap'), url: dztapURL.toString(), title: '应用荟萃' },
  ];
  @State private friendApps: AppConfig[] = [
    { icon: $r('app.media.subscription'), appID: 'C6917594526782928388', title: '记得订阅' },
    { icon: $r('app.media.zhiyu'), appID: 'C6917600807866515662', title: '纸语' },
  ];
  @State private OtherSites: SiteConfig[] = [
    { icon: $r('app.media.AGstatistics'), url: AGstatisticsURL.toString(), title: 'AppGallery统计数据' },
  ];

  @Builder webLists(site: SiteConfig){
    Column(){
      Row() {
        Row() {
          Image(site.icon)
            .height(24)
            .width(24)
            .objectFit(ImageFit.Contain)
          Text(site.title)
            .fontSize(16)
            .margin({ left: 12 })
        }
        Image($r("app.media.right"))
          .height(16)
          .width(16)
          .objectFit(ImageFit.Contain)
      }
      .onClick(() => {
        if(this.vibrationON) vibration.dotVibration()
        let params :FriendWebParams = {
          "url": site.url,
          "title": site.title
        }
        pushPathSafely(this.pageStack, "FriendPageWeb", params, 'pages/more/friend');
      })
      .height(54)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })
      .accessibilityGroup(true)
      .accessibilityText(`打开友情链接${site.title}`)
      Divider()
        .strokeWidth(0.5)
        .color($r("app.color.border"))
        .margin({ left: 16, right: 16 })
    }
  }
  @Builder appLists(site: AppConfig) {
    Column(){
      Row() {
        Row() {
          Image(site.icon)
            .height(24)
            .width(24)
            .objectFit(ImageFit.Contain)
          Text(site.title)
            .fontSize(16)
            .margin({ left: 12 })
        }
        Image($r("app.media.right"))
          .height(16)
          .width(16)
          .objectFit(ImageFit.Contain)
      }
      .onClick(() => {
        if(this.vibrationON) vibration.dotVibration()
        if (site.appID) {
          this.jumpToMarket(site.appID);
        }
      })
      .height(54)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })
      .accessibilityGroup(true)
      .accessibilityText(`在应用市场打开${site.title}`)
      Divider()
        .strokeWidth(0.5)
        .color($r("app.color.border"))
        .margin({ left: 16, right: 16 })
    }

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

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的站点").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          Column() {
            ForEach(this.friendSites, (site: SiteConfig) => {
              this.webLists(site)
            }, (item: SiteConfig) => item.title + item.url)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.v3_surface"))
          .borderRadius(16)
          .width("100%")
          .clip(true)

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的应用").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          Column() {
            ForEach(this.friendApps, (app: AppConfig) => {
              this.appLists(app)
            }, (item: AppConfig) => item.title + item.appID)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.v3_surface"))
          .borderRadius(16)
          .width("100%")
          .clip(true)

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("其他站点").margin({ left: 4, bottom: 5 }).fontWeight(600).fontSize(14).width("100%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          Column() {
            ForEach(this.OtherSites, (site: SiteConfig) => {
              this.webLists(site)
            }, (item: SiteConfig) => item.title + item.url)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.v3_surface"))
          .borderRadius(16)
          .width("100%")
          .clip(true)
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
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if (this.isExiting) {
        return true;
      }
      if(this.vibrationON) vibration.dotVibration()
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
        systemMaterialEffect: this.immersiveTextureON ? {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        } : undefined
      },
      content: {
        title: { mainTitle: "友情链接", mainTitleSize: TitleSize.TITLE_S },
        backIcon: {
          action: () => {
            if (this.isExiting) return;
            if(this.vibrationON) vibration.dotVibration()
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
