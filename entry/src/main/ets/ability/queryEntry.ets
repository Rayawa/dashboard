import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { loadPersistedState } from '../common/storage';
import {
  DEFAULT_WINDOW_HEIGHT,
  DEFAULT_WINDOW_WIDTH,
  LOCAL_STORAGE_KEY_WINDOW_HEIGHT,
  LOCAL_STORAGE_KEY_WINDOW_WIDTH,
} from '../common/constants';
import { setQueryTargetUrl } from '../common/appState';

export default class QueryEntryAbility extends UIAbility {
  private targetUrl: string = "";
  private startupTask: Promise<void> = Promise.resolve();
  private storage: LocalStorage = new LocalStorage();

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 与主 EntryAbility 一致：页面加载前完成旧数据迁移和运行时状态水合，
    // 避免冷启动直入本 ability 时 storage 以无 context 方式初始化失败
    this.startupTask = loadPersistedState(this.context);
    this.targetUrl = want.parameters?.targetUrl as string || "";
    if (this.targetUrl) {
      setQueryTargetUrl(this.targetUrl);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    this.startupTask
      .then(() => this.bindWindowStorage(windowStage))
      .then(() => {
        try {
          windowStage.loadContent('abilityPages/queryWeb', this.storage, (err) => {
            if (err.code) {
              console.error('[Dashboard][ability/queryEntry][ERROR]', '查询页加载失败: ' + JSON.stringify(err));
            }
          });
        } catch (error) {
          console.error('[Dashboard][ability/queryEntry][ERROR]', `查询页加载调用失败: ${JSON.stringify(error)}`);
        }
      })
      .catch((error: Error) => {
        console.error('[Dashboard][ability/queryEntry][ERROR]', `查询窗口初始化失败，保留默认尺寸: ${error.message}`);
      });
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
      console.warn('[Dashboard][ability/queryEntry][WARN]', `查询窗口尺寸读取失败，使用默认尺寸: ${JSON.stringify(error)}`);
    }
  }
  onBackground() {
    this.context.terminateSelf().catch((error: Error) => {
      console.error('[Dashboard][ability/queryEntry][ERROR]', `查询 Ability 后台退出失败: ${error.message}`);
    });
  }
}
