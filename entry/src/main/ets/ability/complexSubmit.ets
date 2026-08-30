import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';

/** 填写信息投稿入口：打开统一搜索页并预填分享内容，等待用户确认。 */
export class ShareAbility extends ShareExtensionAbility {
    async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
        try {
            session.loadContent('abilityPages/loading');
        } catch (error) {
            console.warn('[Dashboard][ability/complexSubmit][WARN]', `完整投稿入口加载提示页失败，将继续打开主应用: ${JSON.stringify(error)}`);
        }
        try {
            const data = await systemShare.getSharedData(want);
            const record = data.getRecords()[0];
            const content = record?.content?.toString().trim() || '';
            if (!content) {
                throw new Error('未读取到分享内容');
            }
            await this.context.startAbility({
                bundleName: 'top.rayawa.dashboard',
                abilityName: 'EntryAbility',
                parameters: {
                    searchText: content,
                    searchAutoRun: false,
                    openDetailOnSuccess: false,
                },
            });
        } catch (error) {
            console.error('[Dashboard][ability/complexSubmit][ERROR]', `[complex share] ${JSON.stringify(error)}`);
        } finally {
            try {
                session.terminateSelfWithResult({ resultCode: systemShare.ShareAbilityResultCode.CLOSE });
            } catch (error) {
                console.error('[Dashboard][ability/complexSubmit][ERROR]', `完整投稿分享会话关闭失败: ${JSON.stringify(error)}`);
            }
        }
    }
}
