//shenjack
import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { parse_app_id_from_url } from '../submits';

/**
 * 这个 ability 是用来接受分享信息, 然后填信息
 * 所以得开一个填信息用的 page
 */
export class ShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {

    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        data.getRecords().forEach((record: systemShare.SharedRecord) => {
          if (record.content == undefined) {
            console.warn("dashboard share get undefined content!");
            return;
          }
          const content: string = record.content!.toString();
          const pared_url = parse_app_id_from_url(content);
          if (pared_url == null) {
            console.warn(`dashboard share get unparseable url ${content}`);
            return;
          }
          const app_query = pared_url!.toString();
          console.info(`dashboard_share_parse ${app_query}`);
          console.info(`dashboard_share_raw ${content}`);
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