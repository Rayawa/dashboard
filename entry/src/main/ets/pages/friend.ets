import { HdsNavDestination, HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
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
  PromptAction: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink("vibrationON") vibrationON: boolean = true;

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

  private triggerVibration(): void {
    if (this.vibrationON) {
      vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(
            `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
          );
          return;
        }
        console.info("Succeed in querying effect");
        if (state) {
          try {
            vibrator.startVibration(
              {
                type: "preset",
                effectId: "haptic.effect.hard",
                count: 1,
                intensity: 50,
              },
              { usage: "touch" },
              (error: BusinessError) => {
                if (error) {
                  console.error(
                    `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                  );
                } else {
                  console.info("Succeed in starting vibration");
                }
              },
            );
          } catch (tryError) {
            console.error(`An unexpected error occurred in try block: ${tryError}`);
          }
        }
      });
    }
  }

  @State private friendSites: SiteConfig[] = [
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: HapStoreURL.toString(), title: 'Hap资源站' },
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: NEXTStoreURL.toString(), title: 'NEXT Store' },
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: OpenStoreURL.toString(), title: 'Open Store' },
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: dztapURL.toString(), title: '小刘的站点' },
  ];
  @State private friendApps: AppConfig[] = [
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), appID: 'C6917594526782928388', title: '记得订阅' },
  ];
  @State private OtherSites: SiteConfig[] = [
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: AGstatisticsURL.toString(), title: 'AppGallery统计数据' },
  ];

  @Builder webLists(site: SiteConfig){
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
      this.triggerVibration();
      let params :FriendWebParams = {
        "url": site.url,
        "title": site.title
      }
      this.pageStack.pushPathByName("FriendPageWeb", params);
    })
    .height(56)
    .width("100%")
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16 })
  }
  @Builder appLists(site: AppConfig) {
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
      this.triggerVibration();
      if (site.appID) {
        this.jumpToMarket(site.appID);
      }
    })
    .height(56)
    .width("100%")
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16 })
  }

  build() {
      HdsNavDestination() {
        Scroll(){
          Column() {
            Blank().height(70)
            Text("重要提醒")
              .fontWeight(800)
              .fontSize(25)
              .fontColor(Color.Red)
              .margin({ bottom: 15 })

            Column(){
              Text("您正在访问友情链接")
                .fontWeight(700)
                .fontSize(20)
                .width("90%").textAlign(TextAlign.Start)
                .fontColor($r("app.color.diff_content"))
              Text("友情链接内网站展示的任何内容均与鸿蒙应用看板无关\n\n" +
                "Harmony Gallery项目组不负责维护友情链接内容")
                .fontWeight(600)
                .fontSize(15)
                .margin({ top: 20 })
                .width("90%").textAlign(TextAlign.Start)
            }.borderWidth(0.5)
            .borderColor($r("app.color.border"))
            .backgroundColor($r("app.color.background"))
            .borderRadius(16)
            .shadow({ radius: 8, color: "#1a000000", offsetX: 0, offsetY: 2 })
            .width("90%")
            .alignItems(HorizontalAlign.Start).padding(20)

            Text("使用Harmony Gallery数据的站点").margin({ top: 30, bottom: 10 }).fontWeight(600).fontSize(20).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
            Divider().color($r("app.color.border")).margin({ bottom: 10 }).padding({ left: 16, right: 16})
            List() {
              ForEach(this.friendSites, (site: SiteConfig) => {
                ListItem() { this.webLists(site) }
              }, (item: SiteConfig) => item.title + item.url)
            }
            .divider({ strokeWidth: 0.5, color: $r("app.color.border"), startMargin: 16, endMargin: 16 }) // 语法优化：使用自带分割线
            .borderWidth(0.5)
            .borderColor($r("app.color.border"))
            .backgroundColor($r("app.color.background"))
            .borderRadius(16)
            .width("90%")

            Text("使用Harmony Gallery数据的应用").margin({ top: 30, bottom: 10 }).fontWeight(600).fontSize(20).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
            Divider().color($r("app.color.border")).margin({ bottom: 10 }).padding({ left: 16, right: 16})
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

            Text("其他站点").margin({ top: 30, bottom: 10 }).fontWeight(600).fontSize(20).width("90%").textAlign(TextAlign.Start).fontColor($r('app.color.diff_content'))
            Divider().color($r("app.color.border")).margin({ bottom: 10 }).padding({ left: 16, right: 16})
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
        .width("100%")
        .backgroundColor($r("app.color.backcolor"))
        .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      }
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
          systemMaterialEffect: {
            materialType: hdsMaterial.MaterialType.IMMERSIVE,
            materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
          },
        },
        content: {
          title: { mainTitle: "友情链接" },
          backIcon: {
            action: () => {
              this.triggerVibration();
              this.pageStack.pop()
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