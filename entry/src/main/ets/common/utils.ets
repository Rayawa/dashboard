import URL from './url';

export interface LinksPkgsAppIds {
    links: string[];
    pkgs: string[];
    app_ids: string[];
}

export class LinksPkgsAppIdsClass implements LinksPkgsAppIds {
    links: string[] = [];
    pkgs: string[] = [];
    app_ids: string[] = [];

    constructor(links: string[] = [], pkgs: string[] = [], app_ids: string[] = []) {
        this.links = links;
        this.pkgs = pkgs;
        this.app_ids = app_ids;
    }

    empty(): boolean {
        return this.links.length === 0 && this.pkgs.length === 0 && this.app_ids.length === 0;
    }
}

/**
 * 解析输入字符串，提取链接、包名和app_id
 *
 * @param inputStr 输入的字符串
 * @returns 包含links, pkgs, app_ids的对象
 */
export function parseInputSplitLinksPkgsAndAppIds(inputStr: string): LinksPkgsAppIds {
    inputStr = inputStr.trim();
    if (!inputStr) {
        return new LinksPkgsAppIdsClass();
    }

    // 支持更多分隔符：空格、换行、逗号、分号、竖线等
    const parts = inputStr.split(/[\s\n,;|]+/);
    const urlLike = /^https?:\/\/[^\s]+$/;

    // 修改正则，将 C+数字 和其他包名分开匹配
    const appIdRegex = /^[Cc]\d+$/; // 匹配 C 开头的数字（app_id）
    const pkgNameRegex = /^[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+$/; // 匹配传统包名

    // 用于从文本中提取的正则（非全局，用于search方法）
    const extractPkgRegex = /[a-zA-Z][a-zA-Z0-9_]*(\.[a-zA-Z0-9_]+)+/;
    const extractAppIdRegex = /[Cc]\d+/;

    const links: string[] = [];
    const pkgs: string[] = [];
    const app_ids: string[] = [];

    for (let i = 0; i < parts.length; i++) {
        const part = parts[i];
        let start = 0;

        // 处理每个part，像Python代码一样扫描
        while (start < part.length) {
            // 匹配 app_id
            const appIdMatch = part.slice(start).match(appIdRegex);
            if (appIdMatch && appIdMatch.index === 0) {
                const matchedAppId = appIdMatch[0];
                app_ids.push(matchedAppId);
                start += matchedAppId.length;
                continue;
            }

            // 匹配 pkg_name
            const pkgNameMatch = part.slice(start).match(pkgNameRegex);
            if (pkgNameMatch && pkgNameMatch.index === 0) {
                const matchedPkg = pkgNameMatch[0];
                pkgs.push(matchedPkg);
                start += matchedPkg.length;
                continue;
            }

            // 匹配 url
            const urlMatch = part.slice(start).match(urlLike);
            if (urlMatch && urlMatch.index === 0) {
                const matchedUrl = urlMatch[0];
                links.push(matchedUrl);

                // 从URL的path部分提取包名和app_id
                try {
                    // 解析URL获取path部分
                    const urlObj = new URL(matchedUrl);
                    const pathname = urlObj.pathname;

                    // 如果pathname以/开头，去掉开头的/
                    let content = matchedUrl.slice(matchedUrl.indexOf(pathname));
                    if (content.startsWith('/')) {
                        content = content.substring(1);
                    }

                    if (content) {
                        // 从path内容中提取包名和app_id
                        let ls = 0;
                        while (ls < content.length) {
                            // 提取包名
                            const pkgExtractMatch = content.slice(ls).match(extractPkgRegex);
                            if (pkgExtractMatch && pkgExtractMatch.index != undefined) {
                                pkgs.push(pkgExtractMatch[0]);
                                ls += pkgExtractMatch.index + pkgExtractMatch[0].length;
                                continue;
                            }

                            // 提取app_id
                            const appIdExtractMatch = content.slice(ls).match(extractAppIdRegex);
                            if (appIdExtractMatch && appIdExtractMatch.index != undefined) {
                                app_ids.push(appIdExtractMatch[0]);
                                ls += appIdExtractMatch.index + appIdExtractMatch[0].length;
                                continue;
                            }
                            ls++;
                        }
                    }
                } catch (e) {
                    // URL解析失败，跳过这个URL的解析
                }

                start += matchedUrl.length;
                continue;
            }

            // 匹配其他包名
            const otherPkgMatch = part.slice(start).match(extractPkgRegex);
            if (otherPkgMatch && otherPkgMatch.index != undefined) {
                pkgs.push(otherPkgMatch[0]);
                start += otherPkgMatch.index + otherPkgMatch[0].length;
                continue;
            }

            // 匹配其他 app_id
            const otherAppIdMatch = part.slice(start).match(extractAppIdRegex);
            if (otherAppIdMatch && otherAppIdMatch.index != undefined) {
                app_ids.push(otherAppIdMatch[0]);
                start += otherAppIdMatch.index + otherAppIdMatch[0].length;
                continue;
            }

            // 如果没有匹配到，则跳过一个字符
            start++;
        }
    }

    // 按顺序的去重，保持输入的顺序
    const finalLinks: string[] = [];
    const finalPkgs: string[] = [];
    const finalAppIds: string[] = [];

    for (let i = 0; i < links.length; i++) {
        const item = links[i];
        if (!finalLinks.includes(item)) {
            finalLinks.push(item);
        }
    }

    for (let i = 0; i < pkgs.length; i++) {
        const item = pkgs[i];
        if (!finalPkgs.includes(item)) {
            finalPkgs.push(item);
        }
    }

    for (let i = 0; i < app_ids.length; i++) {
        const item = app_ids[i];
        if (!finalAppIds.includes(item)) {
            finalAppIds.push(item);
        }
    }

    return new LinksPkgsAppIdsClass(finalLinks, finalPkgs, finalAppIds);
}