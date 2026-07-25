import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    storage: LocalStorage = new LocalStorage();
    private isContinuation: boolean = false;

    onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
        const currentUrl: string = AppStorage.get('pageUrl') || '';
        const currentScroll: number = AppStorage.get('scrollDistance') || 0;

        wantParam['targetUrl'] = currentUrl;
        wantParam['scrollOffset'] = currentScroll;
        return AbilityConstant.OnContinueResult.AGREE;
    }
    private restoreContinuationParams(want: Want, launchParam?: AbilityConstant.LaunchParam): void {
        if (launchParam?.launchReason === AbilityConstant.LaunchReason.CONTINUATION || want.parameters?.['targetUrl']) {
            this.isContinuation = true;
        }
        if (want.parameters?.['targetUrl']) {
            AppStorage.setOrCreate('pageUrl', want.parameters['targetUrl'] as string);
        }
        if (want.parameters?.['scrollOffset']) {
            AppStorage.setOrCreate('restoreScrollOffset', want.parameters['scrollOffset'] as number);
        }
    }
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.restoreContinuationParams(want, launchParam);
    }
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.restoreContinuationParams(want, launchParam);
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        console.info('Ability onWindowStageCreate.');

        windowStage.getMainWindow().then((windowClass) => {
            AppStorage.setOrCreate('winWidth', windowClass.getWindowProperties().windowRect.width);
            AppStorage.setOrCreate('winHeight', windowClass.getWindowProperties().windowRect.height);
            windowClass.on('windowSizeChange', (windowSize) => {
                AppStorage.setOrCreate('winWidth', windowSize.width);
                AppStorage.setOrCreate('winHeight', windowSize.height);
            });
        });
        if (this.isContinuation) {
            this.loadContent(windowStage, "abilityPages/continueWeb");
        } else {
            this.loadContent(windowStage, "pages/Dashboard");
        }
    }
    onWindowStageRestore(windowStage: window.WindowStage): void {
        if (this.isContinuation) {
            this.loadContent(windowStage, "abilityPages/continueWeb");
        } else {
            this.loadContent(windowStage, "pages/Dashboard");
        }
    }
    private loadContent(windowStage: window.WindowStage, path: string) {
        windowStage.loadContent(path, this.storage, (err) => {
            if (err.code) {
                hilog.error(DOMAIN, "EntryAbility", `Failed to load ${path}. Cause: %{public}s`, JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, "EntryAbility", `Succeeded in loading ${path}.`);
        });
    }
}