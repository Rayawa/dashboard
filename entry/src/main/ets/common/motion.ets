import { curves, UIContext } from '@kit.ArkUI';

/**
 * Dashboard 的统一动效节奏。
 *
 * 交互反馈保持短促，页面/组件进出使用无明显回弹的弹簧。
 */
export const CONTENT_ENTER_DURATION_MS: number = 280;
export const PAGE_TRANSITION_DURATION_MS: number = 300;
export const STAGGER_ENTER_DURATION_MS: number = 500;
export const STAGGER_ENTER_DELAY_MS: number = 100;
export const STAGGER_ENTER_INTERVAL_MS: number = 125;

export function contentEnterTransition(offsetY: number = 12): TransitionEffect {
  return TransitionEffect.OPACITY
    .combine(TransitionEffect.translate({ y: offsetY }))
    .combine(TransitionEffect.scale({ x: 0.985, y: 0.985 }))
    .animation({
      duration: CONTENT_ENTER_DURATION_MS,
      curve: curves.springMotion(0.42, 0.92),
    });
}

export function pageTransition(): TransitionEffect {
  return TransitionEffect.asymmetric(
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: 16 }))
      .combine(TransitionEffect.scale({ x: 0.992, y: 0.992 }))
      .animation({ duration: PAGE_TRANSITION_DURATION_MS, curve: curves.springMotion(0.45, 0.94) }),
    TransitionEffect.OPACITY
      .combine(TransitionEffect.translate({ x: 10 }))
      .combine(TransitionEffect.scale({ x: 0.992, y: 0.992 }))
      .animation({ duration: 220, curve: Curve.EaseInOut }),
  );
}

export function runPageEnterAnimation(context: UIContext, update: () => void): void {
  context.animateTo({
    duration: CONTENT_ENTER_DURATION_MS,
    curve: curves.springMotion(0.42, 0.92),
  }, update);
}

/**
 * 使用单一 animStep 驱动任意数量的分组入场，替代为每一组声明状态和定时器。
 */
export function startStaggerEnterAnimation(
    context: UIContext,
    stepCount: number,
    updateStep: (step: number) => void,
): number[] {
    const timers: number[] = [];
    for (let step = 1; step <= stepCount; step++) {
        const targetStep = step;
        timers.push(setTimeout((): void => {
            context.animateTo({
                duration: STAGGER_ENTER_DURATION_MS,
                curve: curves.springMotion(0.35, 0.75),
            }, (): void => updateStep(targetStep));
        }, STAGGER_ENTER_DELAY_MS + (step - 1) * STAGGER_ENTER_INTERVAL_MS));
    }
    return timers;
}

export function cancelStaggerEnterAnimation(timers: number[]): void {
    for (const timer of timers) {
        clearTimeout(timer);
    }
}
