/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */

import { image } from '@kit.ImageKit';
import { LengthMetrics } from '@kit.ArkUI';
import { resourceManager } from '@kit.LocalizationKit';
import { Logger } from '../utils/Logger';

const GUIDE_CARD_MULTIPLE_MIN_HEIGHT = 90;
const GUIDE_CARD_SINGLE_MIN_HEIGHT = 80;
const RAWFILE_SRC_PREFIX = 'resources/rawfile/';


export interface CardRes {
  text: ResourceStr;
  rawfilePrefix: string;
  framesCount: number;
  fps?: number; // default 30
  startDelay?: number; // default 0
  stopDelay?: number; // default 0
}

@Reusable
@Component
export struct KnockShareSingleGuideCard {
  @Prop running: boolean = false;
  @Require res: CardRes;
  @Require minHeight: number;
  @Require hasIndicator: boolean;
  @State animReady: boolean = false;
  private animFrames: ImageFrameInfo[] = [];
  private staticFrame: ImageFrameInfo[] = [];

  aboutToAppear(): void {
    this.staticFrame.push({ src: RAWFILE_SRC_PREFIX + this.getPath(1) });
    this.loadPixels().then(() => {
      this.animReady = true;
    });
  }

  @Builder
  tipTextsBuilder() {
    Column({ space: 2 }) {
      Text('可碰一碰分享')
        .fontFamily('HarmonyHeiTi')
        .textAlign(TextAlign.Start)
        .fontColor($r('sys.color.font_primary'))
        .fontSize($r('sys.float.Body_M'))
        .fontWeight(FontWeight.Medium)
        .lineHeight(19)
        .maxFontScale(1)
      Text() {
        Span(this.res.text)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .fontWeight(FontWeight.Regular)
      }
      .fontSize(12)
      .minFontSize(10)
      .maxFontSize(12)
      .lineHeight(16)
      .maxLines(3)
      .maxFontScale(1)
      .fontFamily('HarmonyHeiTi')
      .wordBreak(WordBreak.BREAK_WORD)
      .textAlign(TextAlign.Start)
      .width('100%')
    }
    .alignItems(HorizontalAlign.Start)
    .padding({
      start: LengthMetrics.vp(16),
      top: LengthMetrics.vp(12),
      bottom: LengthMetrics.vp(this.hasIndicator ? 24 : 12)
    })
    .id('tips_container')
    .alignRules({
      left: { anchor: '__container__', align: HorizontalAlign.Start },
      right: { anchor: '__container__', align: HorizontalAlign.End },
    })
    .margin({ end: LengthMetrics.vp(this.minHeight * 1.5) })
    .constraintSize({ minHeight: this.minHeight })
    .zIndex(1)
  }

  @Builder
  animSurfaceBuilder() {
    ImageAnimator()
      .images(this.animReady ? this.animFrames : this.staticFrame)
      .aspectRatio(1.5)
      .state(AnimationStatus.Running)
      .iterations(-1)
      .id('knock_share_guide_anim')
      .alignRules({
        center: { anchor: 'tips_container', align: VerticalAlign.Center },
        right: { anchor: '__container__', align: HorizontalAlign.End },
      })
      .margin(0)
      .height(this.minHeight)
      .state((this.animReady && this.running) ? AnimationStatus.Running : AnimationStatus.Paused)
      .accessibilityLevel('no')
  }

  build() {
    RelativeContainer() {
      this.tipTextsBuilder()
      this.animSurfaceBuilder()
    }
    .borderRadius(8)
    .backgroundColor(this.getColor($r('sys.color.icon_primary'), 0.02))
    .borderWidth(1)
    .borderColor(this.getColor($r('sys.color.icon_primary'), 0.05))
    .clip(true)
    .height('auto')
    .margin({ left: 16, right: 16 })
  }

  private getColor(res: resourceManager.Resource, opacity?: number): resourceManager.Resource | number {
    if (!opacity) {
      return res;
    }
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    try {
      let color = contextFaker.resourceManager.getColorSync(res.id);
      if (opacity !== undefined && opacity >= 0 && opacity <= 1) {
        let alpha = 0xFF & ((color & 0xFF000000) >> 24);
        // 在原有透明度基础上进行opacity计算
        alpha = Math.floor(alpha * opacity);
        color = (alpha << 24) | (color & 0x00FFFFFF);
      }
      return color;
    } catch (error) {
      Logger.error(`getColorSync error. Code: ${error?.code}, message: ${error?.message}`);
      return res;
    }
  }

  private async loadPixels(): Promise<void> {
    const tasks: Promise<ImageFrameInfo>[] = [];
    for (let i = 1; i <= this.res.framesCount; i++) {
      tasks.push(this.loadByRawfile(i));
    }
    this.animFrames = await Promise.all(tasks);
  }

  private async loadByRawfile(index: number): Promise<ImageFrameInfo> {
    const path = this.getPath(index);
    let src: string | PixelMap = RAWFILE_SRC_PREFIX + path;
    let imageSource: image.ImageSource | undefined = undefined;
    const uiContext: UIContext = this.getUIContext();
    const contextFaker: Context = uiContext.getHostContext() as Context;
    try {
      const fd = await contextFaker.resourceManager.getRawFd(path);
      imageSource = image.createImageSource(fd);
      src = await imageSource.createPixelMapUsingAllocator({}, image.AllocatorType.DMA);
    } catch (err) {
      Logger.error(`Failed to load by rawfile: ${err?.code}, ${err?.message}`);
    } finally {
      try {
        contextFaker.resourceManager.closeRawFd(path);
        imageSource?.release();
      } catch (error) {
        Logger.error(`closeRawFd error. Code: ${error?.code}, message: ${error?.message}`);
      }
    }
    return {
      src: src,
      duration: Math.floor(1000 / (this.res.fps ?? 30)) +
        (index === 1 ? (this.res.startDelay ?? 0) : (index === this.res.framesCount ? (this.res.stopDelay ?? 0) : 0)),
    };
  }

  private getPath(index: number): string {
    return `${this.res.rawfilePrefix}${(index).toString().padStart(2, '0')}.webp`;
  }
}

@Component
export default struct KnockShareGuideCard {
  @Require cardSwiperResources: CardRes[];
  @Provide swiperIndex: number = 0;
  private indicatorController: IndicatorComponentController = new IndicatorComponentController();

  @Builder
  indicatorBuilder() {
    IndicatorComponent()
  }

  build() {
    if (this.cardSwiperResources.length === 1) {
      KnockShareSingleGuideCard({
        running: true,
        res: this.cardSwiperResources[0],
        minHeight: GUIDE_CARD_SINGLE_MIN_HEIGHT,
        hasIndicator: false,
      })
        .width('100%')
    } else {
      Stack({ alignContent: Alignment.Bottom }) {
        Swiper() {
          ForEach(this.cardSwiperResources, (item: CardRes, index: number) => {
            KnockShareSingleGuideCard({
              running: this.swiperIndex === index,
              res: item,
              minHeight: GUIDE_CARD_MULTIPLE_MIN_HEIGHT,
              hasIndicator: true,
            })
          })
        }
        .constraintSize({ minHeight: GUIDE_CARD_MULTIPLE_MIN_HEIGHT })
        .width('100%')
        .zIndex(2)
        .onChange(index => {
          this.swiperIndex = index;
        })
        .autoPlay(false)
        .loop(true)
        .indicator(true)
        .itemSpace(12)
        .indicator(this.indicatorController)

        Row() {
          IndicatorComponent(this.indicatorController)
            .style(new DotIndicator())
            .responseRegion({ y: 4, height: 24 })
        }
        .height(24)
        .width('100%')
        .zIndex(3)
        .padding(0)
        .justifyContent(FlexAlign.Center)
      }
    }
  }
}
