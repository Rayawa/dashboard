import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

export class ShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {

    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        data.getRecords().forEach((record: systemShare.SharedRecord) => {
          // 处理分享数据
        });
        // session.loadContent('pages/Index');
      })
      .catch((error: BusinessError) => {
        console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
        session.terminateSelf();
      });
    session.terminateSelfWithResult({
      resultCode: systemShare.ShareAbilityResultCode.CLOSE
    })
  }
}