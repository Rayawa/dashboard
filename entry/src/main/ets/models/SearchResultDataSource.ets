import type { MarketApp } from './types';

export class SearchResultDataSource implements IDataSource {
    private listeners: DataChangeListener[] = [];
    private data: MarketApp[] = [];

    totalCount(): number { return this.data.length; }
    getData(index: number): MarketApp { return this.data[index]; }
    registerDataChangeListener(listener: DataChangeListener): void {
        if (this.listeners.indexOf(listener) < 0) this.listeners.push(listener);
    }
    unregisterDataChangeListener(listener: DataChangeListener): void {
        const index = this.listeners.indexOf(listener);
        if (index >= 0) this.listeners.splice(index, 1);
    }
    replace(data: MarketApp[]): void {
        this.data = data.slice();
        for (const listener of this.listeners) listener.onDataReloaded();
    }
    items(): MarketApp[] { return this.data; }
}
