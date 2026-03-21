import {
  HdsListItemCard,
  HdsNavigation,
  HdsNavigationTitleMode,
  IconSize,
  PrefixIcon,
  ScrollEffectType,
  SuffixArrow
} from '@kit.UIDesignKit';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { LengthMetrics, router } from '@kit.ArkUI'; // 引入路由用于跳转网页
import { AGstatisticsURL, dztapURL, HapStoreURL, NEXTStoreURL, OpenStoreURL } from '../common/constants';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import { SiteMode } from '../common/types';

interface SiteConfig {
  icon: Resource;
  url: string;
  title: string;
}

@Entry
@Component
struct friend {
  @StorageLink("vibrationON") vibrationON: boolean = true;

  private triggerVibration(): void {
    if (this.vibrationON) {
      vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
        if (state) {
          try {
            vibrator.startVibration({
              type: "preset",
              effectId: "haptic.effect.hard",
              count: 1,
              intensity: 50,
            }, { usage: "touch" });
          } catch (e) {
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
  @State private OtherSites: SiteConfig[] = [
    { icon: $r('sys.media.phone_arrow_down_left_circle_fill'), url: AGstatisticsURL.toString(), title: 'AppGallery统计数据' },
  ];

  @Builder lists(site: SiteConfig){
    Divider()
      .color($r("app.color.border"))
      .strokeWidth(0.5)
      .margin({ left: 16, right: 16 })
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
      router.pushUrl({
        url: 'pages/friendWeb',
        params: {
          url: site.url,
          title: site.title
        }
      })
      this.triggerVibration();
    })
    .height(56)
    .width("100%")
    .justifyContent(FlexAlign.SpaceBetween)
    .padding({ left: 16, right: 16 })
    Divider()
      .color($r("app.color.border"))
      .strokeWidth(0.5)
      .margin({ left: 16, right: 16 })
  }

  build() {
    HdsNavigation() {
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
            .margin({ top: 15 })
            .fontSize(20)
            .width("90%").textAlign(TextAlign.Start)
            .fontColor($r("app.color.diff_content"))
          Text("友情链接内网站展示的任何内容均与HmDashboard无关\n\n" +
            "Harmony Gallery项目组不负责维护友情链接网站内容")
            .fontWeight(600)
            .fontSize(15)
            .margin({ top: 20, bottom: 15 })
            .width("90%").textAlign(TextAlign.Start)
        }.borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: "#1a000000",
          offsetX: 0,
          offsetY: 2,
        })
        .width("90%")

        Text("使用Harmony Gallery数据的站点").margin({ top: 30, bottom: 10 }).fontWeight(600).fontSize(20).width("90%").textAlign(TextAlign.Start)
        Divider().color($r("app.color.border")).margin({ bottom: 10 }).padding({ left: 16, right: 16})
        List() {
          ForEach(this.friendSites, (site: SiteConfig) => {
            this.lists(site)
          }, (item: SiteConfig) => item.title + item.url)
        }
        .borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: "#1a000000",
          offsetX: 0,
          offsetY: 2,
        })
        .width("90%")
        Text("其他站点").margin({ top: 30, bottom: 10 }).fontWeight(600).fontSize(20).width("90%").textAlign(TextAlign.Start)
        Divider().color($r("app.color.border")).margin({ bottom: 10 }).padding({ left: 16, right: 16})
        List() {
          ForEach(this.OtherSites, (site: SiteConfig) => {
            this.lists(site)
          }, (item: SiteConfig) => item.title + item.url)
        }
        .borderWidth(0.5)
        .borderColor($r("app.color.border"))
        .backgroundColor($r("app.color.background"))
        .borderRadius(16)
        .shadow({
          radius: 8,
          color: "#1a000000",
          offsetX: 0,
          offsetY: 2,
        })
        .width("90%")
      }
      .width("100%")
      .height("100%")
      .backgroundColor($r("app.color.backcolor"))
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
    }
    .navBarWidth("100%")
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20),
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r("sys.color.ohos_id_color_background"),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r("sys.color.font_primary"),
              subTitleColor: $r("sys.color.font_secondary"),
            },
            menuStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
            backIconStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r("sys.color.ohos_id_color_background_transparent"),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r("sys.color.font_primary"),
              subTitleColor: $r("sys.color.font_secondary"),
            },
            menuStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
            backIconStyle: {
              backgroundColor: $r("sys.color.comp_background_tertiary"),
              iconColor: $r("sys.color.icon_primary"),
            },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: hdsMaterial.MaterialLevel.EXQUISITE
        },
      },
      content: {
        title: {
          mainTitle: "友情链接",
        },
        backIcon: {
          action: () => {
            this.triggerVibration();
            router.back();
          },
        },
      },
    });

  }
}