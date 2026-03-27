import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    storage: LocalStorage = new LocalStorage();

    private handleContinuation(want: Want, launchParam: AbilityConstant.LaunchParam) {
        if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
            const continueUrl = want.parameters?.['migratedUrl'] as string;
            const continueIndex = want.parameters?.['migratedIndex'] as number;

            if (continueUrl) {
                this.storage.setOrCreate('migratedUrl', continueUrl);
                this.storage.setOrCreate('migratedIndex', continueIndex ?? 0);
                hilog.info(DOMAIN, "dashboard", "Continuation Data Saved: %{public}s", continueUrl);
            }
            this.context.restoreWindowStage(this.storage);
        }
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        hilog.info(DOMAIN, "dashboard", "Ability onCreate");
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        this.handleContinuation(want, launchParam);
    }

    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.handleContinuation(want, launchParam);
    }

    onWindowStageCreate(windowStage: window.WindowStage): void {
        this.loadMainContent(windowStage, "onWindowStageCreate");
    }

    onWindowStageRestore(windowStage: window.WindowStage): void {
        this.loadMainContent(windowStage, "onWindowStageRestore");
    }

    private loadMainContent(windowStage: window.WindowStage, tag: string) {
        windowStage.loadContent("pages/Dashboard", this.storage, (err) => {
            if (err.code) {
                hilog.error(DOMAIN, "dashboard", `${tag} Failed. Cause: %{public}s`, JSON.stringify(err));
                return;
            }
            hilog.info(DOMAIN, "window", `${tag} Succeeded.`);
        });
    }

    onContinue(wantParam: Record<string, Object>) {
        const currentUrl = AppStorage.get<string>('latestWebUrl');
        const currentIndex = AppStorage.get<number>('latestIndex');

        if (currentUrl) {
            wantParam['migratedUrl'] = currentUrl as Object;
            wantParam['migratedIndex'] = (currentIndex ?? 0) as Object;
            return AbilityConstant.OnContinueResult.AGREE;
        }
        return AbilityConstant.OnContinueResult.REJECT;
    }
}