import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class vibration{
  static dotVibration(): void {
    vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
      if (err) {
        console.error(
          `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
        );
        return;
      }
      console.info("Succeed in querying effect");
      if (state) {
        try {
          vibrator.startVibration(
            {
              type: "preset",
              effectId: "haptic.effect.hard",
              count: 1,
              intensity: 50,
            },
            { usage: "touch" },
            (error: BusinessError) => {
              if (error) {
                console.error(
                  `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                );
              } else {
                console.info("Succeed in starting vibration");
              }
            },
          );
        } catch (tryError) {
          console.error(`An unexpected error occurred in try block: ${tryError}`);
        }
      }
    });

  }
  static waveVibration(): void {
    vibrator.isSupportEffect(
      "haptic.effect.hard",
      (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(
            `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
          );
          return;
        }
        console.info("Succeed in querying effect");
        if (state) {
          try {
            vibrator.startVibration(
              {
                type: "preset",
                effectId: "haptic.effect.hard",
                count: 5,
                intensity: 100,
              },
              { usage: "touch" },
              (error: BusinessError) => {
                if (error) {
                  console.error(
                    `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                  );
                } else {
                  console.info("Succeed in starting vibration");
                }
              },
            );
          } catch (tryError) {
            console.error(
              `An unexpected error occurred in try block: ${tryError}`,
            );
          }
        }
      },
    );

  }
  static errorVibration(): void {
    try {
      vibrator.startVibration(
        {
          type: "time",
          duration: 500,
        },
        {
          id: 0,
          usage: "touch",
        },
        (error: BusinessError) => {
          if (error) {
            console.error(
              `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
            );
            return;
          }
          console.info("Succeed in starting vibration");
        },
      );
    } catch (err) {
      let e: BusinessError = err as BusinessError;
      console.error(
        `An unexpected error occurred. Code: ${e.code}, message: ${e.message}`,
      );
    }
  }
}