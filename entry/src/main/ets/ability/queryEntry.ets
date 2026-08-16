import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { loadPersistedState } from '../common/storage';

export default class QueryEntryAbility extends UIAbility {
  private targetUrl: string = "";

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 与主 EntryAbility 一致：页面加载前完成旧数据迁移并水合 AppStorage，
    // 避免冷启动直入本 ability 时 storage 以无 context 方式初始化失败
    loadPersistedState(this.context);
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
  onBackground() {
    this.context.terminateSelf();
  }
}