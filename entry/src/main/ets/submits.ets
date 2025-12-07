//shenjack
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';
import { SUBMIT_PLATFORM, SUBMIT_USERNAME } from './global_data';
import { AppStorageV2 } from '@kit.ArkUI';
import UserStorage from './common/user';

export class SubmitResult {
    public success: boolean = true;
    public is_new_app: boolean = false;
    public is_new_info: boolean = false;
    public is_new_metric: boolean = false;

    constructor(success: boolean) {
        this.success = success;
    }

    static new_success(): SubmitResult {
        return new SubmitResult(true);
    }

    static new_failed(): SubmitResult {
        return new SubmitResult(false);
    }
}

export interface SubmitCommentInfo {
    user?: string;
    note?: string;
}

interface SubmitCommentInfoWithPlatform extends SubmitCommentInfo {
    platform: string;
}

export interface AppSubmitBody {
    app_id?: string;
    pkg_name?: string;
    comment?: SubmitCommentInfo
}

interface AppSubmitBodyWithCommentInfoPlatform extends AppSubmitBody {
    comment?: SubmitCommentInfoWithPlatform
}

export function parse_app_id_from_url(url: string): string | null {
    const parts = url.split(/[\s\n,;|]+/);
    const urlLike = /^https?:\/\/[^\s]+$/;

    // 修改正则，将 C+数字 和其他包名分开匹配
    const appIdRegex = /^[Cc]\d+$/; // 匹配 C 开头的数字（app_id）
    const pkgNameRegex = /^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$/; // 匹配传统包名

    // 用于从文本中提取的正则
    const extractPkgRegex = /([a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+)/g;
    const extractAppIdRegex = /[Cc]\d+/g;

    for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        if (!part) {
            continue;
        }

        // 1. 如果这个片段本身就是合法的 C 开头 ID 或包名，直接返回
        if (appIdRegex.test(part)) {
            return part;
        }
        // 注意：pkgNameRegex 也会匹配 "appgallery.huawei.com"，所以如果它长得像 URL，我们先不急着返回，交给后面提取逻辑处理
        if (pkgNameRegex.test(part) && !urlLike.test(part)) {
            return part;
        }

        // 2. 尝试从字符串（可能是 URL，也可能是杂乱文本）中提取 C 开头的 AppID
        // 华为 AppID (Cxxxx) 特征明显，误判率低，优先提取
        const cIdMatches = part.match(extractAppIdRegex);
        if (cIdMatches && cIdMatches.length > 0) {
            return cIdMatches[0];
        }

        // 3. 尝试提取包名格式
        const pkgMatches = part.match(extractPkgRegex);
        if (pkgMatches && pkgMatches.length > 0) {
            if (urlLike.test(part)) {
                // 【关键逻辑】如果是一个 URL：
                // extractPkgRegex 会同时匹配到 "appgallery.huawei.com" (域名) 和 "yylx.danmaku.bili" (参数)
                // 通常域名在 URL 头部，而目标 ID 在 URL 尾部或参数部分
                // 因此取匹配数组的【最后一项】作为结果
                return pkgMatches[pkgMatches.length - 1];
            } else {
                // 如果不是 URL（是一段普通文本），则返回第一个匹配到的包名
                return pkgMatches[0];
            }
        }
    }

    return null;
}

export async function submit_app_with_user_data(data: AppSubmitBody): Promise<SubmitResult | null> {
    let request = http.createHttp();
    // let data: JSON; // TODO: 解析结果
    try {
        const final_comment: SubmitCommentInfoWithPlatform = {
            platform: SUBMIT_PLATFORM,
            user: data.comment?.user,
            note: data.comment?.note
        };
        const final_data: AppSubmitBodyWithCommentInfoPlatform = {
            app_id: data.app_id,
            pkg_name: data.pkg_name,
            comment: final_comment
        }
        //   const note = user_data.note == null ? "" : `,"note": "${user_data.note}"`;
        //   // const username = "没招了的shenjack"
        //   const username = SUBMIT_USERNAME();
        //   const fmt_json = `{"pkg_name": "${user_data.app_query}",
        // "comment": {
        //   "platform": "${SUBMIT_PLATFORM}",
        //   "user": "${username}"
        //   ${note}
        // }}`;

        console.log(`submitting ${final_comment.user}`);
        const response = await request.request("http://shenjack.top:10003/api/v0/submit", {
            method: http.RequestMethod.POST,
            expectDataType: http.HttpDataType.OBJECT,
            usingCache: false, // 提交可不能用 cache
            // header: {
            //     "Content-Type": "application/json"
            // },
            extraData: final_data
        }
        )
        console.info(`request response code: ${response.responseCode}`);
        // if (response.responseCode == 200) {
        //   console.info(JSON.stringify(response.result));
        // }
    } catch (e) {
        console.warn(`error ${e}`)
    } finally {
        request.destroy();
    }
    console.info("?????")
    return null;
}
