import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { parse_app_id_from_url } from '../submits';

export class ShareAbility extends ShareExtensionAbility {
  onSessionCreate(want: Want, session: UIExtensionContentSession): void {
    console.info("session created!")
    systemShare.getSharedData(want)
      .then((data: systemShare.SharedData) => {
        const contents: string[] = [];
        let parsedAppId: string = ''
        let rawContent: string = '';

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

          contents.push(app_query);
          parsedAppId = app_query
          rawContent = content;
        });

        if (contents.length > 0) {
          const wantForPage: Want = {
            bundleName: 'top.rayawa.dashboard',
            abilityName: 'shareEntry',
            parameters: {
              shareAppId: parsedAppId,
              shareUrl: rawContent,
            }
          };

          this.context.startAbility(wantForPage).then(() => {
            console.info('启动目标页面成功');
          }).catch((startError: BusinessError) => {
            console.error(`启动页面失败: Code: ${startError.code}, message: ${startError.message}`);
          });
        }
      })
      .catch((error: BusinessError) => {
        console.error(`获取分享数据失败: Code: ${error.code}, message: ${error.message}`);
      });

    setTimeout(() => {
      session.terminateSelfWithResult({
        resultCode: systemShare.ShareAbilityResultCode.CLOSE
      });
    }, 300);
  }
}