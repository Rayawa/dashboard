import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { loadPersistedState } from '../common/storage';
import {
    DEFAULT_WINDOW_HEIGHT,
    DEFAULT_WINDOW_WIDTH,
    LOCAL_STORAGE_KEY_WINDOW_HEIGHT,
    LOCAL_STORAGE_KEY_WINDOW_WIDTH,
} from '../common/constants';
import { getContinuationState, setContinuationState } from '../common/appState';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    storage: LocalStorage = new LocalStorage();
    private isContinuation: boolean = false;
    private startupTask: Promise<void> = Promise.resolve();

    onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
        const current = getContinuationState();

        wantParam['targetUrl'] = current.pageUrl;
        wantParam['scrollOffset'] = current.scrollDistance;
        return AbilityConstant.OnContinueResult.AGREE;
    }
    private restoreContinuationParams(want: Want, launchParam?: AbilityConstant.LaunchParam): void {
        if (launchParam?.launchReason === AbilityConstant.LaunchReason.CONTINUATION || want.parameters?.['targetUrl']) {
            this.isContinuation = true;
        }
        if (want.parameters?.['targetUrl'] || want.parameters?.['scrollOffset'] !== undefined) {
            setContinuationState({
                pageUrl: want.parameters?.['targetUrl'] as string || '',
                scrollDistance: want.parameters?.['scrollOffset'] as number || 0,
            });
        }
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.restoreContinuationParams(want, launchParam);
        // UI 绑定前完成持久化设置迁移和运行时状态水合。
        this.startupTask = loadPersistedState(this.context);
    }
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.restoreContinuationParams(want, launchParam);
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        console.info('Ability onWindowStageCreate.');
        this.startupTask
            .then(() => this.bindWindowStorage(windowStage))
            .then(() => this.loadCurrentPage(windowStage));
    }
    onWindowStageRestore(windowStage: window.WindowStage): void {
        this.startupTask
            .then(() => this.bindWindowStorage(windowStage))
            .then(() => this.loadCurrentPage(windowStage));
    }
    private loadCurrentPage(windowStage: window.WindowStage): void {
        this.loadContent(windowStage, this.isContinuation ? 'abilityPages/continueWeb' : 'pages/Dashboard');
    }
    private async bindWindowStorage(windowStage: window.WindowStage): Promise<void> {
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, DEFAULT_WINDOW_WIDTH);
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, DEFAULT_WINDOW_HEIGHT);
        const windowClass = await windowStage.getMainWindow();
        const rect = windowClass.getWindowProperties().windowRect;
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, rect.width);
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, rect.height);
        windowClass.on('windowSizeChange', (windowSize) => {
            this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, windowSize.width);
            this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, windowSize.height);
        });
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
