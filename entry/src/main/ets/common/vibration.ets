import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DEFAULT_VIBRATION_LEVEL, STORAGE_KEY_VIBRATION_LEVEL } from './constants';

const VIBRATION_LEVEL_OFF = 0;
const VIBRATION_LEVEL_SOFT = 1;
const EFFECT_SOFT = 'haptic.effect.soft';
const EFFECT_HARD = 'haptic.effect.hard';

export class vibration {
  private static lastBackVibrationAt: number = 0;
  private static currentEffectId(): string | undefined {
    const level = AppStorage.get<number>(STORAGE_KEY_VIBRATION_LEVEL) ?? DEFAULT_VIBRATION_LEVEL;
    if (level === VIBRATION_LEVEL_OFF) return undefined;
    return level === VIBRATION_LEVEL_SOFT ? EFFECT_SOFT : EFFECT_HARD;
  }

  private static startPresetVibrationWithEffect(effectId: string, count: number, intensity: number): void {
    vibrator.isSupportEffect(effectId, (err: BusinessError, state: boolean) => {
      if (err) {
        console.error('[Dashboard][common/vibration][ERROR]',
          `Failed to query effect ${effectId}. Code: ${err.code}, message: ${err.message}`,
        );
        return;
      }
      if (!state) {
        console.warn('[Dashboard][common/vibration][WARN]', `Vibration effect is unsupported: ${effectId}`);
        return;
      }
      try {
        vibrator.startVibration(
          {
            type: 'preset',
            effectId,
            count,
            intensity,
          },
          { usage: 'touch' },
          (error: BusinessError) => {
            if (error) {
              console.error('[Dashboard][common/vibration][ERROR]',
                `Failed to start ${effectId}. Code: ${error.code}, message: ${error.message}`,
              );
            }
          },
        );
      } catch (error) {
        const businessError = error as BusinessError;
        console.error('[Dashboard][common/vibration][ERROR]',
          `Failed to start ${effectId}. Code: ${businessError.code}, message: ${businessError.message}`,
        );
      }
    });
  }

  private static startPresetVibration(count: number, intensity: number): void {
    const effectId = vibration.currentEffectId();
    if (effectId === undefined) return;
    vibration.startPresetVibrationWithEffect(effectId, count, intensity);
  }

  static dotVibration(): void {
    vibration.startPresetVibration(1, 50);
  }

  /**
   * 返回键、标题栏返回与系统侧滑返回可能在同一帧触发多个回调；短时间去重，
   * 保证一次返回动作只产生一次清晰的触觉反馈。
   */
  static backVibration(): void {
    const now = Date.now();
    if (now - vibration.lastBackVibrationAt < 120) return;
    vibration.lastBackVibrationAt = now;
    vibration.startPresetVibration(1, 50);
  }

  static waveVibration(): void {
    // 首次启动时拦截关闭重要提示属于强制提醒，不受用户常规触觉强度设置影响。
    vibration.startPresetVibrationWithEffect(EFFECT_HARD, 5, 100);
  }

  static errorVibration(): void {
    vibration.startPresetVibration(2, 100);
  }
}
