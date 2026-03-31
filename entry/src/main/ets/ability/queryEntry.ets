import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';

export default class QueryEntryAbility extends UIAbility {
  private targetUrl: string = "";

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    this.targetUrl = want.parameters?.targetUrl as string || "";
    if (this.targetUrl) {
      AppStorage.setOrCreate('queryUrlFromAbility', this.targetUrl);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('abilityPages/queryWeb', (err) => {
      if (err.code) {
        console.error('Failed to load content. Cause: ' + JSON.stringify(err));
      }
    });
  }
}