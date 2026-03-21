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

interface SiteConfig {
  icon: Resource;
  url: string;
  title: string;
  desc: string;
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

  // 建议将 sitesList 放在组件内
  @State private friendSites: SiteConfig[] = [
    {
      icon: $r('sys.media.phone_arrow_down_left_circle_fill'),
      url: HapStoreURL.toString(),
      title: 'Hap资源站',
      desc: '鸿蒙HAP分发站'
    },
    {
      icon: $r('sys.media.phone_arrow_down_left_circle_fill'),
      url: NEXTStoreURL.toString(),
      title: 'NEXT Store',
      desc: 'HarmonyOS NEXT 应用商店'
    },
    {
      icon: $r('sys.media.phone_arrow_down_left_circle_fill'),
      url: OpenStoreURL.toString(),
      title: 'Open Store',
      desc: '开源应用市场'
    },
    {
      icon: $r('sys.media.phone_arrow_down_left_circle_fill'),
      url: dztapURL.toString(),
      title: '小刘的站点',
      desc: '个人分享站'
    },
  ];
  @State private OtherSites: SiteConfig[] = [
    {
      icon: $r('sys.media.phone_arrow_down_left_circle_fill'),
      url: AGstatisticsURL.toString(),
      title: 'AppGallery统计数据',
      desc: 'AppGallery统计数据'
    },
  ];

  @Builder
  siteLink(site: SiteConfig) {
    ListItem() {
      HdsListItemCard({
        cardBackgroundColor: $r('app.color.background'),
        prefixItem: new PrefixIcon({
          iconSize: IconSize.SYSTEM_ICON,
          iconValue: {
            image: site.icon
          },
        }),
        textItem: {
          primaryText: {
            text: site.title
          },
          secondaryText: {
            text: site.desc
          },
        },
        suffixItem: new SuffixArrow({}),
        onClick: () => {
          this.triggerVibration();
          router.pushUrl({
            url: 'pages/CommonWebPage',
            params: {
              url: site.url,
              title: site.title
            }
          })
        }
      })
    }
    .margin({ bottom: 8 })
  }

  build() {
    HdsNavigation() {
      Column() {
        Blank().height(80)
        Text("使用Harmony Gallery数据的站点").fontColor($r('app.color.diff_content')).margin({ bottom:10 }).fontWeight(600).fontSize(17)
        List() {
          ForEach(this.friendSites, (site: SiteConfig) => {
            this.siteLink(site)
          }, (item: SiteConfig) => item.title + item.url)
        }.width("93%")
        Divider()
          .margin({ top: 20, bottom: 20 })
          .color($r("app.color.border"))
        Text("其他站点").fontColor($r('app.color.diff_content')).margin({ bottom:10 }).fontWeight(600).fontSize(17)
        List() {
          ForEach(this.OtherSites, (site: SiteConfig) => {
            this.siteLink(site)
          }, (item: SiteConfig) => item.title + item.url)
        }.width("93%")
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