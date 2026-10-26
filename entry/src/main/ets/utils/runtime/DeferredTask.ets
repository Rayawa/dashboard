/** 单个可替换的延迟任务。组件离开或输入变化时取消，避免旧回调继续持有页面。 */
export class DeferredTask {
    private timer: number = -1;
    private generation: number = 0;

    schedule(action: () => void, delay: number = 0): void {
        this.cancel();
        const generation = this.generation;
        this.timer = setTimeout((): void => {
            if (generation !== this.generation) return;
            this.timer = -1;
            action();
        }, delay);
    }

    cancel(): void {
        this.generation++;
        if (this.timer >= 0) clearTimeout(this.timer);
        this.timer = -1;
    }
}
