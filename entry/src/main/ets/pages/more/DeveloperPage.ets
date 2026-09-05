import { deviceInfo } from '@kit.BasicServicesKit';
import {
  hdsEffect,
  hdsMaterial,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize
} from '@kit.UIDesignKit';
import {
  APP_BUILD_NUMBER,
  APP_BUNDLE_NAME,
  APP_VERSION,
  CONTENT_MAX_WIDTH,
  CONTINUATION_MIN_VERSION,
  customUserAgent,
} from '../../common/constants';
import { curves, LengthMetrics } from '@kit.ArkUI';
import { pageTransition } from '../../common/motion';

interface DeveloperField {
  label: string;
  value: string;
}

@Component
export struct DeveloperPage {
  @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  @State private pressedField: string = '';
  private fields(): DeveloperField[] {
    return [
      { label: '应用版本', value: APP_VERSION },
      { label: '内部构建号', value: String(APP_BUILD_NUMBER) },
      { label: '最低接续版本', value: CONTINUATION_MIN_VERSION },
      { label: 'Bundle Name', value: APP_BUNDLE_NAME },
      { label: 'Custom User-Agent', value: customUserAgent },
      { label: '系统版本', value: deviceInfo.osFullName },
      { label: '增量版本', value: deviceInfo.incrementalVersion },
      { label: 'SDK API', value: String(deviceInfo.sdkApiVersion) },
      { label: '发行版 API', value: String(deviceInfo.distributionOSApiVersion) },
      { label: '产品型号', value: `${deviceInfo.productModel} / ${deviceInfo.productModelAlias}` },
      { label: '软硬件型号', value: `${deviceInfo.softwareModel} / ${deviceInfo.hardwareModel}` },
      { label: '设备类型', value: deviceInfo.deviceType },
      { label: '市场名称', value: deviceInfo.marketName },
      { label: '芯片型号', value: deviceInfo.chipType },
    ];
  }

  build() {
    HdsNavDestination() {
      Scroll() {
        Column({ space: 12 }) {
          Blank().height(100).width('100%')
          Text('仅用于诊断设备适配、网络请求标识与版本信息。')
            .fontSize(13)
            .lineHeight(20)
            .fontColor($r('app.color.v3_text_secondary'))
            .width('100%')
            .accessibilityText('开发者诊断说明')
          Column() {
            ForEach(this.fields(), (field: DeveloperField, index: number) => {
              Column({ space: 5 }) {
                Text(field.label)
                  .fontSize(12)
                  .fontColor($r('app.color.diff_content'))
                  .width('100%')
                Text(field.value || '-')
                  .fontSize(14)
                  .fontColor($r('app.color.v3_text_primary'))
                  .width('100%')
                  .copyOption(CopyOptions.LocalDevice)
              }
              .width('100%')
              .padding(14)
              .scale({ x: this.pressedField === field.label ? 0.99 : 1,
                y: this.pressedField === field.label ? 0.99 : 1 })
              .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
              .visualEffect(new hdsEffect.HdsEffectBuilder()
                .pointLight({
                  sourceType: hdsEffect.PointLightSourceType.BRIGHT,
                  illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER,
                  options: { color: $r('app.color.diff_content'), intensity: 5, height: 96 },
                })
                .buildEffect())
              .onTouch((event: TouchEvent): void => {
                if (event.type === TouchType.Down) this.pressedField = field.label;
                else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedField = '';
              })
              .accessibilityGroup(true)
              .accessibilityText(`${field.label}，${field.value || '未知'}`)
              if (index < this.fields().length - 1) {
                Divider()
                  .color($r('app.color.v3_chart_grid'))
                  .margin({ left: 14, right: 14 })
                  .accessibilityText('开发者信息分隔线')
              }
            }, (field: DeveloperField) => field.label)
          }
          .width('100%')
          .borderRadius(16)
          .backgroundColor($r('app.color.v3_surface'))
          .border({ width: 1, color: $r('app.color.nd_card_border') })
          .clip(true)
          .accessibilityText('开发者信息列表')
          Blank().height(40)
        }
        .width('100%')
        .constraintSize({ maxWidth: Math.min(CONTENT_MAX_WIDTH, 900) })
        .padding({ left: 14, right: 14 })
      }
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.background'))
      .accessibilityText('可滚动的开发者页面')
    }
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
            },
            menuStyle: {
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
            },
            menuStyle: {
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
          mainTitle: '开发者信息',
          mainTitleSize: TitleSize.TITLE_S,
        },
      },
    })
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .accessibilityText('开发者信息导航页')
  }
}
