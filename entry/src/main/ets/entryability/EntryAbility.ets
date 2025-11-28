import { AbilityConstant, ConfigurationConstant, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    try {
      this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    this.setGlobalImmersive(windowStage);
    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
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

      hilog.info(DOMAIN, 'testTag', 'Global immersive mode set successfully');

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set global immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  async setCutoutMode(windowStage: window.WindowStage) {
    try {
      const windowClass = await windowStage.getMainWindow();
      await windowClass.setWindowLayoutFullScreen(true);
      const avoidArea = await windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      hilog.info(DOMAIN, 'testTag', 'Avoid area: %{public}s', JSON.stringify(avoidArea));
      await windowClass.setFullScreen(true);

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set cutout mode. Cause: %{public}s', JSON.stringify(err));
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
      hilog.error(DOMAIN, 'testTag', 'Failed to reset immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
    this.resetImmersiveMode();
  }

  onBackground(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

}