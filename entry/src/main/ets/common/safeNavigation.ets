export function pushPathSafely(
    stack: NavPathStack,
    name: string,
    param: Object = {},
    scope: string = 'Navigation',
): boolean {
    try {
        stack.pushPathByName(name, param);
        return true;
    } catch (error) {
        console.error(`[Dashboard][${scope}][ERROR]`, `打开路由 ${name} 失败: ${JSON.stringify(error)}`);
        return false;
    }
}

export function popPathSafely(stack: NavPathStack, scope: string = 'Navigation'): boolean {
    try {
        stack.pop();
        return true;
    } catch (error) {
        console.error(`[Dashboard][${scope}][ERROR]`, `返回上一页失败: ${JSON.stringify(error)}`);
        return false;
    }
}

export function getPathParamsSafely<T>(
    stack: NavPathStack,
    name: string,
    scope: string = 'Navigation',
): T[] {
    try {
        return stack.getParamByName(name) as T[];
    } catch (error) {
        console.error(`[Dashboard][${scope}][ERROR]`, `读取路由 ${name} 参数失败: ${JSON.stringify(error)}`);
        return [];
    }
}
