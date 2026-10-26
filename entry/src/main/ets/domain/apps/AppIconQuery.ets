/** 榜单接口没有图标字段时，直接请求图标内容，避免为图标加载整个应用详情。 */
export function appIconPath(appId: string = '', packageName: string = ''): string {
    const id = appId.trim();
    if (id) return `apps/icon/content?app_id=${encodeURIComponent(id)}`;
    const pkg = packageName.trim();
    return pkg ? `apps/icon/content?pkg_name=${encodeURIComponent(pkg)}` : '';
}
