// shenjack
import { ShareExtensionAbility, UIExtensionContentSession, Want } from "@kit.AbilityKit";
import { systemShare } from "@kit.ShareKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { getUsername, initialize as initializeUserStorage } from "../common/profile";
import { parseInputSplitLinksPkgsAndAppIds } from "../common/utils";
import { submit_app } from "../common/api";

/**
 * 这个 ability 是用来直接接受并投稿链接的
 * 不需要填东西
 * 所以不要加载任何页面, 直接投稿并关闭 (投后不管)
 */
export class ShareAbility extends ShareExtensionAbility {
    onSessionCreate(want: Want, session: UIExtensionContentSession): void {
        initializeUserStorage(this.context);
        systemShare
            .getSharedData(want)
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
                    const pkg: string | undefined =
                        pkgs.length != 0 ? pkgs[pkgs.length - 1] : undefined;
                    const app_id: string | undefined =
                        app_ids.length != 0 ? app_ids[app_ids.length - 1] : undefined;
                    console.info("content", res.links, res.pkgs, res.app_ids);
                    console.info(`dashboard_share_parse ${pkg || app_id}`);
                    console.info(`dashboard_share_raw ${content}`);

                    getUsername().then((username) => {
                        submit_app({
                            pkg_name: pkg,
                            app_id,
                            comment: {
                                user: username,
                            },
                        }).then(() => {
                            console.log(`dashboard_shared ${content}`);
                            session.terminateSelfWithResult({
                                resultCode: systemShare.ShareAbilityResultCode.CLOSE,
                            });
                        });
                    });
                });
            })
            .catch((error: BusinessError) => {
                console.error(
                    `Failed to getSharedData. Code: ${error.code}, message: ${error.message}`,
                );
                session.terminateSelf();
            });
    }
}
