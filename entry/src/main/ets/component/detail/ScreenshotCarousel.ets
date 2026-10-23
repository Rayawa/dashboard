import { curves } from '@kit.ArkUI';
import type { ScreenshotInfo } from '../../common/types';

interface ScreenshotCard { shot: ScreenshotInfo; index: number; leftCopy: boolean; key: string; }

@Component
export struct ScreenshotCarousel {
    @Prop @Watch('onScreenshotsChanged') screenshots: ScreenshotInfo[] = [];
    @Prop compact: boolean = false;
    @Prop @Watch('restartAutoPlay') active: boolean = true;
    @State @Watch('updateWindow') private currentIndex: number = 0;
    @State private dragOffset: number = 0;
    @State private frameWidth: number = 0;
    private autoPlayTimer: number = -1;
    private switching: boolean = false;
    private alive: boolean = false;
    private inViewport: boolean = false;
    private generation: number = 0;
    private screenshotSignature: string = '';
    @State private cards: ScreenshotCard[] = [];
    private settledScreenshotKeys: string[] = [];

    private updateWindow(): void {
        const count = this.screenshots.length;
        const cards: ScreenshotCard[] = [];
        if (count > 0) {
            const indexes = count === 1 ? [this.currentIndex] :
                [(this.currentIndex + count - 1) % count, this.currentIndex, (this.currentIndex + 1) % count];
            for (let i = 0; i < indexes.length; i++) {
                const index = indexes[i];
                cards.push({ shot: this.screenshots[index], index, leftCopy: count === 2 && i === 0,
                    key: `${this.screenshots[index].url}-${count === 2 && i === 0 ? 'left' : index}` });
            }
        }
        this.cards = cards;
    }

    private onScreenshotsChanged(): void {
        const signature = this.screenshots.map((shot: ScreenshotInfo): string => `${shot.url}:${shot.resolution}:${shot.rotated}`).join('|');
        if (signature === this.screenshotSignature) return;
        this.screenshotSignature = signature;
        this.generation++;
        this.switching = false;
        this.dragOffset = 0;
        const retainedKeys: Set<string> = new Set();
        this.screenshots.forEach((shot: ScreenshotInfo, index: number): void => {
            retainedKeys.add(this.screenshotKey(shot, index));
        });
        this.settledScreenshotKeys = this.settledScreenshotKeys.filter((key: string): boolean => retainedKeys.has(key));
        if (this.currentIndex >= this.screenshots.length) {
            this.currentIndex = 0;
        }
        this.updateWindow();
        this.restartAutoPlay();
    }

    private isLandscape(): boolean {
        if (this.screenshots.length === 0) {
            return false;
        }
        const shot = this.screenshots[0];
        const normalized = shot.resolution.replace('×', '*').replace('x', '*').replace('X', '*');
        const parts = normalized.split('*');
        if (parts.length < 2) {
            return false;
        }
        let width = Number(parts[0]);
        let height = Number(parts[1]);
        if (width <= 0 || height <= 0) {
            return false;
        }
        if (shot.rotated !== 0) {
            const originalWidth = width;
            width = height;
            height = originalWidth;
        }
        return width > height;
    }

    private relativePosition(index: number): number {
        const count = this.screenshots.length;
        if (count <= 1 || index === this.currentIndex) {
            return 0;
        }
        const forward = (index - this.currentIndex + count) % count;
        if (forward === 1) {
            return 1;
        }
        if (forward === count - 1) {
            return -1;
        }
        return 2;
    }

    private cardPosition(index: number, leftCopy: boolean): number {
        if (leftCopy && this.screenshots.length === 2) {
            return index === this.currentIndex ? 2 : -1;
        }
        return this.relativePosition(index);
    }

    private revealProgress(): number {
        return Math.min(1, Math.abs(this.dragOffset) / Math.max(1, this.frameWidth));
    }

    private screenshotKey(shot: ScreenshotInfo, index: number): string {
        return `${shot.url}-${index}`;
    }

    private markScreenshotSettled(shot: ScreenshotInfo, index: number): void {
        const key = this.screenshotKey(shot, index);
        if (!this.settledScreenshotKeys.includes(key)) {
            this.settledScreenshotKeys.push(key);
        }
        if (this.allScreenshotsSettled()) {
            this.restartAutoPlay();
        }
    }

    private allScreenshotsSettled(): boolean {
        const shot = this.screenshots[this.currentIndex];
        return !!shot && this.settledScreenshotKeys.includes(this.screenshotKey(shot, this.currentIndex));
    }

    private cardScale(position: number): number {
        if (position === 0) {
            return 1;
        }
        if (Math.abs(position) > 1) {
            return 0.9;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 0.9 + this.revealProgress() * 0.1 : 0.9;
    }

    private cardTranslateX(position: number): number {
        if (position === 0) {
            return this.dragOffset;
        }
        if (Math.abs(position) > 1) {
            return this.frameWidth * 2;
        }
        const sideOffset = this.frameWidth * (this.isLandscape() ? 0.12 : 0.32);
        if ((this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1)) {
            return position * sideOffset * (1 - this.revealProgress());
        }
        return position * sideOffset;
    }

    private cardOpacity(position: number): number {
        if (position === 0) {
            return 1;
        }
        if (Math.abs(position) > 1) {
            return 0;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 0.68 + this.revealProgress() * 0.32 : 0.68;
    }

    private cardZIndex(position: number): number {
        if (position === 0) {
            return 3;
        }
        if (Math.abs(position) > 1) {
            return 0;
        }
        const revealing = (this.dragOffset < 0 && position === 1) || (this.dragOffset > 0 && position === -1);
        return revealing ? 2 : 1;
    }

    private stopAutoPlay(): void {
        if (this.autoPlayTimer >= 0) {
            clearInterval(this.autoPlayTimer);
            this.autoPlayTimer = -1;
        }
    }

    private restartAutoPlay(): void {
        this.stopAutoPlay();
        if (!this.alive || !this.active || !this.inViewport) {
            if (this.switching) {
                this.generation++; this.switching = false; this.dragOffset = 0;
            }
            return;
        }
        if (this.screenshots.length <= 1 || !this.allScreenshotsSettled()) {
            return;
        }
        this.autoPlayTimer = setInterval((): void => this.completeSwitch(1), 2500);
    }

    private completeSwitch(direction: number, restartTimer: boolean = true): void {
        if (!this.alive || !this.active || !this.inViewport || this.switching || this.screenshots.length <= 1) {
            return;
        }
        this.stopAutoPlay();
        this.switching = true;
        const generation = this.generation;
        const count = this.screenshots.length;
        const targetOffset = direction > 0 ? -Math.max(280, this.frameWidth) : Math.max(280, this.frameWidth);
        this.getUIContext().animateTo({
            duration: 280,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => {
                if (!this.alive || generation !== this.generation) return;
                this.currentIndex = (this.currentIndex + direction + count) % count;
                this.dragOffset = 0;
                this.switching = false;
                if (restartTimer) {
                    this.restartAutoPlay();
                }
            },
        }, (): void => {
            this.dragOffset = targetOffset;
        });
    }

    private restoreCurrentCard(): void {
        if (!this.alive || !this.active || !this.inViewport) { this.dragOffset = 0; return; }
        this.getUIContext().animateTo({
            duration: 220,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => { if (this.alive) this.restartAutoPlay(); },
        }, (): void => {
            this.dragOffset = 0;
        });
    }

    private selectPage(index: number): void {
        if (!this.alive || !this.active || !this.inViewport || index === this.currentIndex || this.switching) {
            return;
        }
        this.stopAutoPlay();
        this.getUIContext().animateTo({
            duration: 260,
            curve: curves.springMotion(0.42, 0.88),
            onFinish: (): void => { if (this.alive) this.restartAutoPlay(); },
        }, (): void => {
            this.currentIndex = index;
            this.dragOffset = 0;
        });
    }

    aboutToAppear(): void {
        this.alive = true;
        this.onScreenshotsChanged();
        this.updateWindow();
    }

    aboutToDisappear(): void {
        this.alive = false;
        this.generation++;
        this.stopAutoPlay();
    }

    @Builder
    private screenshotCard(shot: ScreenshotInfo, index: number, leftCopy: boolean = false): void {
        Image(shot.url)
            .width(this.isLandscape() ? '88%' : (this.compact ? '91%' : '52%'))
            .aspectRatio(this.isLandscape() ? 16 / 9 : 9 / 16)
            .objectFit(ImageFit.Contain)
            .autoResize(true)
            .sourceSize({
                width: Math.ceil(this.getUIContext().vp2px(Math.max(1, this.frameWidth) * (this.isLandscape() ? 0.88 : this.compact ? 0.91 : 0.52))),
                height: Math.ceil(this.getUIContext().vp2px(Math.max(1, this.frameWidth) * (this.isLandscape() ? 0.88 * 9 / 16 : (this.compact ? 0.91 : 0.52) * 16 / 9))),
            })
            .borderRadius(16)
            .clip(true)
            .backgroundColor($r('app.color.v3_surface_alt'))
            .border({ width: 1, color: $r('app.color.nd_card_border') })
            .alt($r('app.media.startIcon'))
            .onComplete((): void => this.markScreenshotSettled(shot, index))
            .onError((): void => this.markScreenshotSettled(shot, index))
            .translate({ x: this.cardTranslateX(this.cardPosition(index, leftCopy)) })
            .scale({
                x: this.cardScale(this.cardPosition(index, leftCopy)),
                y: this.cardScale(this.cardPosition(index, leftCopy)),
            })
            .opacity(this.cardOpacity(this.cardPosition(index, leftCopy)))
            .zIndex(this.cardZIndex(this.cardPosition(index, leftCopy)))
            .accessibilityText(`第${index + 1}张应用截图`)
    }

    build() {
        Column({ space: 12 }) {
            Stack({ alignContent: Alignment.Center }) {
                ForEach(this.cards, (card: ScreenshotCard) => {
                    this.screenshotCard(card.shot, card.index, card.leftCopy)
                }, (card: ScreenshotCard) => card.key)
            }
            .width('100%')
            .constraintSize({ maxWidth: 760 })
            .aspectRatio(this.isLandscape() ? 2 : (this.compact ? 0.62 : 1.1))
            .clip(true)
            .onAreaChange((_oldValue: Area, newValue: Area): void => {
                this.frameWidth = Number(newValue.width);
            })
            .onAppear((): void => this.restartAutoPlay())
            .gesture(
                PanGesture({ fingers: 1, direction: PanDirection.Horizontal })
                    .onActionStart((): void => {
                        if (!this.switching) {
                            this.stopAutoPlay();
                        }
                    })
                    .onActionUpdate((event: GestureEvent): void => {
                        if (!this.switching) {
                            const limit = Math.max(280, this.frameWidth);
                            this.dragOffset = Math.max(-limit, Math.min(limit, event.offsetX));
                        }
                    })
                    .onActionEnd((event: GestureEvent): void => {
                        if (this.switching) {
                            return;
                        }
                        const threshold = Math.max(52, this.frameWidth * 0.18);
                        if (this.dragOffset < -threshold || event.velocityX < -900) {
                            this.completeSwitch(1);
                        } else if (this.dragOffset > threshold || event.velocityX > 900) {
                            this.completeSwitch(-1);
                        } else {
                            this.restoreCurrentCard();
                        }
                    })
                    .onActionCancel((): void => this.restoreCurrentCard())
            )

            if (this.screenshots.length > 1) {
                Row({ space: 7 }) {
                    ForEach(this.screenshots, (_shot: ScreenshotInfo, index: number) => {
                        Row()
                            .width(index === this.currentIndex ? 22 : 7)
                            .height(7)
                            .borderRadius(4)
                            .backgroundColor(index === this.currentIndex ?
                                $r('app.color.diff_content') : $r('app.color.v3_chart_grid'))
                            .animation({ duration: 180, curve: Curve.EaseOut })
                            .onClick((): void => this.selectPage(index))
                            .accessibilityText(`切换到第${index + 1}张应用截图`)
                    }, (_shot: ScreenshotInfo, index: number) => `indicator-${index}`)
                }
                .justifyContent(FlexAlign.Center)
                .width('100%')
                .accessibilityText(`当前为第${this.currentIndex + 1}张，共${this.screenshots.length}张应用截图`)
            }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .onVisibleAreaChange([0, 0.01], (visible: boolean, ratio: number): void => {
            this.inViewport = visible && ratio > 0;
            this.restartAutoPlay();
        })
        .accessibilityGroup(true)
        .accessibilityText('可自动播放和左右滑动的叠加应用截图')
    }
}


