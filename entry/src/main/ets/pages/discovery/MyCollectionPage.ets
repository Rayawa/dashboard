import { HdsNavigationMenuItemOptions } from '@kit.UIDesignKit';
import { DiscoveryInteraction } from '../../common/DiscoveryInteraction';
import { DiscoveryButtonStyle } from '../../common/DiscoveryTheme';
import { showToastSafely } from '../../common/safeUi';
import { openDiscoveryApp, openAppCollection } from '../../common/discoveryNavigation';
import { MarketPageFrame } from '../../component/discovery/MarketPageFrame';
import { AppSummaryRow } from '../../component/discovery/AppSummaryRow';
import { BrowserStatus } from '../../component/discovery/BrowserControls';
import { getLocalCollection, saveCollectedApp, saveFollowedDeveloper } from '../../common/storage';
import type { SavedApp, FollowedDeveloper } from '../../common/types';

@Builder
export function MyCollectionPageBuilder() { MyCollectionPage() }

@Component
export struct MyCollectionPage {
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    @Consume('pageStack') private pageStack: NavPathStack;
    @State private apps: SavedApp[] = [];
    @State private developers: FollowedDeveloper[] = [];
    @State private loading: boolean = false;
    @State private error: string = '';
    @State private saving: boolean = false;
    private token: number = 0;
    private alive: boolean = false;
    aboutToAppear(): void { this.alive = true; }
    aboutToDisappear(): void { this.interaction.dispose(); this.alive = false; this.token++; }
    private async load(): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = '';
        try {
            const saved = await getLocalCollection();
            if (token !== this.token) return;
            this.apps = saved.apps; this.developers = saved.developers;
        } catch (_) {
            if (token === this.token) this.error = '无法读取收藏，请重试';
        } finally { if (token === this.token) this.loading = false; }
    }
    private async removeApp(app: SavedApp): Promise<void> {
        if (this.saving) return;
        this.saving = true;
        try { await saveCollectedApp(app, false); if (this.alive) await this.load(); }
        catch (_) { showToastSafely(this.getUIContext().getPromptAction(), '移除失败，请重试'); }
        finally { if (this.alive) this.saving = false; }
    }
    private async removeDeveloper(developer: FollowedDeveloper): Promise<void> {
        if (this.saving) return;
        this.saving = true;
        try { await saveFollowedDeveloper(developer, false); if (this.alive) await this.load(); }
        catch (_) { showToastSafely(this.getUIContext().getPromptAction(), '取消关注失败，请重试'); }
        finally { if (this.alive) this.saving = false; }
    }
    @Builder
    private content(): void {
        Column({ space: 12 }) {
            Text('收藏与关注保存在本机。打开应用或开发者时获取最新数据。')
                .fontSize(13).fontColor($r('app.color.v3_text_secondary')).width('100%')
            BrowserStatus({ enterSpeed: 2, loading: this.loading, error: this.error,
                empty: this.apps.length + this.developers.length === 0,
                emptyText: '还没有收藏。在应用详情中收藏应用，或在开发者应用页添加关注。',
                onRetry: (): void => { this.load(); } })
            Text(`收藏应用 · ${this.apps.length}`).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            ForEach(this.apps, (app: SavedApp, index: number) => {
                Column({ space: 6 }) {
                    AppSummaryRow({ enterSpeed: 2, enterOrder: index, appId: app.appId, packageName: app.packageName, name: app.name, iconUrl: app.iconUrl, subtitle: '已收藏 · 点击查看应用详情',
                        onOpen: (): void => {
                            openDiscoveryApp(this.pageStack, { appId: app.appId, packageName: app.packageName });
                        } })
                    Button('取消收藏', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === ('remove-app-' + app.appId)))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('remove-app-' + app.appId, event)).enabled(!this.saving).onClick((): void => { this.interaction.activate('remove-app-' + app.appId); this.removeApp(app); })
                    .accessibilityText(`取消收藏${app.name}`)
                }.width('100%').alignItems(HorizontalAlign.End)
            }, (app: SavedApp) => app.appId)
            Text(`关注开发者 · ${this.developers.length}`).fontSize(18).fontWeight(FontWeight.Bold)
                .fontColor($r('app.color.v3_text_primary')).width('100%')
            ForEach(this.developers, (developer: FollowedDeveloper, index: number) => {
                Column({ space: 6 }) {
                    AppSummaryRow({ enterSpeed: 2, enterOrder: index, showIcon: false, name: developer.developerName, subtitle: '查看开发者当前收录的应用',
                        onOpen: (): void => {
                            openAppCollection(this.pageStack, { title: developer.developerName,
                                developerId: developer.developerId, developerName: developer.developerName });
                        } })
                    Button('取消关注', { stateEffect: false }).attributeModifier(new DiscoveryButtonStyle(this.interaction.pressedKey === ('remove-developer-' + developer.developerId)))
                    .onTouch((event: TouchEvent): void => this.interaction.touch('remove-developer-' + developer.developerId, event)).enabled(!this.saving).onClick((): void => { this.interaction.activate('remove-developer-' + developer.developerId); this.removeDeveloper(developer); })
                    .accessibilityText(`取消关注${developer.developerName}`)
                }.width('100%').alignItems(HorizontalAlign.End)
            }, (developer: FollowedDeveloper) => developer.developerId)
        }.width('100%')
    }
    build() {
        MarketPageFrame({ title: '收藏与关注', busy: this.loading, menuProvider: (_busy: boolean): HdsNavigationMenuItemOptions[] => [{ content: { label: '刷新收藏与关注', icon: $r('sys.symbol.arrow_clockwise'), isEnabled: !this.loading,
                action: (): void => { this.interaction.activate('refresh'); this.load(); } } }], content: (): void => { this.content(); }, onShown: (): void => { this.load(); } })
    }
}
