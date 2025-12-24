import { common } from "@kit.AbilityKit";
import { deviceInfo } from "@kit.BasicServicesKit";
import getDiskStorageInstance, { DiskStorageInstance } from "./DiskStorage";

let instance: DiskStorageInstance | undefined = undefined;
export function initialize(ctx?: common.Context) {
    instance = getDiskStorageInstance("profile", ctx);
    if (!instance) {
        throw new Error("Failed to initialize profile storage");
    }
}

export function getDeviceName(): string {
    try {
        const productModel = deviceInfo.productModel;
        return productModel && productModel.trim().length > 0 ? productModel : "HarmonyOS设备";
    } catch (error) {
        console.error("Failed to get device name:", error);
        return "我的设备";
    }
}

export async function getUsername(): Promise<string> {
    if (!instance) {
        throw new Error("Profile storage is not initialized");
    }
    return (await instance.get("username", getDeviceName())) as string;
}

export async function setUsername(username?: string): Promise<void> {
    if (!instance) {
        throw new Error("Profile storage is not initialized");
    }
    if (username == undefined) {
        await instance.remove("username");
        return;
    }
    await instance.set("username", username);
}

export async function clearUsername(): Promise<void> {
    if (!instance) {
        throw new Error("Profile storage is not initialized");
    }
    await instance.set("username", getDeviceName());
}

export async function hasUsername(): Promise<boolean> {
    if (!instance) {
        throw new Error("Profile storage is not initialized");
    }
    const username = await getUsername();
    const deviceName = getDeviceName();
    return username !== deviceName && username.trim().length > 0;
}
