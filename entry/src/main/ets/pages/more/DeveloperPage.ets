import { deviceInfo } from '@kit.BasicServicesKit';
import {
  hdsEffect,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType
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
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import { scrollByAxis } from '../../common/scroll';
import {
  DEVICE_CHIP_TYPE,
  HDS_MATERIAL_LEVEL_GENTLE,
  HDS_MATERIAL_TYPE_IMMERSIVE,
  HDS_TITLE_SIZE_SMALL,
  SUPPORTS_HARMONY_API_23,
} from '../../common/platformCompatibility';

interface DeveloperField {
  label: string;
  value: string;
}

@Component
export struct DeveloperPage {
  @StorageLink('immersiveMaterialLevel') private immersiveMaterialLevel: number = HDS_MATERIAL_LEVEL_GENTLE;
  @State private pressedField: string = '';
  private scroller: Scroller = new Scroller();
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
      { label: '芯片型号', value: DEVICE_CHIP_TYPE },
    ];
  }

  build() {
    HdsNavDestination() {
      Scroll(this.scroller) {
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
              .visualEffect(pressVisualEffect(this.pressedField === field.label,
                hdsEffect.PointLightIlluminatedType.BORDER, 5, 96))
              .compositingFilter(pressLightFieldFilter(this.pressedField === field.label))
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
      .edgeEffect(EdgeEffect.Spring, { alwaysEnabled: true })
      .backgroundColor($r('app.color.background'))
      .accessibilityText('可滚动的开发者页面')
    }
    .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
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
            backgroundColor: Color.Transparent,
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
            backgroundColor: Color.Transparent,
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
        systemMaterialEffect: SUPPORTS_HARMONY_API_23 ? {
          materialType: HDS_MATERIAL_TYPE_IMMERSIVE,
          materialLevel: this.immersiveMaterialLevel,
        } : undefined,
      },
      content: {
        title: {
          mainTitle: '开发者信息',
          mainTitleSize: SUPPORTS_HARMONY_API_23 ? HDS_TITLE_SIZE_SMALL : undefined,
        },
      },
    })
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .accessibilityText('开发者信息导航页')
  }
}
