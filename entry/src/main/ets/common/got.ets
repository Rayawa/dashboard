import { http } from '@kit.NetworkKit';
import URL from './url';
import { util } from '@kit.ArkTS';

export interface RequestOptions extends http.HttpRequestOptions {
    method?: http.RequestMethod;
    header?: Record<string, string>;
    params?: Record<string, string | number | boolean>;
    body?: string | ArrayBuffer | Record<string, unknown>;
    timeout?: number;
    retry?: number;
    url?: string;
}

export interface Response<T = ArrayBuffer> {
    statusCode: number;
    headers: Record<string, string>;
    body: T;
    request: RequestOptions;
    ok: boolean;
}

export class Got {
    private defaultOptions: Partial<RequestOptions>;
    private httpService: http.HttpRequest;

    constructor(defaultOptions: Partial<RequestOptions> = {}) {
        this.defaultOptions = {
            method: http.RequestMethod.GET,
            timeout: 60000,
            ...defaultOptions
        };
        this.httpService = http.createHttp();
    }

    /**
     * 发起HTTP请求
     */
    async request<T = ArrayBuffer>(url: string, options: RequestOptions = {}): Promise<Response<T>> {
        const mergedOptions: RequestOptions = {
            ...this.defaultOptions,
            ...options,
            url
        };

        // 处理查询参数
        if (mergedOptions.params) {
            const urlObj = new URL(url);
            Object.entries(mergedOptions.params).forEach(([key, value]) => {
                urlObj.searchParams.append(key, String(value));
            });
            mergedOptions.url = urlObj.toString();
        }

        // 处理请求体
        if (mergedOptions.body) {
            mergedOptions.method = mergedOptions.method || http.RequestMethod.POST;

            if (mergedOptions.body instanceof ArrayBuffer) {
                // 二进制数据
                mergedOptions.extraData = mergedOptions.body;
                mergedOptions.header = {
                    'Content-Type': 'application/octet-stream',
                    ...mergedOptions.header
                };
            } else if (typeof mergedOptions.body === 'string') {
                // 字符串数据
                mergedOptions.extraData = mergedOptions.body;
                mergedOptions.header = {
                    'Content-Type': 'text/plain',
                    ...mergedOptions.header
                };
            } else if (typeof mergedOptions.body === 'object') {
                // JSON数据
                mergedOptions.extraData = JSON.stringify(mergedOptions.body);
                mergedOptions.header = {
                    'Content-Type': 'application/json',
                    ...mergedOptions.header
                };
            }
        }

        // 设置超时
        if (mergedOptions.timeout) {
            mergedOptions.readTimeout = mergedOptions.timeout;
            mergedOptions.connectTimeout = mergedOptions.timeout;
        }

        let retryCount = mergedOptions.retry || 0;
        let lastError: Error | null = null;

        while (retryCount >= 0) {
            try {
                const response: http.HttpResponse = await this.httpService.request(
                    mergedOptions.url!,
                    mergedOptions
                );

                // 获取响应体，默认为ArrayBuffer
                let body: ArrayBuffer = new ArrayBuffer(0);

                if (response.result) {
                    if (typeof response.result === 'string') {
                        // 字符串转换为ArrayBuffer - 使用 ArkTS 的 TextEncoder
                        const encoder = new util.TextEncoder();
                        body = encoder.encodeInto(response.result).buffer;
                    } else if (response.result instanceof ArrayBuffer) {
                        body = response.result;
                    } else {
                        // 其他类型转换为字符串再转ArrayBuffer
                        const str = String(response.result);
                        const encoder = new util.TextEncoder();
                        body = encoder.encodeInto(str).buffer;
                    }
                }

                return {
                    statusCode: response.responseCode,
                    headers: (response.header as Record<string, string>) || {},
                    body: body as T,
                    request: mergedOptions,
                    ok: response.responseCode >= 200 && response.responseCode < 300
                };
            } catch (error) {
                lastError = error as Error;
                if (retryCount > 0) {
                    retryCount--;
                    // 等待1秒后重试
                    await new Promise(resolve => setTimeout(resolve, 1000));
                } else {
                    break;
                }
            }
        }

        throw lastError || new Error('Request failed');
    }

    /**
     * GET请求 - 返回ArrayBuffer
     */
    async get(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.GET });
    }

    /**
     * GET请求 - 返回字符串
     */
    async getText(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<string>> {
        const response = await this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.GET });

        // 将ArrayBuffer转换为字符串 - 使用 ArkTS 的 TextDecoder

        const decoder = new util.TextDecoder('utf-8');
        const bodyUint8Array = new Uint8Array(response.body);
        const text = decoder.decodeWithStream(bodyUint8Array);

        return {
            ...response,
            body: text
        };
    }

    /**
     * GET请求 - 返回JSON对象
     */
    async getJson<T extends Record<string, unknown>>(url: string,
        options: Omit<RequestOptions, 'method'> = {}): Promise<Response<T>> {
        const response = await this.getText(url, options);

        try {
            const json = JSON.parse(response.body) as T;
            return {
                ...response,
                body: json
            };
        } catch (error) {
            throw new Error(`Failed to parse JSON: ${(error as Error).message}`);
        }
    }

    /**
     * POST请求 - 发送ArrayBuffer
     */
    async post(url: string, body: ArrayBuffer,
        options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.POST, body });
    }

    /**
     * POST请求 - 发送字符串
     */
    async postText(url: string, body: string,
        options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.POST, body });
    }

    /**
     * POST请求 - 发送JSON
     */
    async postJson(url: string, body: Record<string, unknown>,
        options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.POST, body });
    }

    /**
     * POST请求 - 发送JSON并获取JSON响应
     */
    async postJsonWithJsonResponse<T extends Record<string, unknown>>(
        url: string,
        body: Record<string, unknown>,
        options: Omit<RequestOptions, 'method' | 'body'> = {}
    ): Promise<Response<T>> {
        const response = await this.postJson(url, body, options);
        const textResponse = await this.responseToText(response);

        try {
            const json = JSON.parse(textResponse.body) as T;
            return {
                ...textResponse,
                body: json
            };
        } catch (error) {
            throw new Error(`Failed to parse JSON response: ${(error as Error).message}`);
        }
    }

    /**
     * PUT请求
     */
    async put(url: string, body: ArrayBuffer | string | Record<string, unknown>,
        options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.PUT, body });
    }

    /**
     * DELETE请求
     */
    async delete(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.DELETE });
    }

    // /**
    //  * PATCH请求
    //  */
    // async patch(url: string, body: ArrayBuffer | string | Record<string, unknown>,
    //     options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
    //     return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.P, body });
    // }

    /**
     * HEAD请求
     */
    async head(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<ArrayBuffer>> {
        return this.request<ArrayBuffer>(url, { ...options, method: http.RequestMethod.HEAD });
    }

    /**
     * 将响应体转换为字符串
     */
    async responseToText(response: Response<ArrayBuffer>): Promise<Response<string>> {
        const decoder = new util.TextDecoder('utf-8');
        const bodyUint8Array = new Uint8Array(response.body);
        const text = decoder.decodeWithStream(bodyUint8Array);

        return {
            ...response,
            body: text
        };
    }

    /**
     * 将响应体转换为JSON
     */
    async responseToJson<T extends Record<string, unknown>>(response: Response<ArrayBuffer>): Promise<Response<T>> {
        const textResponse = await this.responseToText(response);

        try {
            const json = JSON.parse(textResponse.body) as T;
            return {
                ...textResponse,
                body: json
            };
        } catch (error) {
            throw new Error(`Failed to parse JSON: ${(error as Error).message}`);
        }
    }

    /**
     * 创建实例方法
     */
    static create(defaultOptions: Partial<RequestOptions> = {}): Got {
        return new Got(defaultOptions);
    }

    /**
     * 静态快捷方法
     */
    static async get(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<ArrayBuffer>> {
        return new Got().get(url, options);
    }

    static async getText(url: string, options: Omit<RequestOptions, 'method'> = {}): Promise<Response<string>> {
        return new Got().getText(url, options);
    }

    static async getJson<T extends Record<string, unknown>>(url: string,
        options: Omit<RequestOptions, 'method'> = {}): Promise<Response<T>> {
        return new Got().getJson<T>(url, options);
    }

    static async post(url: string, body: ArrayBuffer,
        options: Omit<RequestOptions, 'method' | 'body'> = {}): Promise<Response<ArrayBuffer>> {
        return new Got().post(url, body, options);
    }

    /**
     * 清理资源
     */
    destroy(): void {
        this.httpService.destroy();
    }
}

// 创建默认实例
export const got = new Got();

// 扩展静态方法
export default Got;