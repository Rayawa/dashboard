import { MIN_PRESS_FEEDBACK_MS, STORAGE_KEY_VIBRATION_LEVEL, DEFAULT_VIBRATION_LEVEL } from './constants';
import { vibration } from './vibration';
import { UIContext } from '@kit.ArkUI';

/** 一个按压状态驱动缩放与光场；取消、离页与兜底计时均会释放。 */
@Observed
export class DiscoveryInteraction {
    pressedKey: string = '';
    private startedAt: number = 0;
    private timer: number = -1;
    private context?: UIContext;

    constructor(context?: UIContext) { this.context = context; }

    private setPressed(key: string): void {
        if (!this.context) { this.pressedKey = key; return; }
        try {
            this.context.animateTo({ duration: 120, curve: Curve.EaseOut }, (): void => {
                this.pressedKey = key;
            });
        } catch (_) {
            // 离页时 UIContext 可能失效，仍须释放按压状态。
            this.pressedKey = key;
        }
    }

    private clearTimer(): void {
        if (this.timer >= 0) clearTimeout(this.timer);
        this.timer = -1;
    }
    private begin(key: string): void {
        this.clearTimer();
        this.setPressed(key);
        this.startedAt = Date.now();
        this.timer = setTimeout((): void => this.dispose(), 800);
    }
    private release(): void {
        this.clearTimer();
        const remaining = Math.max(0, MIN_PRESS_FEEDBACK_MS - (Date.now() - this.startedAt));
        if (remaining === 0) this.setPressed('');
        else this.timer = setTimeout((): void => { this.clearTimer(); this.setPressed(''); }, remaining);
    }
    touch(key: string, event: TouchEvent): void {
        if (event.type === TouchType.Down) this.begin(key);
        else if (this.pressedKey === key) {
            if (event.type === TouchType.Cancel) this.dispose();
            else if (event.type === TouchType.Up) this.release();
        }
    }
    activate(key: string): void {
        if (this.pressedKey !== key) this.begin(key);
        this.release();
        if ((AppStorage.get<number>(STORAGE_KEY_VIBRATION_LEVEL) ?? DEFAULT_VIBRATION_LEVEL) > 0) {
            vibration.dotVibration();
        }
    }
    dispose(): void {
        this.clearTimer();
        this.pressedKey = '';
    }
}
