/*
 * Copyright (c) Huawei Technologies Co., Ltd. 2025-2025. All rights reserved.
 */

import { loadRawPixelMap } from '../../services/media/RawImageLoader';
import { curves, LengthMetrics } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { resourceManager } from '@kit.LocalizationKit';
import { Logger } from '../../utils/diagnostics/Logger';
import { vibration } from '../../utils/device/vibration';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

const GUIDE_CARD_MULTIPLE_MIN_HEIGHT = 90;
const GUIDE_CARD_SINGLE_MIN_HEIGHT = 80;
const RAWFILE_SRC_PREFIX = "resources/rawfile/";

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
    @Prop @Watch('onActivityChanged') running: boolean = false;
    @Require res: CardRes;
    @Require minHeight: number;
    @Require hasIndicator: boolean;
    @State animReady: boolean = false;
    @State private pressed: boolean = false;
    private animFrames: ImageFrameInfo[] = [];
    private staticFrame: ImageFrameInfo[] = [];
    private loadToken: number = 0;
    private alive: boolean = false;
    private inViewport: boolean = false;
    private loading: boolean = false;

    private onActivityChanged(): void {
        if (!this.alive) return;
        if (!this.running || !this.inViewport) {
            this.loadToken++; this.loading = false; this.animReady = false;
            this.releaseAnimationFrames(); return;
        }
        if (this.animReady || this.loading) return;
        this.loading = true;
        const token = ++this.loadToken;
        this.loadPixels(token).catch((error: Error): void => {
            Logger.warn(`Guide animation loading failed: ${error.message}`);
        }).finally((): void => { if (token === this.loadToken) this.loading = false; });
    }

    aboutToAppear(): void {
        this.staticFrame = [{ src: RAWFILE_SRC_PREFIX + this.getPath(1) }];
        this.alive = true;
        this.onActivityChanged();
    }

    aboutToDisappear(): void {
        this.alive = false;
        this.loadToken++;
        this.animReady = false;
        this.releaseAnimationFrames();
        this.staticFrame = [];
    }

    @Builder
    tipTextsBuilder() {
        Column({ space: 2 }) {
            Text("可碰一碰分享")
                .fontFamily("HarmonyHeiTi")
                .textAlign(TextAlign.Start)
                .fontColor($r("sys.color.font_primary"))
                .fontSize($r("sys.float.Body_M"))
                .fontWeight(FontWeight.Medium)
                .lineHeight(19)
                .maxFontScale(1)
                .accessibilityText('可碰一碰分享')
            Text() {
                Span(this.res.text)
                    .fontColor($r("sys.color.ohos_id_color_text_secondary"))
                    .fontWeight(FontWeight.Regular)
            }
            .fontSize(12)
            .minFontSize(10)
            .maxFontSize(12)
            .lineHeight(16)
            .maxLines(3)
            .maxFontScale(1)
            .fontFamily("HarmonyHeiTi")
            .wordBreak(WordBreak.BREAK_WORD)
            .textAlign(TextAlign.Start)
            .width("100%")
            .accessibilityText(`${this.res.text}`)
        }
        .alignItems(HorizontalAlign.Start)
        .padding({
            start: LengthMetrics.vp(16),
            top: LengthMetrics.vp(12),
            bottom: LengthMetrics.vp(this.hasIndicator ? 24 : 12),
        })
        .id("tips_container")
        .alignRules({
            left: { anchor: "__container__", align: HorizontalAlign.Start },
            right: { anchor: "__container__", align: HorizontalAlign.End },
        })
        .margin({ end: LengthMetrics.vp(this.minHeight * 1.5) })
        .constraintSize({ minHeight: this.minHeight })
        .zIndex(1);
    }

    @Builder
    animSurfaceBuilder() {
        ImageAnimator()
            .images(this.animReady ? this.animFrames : this.staticFrame)
            .aspectRatio(1.5)
            .state(AnimationStatus.Running)
            .iterations(-1)
            .id("knock_share_guide_anim")
            .alignRules({
                center: { anchor: "tips_container", align: VerticalAlign.Center },
                right: { anchor: "__container__", align: HorizontalAlign.End },
            })
            .margin(0)
            .height(this.minHeight)
            .state(
                this.animReady && this.running ? AnimationStatus.Running : AnimationStatus.Paused,
            )
            .accessibilityLevel("no");
    }

    build() {
        RelativeContainer() {
            this.tipTextsBuilder()
            this.animSurfaceBuilder()
        }
        .borderRadius(8)
        .backgroundColor(this.getColor($r("sys.color.icon_primary"), 0.02))
        .borderWidth(1)
        .borderColor(this.getColor($r("sys.color.icon_primary"), 0.05))
        .clip(true)
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER, 5, 96))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .height("auto")
        .margin({ left: 16, right: 16 })
        .accessibilityGroup(true)
        .onVisibleAreaChange([0, 0.01], (visible: boolean, ratio: number): void => {
            this.inViewport = visible && ratio > 0; this.onActivityChanged();
        })
        .accessibilityText('碰一碰分享操作说明');
    }

    private getColor(
        res: resourceManager.Resource,
        opacity?: number,
    ): resourceManager.Resource | number {
        if (!opacity) {
            return res;
        }
        const uiContext: UIContext = this.getUIContext();
        const contextFaker: Context = uiContext.getHostContext() as Context;
        try {
            let color = contextFaker.resourceManager.getColorSync(res.id);
            if (opacity !== undefined && opacity >= 0 && opacity <= 1) {
                let alpha = 0xff & ((color & 0xff000000) >> 24);
                // 在原有透明度基础上进行opacity计算
                alpha = Math.floor(alpha * opacity);
                color = (alpha << 24) | (color & 0x00ffffff);
            }
            return color;
        } catch (error) {
            Logger.error(`getColorSync error. Code: ${error?.code}, message: ${error?.message}`);
            return res;
        }
    }

    private async loadPixels(token: number): Promise<void> {
        const frames: ImageFrameInfo[] = [];
        let transferred = false;
        try {
            // 逐帧解码，避免同时打开上百个文件；未移交的帧由 finally 统一释放。
            const count = Math.ceil(this.res.framesCount / 2);
            for (let ordinal = 0; ordinal < count; ordinal++) {
                if (!this.alive || token !== this.loadToken) return;
                const index = ordinal === count - 1 ? this.res.framesCount : ordinal * 2 + 1;
                frames.push(await this.loadByRawfile(index));
                if (!this.alive || token !== this.loadToken) return;
            }
            this.releaseAnimationFrames();
            this.animFrames = frames;
            transferred = true;
            this.animReady = true;
        } finally {
            if (!transferred) this.releaseFrames(frames);
        }
    }

    private releaseFrame(frame: ImageFrameInfo): void {
        if (typeof frame.src === 'string') return;
        try {
            (frame.src as PixelMap).release().catch((error: Error): void => {
                Logger.warn(`Guide animation frame release failed: ${error.message}`);
            });
        } catch (error) {
            Logger.warn(`Guide animation frame release failed: ${JSON.stringify(error)}`);
        }
    }

    private releaseFrames(frames: ImageFrameInfo[]): void {
        for (const frame of frames) this.releaseFrame(frame);
    }

    private releaseAnimationFrames(): void {
        this.releaseFrames(this.animFrames);
        this.animFrames = [];
    }

    private async loadByRawfile(index: number): Promise<ImageFrameInfo> {
        const path = this.getPath(index);
        let src: string | PixelMap = RAWFILE_SRC_PREFIX + path;
        const uiContext: UIContext = this.getUIContext();
        const contextFaker: Context = uiContext.getHostContext() as Context;
        try {
            const height = Math.min(192, Math.ceil(uiContext.vp2px(this.minHeight)));
            src = await loadRawPixelMap(contextFaker.resourceManager, path, Math.ceil(height * 1.5), height);
        } catch (err) {
            Logger.error(`Failed to load by rawfile: ${err?.code}, ${err?.message}`);
        }
        return {
            src: src,
            duration:
            Math.floor(2000 / (this.res.fps ?? 30)) +
                (index === 1
                    ? (this.res.startDelay ?? 0)
                    : index === this.res.framesCount
                        ? (this.res.stopDelay ?? 0)
                        : 0),
        };
    }

    private getPath(index: number): string {
        return `${this.res.rawfilePrefix}${index.toString().padStart(2, "0")}.webp`;
    }
}
@Component
export default struct KnockShareGuideCard {
    @Prop active: boolean = true;
    @Require cardSwiperResources: CardRes[];
    @Provide swiperIndex: number = 0;
    private indicatorController: IndicatorComponentController = new IndicatorComponentController();
    @StorageLink('vibrationLevel') private vibrationLevel: number = 1;

    @Builder
    indicatorBuilder() {
        IndicatorComponent();
    }

    build() {
        if (this.cardSwiperResources.length === 1) {
            KnockShareSingleGuideCard({
                running: this.active,
                res: this.cardSwiperResources[0],
                minHeight: GUIDE_CARD_SINGLE_MIN_HEIGHT,
                hasIndicator: false,
            }).width("100%");
        } else {
            Stack({ alignContent: Alignment.Bottom }) {
                Swiper() {
                    ForEach(this.cardSwiperResources, (item: CardRes, index: number) => {
                        KnockShareSingleGuideCard({
                            running: this.active && this.swiperIndex === index,
                            res: item,
                            minHeight: GUIDE_CARD_MULTIPLE_MIN_HEIGHT,
                            hasIndicator: true,
                        });
                    })
                }
                .constraintSize({ minHeight: GUIDE_CARD_MULTIPLE_MIN_HEIGHT })
                .width("100%")
                .zIndex(2)
                .onChange((index) => {
                    if (this.vibrationLevel > 0) vibration.dotVibration();
                    this.swiperIndex = index;
                })
                .autoPlay(false)
                .loop(true)
                .indicator(true)
                .itemSpace(12)
                .indicator(this.indicatorController)
                .accessibilityText(`碰一碰分享操作说明，第${this.swiperIndex + 1}项，共${this.cardSwiperResources.length}项`)
                Row() {
                    IndicatorComponent(this.indicatorController)
                        .style(new DotIndicator())
                        .responseRegion({ y: 4, height: 24 })
                        .accessibilityText('碰一碰分享说明分页指示器')
                }
                .height(24)
                .width("100%")
                .zIndex(3)
                .padding(0)
                .justifyContent(FlexAlign.Center)
            };
        }
    }
}
