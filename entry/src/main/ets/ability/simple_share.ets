//shenjack
import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 这个 ability 是用来直接接受并投稿链接的
 * 不需要填东西
 * 所以不要加载任何页面, 直接投稿并关闭 (投后不管)
 */
export class ShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {

    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        data.getRecords().forEach((record: systemShare.SharedRecord) => {
          // 处理分享数据
        });
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