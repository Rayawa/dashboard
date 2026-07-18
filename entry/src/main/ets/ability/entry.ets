import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
const DOMAIN = 0x0000;
export default class EntryAbility extends UIAbility {
    storage: LocalStorage = new LocalStorage();
    private isContinuation: boolean = false;
    onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
        const url = AppStorage.get<string>('pageUrl');
        const distance = AppStorage.get<number>('scrollDistance');
        wantParam.pageUrl = url ?? '';
        wantParam.scrollDistance = distance ?? 0;
        return AbilityConstant.OnContinueResult.AGREE;
    }
    private handleContinuation(want: Want, launchParam: AbilityConstant.LaunchParam) {
        if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
            this.isContinuation = true;
            const continueUrl = want.parameters?.['pageUrl'] as string;
            const scrollDistance = want.parameters?.['scrollDistance'] as number;
            if (continueUrl) {
                this.storage.setOrCreate('pageUrl', continueUrl);
                this.storage.setOrCreate('scrollDistance', scrollDistance ?? 0);
            }
        }
    }
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.handleContinuation(want, launchParam);
    }
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.handleContinuation(want, launchParam);
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
        windowStage.loadContent('pages/Index', (err) => {
            if (err.code) {
                console.error('Failed to load the content. Cause: ' + JSON.stringify(err));
                return;
            }
            console.info('Succeeded in loading the content.');
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