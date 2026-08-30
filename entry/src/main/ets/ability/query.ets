import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';

export class QueryAbility extends ShareExtensionAbility {
    async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
        try {
            session.loadContent('abilityPages/loading');
        } catch (error) {
            console.warn('[Dashboard][ability/query][WARN]', `查询分享入口加载提示页失败，将继续打开主应用: ${JSON.stringify(error)}`);
        }
        try {
            const data = await systemShare.getSharedData(want);
            const record = data.getRecords()[0];
            const content = record?.content?.toString().trim() || '';
            if (!content) {
                throw new Error('未读取到可查询的应用信息');
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
            console.error('[Dashboard][ability/query][ERROR]', `[query share] ${JSON.stringify(error)}`);
        } finally {
            try {
                session.terminateSelfWithResult({ resultCode: systemShare.ShareAbilityResultCode.CLOSE });
            } catch (error) {
                console.error('[Dashboard][ability/query][ERROR]', `查询分享会话关闭失败: ${JSON.stringify(error)}`);
            }
        }
    }
}
