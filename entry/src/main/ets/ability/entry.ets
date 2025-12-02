import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { uri } from '@kit.ArkTS';
import { url } from '@kit.ArkTS';
const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  //
  // private parseDeepLinkUrl(want: Want): string {
  //   if (!want || !want.uri) { return ''; }
  //   try {
  //     const urlObj: uri.URI = new uri.URI(want.uri);
  //     const queryString: string | undefined = urlObj.query;
  //     if (!queryString) { return '';}
  //     const params: url.URLParams = new url.URLParams(queryString);
  //     const targetUrl: string | null = params.get('url');
  //
  //     return targetUrl ? decodeURIComponent(targetUrl) : '';
  //   } catch (err) {
  //     const error = err as BusinessError;
  //     hilog.error(DOMAIN, 'dashboard', 'Failed to parse deep link URL: %{public}s', JSON.stringify(error));
  //     return '';
  //   }
  // }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'dashboard', '%{public}s', 'dashboard Ability onWindowStageCreate');
    this.setGlobalImmersive(windowStage);
    // const targetUrl = this.parseDeepLinkUrl(this.launchWant!);
    // const pageParams: Record<string, string> = {};
    // if (targetUrl && targetUrl.length > 0) {
    //   pageParams.url = targetUrl;
    // }
    windowStage.loadContent('pages/WebView', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'dashboard', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'window', 'Succeeded in loading the content.');
      // try {
      //   const mainWindow = windowStage.getMainWindowSync();
      //   const uiContext = mainWindow.getUIContext();
      //   if (pageParams.url) {
      //     uiContext.getRouter().pushUrl({ url: 'pages/WebView', params: pageParams }).catch((error: BusinessError) => {
      //       hilog.error(DOMAIN, 'dashboard', 'Router pushUrl failed: %{public}s', JSON.stringify(error));
      //     });
      //   }
      // } catch (err) {
      //   const error = err as BusinessError;
      //   hilog.error(DOMAIN, 'dashboard', 'Failed to push WebView: %{public}s', JSON.stringify(error));
      // }
    });
  }

  // onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
  //   const targetUrl = this.parseDeepLinkUrl(want);
  //   if (targetUrl && targetUrl.length > 0) {
  //     try {
  //       window.getLastWindow(this.context).then((mainWindow) => {
  //         if (mainWindow) {
  //           const uiContext = mainWindow.getUIContext();
  //           uiContext.getRouter().pushUrl({ url: 'pages/WebView', params: { url: targetUrl } }).catch((error: BusinessError) => {
  //             hilog.error(DOMAIN, 'dashboard', 'Router pushUrl failed on new Want: %{public}s', JSON.stringify(error));
  //           });
  //         }
  //       }).catch((error: BusinessError) => {
  //         hilog.error(DOMAIN, 'dashboard', 'Failed to get last window: %{public}s', JSON.stringify(error));
  //       });
  //     } catch (err) {
  //       const error = err as BusinessError;
  //       hilog.error(DOMAIN, 'dashboard', 'Failed to handle new want: %{public}s', JSON.stringify(error));
  //     }
  //   }
  // }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'dashboard', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'dashboard', '%{public}s', 'dashboard Ability onCreate');
  }

  async setGlobalImmersive(windowStage: window.WindowStage) {
    try {
      const windowClass = await windowStage.getMainWindow();
      await windowClass.setWindowLayoutFullScreen(true);
      await windowClass.setWindowSystemBarEnable(['status', 'navigation']);
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000',
        navigationBarColor: '#00000000',
        statusBarContentColor: '#FFffffff',
        navigationBarContentColor: '#FFffffff'
      });
      await windowClass.setWindowSystemBarProperties({
        isStatusBarLightIcon: true,
        isNavigationBarLightIcon: true
      });
    } catch (err) {
      hilog.error(DOMAIN, 'dashboard', 'Failed to set global immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  async setCutoutMode(windowStage: window.WindowStage) {
    try {
      const windowClass = await windowStage.getMainWindow();
      await windowClass.setWindowLayoutFullScreen(true);
      const avoidArea = windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      hilog.info(DOMAIN, 'dashboard', 'Avoid area: %{public}s', JSON.stringify(avoidArea));
      await windowClass.setFullScreen(true);
    } catch (err) {
      hilog.error(DOMAIN, 'dashboard', 'Failed to set cutout mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  async resetImmersiveMode() {
    try {
      const windowClass = await window.getLastWindow(this.context);
      if (windowClass) {
        await windowClass.setWindowSystemBarProperties({
          statusBarColor: '#00000000',
          navigationBarColor: '#00000000',
          statusBarContentColor: '#FFffffff',
          navigationBarContentColor: '#FFffffff'
        });
      }
    } catch (err) {
      hilog.error(DOMAIN, 'dashboard', 'Failed to reset immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onForeground(): void {
    this.resetImmersiveMode();
  }
}