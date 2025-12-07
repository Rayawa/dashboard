// shenjack
import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { parseInputSplitLinksPkgsAndAppIds, parse_app_id_from_url, submit_app_with_user_data } from '../submits';
import UserStorage from '../common/user';

/**
 * 这个 ability 是用来直接接受并投稿链接的
 * 不需要填东西
 * 所以不要加载任何页面, 直接投稿并关闭 (投后不管)
 */
export class ShareAbility extends ShareExtensionAbility {
    onSessionCreate(want: Want, session: UIExtensionContentSession): void {
        const userStorage = UserStorage.getInstance(this.context);
        systemShare.getSharedData(want)
            .then((data: systemShare.SharedData) => {
                data.getRecords().forEach((record: systemShare.SharedRecord) => {
                    if (record.content == undefined) {
                        console.warn("dashboard share get undefined content!");
                        return;
                    }
                    const content: string = record.content!.toString();
                    const res = parseInputSplitLinksPkgsAndAppIds(content);
                    const pkgs = res.pkgs;
                    const app_ids = res.app_ids;
                    const pkg: string | undefined = pkgs.length != 0 ? pkgs[pkgs.length - 1] : undefined;
                    const app_id: string | undefined = app_ids.length != 0 ? app_ids[app_ids.length - 1] : undefined;
                    console.info(`dashboard_share_parse ${pkg || app_id}`);
                    console.info(`dashboard_share_raw ${content}`);

                    userStorage.getUsername().then((username) => {
                        submit_app_with_user_data({
                            pkg_name: pkg,
                            app_id,
                            comment: {
                                user: username
                            }
                        }).then(() => {
                            console.log(`dashboard_shared ${content}`)
                            session.terminateSelfWithResult({
                                resultCode: systemShare.ShareAbilityResultCode.CLOSE
                            })
                        });
                    })
                });
            })
            .catch((error: BusinessError) => {
                console.error(`Failed to getSharedData. Code: ${error.code}, message: ${error.message}`);
                session.terminateSelf();
            });
    }
}