import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { webview } from '@kit.ArkWeb';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { loadPersistedState } from '../common/storage';
import {
    CONTINUATION_ROUTE_DETAIL,
    CONTINUATION_ROUTE_MAIN,
    CONTINUATION_MIN_VERSION_CODE,
    DEFAULT_WINDOW_HEIGHT,
    DEFAULT_WINDOW_WIDTH,
    LOCAL_STORAGE_KEY_WINDOW_HEIGHT,
    LOCAL_STORAGE_KEY_WINDOW_WIDTH,
    SBaseURL,
} from '../common/constants';
import {
    defaultAppsListState,
    defaultDetailChartsState,
    defaultOverviewState,
    getContinuationState,
    setContinuationState,
    setDetailTarget,
    setMainTab,
    setSearchTarget,
} from '../common/appState';
import type {
    AppsListContinuationState,
    DetailChartsContinuationState,
    OverviewContinuationState,
} from '../common/appState';
import { initializeCache } from '../common/CacheService';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
    storage: LocalStorage = new LocalStorage();
    private isContinuation: boolean = false;
    private startupTask: Promise<void> = Promise.resolve();

    onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
        // `version` is supplied by the distributed framework, but it can be absent for
        // some continuation entry points. An absent value means "unknown", not version 0.
        // Only reject a target when the framework supplied a valid, positive old version.
        const rawTargetVersion = wantParam['version'];
        const targetVersion = Number(rawTargetVersion);
        if (rawTargetVersion !== undefined && targetVersion > 0 &&
            targetVersion < CONTINUATION_MIN_VERSION_CODE) {
            console.warn('[Dashboard][ability/entry][WARN]',
                `目标设备应用版本过低，拒绝接续: ${targetVersion} < ${CONTINUATION_MIN_VERSION_CODE}`);
            return AbilityConstant.OnContinueResult.MISMATCH;
        }
        const current = getContinuationState();

        wantParam['targetUrl'] = current.pageUrl;
        wantParam['scrollOffset'] = current.scrollDistance;
        wantParam['mainTabIndex'] = current.mainTab;
        wantParam['routeName'] = current.routeName;
        wantParam['detailAppId'] = current.detailAppId;
        wantParam['detailPackage'] = current.detailPackageName;
        wantParam['appsViewIndex'] = current.appsViewIndex;
        wantParam['appsListState'] = current.appsListState;
        wantParam['overviewState'] = current.overviewState;
        wantParam['detailChartsState'] = current.detailChartsState;
        return AbilityConstant.OnContinueResult.AGREE;
    }
    private restoreContinuationParams(want: Want, launchParam?: AbilityConstant.LaunchParam): void {
        if (launchParam?.launchReason === AbilityConstant.LaunchReason.CONTINUATION || want.parameters?.['targetUrl']) {
            this.isContinuation = true;
        }
        if (this.isContinuation) {
            const mainTab = want.parameters?.['mainTabIndex'] as number | undefined;
            const routeName = want.parameters?.['routeName'] as string || CONTINUATION_ROUTE_MAIN;
            const detailAppId = want.parameters?.['detailAppId'] as string || '';
            const detailPackageName = want.parameters?.['detailPackage'] as string || '';
            const appsViewIndex = want.parameters?.['appsViewIndex'] as number || 0;
            const appsListState = want.parameters?.['appsListState'] as AppsListContinuationState | undefined;
            const overviewState = want.parameters?.['overviewState'] as OverviewContinuationState | undefined;
            const detailChartsState =
                want.parameters?.['detailChartsState'] as DetailChartsContinuationState | undefined;
            setContinuationState({
                pageUrl: want.parameters?.['targetUrl'] as string || '',
                scrollDistance: want.parameters?.['scrollOffset'] as number || 0,
                mainTab: mainTab ?? 1,
                routeName,
                detailAppId,
                detailPackageName,
                appsViewIndex,
                appsListState: appsListState ?? defaultAppsListState(),
                overviewState: overviewState ?? defaultOverviewState(),
                detailChartsState: detailChartsState ?? defaultDetailChartsState(),
            });
            setMainTab(mainTab ?? 1);
            if (routeName === CONTINUATION_ROUTE_DETAIL && (detailAppId || detailPackageName)) {
                setDetailTarget({
                    appId: detailAppId || undefined,
                    packageName: detailPackageName || undefined,
                });
            }
        }
    }

    private prepareSStation(): void {
        try {
            webview.WebviewController.initializeWebEngine();
            webview.WebviewController.prepareForPageLoad(SBaseURL.toString(), true, 2);
        } catch (error) {
            console.warn('[Dashboard][ability/entry][WARN]', `S站预热失败，将在页面创建时正常加载: ${JSON.stringify(error)}`);
        }
    }

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.prepareSStation();
        this.restoreContinuationParams(want, launchParam);
        if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
            try {
                this.context.restoreWindowStage(this.storage);
            } catch (error) {
                console.warn('[Dashboard][ability/entry][WARN]', `恢复接续窗口栈失败，将使用业务状态恢复: ${JSON.stringify(error)}`);
            }
        }
        this.applyV3LaunchParams(want);
        initializeCache(this.context);
        // UI 绑定前完成持久化设置迁移和运行时状态水合。
        this.startupTask = loadPersistedState(this.context);
    }
    onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        this.restoreContinuationParams(want, launchParam);
        if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
            try {
                this.context.restoreWindowStage(this.storage);
            } catch (error) {
                console.warn('[Dashboard][ability/entry][WARN]', `热启动接续窗口栈恢复失败: ${JSON.stringify(error)}`);
            }
        }
        this.applyV3LaunchParams(want);
    }
    private decodeUriValue(value: string): string {
        try {
            return decodeURIComponent(value);
        } catch (error) {
            console.warn('[Dashboard][ability/entry][WARN]', `忽略无法解码的启动参数: ${JSON.stringify(error)}`);
            return value;
        }
    }
    private applyV3LaunchParams(want: Want): void {
        const incomingUri = want.uri || '';
        const uriAppId = incomingUri.match(/[?&#]app_id=([^&#]+)/);
        const uriPackage = incomingUri.match(/[?&#]pkg=([^&#]+)/);
        const uriDetailAppId = uriAppId && uriAppId[1] ? this.decodeUriValue(uriAppId[1]) : '';
        const uriDetailPackage = uriPackage && uriPackage[1] ? this.decodeUriValue(uriPackage[1]) : '';
        const detailAppId = want.parameters?.['detailAppId'] as string || uriDetailAppId;
        const detailPackage = want.parameters?.['detailPackage'] as string || uriDetailPackage;
        const searchText = want.parameters?.['searchText'] as string || '';
        const searchAutoRun = want.parameters?.['searchAutoRun'] as boolean | undefined;
        const openDetailOnSuccess = want.parameters?.['openDetailOnSuccess'] as boolean | undefined;
        if (detailAppId || detailPackage) {
            setDetailTarget({ appId: detailAppId || undefined, packageName: detailPackage || undefined });
        }
        if (searchText) {
            setSearchTarget({
                rawText: searchText,
                autoRun: searchAutoRun ?? true,
                openDetailOnSuccess: openDetailOnSuccess ?? false,
            });
        }
    }
    onWindowStageCreate(windowStage: window.WindowStage): void {
        console.info('[Dashboard][ability/entry][INFO]', 'Ability onWindowStageCreate.');
        this.startupTask
            .then(() => this.bindWindowStorage(windowStage))
            .then(() => this.loadCurrentPage(windowStage))
            .catch((error: Error) => {
                console.error('[Dashboard][ability/entry][ERROR]', `窗口初始化失败，继续使用默认尺寸: ${error.message}`);
                this.loadCurrentPage(windowStage);
            });
    }
    onWindowStageRestore(windowStage: window.WindowStage): void {
        this.startupTask
            .then(() => this.bindWindowStorage(windowStage))
            .then(() => this.loadCurrentPage(windowStage))
            .catch((error: Error) => {
                console.error('[Dashboard][ability/entry][ERROR]', `窗口恢复失败，继续使用默认尺寸: ${error.message}`);
                this.loadCurrentPage(windowStage);
            });
    }
    private loadCurrentPage(windowStage: window.WindowStage): void {
        this.loadContent(windowStage, 'pages/Dashboard');
    }
    private async bindWindowStorage(windowStage: window.WindowStage): Promise<void> {
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, DEFAULT_WINDOW_WIDTH);
        this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, DEFAULT_WINDOW_HEIGHT);
        try {
            const windowClass = await windowStage.getMainWindow();
            const rect = windowClass.getWindowProperties().windowRect;
            this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, rect.width);
            this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, rect.height);
            windowClass.on('windowSizeChange', (windowSize) => {
                this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_WIDTH, windowSize.width);
                this.storage.setOrCreate(LOCAL_STORAGE_KEY_WINDOW_HEIGHT, windowSize.height);
            });
        } catch (error) {
            console.warn('[Dashboard][ability/entry][WARN]', `无法读取或监听窗口尺寸，使用默认尺寸: ${JSON.stringify(error)}`);
        }
    }
    private loadContent(windowStage: window.WindowStage, path: string): void {
        try {
            windowStage.loadContent(path, this.storage, (err) => {
                if (err.code) {
                    hilog.error(DOMAIN, "EntryAbility", `Failed to load ${path}. Cause: %{public}s`, JSON.stringify(err));
                    return;
                }
                hilog.info(DOMAIN, "EntryAbility", `Succeeded in loading ${path}.`);
            });
        } catch (error) {
            console.error('[Dashboard][ability/entry][ERROR]', `页面 ${path} 加载调用失败: ${JSON.stringify(error)}`);
        }
    }
}
