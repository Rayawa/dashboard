import { motion } from '@kit.MultimodalAwarenessKit';

/**
 * 暂不展示智感握持设置时保留的检测内核。
 * 后续重新启用悬浮控件时，可通过 start/stop 接回左右手位置动画。
 */
export class HoldingHandMonitor {
  private callback: Callback<motion.HoldingHandStatus> | null = null;
  private lastSwitchTime: number = 0;
  private currentRightHand: boolean = false;

  start(onHandChanged: (rightHand: boolean) => void): void {
    if (this.callback !== null) return;
    if (!canIUse('SystemCapability.MultimodalAwareness.Motion')) {
      console.warn('[Dashboard][common/HoldingHandMonitor][WARN]', '当前设备不支持智感握持能力');
      return;
    }
    try {
      this.callback = (status: motion.HoldingHandStatus): void => {
        const rightHand = status === motion.HoldingHandStatus.RIGHT_HAND_HELD;
        if (rightHand === this.currentRightHand) return;
        const now = Date.now();
        if (now - this.lastSwitchTime < 2000) return;
        this.lastSwitchTime = now;
        this.currentRightHand = rightHand;
        onHandChanged(rightHand);
      };
      motion.on('holdingHandChanged', this.callback);
    } catch (error) {
      this.callback = null;
      console.error('[Dashboard][common/HoldingHandMonitor][ERROR]', `订阅握持状态失败: ${JSON.stringify(error)}`);
    }
  }

  stop(): void {
    if (this.callback === null) return;
    try {
      if (canIUse('SystemCapability.MultimodalAwareness.Motion')) {
        motion.off('holdingHandChanged', this.callback);
      }
    } catch (error) {
      console.error('[Dashboard][common/HoldingHandMonitor][ERROR]', `取消握持订阅失败: ${JSON.stringify(error)}`);
    } finally {
      this.callback = null;
    }
  }
}
