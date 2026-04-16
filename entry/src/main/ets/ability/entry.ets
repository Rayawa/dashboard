import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
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
        if (this.isContinuation) {
            this.loadContent(windowStage, "abilityPages/continueWeb");
        } else {
            this.loadContent(windowStage, "pages/Dashboard");
        }
    }

    onWindowStageRestore(windowStage: window.WindowStage): void {
        this.loadContent(windowStage, "abilityPages/continueWeb");
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