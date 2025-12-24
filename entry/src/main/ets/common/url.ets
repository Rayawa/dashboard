// ==================== 接口定义 ====================
interface IteratorResult<T> {
    value: T;
    done: boolean;
}

interface Iterator<T> {
    next(): IteratorResult<T>;
}

interface IterableIterator<T> extends Iterator<T> {
    [Symbol.iterator](): IterableIterator<T>;
}

interface URLComponents {
    href: string;
    protocol: string;
    username: string;
    password: string;
    hostname: string;
    port: string;
    host: string;
    pathname: string;
    search: string;
    hash: string;
    origin: string;
    searchParams: URLSearchParams;
}

interface ParseResult {
    href: string;
    protocol: string;
    slashes: boolean;
    auth?: string;
    host: string;
    hostname: string;
    port: string;
    pathname: string;
    search: string;
    query: string | Record<string, string>;
    hash: string;
    origin: string;
}

interface KeyValuePair {
    key: string;
    value: string;
}

// ==================== URLSearchParams 实现 ====================
class URLSearchParams {
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

            const parts = pair.split("=");
            const name = parts[0];
            const value = parts.length > 1 ? parts[1] : "";
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
            if (keys.includes(key)) {
                this._params.push({ key: key, value: obj[key] });
            }
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

    // entries(): IterableIterator<[string, string]> {
    //     const params = this._params;
    //     let index = 0;
    //
    //     const iterator: IterableIterator<[string, string]> = {
    //         next(): IteratorResult<[string, string]> {
    //             if (index < params.length) {
    //                 const param = params[index];
    //                 const result: [string, string] = [param.key, param.value];
    //                 index++;
    //                 return { value: result, done: false };
    //             }
    //             return { value: ['', ''], done: true };
    //         },
    //         [Symbol.iterator](): IterableIterator<[string, string]> {
    //             return this;
    //         }
    //     };
    //     return iterator;
    // }

    // keys(): IterableIterator<string> {
    //     const params = this._params;
    //     let index = 0;
    //
    //     const iterator: IterableIterator<string> = {
    //         next(): IteratorResult<string> {
    //             if (index < params.length) {
    //                 const value = params[index].key;
    //                 index++;
    //                 return { value: value, done: false };
    //             }
    //             return { value: '', done: true };
    //         },
    //         [Symbol.iterator](): IterableIterator<string> {
    //             return this;
    //         }
    //     };
    //     return iterator;
    // }

    // values(): IterableIterator<string> {
    //     const params = this._params;
    //     let index = 0;
    //
    //     const iterator: IterableIterator<string> = {
    //         next(): IteratorResult<string> {
    //             if (index < params.length) {
    //                 const value = params[index].value;
    //                 index++;
    //                 return { value: value, done: false };
    //             }
    //             return { value: '', done: true };
    //         },
    //         [Symbol.iterator](): IterableIterator<string> {
    //             return this;
    //         }
    //     };
    //     return iterator;
    // }

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

// ==================== URL 主类 ====================
class URL {
    private _url: string = "";
    private _scheme: string = "";
    private _username: string = "";
    private _password: string = "";
    private _hostname: string = "";
    private _port: string = "";
    private _pathname: string = "";
    private _search: string = "";
    private _hash: string = "";
    private _origin: string = "";
    private _host: string = "";
    private _searchParams: URLSearchParams;

    private static readonly SPECIAL_SCHEMES: Set<string> = new Set([
        "ftp",
        "file",
        "http",
        "https",
        "ws",
        "wss",
    ]);
    private static readonly DEFAULT_PORTS: Map<string, string> = new Map([
        ["ftp", "21"],
        ["file", ""],
        ["http", "80"],
        ["https", "443"],
        ["ws", "80"],
        ["wss", "443"],
    ]);

    constructor(url: string, base?: string | URL) {
        this._searchParams = new URLSearchParams();

        if (base) {
            const baseURL = base instanceof URL ? base : new URL(base);
            const resolved = this._resolve(url, baseURL);
            this._parse(resolved);
        } else {
            this._parse(url);
        }
    }

    // ==================== 核心解析方法 ====================
    private _parse(input: string): void {
        // 1. 分离片段
        const hashIndex = input.indexOf("#");
        if (hashIndex !== -1) {
            this._hash = input.substring(hashIndex + 1);
            input = input.substring(0, hashIndex);
        }

        // 2. 分离查询部分
        const queryIndex = input.indexOf("?");
        if (queryIndex !== -1) {
            this._search = input.substring(queryIndex + 1);
            this._searchParams = new URLSearchParams(this._search);
            input = input.substring(0, queryIndex);
        }

        // 3. 分离协议
        const schemeMatch = input.match(/^([a-z][a-z0-9+\-.]*):/i);
        if (schemeMatch) {
            this._scheme = schemeMatch[1].toLowerCase();
            input = input.substring(schemeMatch[0].length);
        }

        // 4. 处理特殊协议的双斜杠
        if (URL.SPECIAL_SCHEMES.has(this._scheme) && input.startsWith("//")) {
            input = input.substring(2);

            // 5. 解析授权部分
            const authorityEnd = this._findAuthorityEnd(input);
            const authority = input.substring(0, authorityEnd);
            input = input.substring(authorityEnd);

            this._parseAuthority(authority);
        }

        // 6. 剩余部分为路径
        this._pathname = input || "/";

        // 7. 构建完整URL组件
        this._buildComponents();
    }

    private _findAuthorityEnd(input: string): number {
        for (let i = 0; i < input.length; i++) {
            const char = input.charAt(i);
            if (char === "/" || char === "?" || char === "#") {
                return i;
            }
        }
        return input.length;
    }

    private _parseAuthority(authority: string): void {
        // 分离用户信息
        const atIndex = authority.lastIndexOf("@");
        let hostPart = authority;

        if (atIndex !== -1) {
            const userinfo = authority.substring(0, atIndex);
            hostPart = authority.substring(atIndex + 1);
            this._parseUserInfo(userinfo);
        }

        // 解析主机和端口
        this._parseHostPort(hostPart);
    }

    private _parseUserInfo(userinfo: string): void {
        const colonIndex = userinfo.indexOf(":");
        if (colonIndex !== -1) {
            this._username = this._percentDecode(userinfo.substring(0, colonIndex));
            this._password = this._percentDecode(userinfo.substring(colonIndex + 1));
        } else {
            this._username = this._percentDecode(userinfo);
        }
    }

    private _parseHostPort(hostPort: string): void {
        // 处理IPv6地址
        if (hostPort.startsWith("[")) {
            const endBracket = hostPort.indexOf("]");
            if (endBracket === -1) {
                throw new TypeError("Invalid URL");
            }

            this._hostname = hostPort.substring(0, endBracket + 1);
            const afterBracket = hostPort.substring(endBracket + 1);

            if (afterBracket.startsWith(":")) {
                this._port = afterBracket.substring(1);
            }
        } else {
            const colonIndex = hostPort.lastIndexOf(":");
            if (colonIndex !== -1) {
                this._hostname = hostPort.substring(0, colonIndex);
                this._port = hostPort.substring(colonIndex + 1);
            } else {
                this._hostname = hostPort;
            }
        }

        // 验证端口
        if (this._port && !/^\d+$/.test(this._port)) {
            throw new TypeError("Invalid URL: port must be a number");
        }

        // 如果是特殊协议且端口是默认端口，清空端口
        if (URL.SPECIAL_SCHEMES.has(this._scheme)) {
            const defaultPort = URL.DEFAULT_PORTS.get(this._scheme);
            if (defaultPort !== undefined && this._port === defaultPort) {
                this._port = "";
            }
        }

        // 构建host
        if (this._port) {
            this._host = this._hostname + ":" + this._port;
        } else {
            this._host = this._hostname;
        }
    }

    private _percentDecode(input: string): string {
        return decodeURIComponent(input);
    }

    // ==================== 相对URL解析 ====================
    private _resolve(relative: string, base: URL): string {
        // 如果已经是绝对URL
        if (/^[a-z][a-z0-9+\-.]*:/i.test(relative)) {
            return relative;
        }

        let result = "";

        // 处理协议相对URL (//)
        if (relative.startsWith("//")) {
            return base.protocol + relative;
        }

        // 处理绝对路径
        if (relative.startsWith("/")) {
            result = base.protocol + "//" + base.host + relative;
        }
        // 处理查询相对
        else if (relative.startsWith("?")) {
            result = base.protocol + "//" + base.host + base.pathname + relative;
        }
        // 处理哈希相对
        else if (relative.startsWith("#")) {
            result = base.protocol + "//" + base.host + base.pathname + base.search + relative;
        }
        // 处理相对路径
        else {
            const basePath = base.pathname;
            const lastSlash = basePath.lastIndexOf("/");
            const baseDir = lastSlash >= 0 ? basePath.substring(0, lastSlash + 1) : "/";
            const resolvedPath = this._normalizePath(baseDir + relative);
            result = base.protocol + "//" + base.host + resolvedPath + base.search + base.hash;
        }

        return result;
    }

    private _normalizePath(path: string): string {
        const parts = path.split("/");
        const result: Array<string> = [];

        for (let i = 0; i < parts.length; i++) {
            const part = parts[i];
            if (part === "" || part === ".") {
                continue;
            } else if (part === "..") {
                if (result.length > 0) {
                    result.pop();
                }
            } else {
                result.push(part);
            }
        }

        return "/" + result.join("/");
    }

    // ==================== 构建组件 ====================
    private _buildComponents(): void {
        // 构建URL字符串
        let url = "";

        // 协议
        if (this._scheme) {
            url += this._scheme + ":";
        }

        // 授权部分
        if (this._hostname) {
            url += "//";

            // 用户信息
            if (this._username || this._password) {
                url += this._encodeUserInfo(this._username);
                if (this._password) {
                    url += ":" + this._encodeUserInfo(this._password);
                }
                url += "@";
            }

            // 主机
            url += this._hostname;

            // 端口
            if (this._port) {
                url += ":" + this._port;
            }
        }

        // 路径
        url += this._encodePath(this._pathname);

        // 查询
        if (this._search) {
            url += "?" + this._search;
        }

        // 哈希
        if (this._hash) {
            url += "#" + this._hash;
        }

        this._url = url;

        // 构建origin
        if (this._scheme && this._hostname) {
            let port = "";
            if (this._port && URL.SPECIAL_SCHEMES.has(this._scheme)) {
                const defaultPort = URL.DEFAULT_PORTS.get(this._scheme);
                if (defaultPort !== undefined && this._port !== defaultPort) {
                    port = ":" + this._port;
                }
            }
            this._origin = this._scheme + "://" + this._hostname + port;
        } else if (this._scheme === "file") {
            this._origin = "null";
        } else {
            this._origin = "";
        }
    }

    private _encodeUserInfo(input: string): string {
        return encodeURIComponent(input);
    }

    private _encodePath(input: string): string {
        if (!input) {
            return "/";
        }
        if (!input.startsWith("/")) {
            input = "/" + input;
        }
        return encodeURI(input);
    }

    // ==================== 公共API ====================
    get href(): string {
        return this._url;
    }

    set href(value: string) {
        this._parse(value);
    }

    get origin(): string {
        return this._origin;
    }

    get protocol(): string {
        return this._scheme ? this._scheme + ":" : "";
    }

    set protocol(value: string) {
        const match = value.match(/^([a-z][a-z0-9+\-.]*):?$/i);
        if (!match) {
            throw new TypeError("Invalid protocol");
        }

        const newScheme = match[1].toLowerCase();
        if (newScheme !== this._scheme) {
            this._scheme = newScheme;
            this._buildComponents();
        }
    }

    get username(): string {
        return this._username;
    }

    set username(value: string) {
        this._username = this._encodeUserInfo(value);
        this._buildComponents();
    }

    get password(): string {
        return this._password;
    }

    set password(value: string) {
        this._password = this._encodeUserInfo(value);
        this._buildComponents();
    }

    get host(): string {
        return this._host;
    }

    set host(value: string) {
        // 解析主机和端口
        const hostPort = this._parseHostPortString(value);

        this._hostname = hostPort[0];
        this._port = hostPort[1] || "";
        if (this._port) {
            this._host = this._hostname + ":" + this._port;
        } else {
            this._host = this._hostname;
        }
        this._buildComponents();
    }

    get hostname(): string {
        return this._hostname;
    }

    set hostname(value: string) {
        this._hostname = value;
        if (this._port) {
            this._host = value + ":" + this._port;
        } else {
            this._host = value;
        }
        this._buildComponents();
    }

    get port(): string {
        return this._port;
    }

    set port(value: string) {
        if (value && !/^\d+$/.test(value)) {
            throw new TypeError("Invalid port");
        }

        this._port = value || "";
        if (this._hostname) {
            if (value) {
                this._host = this._hostname + ":" + value;
            } else {
                this._host = this._hostname;
            }
        } else {
            this._host = "";
        }
        this._buildComponents();
    }

    get pathname(): string {
        return this._pathname || "/";
    }

    set pathname(value: string) {
        this._pathname = this._encodePath(value);
        this._buildComponents();
    }

    get search(): string {
        return this._search ? "?" + this._search : "";
    }

    set search(value: string) {
        const query = value.startsWith("?") ? value.substring(1) : value;
        this._search = query;
        this._searchParams = new URLSearchParams(query);
        this._buildComponents();
    }

    get searchParams(): URLSearchParams {
        return this._searchParams;
    }

    get hash(): string {
        return this._hash ? "#" + this._hash : "";
    }

    set hash(value: string) {
        this._hash = value.startsWith("#") ? value.substring(1) : value;
        this._buildComponents();
    }

    private _parseHostPortString(input: string): [string, string] {
        input = input.trim();

        // 处理IPv6地址
        if (input.startsWith("[")) {
            const endBracket = input.indexOf("]");
            if (endBracket === -1) {
                throw new TypeError("Invalid host");
            }

            const hostname = input.substring(0, endBracket + 1);
            const rest = input.substring(endBracket + 1);

            if (rest.startsWith(":")) {
                return [hostname, rest.substring(1)];
            }
            return [hostname, ""];
        }

        // 处理普通主机名
        const colonIndex = input.lastIndexOf(":");
        if (colonIndex === -1) {
            return [input, ""];
        }

        const hostname = input.substring(0, colonIndex);
        const port = input.substring(colonIndex + 1);

        if (port && !/^\d+$/.test(port)) {
            throw new TypeError("Invalid port");
        }

        return [hostname, port];
    }

    // ==================== 字符串表示 ====================
    toString(): string {
        return this._url;
    }

    toJSON(): string {
        return this._url;
    }

    // ==================== 静态方法 ====================
    static canParse(url: string, base?: string): boolean {
        try {
            new URL(url, base);
            return true;
        } catch {
            return false;
        }
    }

    static createObjectURL(object: Object): string {
        const uuid = "blob:" + URL._generateUUID();
        return uuid;
    }

    static revokeObjectURL(url: string): void {
        // 实际实现中会清理资源
    }

    private static _generateUUID(): string {
        const chars = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx";
        let result = "";
        for (let i = 0; i < chars.length; i++) {
            const c = chars.charAt(i);
            if (c === "x") {
                const r = Math.floor(Math.random() * 16);
                result += r.toString(16);
            } else if (c === "y") {
                const r = Math.floor(Math.random() * 16);
                const v = (r & 0x3) | 0x8;
                result += v.toString(16);
            } else {
                result += c;
            }
        }
        return result;
    }
}

// ==================== 辅助工具函数 ====================
function parseURL(urlString: string, base?: string): URLComponents | null {
    try {
        const url = new URL(urlString, base);
        const components: URLComponents = {
            href: url.href,
            protocol: url.protocol,
            username: url.username,
            password: url.password,
            hostname: url.hostname,
            port: url.port,
            host: url.host,
            pathname: url.pathname,
            search: url.search,
            hash: url.hash,
            origin: url.origin,
            searchParams: url.searchParams,
        };
        return components;
    } catch {
        return null;
    }
}

function urlParse(
    urlString: string,
    parseQueryString: boolean = false,
    slashesDenoteHost: boolean = false,
): ParseResult | null {
    try {
        const url = new URL(urlString);
        const result: ParseResult = {
            href: url.href,
            protocol: url.protocol,
            slashes: !!(url.protocol && url.hostname),
            host: url.host,
            hostname: url.hostname,
            port: url.port,
            pathname: url.pathname,
            search: url.search,
            query: parseQueryString ? {} : url.search,
            hash: url.hash,
            origin: url.origin,
        };

        if (url.username || url.password) {
            result.auth = url.username;
            if (url.password) {
                result.auth = result.auth + ":" + url.password;
            }
        }

        if (parseQueryString && result.query instanceof Object) {
            url.searchParams.forEach((value: string, key: string) => {
                (result.query as object)[key] = value;
            });
        }

        return result;
    } catch {
        // 简化解析
        const match = urlString.match(/^([^:/?#]+:)?(\/\/[^/?#]*)?([^?#]*)(\?[^#]*)?(#.*)?/);
        if (!match) {
            return null;
        }

        const result: ParseResult = {
            href: urlString,
            protocol: match[1] || "",
            slashes: !!match[2],
            host: match[2] ? match[2].substring(2) : "",
            hostname: "",
            port: "",
            pathname: match[3] || "",
            search: match[4] || "",
            query: parseQueryString ? {} : match[4] || "",
            hash: match[5] || "",
            origin: "",
        };
        return result;
    }
}

// ==================== 导出 ====================
export { URL, URLSearchParams, parseURL, urlParse };
export default URL;
