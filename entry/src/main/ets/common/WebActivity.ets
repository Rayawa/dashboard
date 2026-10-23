import { webview } from '@kit.ArkWeb';

/** ArkWeb timers are process-wide; one hidden page must not pause another visible page. */
export class WebActivity {
    private static nextOwner: number = 1;
    private static owners: Set<number> = new Set<number>();
    private static running: boolean | undefined = undefined;

    static createOwner(): number { return WebActivity.nextOwner++; }

    static setActive(owner: number, active: boolean): void {
        if (active) WebActivity.owners.add(owner);
        else WebActivity.owners.delete(owner);
        const running: boolean = WebActivity.owners.size > 0;
        if (WebActivity.running === running) return;
        try {
            if (running) webview.WebviewController.resumeAllTimers();
            else webview.WebviewController.pauseAllTimers();
            WebActivity.running = running;
        } catch (_) { /* Retry when a controller attaches if the engine is not ready yet. */ }
    }
}
