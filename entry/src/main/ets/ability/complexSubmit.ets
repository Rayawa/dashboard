import { ShareExtensionAbility, UIExtensionContentSession, Want } from "@kit.AbilityKit";
import { systemShare } from "@kit.ShareKit";
import { BusinessError } from "@kit.BasicServicesKit";
import { initialize as initializeUserStorage } from "../common/storage";
import { parseInputSplitLinksPkgsAndAppIds } from "../common/utils";

export class ShareAbility extends ShareExtensionAbility {
    onSessionCreate(want: Want, session: UIExtensionContentSession): void {
        console.info("session created!");
        initializeUserStorage(this.context);

        systemShare
            .getSharedData(want)
            .then((data: systemShare.SharedData) => {
                const contents: string[] = [];
                let parsedPackageName: string = "";
                let rawContent: string = "";

                data.getRecords().forEach((record: systemShare.SharedRecord) => {
                    if (record.content == undefined) {
                        console.warn("dashboard share get undefined content!");
                        return;
                    }
                    const content: string = record.content!.toString();
                    const res = parseInputSplitLinksPkgsAndAppIds(content);
                    const link = res.links.length != 0 ? [res.links.length - 1] : undefined;
                    if (link == undefined) {
                        console.warn(`dashboard share get unparseable url ${content}`);
                        return;
                    }
                    const app_query = link!.toString();
                    console.info(`dashboard_share_parse ${app_query}`);
                    console.info(`dashboard_share_raw ${content}`);

                    contents.push(app_query);
                    parsedPackageName = app_query;
                    rawContent = content;
                });

                if (contents.length > 0) {
                    const wantForPage: Want = {
                        bundleName: "top.rayawa.dashboard",
                        abilityName: "submitEntryAbility",
                        parameters: {
                            sharePackageName: parsedPackageName,
                            shareUrl: rawContent,
                        },
                    };

                    this.context
                        .startAbility(wantForPage)
                        .then(() => {
                            console.info("启动目标页面成功");
                        })
                        .catch((startError: BusinessError) => {
                            console.error(
                                `启动页面失败: Code: ${startError.code}, message: ${startError.message}`,
                            );
                        });
                }
            })
            .catch((error: BusinessError) => {
                console.error(`获取分享数据失败: Code: ${error.code}, message: ${error.message}`);
            });

        setTimeout(() => {
            session.terminateSelfWithResult({
                resultCode: systemShare.ShareAbilityResultCode.CLOSE,
            });
        }, 300);
    }
}
