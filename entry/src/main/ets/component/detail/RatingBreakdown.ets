import { hdsEffect } from '@kit.UIDesignKit';
import { formatExactCount } from '../../common/format';
import type { MarketApp } from '../../common/types';
import { cancelStaggerEnterAnimation, contentEnterTransition, startStaggerEnterAnimation } from '../../common/motion';
import { pressLightFieldFilter, pressVisualEffect } from '../../common/visualEffects';

interface StarCount {
    star: number;
    count: number;
}

@Component
export struct RatingBreakdown {
    @Prop app: MarketApp = {} as MarketApp;
    @State private pressedStar: number = 0;
    @State private animStep: number = 0;
    private enterAnimationTimers: number[] = [];

    private startEnterAnimation(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.animStep = 0;
        this.enterAnimationTimers = startStaggerEnterAnimation(this.getUIContext(), 1, (step: number): void => {
            this.animStep = step;
        });
    }

    aboutToDisappear(): void {
        cancelStaggerEnterAnimation(this.enterAnimationTimers);
        this.enterAnimationTimers = [];
    }

    private rows(): StarCount[] {
        return [
            { star: 5, count: Number(this.app.star_5_rating_count ?? 0) },
            { star: 4, count: Number(this.app.star_4_rating_count ?? 0) },
            { star: 3, count: Number(this.app.star_3_rating_count ?? 0) },
            { star: 2, count: Number(this.app.star_2_rating_count ?? 0) },
            { star: 1, count: Number(this.app.star_1_rating_count ?? 0) },
        ];
    }

    private maxCount(): number {
        let max = 1;
        for (const item of this.rows()) {
            if (item.count > max) max = item.count;
        }
        return max;
    }

    build() {
        Column({ space: 9 }) {
            Row() {
                Text('逐星评分数量').fontSize(16).fontWeight(FontWeight.Bold)
                    .fontColor($r('app.color.v3_text_primary'))
                Blank()
                Text(`共 ${formatExactCount(this.app.total_star_rating_count)} 条`)
                    .fontSize(12).fontColor($r('app.color.v3_text_secondary'))
            }.width('100%')
            ForEach(this.rows(), (item: StarCount) => {
                Row({ space: 10 }) {
                    Text(`${item.star} 星`).width(36).fontSize(12)
                        .fontColor($r('app.color.v3_text_secondary'))
                    Progress({ value: item.count, total: this.maxCount() })
                        .layoutWeight(1).height(6).color($r('app.color.v3_accent_orange'))
                    Text(formatExactCount(item.count)).width(62).fontSize(12).textAlign(TextAlign.End)
                        .fontColor($r('app.color.v3_text_primary'))
                }
                .width('100%')
                .padding({ top: 3, bottom: 3 })
                .borderRadius(8)
                .scale({ x: this.pressedStar === item.star ? 0.985 : 1,
                    y: this.pressedStar === item.star ? 0.985 : 1 })
                .animation({ duration: 120, curve: Curve.EaseOut })
                .visualEffect(pressVisualEffect(this.pressedStar === item.star,
                    hdsEffect.PointLightIlluminatedType.BORDER_CONTENT, 4, 72))
                .compositingFilter(pressLightFieldFilter(this.pressedStar === item.star))
                .onTouch((event: TouchEvent): void => {
                    if (event.type === TouchType.Down) this.pressedStar = item.star;
                    else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressedStar = 0;
                })
                .transition(contentEnterTransition(5))
                .accessibilityText(`${item.star}星评分${item.count}条`)
            }, (item: StarCount) => String(item.star))
        }
        .width('100%').padding(14).borderRadius(14).backgroundColor($r('app.color.v3_surface_alt'))
        .opacity(this.animStep >= 1 ? 1 : 0)
        .translate({ y: this.animStep >= 1 ? 0 : 16 })
        .onAppear((): void => this.startEnterAnimation())
        .accessibilityGroup(true).accessibilityText('逐星评分数量')
    }
}
