import { PromptAction } from '@kit.ArkUI';

/**
 * PromptAction 在窗口已销毁、切换到后台或 UIContext 不可用时可能抛出异常。
 * 所有非关键 Toast 统一通过此入口显示；失败时保留可检索日志，不中断业务流程。
 */
export function showToastSafely(
    prompt: PromptAction,
    message: string,
    duration: number = 2000,
    scope: string = 'UI',
): void {
    try {
        prompt.showToast({ message, duration });
    } catch (error) {
        console.error('[Dashboard][common/safeUi][ERROR]', `[safeUi][${scope}] Toast 显示失败: ${JSON.stringify(error)}`);
    }
}
