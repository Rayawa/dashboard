import type { MarketApp } from './types';

@Observed
export class AppTableItem {
    app: MarketApp;
    index: number;
    constructor(app: MarketApp, index: number) { this.app = app; this.index = index; }
}

/** Stable app identities with explicit reload notifications; rows receive reactive data props. */
export class AppDataSource implements IDataSource {
    private data: AppTableItem[] = [];
    private listeners: DataChangeListener[] = [];
    totalCount(): number { return this.data.length; }
    getData(index: number): AppTableItem { return this.data[index]; }
    registerDataChangeListener(listener: DataChangeListener): void {
        if (!this.listeners.includes(listener)) this.listeners.push(listener);
    }
    unregisterDataChangeListener(listener: DataChangeListener): void {
        const index = this.listeners.indexOf(listener);
        if (index >= 0) this.listeners.splice(index, 1);
    }
    replace(data: MarketApp[], offset: number = 0): void {
        const previous: Map<string, AppTableItem> = new Map();
        for (const item of this.data) previous.set(item.app.app_id, item);
        this.data = data.map((app: MarketApp, index: number): AppTableItem => {
            const item = previous.get(app.app_id) ?? new AppTableItem(app, offset + index + 1);
            item.app = app;
            item.index = offset + index + 1;
            return item;
        });
        for (const listener of this.listeners) listener.onDataReloaded();
    }
}
