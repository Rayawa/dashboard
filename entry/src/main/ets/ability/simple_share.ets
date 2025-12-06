// shenjack
import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { parse_app_id_from_url, SubmitBody, submit_app_with_user_data } from '../submits';

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
          console.info(`dashboard_parse ${app_query}`);
          console.info(`dashboard_get_share ${content}`);

          const submit_body = new SubmitBody(null, app_query, null);
          submit_app_with_user_data(submit_body);
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