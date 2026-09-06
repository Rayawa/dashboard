import { hdsEffect } from '@kit.UIDesignKit';

/**
 * HDS 点光源的全局泛光强度。
 * bloom 由 HDS 在光源层完成，可在不提高整个组件亮度的情况下产生 HDR 式高亮。
 */
const GLOBAL_POINT_LIGHT_BLOOM: number = 1.0;

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
                bloom: pressed ? GLOBAL_POINT_LIGHT_BLOOM : 0,
            },
        })
        .buildEffect();
}
