import { http } from '@kit.NetworkKit';
import {
  APP_BUNDLE_NAME,
  APP_VERSION,
  customUserAgent,
  FullDeviceInfo,
  ONLY_ID,
  SUBMIT_PLATFORM,
} from './constants';
import type {
  BaseAPIResponse,
  TelemetryDeviceInfo,
  TelemetryIngestResponse,
  TelemetryReportBody,
} from './types';

const TELEMETRY_REPORT_URL: string = 'https://ddns.shenjack.top:10003/api/v0/telemetry/report';
const TELEMETRY_TIMEOUT_MS: number = 10000;

/**
 * 遥测边界：设备信息、ODID、自定义 User-Agent 与 2.x 上报字段保持完整兼容。
 * 页面层只负责决定上报时机，不再持有网络请求与数据组装细节。
 */
export async function reportUserTelemetry(
  eventName: string = customUserAgent,
): Promise<BaseAPIResponse<TelemetryIngestResponse> | null> {
  const reportBody: TelemetryReportBody = {
    app_id: APP_BUNDLE_NAME,
    only_id: ONLY_ID,
    app_version: APP_VERSION,
    submit_platform: SUBMIT_PLATFORM,
    custom_user_agent: customUserAgent,
    event_name: eventName,
    device_info: new FullDeviceInfo() as TelemetryDeviceInfo,
  };
  let request: http.HttpRequest | undefined = undefined;

  try {
    request = http.createHttp();
    const response = await request.request(TELEMETRY_REPORT_URL, {
      method: http.RequestMethod.POST,
      header: { 'Content-Type': 'application/json', 'User-Agent': customUserAgent },
      extraData: JSON.stringify(reportBody),
      expectDataType: http.HttpDataType.STRING,
      usingCache: false,
      connectTimeout: TELEMETRY_TIMEOUT_MS,
      readTimeout: TELEMETRY_TIMEOUT_MS,
    });
    console.info('[Dashboard][common/TelemetryService][INFO]',
      `遥测上报响应状态: ${response.responseCode}`);
    if (response.responseCode !== 200 || !response.result) {
      console.warn('[Dashboard][common/TelemetryService][WARN]',
        `遥测上报失败，状态码: ${response.responseCode}`);
      return null;
    }

    const rawResult = response.result;
    if (typeof rawResult !== 'string') {
      return rawResult as BaseAPIResponse<TelemetryIngestResponse>;
    }
    if (!rawResult.trim()) {
      console.warn('[Dashboard][common/TelemetryService][WARN]', '遥测接口返回空内容');
      return null;
    }
    try {
      return JSON.parse(rawResult) as BaseAPIResponse<TelemetryIngestResponse>;
    } catch (error) {
      console.warn('[Dashboard][common/TelemetryService][WARN]',
        `遥测响应解析失败: ${JSON.stringify(error)}`);
      return null;
    }
  } catch (error) {
    console.warn('[Dashboard][common/TelemetryService][WARN]',
      `遥测网络请求失败: ${JSON.stringify(error)}`);
    return null;
  } finally {
    if (request) {
      try {
        request.destroy();
      } catch (error) {
        console.warn('[Dashboard][common/TelemetryService][WARN]',
          `遥测请求对象释放失败: ${JSON.stringify(error)}`);
      }
    }
  }
}
