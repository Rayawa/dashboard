import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';

/**
 * 直接投稿入口统一交给主应用搜索页：
 * 新应用执行 simple 投稿，已有应用执行 query 并后台更新。
 */
export class ShareAbility extends ShareExtensionAbility {
    async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
        try {
            session.loadContent('abilityPages/loading');
        } catch (error) {
            console.warn('[Dashboard][ability/simpleSubmit][WARN]', `简单投稿入口加载提示页失败，将继续打开主应用: ${JSON.stringify(error)}`);
        }
        try {
            const data = await systemShare.getSharedData(want);
            const record = data.getRecords()[0];
            const content = record?.content?.toString().trim() || '';
            if (!content) {
                throw new Error('未读取到可投稿的应用信息');
            }
            await this.context.startAbility({
                bundleName: 'top.rayawa.dashboard',
                abilityName: 'EntryAbility',
                parameters: {
                    searchText: content,
                    searchAutoRun: true,
                    openDetailOnSuccess: true,
                },
            });
        } catch (error) {
            console.error('[Dashboard][ability/simpleSubmit][ERROR]', `[simple share] ${JSON.stringify(error)}`);
        } finally {
            try {
                session.terminateSelfWithResult({ resultCode: systemShare.ShareAbilityResultCode.CLOSE });
            } catch (error) {
                console.error('[Dashboard][ability/simpleSubmit][ERROR]', `简单投稿分享会话关闭失败: ${JSON.stringify(error)}`);
            }
        }
    }
}
