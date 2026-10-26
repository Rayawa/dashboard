import { FrameCallback, UIContext } from '@kit.ArkUI';

class ScheduledFrame extends FrameCallback {
    private action?: () => void;
    constructor(action: () => void) { super(); this.action = action; }
    onFrame(_time: number): void {
        const action = this.action;
        this.cancel();
        action?.();
    }
    cancel(): void { this.action = undefined; }
}

/** Coalesce input events into one VSync callback; invalidation also covers queued native callbacks. */
export class FrameScheduler {
    private pending: boolean = false;
    private generation: number = 0;
    private frame?: ScheduledFrame;
    request(context: UIContext, action: () => void): void {
        if (this.pending) return;
        this.pending = true;
        const generation = this.generation;
        const frame = new ScheduledFrame((): void => {
            if (generation !== this.generation) return;
            this.pending = false;
            this.frame = undefined;
            action();
        });
        this.frame = frame;
        try { context.postFrameCallback(frame); }
        catch (error) {
            this.cancel();
            throw error as Error;
        }
    }
    cancel(): void {
        this.generation++;
        this.pending = false;
        // 原生队列可能在后台长时间不触发，取消时立即释放捕获页面的闭包。
        this.frame?.cancel();
        this.frame = undefined;
    }
}

/** Run non-critical startup work after rendering, with a bounded fallback if there are no idle frames. */
export class IdleTask extends FrameCallback {
    private action?: () => void;
    private timer: number = -1;
    constructor(context: UIContext, action: () => void, maximumDelay: number = 2000) {
        super();
        this.action = action;
        this.timer = setTimeout((): void => this.run(), maximumDelay);
        context.postFrameCallback(this);
    }
    onIdle(_remaining: number): void { this.run(); }
    private run(): void {
        const action = this.action;
        this.cancel();
        action?.();
    }
    cancel(): void {
        this.action = undefined;
        if (this.timer >= 0) clearTimeout(this.timer);
        this.timer = -1;
    }
}
