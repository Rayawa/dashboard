import { hdsEffect } from '@kit.UIDesignKit';
import { deviceInfo } from '@kit.BasicServicesKit';
import { uiEffect } from '@kit.ArkGraphics2D';
import {
    DEFAULT_LIGHT_FIELD_LEVEL,
    STORAGE_KEY_LIGHT_FIELD_LEVEL,
} from './constants';

const LIGHT_FIELD_LEVEL_DIM = 0;
const LIGHT_FIELD_LEVEL_BRIGHT = 1;
const LIGHT_FIELD_LEVEL_HIGH = 2;
const DIM_INTENSITY_RATIO = 0.55;
const DIM_HEIGHT_RATIO = 0.78;
const DIM_BLOOM = 0.25;
const BRIGHT_BLOOM = 1.0;
const HIGH_INTENSITY_RATIO = 1.25;
const HIGH_HEIGHT_RATIO = 1.12;
const HDR_BRIGHTNESS_RATIO = 1.5;
let hdrFailureLogged = false;

// SDK 23 的类型定义不含 API 24 方法。通过窄接口隔离符号，并在调用前做运行时版本判断。
interface Api24HdrFilter extends uiEffect.Filter {
    hdrBrightnessRatio(ratio: number): uiEffect.Filter;
}

function getLightFieldLevel(): number {
    const stored = AppStorage.get<number>(STORAGE_KEY_LIGHT_FIELD_LEVEL);
    const level = stored === LIGHT_FIELD_LEVEL_DIM || stored === LIGHT_FIELD_LEVEL_BRIGHT ||
        stored === LIGHT_FIELD_LEVEL_HIGH ? stored : DEFAULT_LIGHT_FIELD_LEVEL;
    return level === LIGHT_FIELD_LEVEL_HIGH && !isHdrLightFieldSupported() ?
        LIGHT_FIELD_LEVEL_BRIGHT : level;
}

export function isHdrLightFieldSupported(): boolean {
    return deviceInfo.sdkApiVersion >= 24;
}

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
    const level = getLightFieldLevel();
    const resolvedIntensity = level === LIGHT_FIELD_LEVEL_DIM ? intensity * DIM_INTENSITY_RATIO :
        level === LIGHT_FIELD_LEVEL_HIGH ? intensity * HIGH_INTENSITY_RATIO : intensity;
    const resolvedHeight = level === LIGHT_FIELD_LEVEL_DIM ? height * DIM_HEIGHT_RATIO :
        level === LIGHT_FIELD_LEVEL_HIGH ? height * HIGH_HEIGHT_RATIO : height;
    const resolvedBloom = !pressed ? 0 :
        level === LIGHT_FIELD_LEVEL_DIM ? DIM_BLOOM : BRIGHT_BLOOM;

    return new hdsEffect.HdsEffectBuilder()
        .pointLight({
            sourceType: !pressed ? hdsEffect.PointLightSourceType.NONE :
                level === LIGHT_FIELD_LEVEL_DIM ? hdsEffect.PointLightSourceType.SOFT :
                    hdsEffect.PointLightSourceType.BRIGHT,
            illuminatedType,
            options: {
                color: $r('app.color.diff_content'),
                intensity: resolvedIntensity,
                height: resolvedHeight,
                bloom: resolvedBloom,
            },
        })
        .buildEffect();
}

/**
 * 仅在“高亮”档、按压点光源发光期间，对该组件自身的合成结果启用 HDR。
 * API 23 只会创建空滤镜，不会解析或执行 API 24 方法。
 */
export function pressLightFieldFilter(pressed: boolean): uiEffect.Filter {
    const filter = uiEffect.createFilter();
    if (!pressed || getLightFieldLevel() !== LIGHT_FIELD_LEVEL_HIGH || !isHdrLightFieldSupported()) {
        return filter;
    }

    try {
        return (filter as Api24HdrFilter).hdrBrightnessRatio(HDR_BRIGHTNESS_RATIO);
    } catch (error) {
        if (!hdrFailureLogged) {
            hdrFailureLogged = true;
            console.warn('[Dashboard][common/visualEffects][WARN]',
                `点光源 HDR 启用失败，已保持普通光场: ${JSON.stringify(error)}`);
        }
        return filter;
    }
}
