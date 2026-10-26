interface KeyValuePair {
    key: string;
    value: string;
}

// ==================== URLSearchParams 实现 ====================
export class URLSearchParams {
    private _params: Array<KeyValuePair> = [];

    constructor(
        init?: string | Record<string, string> | Array<[string, string]> | URLSearchParams,
    ) {
        if (typeof init === "string") {
            this._fromString(init);
        } else if (init && typeof init === "object") {
            if (Array.isArray(init)) {
                this._fromArray(init);
            } else if (init instanceof URLSearchParams) {
                this._fromURLSearchParams(init);
            } else {
                this._fromRecord(init as Record<string, string>);
            }
        }
    }

    private _fromString(query: string): void {
        if (query.startsWith("?")) {
            query = query.substring(1);
        }

        const pairs = query.split("&");
        for (let i = 0; i < pairs.length; i++) {
            const pair = pairs[i];
            if (!pair) continue;

            const separator = pair.indexOf("=");
            const name = separator < 0 ? pair : pair.substring(0, separator);
            const value = separator < 0 ? "" : pair.substring(separator + 1);
            if (name) {
                const decodedName = decodeURIComponent(name.replace(/\+/g, " "));
                const decodedValue = decodeURIComponent(value.replace(/\+/g, " "));
                this._params.push({ key: decodedName, value: decodedValue });
            }
        }
    }

    private _fromArray(pairs: Array<[string, string]>): void {
        for (let i = 0; i < pairs.length; i++) {
            const pair = pairs[i];
            const name = pair[0];
            const value = pair[1];
            this._params.push({ key: String(name), value: String(value) });
        }
    }

    private _fromRecord(obj: Record<string, string>): void {
        const keys = Object.keys(obj);
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            this._params.push({ key: key, value: obj[key] });
        }
    }

    private _fromURLSearchParams(other: URLSearchParams): void {
        const newParams: Array<KeyValuePair> = [];
        for (let i = 0; i < other._params.length; i++) {
            const param = other._params[i];
            newParams.push({ key: param.key, value: param.value });
        }
        this._params = newParams;
    }

    append(name: string, value: string): void {
        this._params.push({ key: String(name), value: String(value) });
    }

    delete(name: string): void {
        const normalizedName = String(name);
        const newParams: Array<KeyValuePair> = [];
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            if (param.key !== normalizedName) {
                newParams.push(param);
            }
        }
        this._params = newParams;
    }

    get(name: string): string | null {
        const normalizedName = String(name);
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            if (param.key === normalizedName) {
                return param.value;
            }
        }
        return null;
    }

    getAll(name: string): Array<string> {
        const normalizedName = String(name);
        const result: Array<string> = [];
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            if (param.key === normalizedName) {
                result.push(param.value);
            }
        }
        return result;
    }

    has(name: string): boolean {
        const normalizedName = String(name);
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            if (param.key === normalizedName) {
                return true;
            }
        }
        return false;
    }

    set(name: string, value: string): void {
        const normalizedName = String(name);
        const normalizedValue = String(value);

        this.delete(name);
        this.append(normalizedName, normalizedValue);
    }

    sort(): void {
        this._params.sort((paramA: KeyValuePair, paramB: KeyValuePair): number => {
            const a = paramA.key;
            const b = paramB.key;
            if (a < b) {
                return -1;
            }
            if (a > b) {
                return 1;
            }
            return 0;
        });
    }

    forEach(callback: (value: string, key: string, parent: URLSearchParams) => void): void {
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            callback(param.value, param.key, this);
        }
    }

    toString(): string {
        const pairs: Array<string> = [];
        for (let i = 0; i < this._params.length; i++) {
            const param = this._params[i];
            const encodedName = encodeURIComponent(param.key).replace(/%20/g, "+");
            const encodedValue = encodeURIComponent(param.value).replace(/%20/g, "+");
            pairs.push(encodedName + "=" + encodedValue);
        }
        return pairs.join("&");
    }

    // [Symbol.iterator](): IterableIterator<[string, string]> {
    //     return this.entries();
    // }

    toJSON(): string {
        return this.toString();
    }
}
