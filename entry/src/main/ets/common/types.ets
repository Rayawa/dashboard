export interface CommentInfo {
    platform?: string;
    user?: string;
    note?: string;
}

export interface appIdOrPkgName {
    app_id?: string;
    pkg_name?: string;
}
export interface SubmitAppBody extends appIdOrPkgName {
    comment?: CommentInfo
}

export function checkAppIdOrPkgName(value: appIdOrPkgName, raise_error: boolean = false): boolean {
    const res = Number(value.app_id != undefined) + Number(value.pkg_name != undefined)
    if (!raise_error) return res == 1;
    if (res == 0) {
        throw new Error("app_id and pkg_name are both undefined");
    }
    if (res > 1) {
        throw new Error("app_id and pkg_name are both defined");
    }
    return true;
}