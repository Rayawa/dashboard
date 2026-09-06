import { common, Want } from '@kit.AbilityKit';
import { BusinessError, pasteboard } from '@kit.BasicServicesKit';
import { curves, LengthMetrics, PromptAction } from '@kit.ArkUI';
import { hdsMaterial } from '@hms.hds.hdsMaterial';
import {
  hdsEffect,
  HdsNavDestination,
  HdsNavDestinationTitleMode,
  ScrollEffectType,
  TitleSize,
} from '@kit.UIDesignKit';
import { APP_VERSION, CONTENT_MAX_WIDTH, mainPage } from '../../common/constants';
import { popPathSafely } from '../../common/safeNavigation';
import { showToastSafely } from '../../common/safeUi';
import { vibration } from '../../common/vibration';
import { cancelStaggerEnterAnimation, pageTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';
import KnockShareGuideCard, { CardRes } from '../../component/KnockShareGuideCard';

const TUTORIAL_COLUMN_BREAKPOINT = 840;
const SHARE_ROW_BREAKPOINT = 680;
const QUERY_IMAGE_RATIO = 1216 / 1893;

@Component
export struct TutorialPage {
  @Consume('pageStack') pageStack: NavPathStack;
  @StorageLink('vibrationLevel') vibrationLevel: number = 1;
  @StorageLink('immersiveMaterialLevel') immersiveMaterialLevel: hdsMaterial.MaterialLevel =
    hdsMaterial.MaterialLevel.GENTLE;
  private prompt: PromptAction = this.getUIContext().getPromptAction();
  @State private pressedCard: string = '';
  @State private contentWidth: number = 0;
  @State private shareContentWidth: number = 0;
  @State private animStep: number = 0;
  private enterAnimationPlayed: boolean = false;
  private enterAnimationTimers: number[] = [];
  private readonly cardSwiperResourcesPhone: CardRes[] = [{
    text: '打开碰一碰分享后，按系统提示将两台设备靠近即可发送。',
    rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
    framesCount: 128,
    startDelay: 50,
    stopDelay: 500,
  }];

  private startPageAnimationOnce(totalSteps: number): void {
    if (this.enterAnimationPlayed) return;
    this.enterAnimationPlayed = true;
    this.animStep = 0;
    this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), totalSteps, (step: number): void => {
      this.animStep = step;
    });
  }

  private enterStep(narrowStep: number, wideStep: number): number {
    return this.contentWidth >= TUTORIAL_COLUMN_BREAKPOINT ? wideStep : narrowStep;
  }

  aboutToDisappear(): void {
    cancelStaggerEnterAnimation(this.enterAnimationTimers);
    this.enterAnimationTimers = [];
  }

  private updatePressed(key: string, pressed: boolean): void {
    this.pressedCard = pressed ? key : '';
  }

  private async openProjectSite(): Promise<void> {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    try {
      showToastSafely(this.prompt, '正在跳转…', 500, 'Tutorial');
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      await context.startAbility({
        action: 'ohos.want.action.viewData',
        entities: ['entity.system.browsable'],
        uri: mainPage.toString(),
      } as Want);
    } catch (error) {
      const businessError = error as BusinessError;
      console.error('[Dashboard][pages/more/TutorialPage][ERROR]', `打开项目网站失败: ${businessError.message}`);
      showToastSafely(this.prompt, '打开项目网站失败', 1000, 'Tutorial');
    }
  }

  private async copyContact(content: string, label: string): Promise<void> {
    if (this.vibrationLevel > 0) vibration.dotVibration();
    try {
      const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, content);
      await pasteboard.getSystemPasteboard().setData(pasteData);
      showToastSafely(this.prompt, `已复制${label}`, 1600, 'Tutorial');
    } catch (error) {
      console.error('[Dashboard][pages/more/TutorialPage][ERROR]', `复制${label}失败: ${JSON.stringify(error)}`);
      showToastSafely(this.prompt, '复制失败', 1600, 'Tutorial');
    }
  }

  @Builder
  private bullet(text: string): void {
    Row({ space: 8 }) {
      Text('•').fontSize(16).fontColor($r('app.color.diff_content'))
      Text(text)
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.v3_text_secondary'))
        .layoutWeight(1)
        .accessibilityText(text)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private featureItem(title: string, detail: string): void {
    Row({ space: 12 }) {
      Text(title)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.diff_content'))
        .width(76)
      Text(detail)
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.v3_text_secondary'))
        .layoutWeight(1)
        .accessibilityText(`${title}，${detail}`)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
    .padding({ top: 9, bottom: 9 })
  }

  @Builder
  private shareMethod(number: string, title: string, detail: string): void {
    Row({ space: 10 }) {
      Text(number)
        .fontSize(12)
        .fontWeight(FontWeight.Bold)
        .fontColor(Color.White)
        .textAlign(TextAlign.Center)
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor($r('app.color.diff_content'))
      Column({ space: 2 }) {
        Text(title)
          .fontSize(14)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.v3_text_primary'))
        Text(detail)
          .fontSize(12)
          .lineHeight(18)
          .fontColor($r('app.color.v3_text_secondary'))
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .alignItems(VerticalAlign.Top)
  }

  @Builder
  private contactRow(title: string, name: string, detail: string, copyContent: string, label: string): void {
    Row({ space: 10 }) {
      Column({ space: 2 }) {
        Text(title)
          .fontSize(13)
          .fontWeight(FontWeight.Medium)
          .fontColor($r('app.color.v3_text_primary'))
        Text(`${name} · ${detail}`)
          .fontSize(12)
          .lineHeight(18)
          .fontColor($r('app.color.v3_text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('复制').fontSize(12).fontColor($r('app.color.diff_content'))
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 10, bottom: 10 })
    .borderRadius(12)
    .backgroundColor($r('app.color.v3_surface_alt'))
    .scale({ x: this.pressedCard === `contact-${title}` ? 0.98 : 1,
      y: this.pressedCard === `contact-${title}` ? 0.98 : 1 })
    .animation({ duration: 120, curve: Curve.EaseOut })
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.updatePressed(`contact-${title}`, true);
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.updatePressed(`contact-${title}`, false);
      }
    })
    .onClick((): void => {
      this.copyContact(copyContent, label);
    })
    .accessibilityGroup(true)
    .accessibilityText(`${title}，${name}，${detail}，点击复制${label}`)
  }

  @Builder
  private appIntroductionCard(): void {
    Column({ space: 11 }) {
      Text('应用介绍')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content'))
      Text('欢迎来到 Dashboard 应用看板')
        .fontSize(17).fontWeight(FontWeight.Medium).fontColor($r('app.color.v3_text_primary'))
      Text('这是一款面向 HarmonyOS 应用生态的数据看板，帮助你快速了解应用市场全貌，也能定向查询一款应用的详细资料与变化趋势。')
        .fontSize(14).lineHeight(22).fontColor($r('app.color.v3_text_primary'))
      Text(`当前版本 ${APP_VERSION}`).fontSize(12).fontColor($r('app.color.v3_text_secondary'))
      Text('打开项目网站')
        .fontSize(13)
        .fontColor($r('app.color.diff_content'))
        .decoration({ type: TextDecorationType.Underline, color: $r('app.color.diff_content') })
        .padding({ top: 3, bottom: 3 })
        .onClick(() => this.openProjectSite())
        .accessibilityText('打开Dashboard项目网站')
      Text('市场数据来自公开网络信息，仅供参考，实际信息请以应用市场为准。')
        .fontSize(12)
        .lineHeight(18)
        .fontColor($r('app.color.v3_accent_red'))
        .width('100%')
        .padding(10)
        .borderRadius(10)
        .backgroundColor($r('app.color.v3_warning_bg'))
      Divider()
        .color($r('app.color.border'))
        .margin({ top: 2, bottom: 2 })
        .accessibilityText('应用介绍与联系方式分隔线')
      Text('联系我们')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.diff_content'))
        .width('100%')
      Text('欢迎加入我们的用户群聊。使用中遇到问题、发现数据异常，或对功能有任何建议，都欢迎联系我们。点击下方条目即可复制联系方式。')
        .fontSize(13)
        .lineHeight(20)
        .fontColor($r('app.color.v3_text_primary'))
        .width('100%')
      this.contactRow('用户群聊', 'Harmony Dashboard 官方交流群', 'QQ群 757273833', '757273833', '群号')
      this.contactRow('主要负责人', '清霁·Rayawa', 'rayawa.work@outlook.com',
        'rayawa.work@outlook.com', '邮箱')
      this.contactRow('项目负责人', 'shenjack', '3695888@qq.com', '3695888@qq.com', '邮箱')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
    .padding(16)
    .borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .scale({ x: this.pressedCard === 'intro' ? 0.985 : 1, y: this.pressedCard === 'intro' ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressedCard === 'intro', hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressedCard === 'intro'))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.updatePressed('intro', true);
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updatePressed('intro', false);
    })
    .opacity(this.animStep >= this.enterStep(1, 1) ? 1 : 0)
    .translate({ y: this.animStep >= this.enterStep(1, 1) ? 0 : 20 })
    .accessibilityGroup(true)
    .accessibilityText('应用介绍')
  }

  @Builder
  private appFeaturesCard(): void {
    Column({ space: 4 }) {
      Text('应用功能')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content')).width('100%')
      Text('从市场概览到单个应用趋势，常用数据都集中在看板中。')
        .fontSize(14).lineHeight(21).fontColor($r('app.color.v3_text_primary')).width('100%')
        .margin({ bottom: 5 })
      this.featureItem('首页', '查看应用数量、开发者与专题规模、服务状态，以及最近收录的应用。')
      Divider().color($r('app.color.v3_chart_grid'))
      this.featureItem('概况', '通过目标 SDK、最低 SDK、评分分布饼图和 Harmony API 历史图了解市场结构。')
      Divider().color($r('app.color.v3_chart_grid'))
      this.featureItem('应用详情', '查看上架应用的版本、开发者、下载量、评分、截图、介绍等完整资料。')
      Divider().color($r('app.color.v3_chart_grid'))
      this.featureItem('趋势分析', '在详情页继续查看下载趋势和评分趋势，了解一款应用随时间的变化。')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').padding(16).borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .scale({ x: this.pressedCard === 'features' ? 0.985 : 1,
      y: this.pressedCard === 'features' ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressedCard === 'features', hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressedCard === 'features'))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.updatePressed('features', true);
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updatePressed('features', false);
    })
    .opacity(this.animStep >= this.enterStep(2, 1) ? 1 : 0)
    .translate({ y: this.animStep >= this.enterStep(2, 1) ? 0 : 20 })
    .accessibilityGroup(true)
    .accessibilityText('应用功能')
  }

  @Builder
  private queryImage(title: string, imageResource: Resource, accessibility: string): void {
    Column({ space: 8 }) {
      Text(title)
        .fontSize(12).lineHeight(18).fontColor($r('app.color.v3_text_secondary'))
        .textAlign(TextAlign.Center).width('100%')
      Image(imageResource)
        .width('100%')
        .aspectRatio(QUERY_IMAGE_RATIO)
        .objectFit(ImageFit.Cover)
        .borderRadius(9)
        .border({ width: 1, color: $r('app.color.border') })
        .accessibilityText(accessibility)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private queryCard(): void {
    Column({ space: 10 }) {
      Text('查询功能')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content')).width('100%')
      Text('看板既支持浏览全量应用，也支持通过明确目标快速找到某一款应用。')
        .fontSize(14).lineHeight(21).fontColor($r('app.color.v3_text_primary')).width('100%')
      this.bullet('在“总表”中查看全部已收录应用，并按应用类型、名称、分类、标签、开发者等条件筛选。')
      this.bullet('支持按下载量、评分、更新时间等字段排序，还可以切换每页数量、翻页或跳转到指定页。')
      this.bullet('想定向检索时，可以使用应用内顶部搜索栏；也可以长按应用图标分享至本应用，或从华为应用市场把应用分享至本应用。')
      Row({ space: 10 }) {
        this.queryImage('应用内顶部搜索栏', $r('app.media.submit_app'), '应用内顶部搜索栏查询示意图')
        this.queryImage('从应用图标或应用市场分享', $r('app.media.submit_store'), '从应用图标或应用市场分享查询示意图')
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').padding(16).borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .scale({ x: this.pressedCard === 'query' ? 0.985 : 1, y: this.pressedCard === 'query' ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressedCard === 'query', hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressedCard === 'query'))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.updatePressed('query', true);
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updatePressed('query', false);
    })
    .opacity(this.animStep >= this.enterStep(3, 2) ? 1 : 0)
    .translate({ y: this.animStep >= this.enterStep(3, 2) ? 0 : 20 })
    .accessibilityGroup(true)
    .accessibilityText('查询功能')
  }

  @Builder
  private knockShareBlock(): void {
    Column({ space: 8 }) {
      Text('碰一碰分享')
        .fontSize(13).fontWeight(FontWeight.Medium).fontColor($r('app.color.v3_text_primary')).width('100%')
      KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone })
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private airShareBlock(): void {
    Column({ space: 8 }) {
      Text('隔空传送分享')
        .fontSize(13).fontWeight(FontWeight.Medium).fontColor($r('app.color.v3_text_primary')).width('100%')
      Text('选择隔空传送并按画面提示完成手势，即可把当前网页或应用详情卡片发送到附近设备。')
        .fontSize(12).lineHeight(18).fontColor($r('app.color.v3_text_secondary')).width('100%')
      Image($r('app.media.grasp'))
        .width('100%')
        .aspectRatio(400 / 267)
        .constraintSize({ maxWidth: 400, maxHeight: 267 })
        .objectFit(ImageFit.Contain)
        .borderRadius(10)
        .border({ width: 1, color: $r('app.color.border') })
        .accessibilityText('隔空传送分享操作示意图')
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%')
  }

  @Builder
  private shareGuides(): void {
    if (this.shareContentWidth >= SHARE_ROW_BREAKPOINT) {
      Row({ space: 14 }) {
        Column() { this.knockShareBlock() }
          .layoutWeight(1)
          .constraintSize({ minWidth: 320 })
        Column() { this.airShareBlock() }.layoutWeight(1)
      }
      .width('100%')
      .alignItems(VerticalAlign.Top)
    } else {
      Column({ space: 14 }) {
        this.knockShareBlock()
        this.airShareBlock()
      }
      .width('100%')
    }
  }

  @Builder
  private shareCard(): void {
    Column({ space: 11 }) {
      Text('分享功能')
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor($r('app.color.diff_content')).width('100%')
      Text('S站网页和应用详情页都支持分享。你可以根据接收方和设备选择下面三种方式。')
        .fontSize(14).lineHeight(21).fontColor($r('app.color.v3_text_primary')).width('100%')
      this.shareMethod('1', '点击分享按钮', '点击页面右上角的分享按钮，通过系统分享面板发送。')
      this.shareMethod('2', '碰一碰分享', '让支持该能力的两台 HarmonyOS 设备靠近，按系统提示完成分享。')
      this.shareMethod('3', '隔空传送分享', '选择附近设备并完成手势，把当前内容直接发送给对方。')
      this.shareGuides()
    }
    .alignItems(HorizontalAlign.Start)
    .width('100%').padding(16).borderRadius(16)
    .backgroundColor($r('app.color.v3_surface'))
    .border({ width: 1, color: $r('app.color.nd_card_border') })
    .scale({ x: this.pressedCard === 'share' ? 0.985 : 1, y: this.pressedCard === 'share' ? 0.985 : 1 })
    .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
    .visualEffect(pressVisualEffect(this.pressedCard === 'share', hdsEffect.PointLightIlluminatedType.BORDER))
    .compositingFilter(pressLightFieldFilter(this.pressedCard === 'share'))
    .onTouch((event: TouchEvent): void => {
      if (event.type === TouchType.Down) this.updatePressed('share', true);
      else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.updatePressed('share', false);
    })
    .onAreaChange((_oldValue: Area, newValue: Area): void => {
      this.shareContentWidth = Number(newValue.width) - 32;
    })
    .opacity(this.animStep >= this.enterStep(4, 3) ? 1 : 0)
    .translate({ y: this.animStep >= this.enterStep(4, 3) ? 0 : 20 })
    .accessibilityGroup(true)
    .accessibilityText('分享功能')
  }

  @Builder
  private narrowTutorialContent(): void {
    Scroll() {
      Column({ space: 16 }) {
        Blank().height(100).width('100%')
        this.appIntroductionCard()
        this.appFeaturesCard()
        this.queryCard()
        this.shareCard()
        Blank().height(32).width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .accessibilityText('可滚动的应用使用教程')
  }

  @Builder
  private wideTutorialContent(): void {
    Row({ space: 16 }) {
      Column() {
        Blank().height(80).width('100%')
        Column() {
          this.appIntroductionCard()
        }
        .layoutWeight(1)
        .width('100%')
        .justifyContent(FlexAlign.Center)
      }
      .layoutWeight(4)
      .height('100%')
      .accessibilityGroup(true)
      .accessibilityText('固定显示的应用介绍与联系方式')

      Divider()
        .vertical(true)
        .height('100%')
        .color($r('app.color.border'))
        .accessibilityText('教程介绍与功能说明分隔线')

      Scroll() {
        Column({ space: 16 }) {
          Blank().height(100).width('100%')
          this.appFeaturesCard()
          this.queryCard()
          this.shareCard()
          Blank().height(32).width('100%')
        }
        .width('100%')
      }
      .layoutWeight(6)
      .height('100%')
      .scrollBar(BarState.Off)
      .accessibilityText('可独立滚动的教程右栏')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .constraintSize({ maxWidth: CONTENT_MAX_WIDTH })
    .alignItems(VerticalAlign.Top)
  }

  build() {
    HdsNavDestination() {
      Column() {
        if (this.contentWidth >= TUTORIAL_COLUMN_BREAKPOINT) {
          this.wideTutorialContent()
        } else {
          this.narrowTutorialContent()
        }
      }
      .backgroundColor($r('app.color.backcolor'))
      .width('100%')
      .height('100%')
      .alignItems(HorizontalAlign.Center)
      .onAreaChange((_oldValue: Area, newValue: Area): void => {
        const nextWidth = Number(newValue.width);
        this.contentWidth = nextWidth;
        this.startPageAnimationOnce(nextWidth >= TUTORIAL_COLUMN_BREAKPOINT ? 3 : 4);
      })
    }
    .titleMode(HdsNavDestinationTitleMode.MINI)
    .transition(pageTransition())
    .ignoreLayoutSafeArea([LayoutSafeAreaType.SYSTEM], [LayoutSafeAreaEdge.TOP, LayoutSafeAreaEdge.BOTTOM])
    .onBackPressed(() => {
      if (this.vibrationLevel > 0) vibration.backVibration();
      popPathSafely(this.pageStack, 'pages/more/TutorialPage');
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
          backgroundStyle: { backgroundColor: Color.Transparent },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'), subTitleColor: $r('sys.color.font_secondary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        scrollEffectStyle: {
          backgroundStyle: { backgroundColor: Color.Transparent },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'), subTitleColor: $r('sys.color.font_secondary'),
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary'),
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'), iconColor: $r('sys.color.icon_primary'),
            },
          },
        },
        systemMaterialEffect: {
          materialType: hdsMaterial.MaterialType.IMMERSIVE,
          materialLevel: this.immersiveMaterialLevel,
        },
      },
      content: {
        title: { mainTitle: '教程', mainTitleSize: TitleSize.TITLE_S },
        backIcon: {
          action: () => {
            if (this.vibrationLevel > 0) vibration.backVibration();
            popPathSafely(this.pageStack, 'pages/more/TutorialPage');
          },
        },
      },
    })
    .accessibilityText('教程导航页')
  }
}

@Builder
export function TutorialPageBuilder(): void {
  TutorialPage()
}
