import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { DEFAULT_VIBRATION_LEVEL, STORAGE_KEY_VIBRATION_LEVEL } from './constants';

const VIBRATION_LEVEL_OFF = 0;
const VIBRATION_LEVEL_SOFT = 1;
const EFFECT_SOFT = 'haptic.effect.soft';
const EFFECT_HARD = 'haptic.effect.hard';

export class vibration {
  private static currentEffectId(): string | undefined {
    const level = AppStorage.get<number>(STORAGE_KEY_VIBRATION_LEVEL) ?? DEFAULT_VIBRATION_LEVEL;
    if (level === VIBRATION_LEVEL_OFF) return undefined;
    return level === VIBRATION_LEVEL_SOFT ? EFFECT_SOFT : EFFECT_HARD;
  }

  private static startPresetVibration(count: number, intensity: number): void {
    const effectId = vibration.currentEffectId();
    if (effectId === undefined) return;
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

  static dotVibration(): void {
    vibration.startPresetVibration(1, 50);
  }

  static waveVibration(): void {
    vibration.startPresetVibration(5, 100);
  }

  static errorVibration(): void {
    vibration.startPresetVibration(2, 100);
  }
}
