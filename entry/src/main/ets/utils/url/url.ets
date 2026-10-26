import { URLSearchParams } from './URLSearchParams';

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

}

export { URL, URLSearchParams };
export default URL;
