import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class QueryEntryAbility extends UIAbility {
  private targetUrl: string = "";

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 1. 接收从 Extension 传来的 URL
    this.targetUrl = want.parameters?.targetUrl as string || "";
    // 2. 立即存入全局存储，确保页面加载时能直接读到
    if (this.targetUrl) {
      AppStorage.setOrCreate('queryUrlFromAbility', this.targetUrl);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // 3. 直接加载页面，不需要再用 router.replaceUrl
    windowStage.loadContent('pages/queryWeb', (err) => {
      if (err.code) {
        console.error('Failed to load content. Cause: ' + JSON.stringify(err));
      }
    });
  }
}