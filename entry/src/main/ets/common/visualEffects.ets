import { hdsEffect } from '@kit.UIDesignKit';

/**
 * Dashboard 可按压组件统一使用的点光源。
 *
 * 一个 pressed 状态同时驱动光源和组件缩放，避免各组件分别维护多个枚举状态。
 */
export function pressVisualEffect(
    pressed: boolean,
    illuminatedType: hdsEffect.PointLightIlluminatedType,
    intensity: number = 6,
    height: number = 110,
): VisualEffect {
    return new hdsEffect.HdsEffectBuilder()
        .pointLight({
            sourceType: pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.NONE,
            illuminatedType,
            options: {
                color: $r('app.color.diff_content'),
                intensity,
                height,
            },
        })
        .buildEffect();
}
