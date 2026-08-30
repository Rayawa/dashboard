import { ShareExtensionAbility, UIExtensionContentSession, Want } from '@kit.AbilityKit';
import { systemShare } from '@kit.ShareKit';
import { APP_BUNDLE_NAME } from '../common/constants';

/**
 * 唯一的系统分享入口。分享内容统一交给搜索页处理：
 * 新应用执行 simple 投稿，已有应用执行 query 更新，随后进入公用详情页。
 */
export class ShareAbility extends ShareExtensionAbility {
    async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
        try {
            session.loadContent('abilityPages/loading');
        } catch (error) {
            console.warn('[Dashboard][ability/shareAbility][WARN]', `分享提示页加载失败: ${JSON.stringify(error)}`);
        }
        try {
            const sharedData = await systemShare.getSharedData(want);
            const record = sharedData.getRecords()[0];
            const content = record?.content?.toString().trim() || '';
            if (!content) {
                throw new Error('未读取到可处理的应用信息');
            }
            await this.context.startAbility({
                bundleName: APP_BUNDLE_NAME,
                abilityName: 'EntryAbility',
                parameters: {
                    searchText: content,
                    searchAutoRun: true,
                    openDetailOnSuccess: true,
                },
            });
        } catch (error) {
            console.error('[Dashboard][ability/shareAbility][ERROR]', `统一分享入口处理失败: ${JSON.stringify(error)}`);
        } finally {
            try {
                session.terminateSelfWithResult({ resultCode: systemShare.ShareAbilityResultCode.CLOSE });
            } catch (error) {
                console.error('[Dashboard][ability/shareAbility][ERROR]', `分享会话关闭失败: ${JSON.stringify(error)}`);
            }
        }
    }
}
