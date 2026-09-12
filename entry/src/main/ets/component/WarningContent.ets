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
  private marketplaceComplianceCard(): void {
    Column({ space: 10 }) {
      Text('应用市场合规调整说明')
        .fontSize(16)
        .fontColor($r('app.color.diff_content'))
        .fontWeight(FontWeight.Bold)
        .width('100%')

      Text('近期版本在提交华为应用市场审核时，审核方对部分功能和宣传内容提出了合规要求。为保证应用能够继续上架，我们对以下内容进行了调整。')
        .fontSize(13)
        .fontColor($r('app.color.v3_text_primary'))
        .lineHeight(21)
        .width('100%')

      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('下载量展示',
        '审核方认为应用下载量的真实性和准确性难以由应用独立证明，可能使用户对统计效果产生误解，因此应用内不再提供下载量及下载趋势展示。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('外部链接与应用分发',
        '审核方不允许应用内容引导用户前往第三方应用市场或赞助平台，因此应用移除了友情链接、赞助我们、外部应用市场及相关帮助入口。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('社区功能',
        '具备交流和内容发布能力的社区模块需要提交安全评估报告及审核通过证明。由于未提交相关资质，当前版本不提供社区频道与用户群聊功能。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)
      this.noticeSection('品牌表述',
        '审核方要求避免在未获得书面授权时使用可能暗示合作关系的品牌宣传。应用因此统一使用“Dashboard应用看板”名称；本应用与华为不存在合作、授权或官方关联。')
      Divider().color($r('app.color.v3_chart_grid')).strokeWidth(0.5)

      Text('上述调整不影响SDK、版本、分类、评分等公开信息查询。')
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
    .accessibilityText('应用市场合规调整说明，包含下载量、外部链接、社区功能和品牌表述的调整原因')
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

          this.marketplaceComplianceCard()
          this.projectPageCard()
        }
        .width('100%')
        .padding({ top: 6, bottom: 16 })
        .alignItems(HorizontalAlign.Start)
      } else {
        Column({ space: 14 }) {
          this.primaryNoticeCard()
          this.limitationCard()
          this.marketplaceComplianceCard()
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
