import { AppSummaryRow } from '../discovery/AppSummaryRow';
import { openDiscoveryApp, openAppCollection } from '../../ui/navigation/discoveryNavigation';
import type { SavedApp, FollowedDeveloper } from '../../models/types';

/** 浏览与管理共用收藏条目；选择状态由管理页持有。 */
@Component
export struct CollectionList {
    @Consume('pageStack') private pageStack: NavPathStack;
    @Prop apps: SavedApp[] = [];
    @Prop developers: FollowedDeveloper[] = [];
    @Prop selectedIndex: number = 0;
    @Prop managing: boolean = false;
    @Prop interactive: boolean = true;
    @Prop selectedIds: string[] = [];
    onSelect: (id: string) => void = (): void => {};

    @Builder
    private selection(id: string, name: string): void {
        Checkbox()
            .select(this.selectedIds.includes(id)).enabled(this.interactive)
            .selectedColor($r('app.color.diff_content'))
            .onChange((selected: boolean): void => {
                if (selected !== this.selectedIds.includes(id)) this.onSelect(id);
            })
            .accessibilityText(`${this.selectedIds.includes(id) ? '取消选择' : '选择'}${name}`)
    }

    build() {
        Column({ space: 12 }) {
            if (this.selectedIndex === 1) {
                ForEach(this.developers, (developer: FollowedDeveloper, index: number) => {
                    Row({ space: 8 }) {
                        if (this.managing) { this.selection(developer.developerId, developer.developerName) }
                        AppSummaryRow({ enterSpeed: 2, enterOrder: index, showIcon: false,
                            name: developer.developerName, subtitle: this.managing ?
                                (this.selectedIds.includes(developer.developerId) ? '已选择' : '点击选择') : '查看开发者当前收录的应用',
                            showArrow: !this.managing, actionLabel: this.managing ? '点击切换选择' : '点击查看',
                            onOpen: (): void => {
                                if (this.managing) this.onSelect(developer.developerId);
                                else openAppCollection(this.pageStack, { title: developer.developerName,
                                    developerId: developer.developerId, developerName: developer.developerName });
                            } })
                            .layoutWeight(1).enabled(this.interactive)
                    }.width('100%')
                }, (developer: FollowedDeveloper) => developer.developerId)
            } else {
                ForEach(this.apps, (app: SavedApp, index: number) => {
                    Row({ space: 8 }) {
                        if (this.managing) { this.selection(app.appId, app.name) }
                        AppSummaryRow({ enterSpeed: 2, enterOrder: index, appId: app.appId,
                            packageName: app.packageName, name: app.name, iconUrl: app.iconUrl,
                            subtitle: this.managing ? (this.selectedIds.includes(app.appId) ? '已选择' : '点击选择') :
                                '已收藏 · 点击查看应用详情', showArrow: !this.managing,
                            actionLabel: this.managing ? '点击切换选择' : '点击查看',
                            onOpen: (): void => {
                                if (this.managing) this.onSelect(app.appId);
                                else openDiscoveryApp(this.pageStack, { appId: app.appId, packageName: app.packageName });
                            } })
                            .layoutWeight(1).enabled(this.interactive)
                    }.width('100%')
                }, (app: SavedApp) => app.appId)
            }
        }.width('100%')
    }
}
