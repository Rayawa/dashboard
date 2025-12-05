import { AbilityConstant, UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import Logger from '../utils/Logger';

let logger = Logger.getLogger('[ShareUIAbility]');

interface Storage {
  ShareUIAbilityWant: Want
}

export default class ShareUIAbility extends UIAbility {
  private storageWant: Want = {};

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      logger.info('被拉起原因：系统分享');
    }
    this.storageWant = want;
  }

  onNewWant(_: Want, launchParam: AbilityConstant.LaunchParam): void {
    logger.info('launchReason: ', String(launchParam.launchReason));
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    try {
      let para: Storage = { ShareUIAbilityWant: this.storageWant };
      let storage = new LocalStorage(para);
      windowStage.loadContent('pages/ShareUIPage', storage);
    } catch (error) {
      logger.error(`onWindowStageCreate error. Code: ${error?.code}, message: ${error?.message}`);
    }
  }
}
