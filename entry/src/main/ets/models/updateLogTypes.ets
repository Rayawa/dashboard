export interface UpdateLog {
    version: string;
    date: string;
    type: "beta" | "rc" | "release";
    isRelease?: boolean;
    items: string[];
}
