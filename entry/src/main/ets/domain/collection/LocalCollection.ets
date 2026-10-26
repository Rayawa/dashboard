import type { LocalCollection } from '../../models/types';

/** 独立校验两组本地记录；单个损坏条目不会导致另一组收藏丢失。 */
export function parseLocalCollection(raw: string): LocalCollection {
    const result: LocalCollection = { apps: [], developers: [] };
    try {
        const parsed = JSON.parse(raw) as LocalCollection;
        if (!parsed || typeof parsed !== 'object') return result;
        const appIds: Set<string> = new Set<string>();
        if (Array.isArray(parsed.apps)) {
            for (const app of parsed.apps) {
                if (!app || typeof app !== 'object' || typeof app.appId !== 'string' || !app.appId.trim()) continue;
                if (appIds.has(app.appId)) continue;
                appIds.add(app.appId);
                result.apps.push({ appId: app.appId,
                    packageName: typeof app.packageName === 'string' ? app.packageName : '',
                    name: typeof app.name === 'string' && app.name ? app.name : app.appId,
                    iconUrl: typeof app.iconUrl === 'string' ? app.iconUrl : '',
                });
            }
        }
        const developerIds: Set<string> = new Set<string>();
        if (Array.isArray(parsed.developers)) {
            for (const developer of parsed.developers) {
                if (!developer || typeof developer !== 'object' || typeof developer.developerId !== 'string' ||
                    !developer.developerId.trim()) continue;
                if (developerIds.has(developer.developerId)) continue;
                developerIds.add(developer.developerId);
                result.developers.push({ developerId: developer.developerId,
                    developerName: typeof developer.developerName === 'string' && developer.developerName ?
                        developer.developerName : developer.developerId });
            }
        }
    } catch (_) { /* 损坏的整个文档视为空集合。 */ }
    return result;
}
