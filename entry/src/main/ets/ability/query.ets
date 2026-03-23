import { ShareExtensionAbility, UIExtensionContentSession, Want } from "@kit.AbilityKit";
import { systemShare } from "@kit.ShareKit";
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';

interface FullInfo {
  alliance_app_id: string;
}

interface AppData {
  full_info: FullInfo;
}

interface ApiResponse {
  success: boolean;
  data?: AppData;
}

export class QueryAbility extends ShareExtensionAbility {
  async onSessionCreate(want: Want, session: UIExtensionContentSession): Promise<void> {
    try {
      const data = await systemShare.getSharedData(want);
      const records = data.getRecords();
      if (records.length === 0) return;

      const rawContent = records[0].content?.toString() || "";

      const pkgName = this.extractPkg(rawContent);
      if (!pkgName) throw new Error("无法解析包名");

      const appId = await this.getAppIdByPackage(pkgName);

      const exists = await this.verifyAppIdExists(appId);
      if (!exists) throw new Error("市场未收录此应用");

      const finalUrl = `https://hmos.txit.top/app/${appId}`;

      const wantForUI: Want = {
        bundleName: "top.rayawa.dashboard",
        abilityName: "queryEntryAbility",
        parameters: {
          targetUrl: finalUrl
        }
      };
      await this.context.startAbility(wantForUI);

    } catch (err) {
      const error = err as Error;
      console.error(`queryResult [QueryAbility] Error: ${error.message}`);
    } finally {
      session.terminateSelfWithResult({ resultCode: 0 });
    }
  }

  extractPkg(url: string): string | null {
    const match = url.match(/[?&]id=([^&]+)/);
    return match ? match[1] : null;
  }

  async getAppIdByPackage(pkg: string): Promise<string> {
    return new Promise((resolve, reject) => {
      let apiUrl = `http://shenjack.top:10003/api/v0/apps/pkg_name/${pkg}`;
      http.createHttp().request(apiUrl, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            const res = JSON.parse(data.result.toString()) as ApiResponse;
            const id = res.data?.full_info?.alliance_app_id;
            if (id) {
              resolve(id.startsWith('C') ? id : `C${id}`);
            } else {
              reject(new Error("未找到 AppID 字段"));
            }
          } catch (e) {
            reject(new Error("JSON 解析错误"));
          }
        } else {
          reject(new Error("网络请求失败"));
        }
      });
    });
  }

  async verifyAppIdExists(appId: string): Promise<boolean> {
    return new Promise((resolve) => {
      let apiUrl = `http://shenjack.top:10003/api/v0/apps/app_id/${appId}`;
      http.createHttp().request(apiUrl, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            const res = JSON.parse(data.result.toString()) as ApiResponse;
            resolve(res.success === true);
          } catch (e) {
            resolve(false);
          }
        } else {
          resolve(false);
        }
      });
    });
  }
}