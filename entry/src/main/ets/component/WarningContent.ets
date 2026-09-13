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
  @State wideTopCardHeight: number = 0;
  private scroller: Scroller = new Scroller();

  private readonly WIDE_LAYOUT_BREAKPOINT: number = 680;

  private vibrate(): void {
    if (this.vibrationLevel > 0) {
      vibration.dotVibration();
    }
  }

  private updateWideTopCardHeight(height: number): void {
    if (this.contentWidth >= this.WIDE_LAYOUT_BREAKPOINT && height > this.wideTopCardHeight) {
      this.wideTopCardHeight = height;
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
        Text('Dashboard应用看板信息来源于网络')
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
        Text('所有信息均来自公开网络，不代表任何平台官方立场！')
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
    .constraintSize({
      minHeight: this.contentWidth >= this.WIDE_LAYOUT_BREAKPOINT ? this.wideTopCardHeight : 0,
    })
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.updateWideTopCardHeight(Number(newValue.height));
    })
  }

  @Builder
  private dataScopeCard(): void {
    Column({ space: 10 }) {
      Text('数据口径与功能说明')
        .fontSize(16)
        .fontColor($r('app.color.diff_content'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('Dashboard应用看板整理公开网络信息，提供应用、SDK、版本、分类、评分及历史快照查询。以下数据均为统计结果，不是任何平台的官方运营数据。')
        .fontSize(13)
        .fontColor($r('app.color.v3_text_primary'))
        .lineHeight(21)
        .width('100%')

      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('下载量与增长',
        '下载量、每日最高下载量和增长榜基于后端按期同步的公开快照计算，可能受到更新间隔、数据源变化和网络状态影响。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('外部内容',
        '隐私政策、应用市场详情、项目网站、友情链接和赞助页由对应第三方提供，打开后请以目标页面的条款与数据为准。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('社区功能',
        '社区频道和用户群由外部平台运营，请遵守对应平台规则，不要发布个人敏感信息或不合规内容。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('品牌表述',
        '页面中出现的产品、平台和公司名称仅用于说明数据来源或跳转目标，不表示 Dashboard应用看板与其存在合作、授权或官方关联。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)

      Text('查询结果仅供参考，重要决策请回到原始信息页面复核。')
        .fontSize(13)
        .fontColor($r('app.color.v3_notice_text_secondary'))
        .lineHeight(21)
        .width('100%')
    }
    .width('100%')
    .padding(16)
    .alignItems(HorizontalAlign.Start)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .accessibilityGroup(true)
    .accessibilityText('数据口径与功能说明，包含下载量、外部内容、社区功能和品牌表述')
  }

  @Builder
  private limitationCard(): void {
    Column({ space: 9 }) {
      this.noticeSection('收录范围',
        '仅收录已正式公开发布的应用与元服务；不包含侧载、公开测试或邀请测试内容。')
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
    .constraintSize({
      minHeight: this.contentWidth >= this.WIDE_LAYOUT_BREAKPOINT ? this.wideTopCardHeight : 0,
    })
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.updateWideTopCardHeight(Number(newValue.height));
    })
  }

  @Builder
  private projectPageCard(): void {
    Row() {
      Text('查看项目网站首页')
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
    .accessibilityText('打开Dashboard项目网站首页查看详细说明')
  }

  @Builder
  private noticeContent(): void {
    Scroll(this.scroller) {
      if (this.contentWidth >= this.WIDE_LAYOUT_BREAKPOINT) {
        Column({ space: 14 }) {
          Row({ space: 16 }) {
            Column() {
              this.primaryNoticeCard()
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
          .alignItems(VerticalAlign.Top)

          this.dataScopeCard()
          this.projectPageCard()
        }
        .width('100%')
        .padding({ top: 6, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      } else {
        Column({ space: 14 }) {
          this.primaryNoticeCard()
          this.limitationCard()
          this.dataScopeCard()
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
