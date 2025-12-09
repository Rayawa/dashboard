import { URL } from "./url";

export const SBaseURL = new URL("http://shenjack.top:10003/")
export const SAPIBaseURL = new URL("/api/v0/", SBaseURL);
export const TBaseURL = new URL("https://hmos.txit.top/")
export const TAPIBaseURL = new URL("/api/", TBaseURL);

export const submitURL: string = "submit";