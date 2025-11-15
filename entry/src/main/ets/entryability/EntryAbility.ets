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
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    // 设置全局沉浸式效果
    this.setGlobalImmersive(windowStage);

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  // 设置全局沉浸式效果
  async setGlobalImmersive(windowStage: window.WindowStage) {
    try {
      // 获取窗口对象
      const windowClass = await windowStage.getMainWindow();

      // 设置窗口全屏布局
      await windowClass.setWindowLayoutFullScreen(true);

      // 设置系统栏可见性（状态栏和导航栏）
      await windowClass.setWindowSystemBarEnable(['status', 'navigation']);

      // 设置系统栏属性 - 完全透明
      await windowClass.setWindowSystemBarProperties({
        statusBarColor: '#00000000', // 完全透明
        navigationBarColor: '#00000000', // 完全透明
        statusBarContentColor: '#FFffffff', // 状态栏图标和文字颜色（白色）
        navigationBarContentColor: '#FFffffff' // 导航栏图标颜色（白色）
      });

      // 设置窗口背景色延伸至系统栏下方
      await windowClass.setWindowSystemBarProperties({
        isStatusBarLightIcon: true, // 状态栏浅色图标
        isNavigationBarLightIcon: true // 导航栏浅色图标
      });

      hilog.info(DOMAIN, 'testTag', 'Global immersive mode set successfully');

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set global immersive mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  // 处理摄像头挖孔区域的安全区域
  async setCutoutMode(windowStage: window.WindowStage) {
    try {
      const windowClass = await windowStage.getMainWindow();

      // 设置布局延伸到摄像头挖孔区域
      await windowClass.setWindowLayoutFullScreen(true);

      // 获取安全区域信息
      const avoidArea = await windowClass.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      hilog.info(DOMAIN, 'testTag', 'Avoid area: %{public}s', JSON.stringify(avoidArea));

      // 设置内容延伸到挖孔区域，但通过padding避免内容被遮挡
      await windowClass.setFullScreen(true);

    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set cutout mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground - 重新应用沉浸式效果
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');

    // 应用回到前台时重新设置沉浸式
    this.resetImmersiveMode();
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }

  // 重置沉浸式模式
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
}