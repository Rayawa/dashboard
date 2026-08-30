import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { loadPersistedState } from '../common/storage';
import { setShareRequest, ShareRequest } from '../common/appState';
const DOMAIN = 0x0000;

export default class shareEntryAbility extends UIAbility {
    private startupTask: Promise<void> = Promise.resolve();
    onWindowStageCreate(windowStage: window.WindowStage): void {
        hilog.info(DOMAIN, "dashboard", "%{public}s", "dashboard Ability onWindowStageCreate");
        this.startupTask.then(() => {
            this.setGlobalImmersive(windowStage);
            windowStage.loadContent("abilityPages/complexSubmit", (err) => {
                if (err.code) {
                    hilog.error(
                        DOMAIN,
                        "dashboard",
                        "Failed to load the content. Cause: %{public}s",
                        JSON.stringify(err),
                    );
                    return;
                }
                hilog.info(DOMAIN, "window", "Succeeded in loading the content.");
            });
        });
    }

    private shareWantParams: ShareRequest = { sharePackageName: "", shareUrl: "" };

    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 与主 EntryAbility 一致：页面加载前完成旧数据迁移和运行时状态水合。
        this.startupTask = loadPersistedState(this.context);
        try {
            this.context
                .getApplicationContext()
                .setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        } catch (err) {
            console.warn('[Dashboard][ability/submitEntry][WARN]', `颜色模式设置失败，保留系统当前模式: ${JSON.stringify(err)}`);
            hilog.error(
                DOMAIN,
                "dashboard",
                "Failed to set colorMode. Cause: %{public}s",
                JSON.stringify(err),
            );
        }
        hilog.info(DOMAIN, "dashboard", "%{public}s", "dashboard Ability onCreate");

        const sharePackageName = want.parameters?.sharePackageName as string;
        const shareUrl = want.parameters?.shareUrl as string;

        if (shareUrl) {
            this.shareWantParams = { sharePackageName: sharePackageName || '', shareUrl };
            setShareRequest(this.shareWantParams);
        }
    }

    async setGlobalImmersive(windowStage: window.WindowStage) {
        try {
            const windowClass = await windowStage.getMainWindow();
            await windowClass.setWindowLayoutFullScreen(true);
            await windowClass.setWindowSystemBarEnable(["status", "navigation"]);
            await windowClass.setWindowSystemBarProperties({
                statusBarColor: "#00000000",
                navigationBarColor: "#00000000",
                statusBarContentColor: "#FFffffff",
                navigationBarContentColor: "#FFffffff",
            });
            await windowClass.setWindowSystemBarProperties({
                isStatusBarLightIcon: true,
                isNavigationBarLightIcon: true,
            });
        } catch (err) {
            console.warn('[Dashboard][ability/submitEntry][WARN]', `沉浸式系统栏设置不可用，保留系统默认样式: ${JSON.stringify(err)}`);
            hilog.error(
                DOMAIN,
                "dashboard",
                "Failed to set global immersive mode. Cause: %{public}s",
                JSON.stringify(err),
            );
        }
    }

    async setCutoutMode(windowStage: window.WindowStage) {
        try {
            const windowClass = await windowStage.getMainWindow();
            await windowClass.setWindowLayoutFullScreen(true);
            const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
            hilog.info(DOMAIN, "dashboard", "Avoid area: %{public}s", JSON.stringify(avoidArea));
        } catch (err) {
            console.warn('[Dashboard][ability/submitEntry][WARN]', `挖孔区域设置不可用，使用系统默认安全区: ${JSON.stringify(err)}`);
            hilog.error(
                DOMAIN,
                "dashboard",
                "Failed to set cutout mode. Cause: %{public}s",
                JSON.stringify(err),
            );
        }
    }

    async resetImmersiveMode() {
        try {
            const windowClass = await window.getLastWindow(this.context);
            if (windowClass) {
                await windowClass.setWindowSystemBarProperties({
                    statusBarColor: "#00000000",
                    navigationBarColor: "#00000000",
                    statusBarContentColor: "#FFffffff",
                    navigationBarContentColor: "#FFffffff",
                });
            }
        } catch (err) {
            console.warn('[Dashboard][ability/submitEntry][WARN]', `系统栏恢复失败，保留当前窗口样式: ${JSON.stringify(err)}`);
            hilog.error(
                DOMAIN,
                "dashboard",
                "Failed to reset immersive mode. Cause: %{public}s",
                JSON.stringify(err),
            );
        }
    }

    onForeground(): void {
        this.resetImmersiveMode();
    }
    onBackground() {
        this.context.terminateSelf().catch((error: Error) => {
            console.error('[Dashboard][ability/submitEntry][ERROR]', `投稿 Ability 后台退出失败: ${error.message}`);
        });
    }
}
