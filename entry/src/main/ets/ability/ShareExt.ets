import { AbilityConstant, ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { Logger } from '../utils/Logger';


interface IStorage {
  ShareExtAbilityWant: Want,
  ShareExtAbilitySession: UIExtensionContentSession
}

export default class ShareExtAbility extends ShareExtensionAbility {
  onCreate(launchParam: AbilityConstant.LaunchParam): void {
    if (launchParam.launchReasonMessage === 'ReasonMessage_SystemShare') {
      // 识别为被系统分享拉起
      Logger.info('被拉起原因：系统分享');
    }
  }

  onSessionCreate(want: Want, session: UIExtensionContentSession) {
    let para: IStorage = { ShareExtAbilityWant: want, ShareExtAbilitySession: session };
    let storage = new LocalStorage(para);
    try {
      session.loadContent('pages/ShareExtDialog', storage);
    } catch (error) {
      Logger.error(`loadContent error. Code: ${error?.code}, message: ${error?.message}`);
    }
  }
}
