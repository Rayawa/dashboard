import { image } from '@kit.ImageKit';
import { resourceManager } from '@kit.LocalizationKit';

/** 返回的 PixelMap 归调用方；文件描述符和 ImageSource 始终在本次解码内释放。 */
export async function loadRawPixelMap(resources: resourceManager.ResourceManager, path: string,
    width: number, height: number): Promise<PixelMap> {
    let opened = false;
    let source: image.ImageSource | undefined = undefined;
    try {
        const descriptor = await resources.getRawFd(path);
        opened = true;
        source = image.createImageSource(descriptor);
        return await source.createPixelMap({ desiredSize: { width, height } });
    } catch (error) {
        throw error as Error;
    } finally {
        // 两个释放操作相互独立；同时处理异步失败，避免清理异常覆盖原始解码错误。
        if (source) {
            try { await source.release(); }
            catch (error) { console.warn('[Dashboard][RawImageLoader] ImageSource release failed', error); }
        }
        if (opened) {
            try { await resources.closeRawFd(path); }
            catch (error) { console.warn('[Dashboard][RawImageLoader] Raw file close failed', error); }
        }
    }
}
