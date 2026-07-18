import { HdsNavDestination, ScrollEffectType } from '@kit.UIDesignKit';
import { vibration } from '../common/vibration';
import { LengthMetrics, PromptAction } from '@kit.ArkUI';
import { AGstatisticsURL, dztapURL, HapStoreURL, NEXTStoreURL, OpenStoreURL } from '../common/constants';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { common, Want } from '@kit.AbilityKit';

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
  @StorageLink("immersiveTextureON") immersiveTextureON: boolean = true;
  private isExiting: boolean = false;

  private jumpToMarket(appId: string) {
    const context = getContext(this) as common.UIAbilityContext;
    const want: Want = {
      action: 'ohos.want.action.appdetail',
      uri: `store://appgallery.huawei.com/app/detail?id=${appId}`
    };

    context.startAbility(want).then(() => {
      console.info(`queryResult [Market] 跳转成功: ${appId}`);
    }).catch((err: Error) => {
      console.error(`queryResult [Market] 跳转失败: ${err.message}`);
      this.PromptAction.showToast({ message: "无法打开应用市场" });
    });
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
        this.pageStack.pushPathByName("FriendPageWeb", params);
      })
      .height(50)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })
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
      .height(50)
      .width("100%")
      .justifyContent(FlexAlign.SpaceBetween)
      .padding({ left: 16, right: 16 })
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
          Blank().height(70)
          Column(){
            Text("重要提示：\n您正在访问友情链接")
              .fontWeight(700)
              .fontSize(20)
              .fontColor(Color.Red)
            Text("友情链接内网站展示的任何内容均与应用看板无关；\n" +
              "Harmony Dashboard项目组不负责维护友情链接内容。")
              .fontWeight(600)
              .fontSize(15)
              .margin({ top: 15 })
              .textAlign(TextAlign.Start)
          }.borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.background"))
          .borderRadius(16)
          .shadow({ radius: 8, color: "#1a000000", offsetX: 0, offsetY: 2 })
          .width("90%")
          .alignItems(HorizontalAlign.Start).padding(15)

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的站点").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          List() {
            ForEach(this.friendSites, (site: SiteConfig) => {
              ListItem() { this.webLists(site) }
            }, (item: SiteConfig) => item.title + item.url)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.background"))
          .borderRadius(16)
          .width("90%")

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("使用Harmony Dashboard数据的应用").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          List() {
            ForEach(this.friendApps, (app: AppConfig) => {
              ListItem() { this.appLists(app) }
            }, (item: AppConfig) => item.title + item.appID)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.background"))
          .borderRadius(16)
          .width("90%")

          Divider()
            .margin({ top: 20, bottom: 20 })
            .color($r("app.color.border"))

          Text("其他站点").margin({ left: 10, bottom: 5 }).fontWeight(600).fontSize(14).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
          List() {
            ForEach(this.OtherSites, (site: SiteConfig) => {
              ListItem() { this.webLists(site) }
            }, (item: SiteConfig) => item.title + item.url)
          }
          .borderWidth(0.5)
          .borderColor($r("app.color.border"))
          .backgroundColor($r("app.color.background"))
          .borderRadius(16)
          .width("90%")
        }.margin({ bottom: 30 })
      }
      .height("100%")
      .width("100%")
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .onBackPressed(() => {
      if (this.isExiting) {
        return true;
      }
      if(this.vibrationON) vibration.dotVibration()
      this.isExiting = true;
      this.pageStack.pop();
      return true;
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
        title: { mainTitle: "友情链接" },
        backIcon: {
          action: () => {
            if (this.isExiting) return;
            if(this.vibrationON) vibration.dotVibration()
            this.isExiting = true;
            this.pageStack.pop();
          },
        },
      },
    });

  }
}

@Builder
export function FriendPageBuilder(){
  friend()
}