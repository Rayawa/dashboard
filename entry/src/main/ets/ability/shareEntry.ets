import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window, router } from '@kit.ArkUI';

interface  WantParams {
  shareAppId: string;
  shareUrl: string;
};
const DOMAIN = 0x0000;

export default class shareEntryAbility extends UIAbility {

  private shareWantParams: WantParams = { shareAppId: '', shareUrl: '' };
  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'dashboard', 'onWindowStageCreate');
    this.setGlobalImmersive(windowStage);

    windowStage.loadContent('pages/complex_share', () => {
      hilog.info(DOMAIN, 'dashboard', '基础容器页加载完成');
      router.replaceUrl({
        url: 'pages/complex_share',
        params: this.shareWantParams
      }).then(() => {
        hilog.info(DOMAIN, 'dashboard', '参数已经分享至complex_share');
      })
    })

  }


  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'dashboard', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'dashboard', '%{public}s', 'dashboard Ability onCreate');

    const shareAppId = want.parameters?.shareAppId as string;
    const shareUrl = want.parameters?.shareUrl as string;

    if (shareAppId && shareUrl) {
      this.shareWantParams = { shareAppId, shareUrl } as WantParams;
    }
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
      hilog.error(DOMAIN, 'dashboard', 'Failed to set global immersive mode. Cause: %{public}s',
        JSON.stringify(err));
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