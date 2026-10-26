import { SegmentButtonV2Items } from '@kit.ArkUI';
import { HdsNavigationMenuItemOptions } from '@kit.UIDesignKit';
import { MarketPageFrame } from '../../components/discovery/MarketPageFrame';
import { HdsTitleBarSegment } from '../../components/common/HdsTitleBarSegment';
import { CollectionList } from '../../components/collection/CollectionList';
import { BrowserStatus } from '../../components/discovery/BrowserControls';
import { getLocalCollection, removeCollectedItems } from '../../services/storage/storage';
import { showToastSafely } from '../../ui/feedback/safeUi';
import { DiscoveryInteraction } from '../../ui/interaction/DiscoveryInteraction';
import type { SavedApp, FollowedDeveloper } from '../../models/types';

@Builder
export function CollectionManagementPageBuilder() { CollectionManagementPage() }

@Component
export struct CollectionManagementPage {
    initialIndex: number = 0;
    @State private selectedIndexes: number[] = [0];
    @State private apps: SavedApp[] = [];
    @State private developers: FollowedDeveloper[] = [];
    @State private selectedApps: string[] = [];
    @State private selectedDevelopers: string[] = [];
    @State private loading: boolean = false;
    @State private saving: boolean = false;
    @State private confirming: boolean = false;
    @State private error: string = '';
    @State private interaction: DiscoveryInteraction = new DiscoveryInteraction(this.getUIContext());
    private alive: boolean = false;
    private token: number = 0;
    private items: SegmentButtonV2Items = new SegmentButtonV2Items([
        { text: '应用', accessibilityText: '管理收藏的应用' },
        { text: '开发者', accessibilityText: '管理收藏的开发者' },
    ]);

    aboutToAppear(): void { this.alive = true; this.selectedIndexes = [this.initialIndex === 1 ? 1 : 0]; }
    aboutToDisappear(): void { this.alive = false; this.token++; this.interaction.dispose(); }
    private busy(): boolean { return this.loading || this.saving || this.confirming; }
    private count(): number { return this.selectedApps.length + this.selectedDevelopers.length; }
    private currentIds(): string[] {
        return this.selectedIndexes[0] === 1 ? this.developers.map((item: FollowedDeveloper) => item.developerId) :
            this.apps.map((item: SavedApp) => item.appId);
    }
    private selectedIds(): string[] { return this.selectedIndexes[0] === 1 ? this.selectedDevelopers : this.selectedApps; }
    private select(id: string): void {
        if (this.busy()) return;
        this.interaction.activate('select');
        const selected = this.selectedIds();
        const next = selected.includes(id) ? selected.filter((value: string) => value !== id) : selected.concat(id);
        if (this.selectedIndexes[0] === 1) this.selectedDevelopers = next;
        else this.selectedApps = next;
    }
    private selectAll(): void {
        if (this.busy()) return;
        this.interaction.activate('all');
        const ids = this.currentIds();
        const next: string[] = this.selectedIds().length === ids.length ? [] : ids;
        if (this.selectedIndexes[0] === 1) this.selectedDevelopers = next;
        else this.selectedApps = next;
    }
    private async load(): Promise<void> {
        const token = ++this.token;
        this.loading = true; this.error = '';
        try {
            const saved = await getLocalCollection();
            if (!this.alive || token !== this.token) return;
            this.apps = saved.apps; this.developers = saved.developers;
            this.selectedApps = this.selectedApps.filter((id: string) => this.apps.some((item: SavedApp) => item.appId === id));
            this.selectedDevelopers = this.selectedDevelopers.filter((id: string) =>
                this.developers.some((item: FollowedDeveloper) => item.developerId === id));
        } catch (_) {
            if (this.alive && token === this.token) this.error = '无法读取收藏，请重试';
        } finally { if (this.alive && token === this.token) this.loading = false; }
    }
    private async removeSelected(): Promise<void> {
        if (this.busy() || this.count() === 0) return;
        this.interaction.activate('remove');
        const apps = this.selectedApps.slice();
        const developers = this.selectedDevelopers.slice();
        this.confirming = true;
        try {
            const result = await this.getUIContext().getPromptAction().showDialog({
                title: '取消收藏', message: `确定取消收藏选中的 ${apps.length + developers.length} 项？`,
                buttons: [{ text: '保留', color: $r('app.color.v3_text_primary') },
                    { text: '取消收藏', color: $r('app.color.v3_accent_red') }],
            });
            if (!this.alive || result.index !== 1) return;
            this.saving = true;
            await removeCollectedItems(apps, developers);
            if (!this.alive) return;
            this.selectedApps = []; this.selectedDevelopers = [];
            showToastSafely(this.getUIContext().getPromptAction(), '取消收藏');
            await this.load();
        } catch (_) {
            if (this.alive && this.saving) showToastSafely(this.getUIContext().getPromptAction(), '取消收藏失败，请重试');
        } finally { if (this.alive) { this.confirming = false; this.saving = false; } }
    }
    private menus(): HdsNavigationMenuItemOptions[] {
        return [
            { content: { label: this.currentIds().length > 0 && this.selectedIds().length === this.currentIds().length ?
                '取消全选当前页面' : '全选当前页面', icon: $r('sys.symbol.checkmark_circle'),
                isEnabled: !this.busy() && !this.error && this.currentIds().length > 0,
                action: (): void => this.selectAll() } },
            { content: { label: `取消收藏选中的 ${this.count()} 项`, icon: $r('sys.symbol.trash'),
                isEnabled: !this.busy() && !this.error && this.count() > 0,
                action: (): void => { this.removeSelected(); } } },
        ];
    }
    @Builder
    private content(): void {
        Column({ space: 14 }) {
            HdsTitleBarSegment({ items: this.items, selectedIndexes: $selectedIndexes,
                onItemClicked: (): void => { this.interaction.activate('segment'); } })
                .enabled(!this.busy())
            Text(`已选择 ${this.count()} 项，可跨应用和开发者页面选择后统一取消收藏。`)
                .fontSize(13).fontColor($r('app.color.v3_text_secondary')).width('100%')
            BrowserStatus({ enterSpeed: 2, loading: this.loading || this.saving, error: this.error,
                empty: this.currentIds().length === 0, emptyText: '当前页面没有收藏',
                onRetry: (): void => { this.load(); } })
            CollectionList({ apps: this.apps, developers: this.developers, selectedIndex: this.selectedIndexes[0],
                managing: true, interactive: !this.busy() && !this.error, selectedIds: this.selectedIds(),
                onSelect: (id: string): void => this.select(id) })
        }.width('100%')
    }
    build() {
        MarketPageFrame({ title: '管理收藏', subtitle: `应用 ${this.apps.length} · 开发者 ${this.developers.length}`,
            resetKey: `${this.selectedIndexes[0]}`, busy: this.busy(),
            menuProvider: (_busy: boolean): HdsNavigationMenuItemOptions[] => this.menus(),
            content: (): void => { this.content(); }, onShown: (): void => { this.load(); } })
    }
}
