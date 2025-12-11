import type { appIdOrPkgName, CommentInfo, SubmitAppBody } from './types';
import { SUBMIT_PLATFORM } from '../common/constants';
import { SAPIBaseURL, submitURL } from './constants';
import URL from './url';
import { http } from '@kit.NetworkKit';

// 本文件代碼所使用的源站（也就是基礎的 url）
const BASEURL = SAPIBaseURL;

export async function request() {
}

export async function submit_app(
    data: SubmitAppBody
) {
    const final_comment: CommentInfo = {
        user: data.comment?.user,
        note: data.comment?.note,
        platform: SUBMIT_PLATFORM
    }
    const final_data: SubmitAppBody = {
        app_id: data.app_id,
        pkg_name: data.pkg_name,
        comment: final_comment
    }
    console.log("submit data:", JSON.stringify(final_data));
    const path = new URL(submitURL, BASEURL);
    const request = http.createHttp();
    // console.log("path:", path.toString())
    try {
        const response = await request.request(path.toString(), {
            method: http.RequestMethod.POST,
            expectDataType: http.HttpDataType.OBJECT,
            usingCache: false, // 提交可不能用 cache
            header: {
                "Content-Type": "application/json"
            },
            extraData: final_data,
        }
        )
        console.info(`request response code: ${response.responseCode}`);
        if (response.responseCode == 200) {
            console.info(JSON.stringify(response.result));
        }
    } catch (e) {
        console.warn(`error ${e}`)
    } finally {
        request.destroy();
    }
    return null;
}

export async function query_app(
    data: appIdOrPkgName
) {
    return null;
}