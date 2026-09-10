import { PromptAction } from '@kit.ArkUI';
import { common, Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { vibration } from '../common/vibration';
import { PrivacyConfirmationButtons } from './PrivacyConfirmationButtons';
import { mainPage } from '../common/constants';
import { showToastSafely } from '../common/safeUi';
import { scrollByAxis } from '../common/scroll';

@Component
export struct WarningContent {
  @Link isShow: boolean;
  @Prop requiresConfirmation: boolean = true;
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @State contentWidth: number = 0;
  private scroller: Scroller = new Scroller();

  private readonly WIDE_LAYOUT_BREAKPOINT: number = 680;

  private vibrate(): void {
    if (this.vibrationLevel > 0) {
      vibration.dotVibration();
    }
  }

  private async openProjectPage(): Promise<void> {
    this.vibrate();
    const uiContent = this.getUIContext();
    try {
      showToastSafely(this.prompt, '正在跳转…', 500, 'Warning');
      const context = uiContent.getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: mainPage.toString(),
      } as Want);
    } catch (error) {
      console.error('[Dashboard][component/WarningContent][ERROR]', '打开链接失败:',
        (error as BusinessError).message);
      showToastSafely(this.prompt, '打开链接失败', 1000, 'Warning');
    }
  }

  @Builder
  private noticeSection(title: string, body: string): void {
    Column({ space: 3 }) {
      Text(title)
        .fontSize(14)
        .fontColor($r('app.color.v3_text_primary'))
        .fontWeight(FontWeight.Bold)
      Text(body)
        .fontSize(13)
        .fontColor($r('app.color.v3_text_secondary'))
        .lineHeight(19)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private primaryNoticeCard(): void {
    Column({ space: 14 }) {
      Row() {
        Text('Harmony Dashboard 数据来源于网络')
          .layoutWeight(1)
          .fontSize(16)
          .fontColor($r('app.color.v3_accent_red'))
          .fontWeight(FontWeight.Bold)
          .lineHeight(23)
      }
      .width('100%')
      .alignItems(VerticalAlign.Center)

      Text('不保证来源的准确性、完整性和真实性，所有信息仅供参考。')
        .width('100%')
        .fontSize(13)
        .fontColor($r('app.color.v3_notice_text_secondary'))
        .lineHeight(21)

      Divider()
        .color($r('app.color.v3_notice_divider'))
        .strokeWidth(0.5)
        .accessibilityText('数据来源与免责声明分隔线')

      Column({ space: 7 }) {
        Text('免责声明')
          .fontSize(13)
          .fontColor($r('app.color.v3_notice_text_secondary'))
          .fontWeight(FontWeight.Medium)
        Text('所有数据由第三方测算，不代表华为官方立场！')
          .fontColor($r('app.color.v3_accent_red'))
          .fontWeight(FontWeight.Bold)
          .fontSize(14)
          .lineHeight(21)
        Text('项目组不对数据来源的准确性、完整性与真实性做任何法律担保，不承担用户因采信结果产生的任何损失。')
          .fontSize(13)
          .fontColor($r('app.color.v3_notice_text_secondary'))
          .lineHeight(21)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .padding(18)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_notice_bg'))
    .border({ width: 1, color: $r('app.color.v3_notice_divider') })
  }

  @Builder
  private limitationCard(): void {
    Column({ space: 9 }) {
      this.noticeSection('收录范围',
        '应用仅收录已正式上架HarmonyOS NEXT及后续版本华为应用市场的应用；不包含侧载应用、公开测试应用或邀请测试应用。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('更新延迟', '数据存在滞后性，同步质量受限于用户网络稳定性，项目组不保证信息的即时性。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('知识产权', '算法原创，严禁商用。使用 API 对接数据库前请先与我们取得联系。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('动态调整',
        '项目组拥有对本统计方法论及数据口径的最终解释权，并保留在不预先通知的情况下修正算法逻辑的权利。')
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .accessibilityGroup(true)
    .accessibilityText('应用收录范围、更新延迟、知识产权和动态调整')
  }

  @Builder
  private projectPageCard(): void {
    Row() {
      Text('查看项目总网页')
        .layoutWeight(1)
        .fontSize(14)
        .fontColor($r('app.color.v3_text_primary'))
        .fontWeight(FontWeight.Medium)
      Text('→')
        .fontSize(18)
        .fontColor($r('app.color.diff_content'))
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .onClick(() => this.openProjectPage())
    .accessibilityText('打开Dashboard项目总网页查看详细说明')
  }

  @Builder
  private noticeContent(): void {
    Scroll(this.scroller) {
      if (this.contentWidth >= this.WIDE_LAYOUT_BREAKPOINT) {
        Row({ space: 16 }) {
          Column({ space: 14 }) {
            this.primaryNoticeCard()
            this.projectPageCard()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          Column() {
            this.limitationCard()
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
        }
        .width('100%')
        .padding({ top: 6, bottom: 16 })
        .alignItems(VerticalAlign.Top)
      } else {
        Column({ space: 14 }) {
          this.primaryNoticeCard()
          this.limitationCard()
          this.projectPageCard()
        }
        .width('100%')
        .padding({ top: 6, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.contentWidth = Number(newValue.width);
    })
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .nestedScroll({
      scrollForward: NestedScrollMode.PARENT_FIRST,
      scrollBackward: NestedScrollMode.SELF_FIRST,
    })
  }

  build() {
    Column({ space: 12 }) {
      this.noticeContent()
      if (this.requiresConfirmation) {
        PrivacyConfirmationButtons({ isShow: this.isShow })
      }
    }
    .width('100%')
    .padding({ left: 16, right: 16, bottom: 16 })
    .onAxisEvent((event: AxisEvent): void => scrollByAxis(this.scroller, event))
    .accessibilityGroup(true)
    .accessibilityText('应用数据来源和免责声明')
  }
}
