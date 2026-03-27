import { vibrator } from '@kit.SensorServiceKit';
import { http } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { prompt, router } from '@kit.ArkUI';
import type { FormData } from '../common/types';

interface Scale {
  x: number;
  y: number;
}

interface ButtonAnimationState {
  immediatelyOpacity: number;
  immediatelyScale: Scale;
  delayOpacity: number;
  delayScale: Scale;
}
interface FullInfo {
  alliance_app_id: string;
}

interface AppData {
  full_info: FullInfo;
}

interface ApiResponse {
  success: boolean;
  data: AppData;
  message?: string;
}

interface AppItem {
  app_id: string;
  name: string;
  pkg_name: string;
}

interface AppListData {
  data: AppItem[];
  total_count: number;
  page: number;
}

interface SearchResponse {
  success: boolean;
  data: AppListData;
}
@Component
export struct queryButtons {
  @State appId: string = '';
  @State isLoading: boolean = false;

  @StorageLink("userName") userName: string = "";
  @StorageLink("inputText") inputText: string = "";
  @StorageLink("formData") formData: FormData = {
    appName: "",
    appLink: "",
    packageName: "",
    appId: "",
  };


  extractBundleName(url: string): string | null {
    const regex = /[?&]id=([^&]+)/;
    const match = url.match(regex);
    const pkg = match ? match[1] : null;
    console.info(`queryResult [Extract] 包名结果: ${pkg}`);
    return pkg;
  }
  async getAppIdByName(appName: string): Promise<string> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();

      const baseUrl = "http://shenjack.top:10003/api/v0/apps/list/0";
      const params = `?page_size=5&detail=false&search_key=name&search_value=${encodeURIComponent(appName)}&search_exact=false`;
      const fullUrl = baseUrl + params;

      console.info(`queryResult [Name API] Requesting URL: ${fullUrl}`);

      httpRequest.request(
        fullUrl,
        {
          method: http.RequestMethod.GET,
          expectDataType: http.HttpDataType.STRING,
          readTimeout: 5000,
        },
        (err: BusinessError, data: http.HttpResponse) => {
          if (!err && data.responseCode === 200) {
            const rawResult = data.result.toString();
            console.info(`queryResult [Name API] Raw Response: ${rawResult}`);

            try {
              const res = JSON.parse(rawResult) as SearchResponse;

              if (res.success && res.data && res.data.data && res.data.data.length > 0) {
                const firstApp = res.data.data[0];
                const rawId = firstApp.app_id;

                console.info(`queryResult [Name API] Match Found: ${firstApp.name}, ID: ${rawId}`);

                const finalId = rawId.startsWith('C') ? rawId : `C${rawId}`;
                resolve(finalId);
              } else {
                console.warn(`queryResult [Name API] No match found in the list.`);
                reject(new Error("未找到匹配的应用名称"));
              }
            } catch (e) {
              console.error(`queryResult [Name API] JSON Parse Error: ${e.message}`);
              reject(new Error("返回数据结构解析失败"));
            }
          } else {
            const errorMsg = err ? err.message : `HTTP ${data?.responseCode}`;
            console.error(`queryResult [Name API] Network Error: ${errorMsg}`);
            reject(new Error(`网络请求失败: ${errorMsg}`));
          }
          httpRequest.destroy();
        }
      );
    });
  }
  async getAppIdByPackage(pkgName: string): Promise<string> {
    return new Promise((resolve, reject) => {
      let httpRequest = http.createHttp();
      let apiUrl = `http://shenjack.top:10003/api/v0/apps/pkg_name/${pkgName}`;
      httpRequest.request(apiUrl, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          const res = JSON.parse(data.result.toString()) as ApiResponse;
          if (res.success && res.data?.full_info?.alliance_app_id) {
            const rawId = res.data.full_info.alliance_app_id;
            resolve(rawId.startsWith('C') ? rawId : `C${rawId}`);
          } else { reject(new Error("包名转换失败")); }
        } else { reject(new Error("网络请求失败")); }
        httpRequest.destroy();
      });
    });
  }

  async verifyAppIdExists(appId: string): Promise<boolean> {
    console.info(`queryResult [Verify Start] 正在校验 AppID 真实性: ${appId}`);
    return new Promise((resolve) => {
      let httpRequest = http.createHttp();
      let apiUrl = `http://shenjack.top:10003/api/v0/apps/app_id/${appId}`;
      httpRequest.request(apiUrl, (err: BusinessError, data: http.HttpResponse) => {
        if (!err && data.responseCode === 200) {
          try {
            const res = JSON.parse(data.result.toString()) as ApiResponse;
            console.info(`queryResult [Verify Response] success: ${res.success}`);
            resolve(res.success);
          } catch (e) { resolve(false); }
        } else { resolve(false); }
        httpRequest.destroy();
      });
    });
  }

  async queryForm(): Promise<void> {
    if (this.isSearching) return;
    this.isSearching = true;
    this.startSearchRippleLoop();

    let tempAppId = "";

    try {
      // 1. 优先级最高：直接输入了 AppID (以 C 开头)
      if (this.formData.appId && this.formData.appId.trim().startsWith('C')) {
        tempAppId = this.formData.appId.trim();
      }
      // 2. 优先级二：输入了包名 (如 com.xxx.xxx)
      else if (this.formData.packageName && this.formData.packageName.trim().length > 0) {
        tempAppId = await this.getAppIdByPackage(this.formData.packageName.trim());
      }
      // 3. 优先级三：输入了分享链接 (从链接提取包名)
      else if (this.formData.appLink && this.formData.appLink.trim().length > 0) {
        const pkg = this.extractBundleName(this.formData.appLink);
        if (pkg) {
          tempAppId = await this.getAppIdByPackage(pkg);
        } else { throw new Error("链接格式不正确"); }
      }
      // 4. 优先级四：输入了应用名称 (调用新接口模糊搜索)
      else if (this.formData.appName && this.formData.appName.trim().length > 0) {
        tempAppId = await this.getAppIdByName(this.formData.appName.trim());
      }
      else {
        throw new Error("请输入任何有效信息");
      }

      // 5. 最后一步：校验该 ID 在库中是否存在
      const isExists = await this.verifyAppIdExists(tempAppId);

      if (isExists) {
        this.formData.appId = tempAppId;
        const finalUrl = `https://hmos.txit.top/app/${tempAppId}`;

        this.isSearching = false;
        this.stopSearchRippleLoop();

        router.pushUrl({
          url: 'pages/queryWeb',
          params: { url: finalUrl }
        });

        this.formData = {
          appLink: "",
          packageName: "",
          appId: "",
          remark: "",
        };
        this.inputText = "";

      } else {
        throw new Error("库中未找到该应用");
      }

    } catch (error) {
      this.isSearching = false;
      this.stopSearchRippleLoop();
      prompt.showToast({ message: `查询失败：${error.message}` });
    }
  }
  async clearForm(): Promise<void> {
    if (this.isCleaning) {
      return;
    }
    this.isCleaning = true;
    this.startCleanRippleLoop();

    this.formData = {
      appLink: "",
      packageName: "",
      appId: "",
      remark: "",
    };
    this.inputText = "";

    setTimeout(() => {
      this.isCleaning = false;
      this.stopCleanRippleLoop();
      vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(
            `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
          );
          return;
        }
        console.info("Succeed in querying effect");
        if (state) {
          try {
            vibrator.startVibration(
              {
                type: "preset",
                effectId: "haptic.effect.hard",
                count: 5,
                intensity: 100,
              },
              { usage: "touch" },
              (error: BusinessError) => {
                if (error) {
                  console.error(
                    `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                  );
                } else {
                  console.info("Succeed in starting vibration");
                }
              },
            );
          } catch (tryError) {
            console.error(`An unexpected error occurred in try block: ${tryError}`);
          }
        }
      });
      prompt.showToast({
        message: "表单已清空",
        duration: 1500,
      });
    }, 700);
  }

  @StorageLink("vibrationON") vibrationON: boolean = true;
  private triggerVibration(): void {
    if (this.vibrationON) {
      vibrator.isSupportEffect("haptic.effect.hard", (err: BusinessError, state: boolean) => {
        if (err) {
          console.error(
            `Failed to query effect. Code: ${err.code}, message: ${err.message}`,
          );
          return;
        }
        console.info("Succeed in querying effect");
        if (state) {
          try {
            vibrator.startVibration(
              {
                type: "preset",
                effectId: "haptic.effect.hard",
                count: 1,
                intensity: 50,
              },
              { usage: "touch" },
              (error: BusinessError) => {
                if (error) {
                  console.error(
                    `Failed to start vibration. Code: ${error.code}, message: ${error.message}`,
                  );
                } else {
                  console.info("Succeed in starting vibration");
                }
              },
            );
          } catch (tryError) {
            console.error(`An unexpected error occurred in try block: ${tryError}`);
          }
        }
      });
    }
  }

  @State isSearching: boolean = false;
  @State isCleaning: boolean = false;
  private readonly BUTTON_WIDTH: string = "30%";
  private readonly BUTTON_HEIGHT: number = 44;
  private readonly BUTTON_CLICK_SCALE: number = 0.8;
  private readonly ANIMATION_DURATION: number = 1300;
  private readonly BORDER_RADIUS: number = 22;
  private readonly CLICK_INTERVAL = 800;
  private _cleanAnimationCompleted: boolean = false;
  private _searchAnimationCompleted: boolean = false;

  @Styles
  ripplesStyleSearch() {
    .width(this.BUTTON_WIDTH)
    .height(this.BUTTON_HEIGHT)
    .borderRadius(this.BORDER_RADIUS)
    .backgroundColor(Color.Blue);
  }
  @Styles
  ripplesStyleClean() {
    .width(this.BUTTON_WIDTH)
    .height(this.BUTTON_HEIGHT)
    .borderRadius(this.BORDER_RADIUS)
    .backgroundColor(Color.Green);
  }

  @State searchAnimation: ButtonAnimationState = {
    immediatelyOpacity: 0.8,
    immediatelyScale: { x: 1, y: 1 },
    delayOpacity: 0.4,
    delayScale: { x: 1, y: 1 },
  };
  @State cleanAnimation: ButtonAnimationState = {
    immediatelyOpacity: 0.8,
    immediatelyScale: { x: 1, y: 1 },
    delayOpacity: 0.4,
    delayScale: { x: 1, y: 1 },
  };

  private _searchLoopRunning: boolean = false;
  private _searchLastClick: number = 0;
  private _cleanLoopRunning: boolean = false;
  private _cleanLastClick: number = 0;

  private startSearchRippleLoop() {
    if (this._searchLoopRunning) {
      return;
    }
    this._searchLoopRunning = true;
    this._searchAnimationCompleted = false;

    const loop = () => {
      if (!this._searchLoopRunning) {
        return;
      }

      this.getUIContext().animateTo(
        {
          duration: this.ANIMATION_DURATION,
          curve: Curve.EaseInOut,
        },
        () => {
          this.searchAnimation.immediatelyOpacity = 0;
          this.searchAnimation.immediatelyScale = { x: 4, y: 4 };
        },
      );

      this.getUIContext().animateTo(
        {
          duration: this.ANIMATION_DURATION,
          delay: 200,
          curve: Curve.EaseInOut,
        },
        () => {
          this.searchAnimation.delayOpacity = 0;
          this.searchAnimation.delayScale = { x: 4, y: 4 };
        },
      );

      const total = this.ANIMATION_DURATION + 200 + 40;

      setTimeout(() => {
        this._searchAnimationCompleted = true;

        if (!this._searchLoopRunning) {
          this.searchAnimation.immediatelyOpacity = 0.8;
          this.searchAnimation.delayOpacity = 0.8;
          this.searchAnimation.immediatelyScale = { x: 1, y: 1 };
          this.searchAnimation.delayScale = { x: 1, y: 1 };
          return;
        }

        this.searchAnimation.immediatelyOpacity = 0.8;
        this.searchAnimation.delayOpacity = 0.8;
        this.searchAnimation.immediatelyScale = { x: 1, y: 1 };
        this.searchAnimation.delayScale = { x: 1, y: 1 };

        loop();
      }, total);
    };

    loop();
  }
  private stopSearchRippleLoop() {
    if (!this._searchAnimationCompleted) {
      setTimeout(() => {
        this._searchLoopRunning = false;
        this.searchAnimation.immediatelyOpacity = 0.8;
        this.searchAnimation.delayOpacity = 0.8;
        this.searchAnimation.immediatelyScale = { x: 1, y: 1 };
        this.searchAnimation.delayScale = { x: 1, y: 1 };
      }, 700);
    } else {
      this._searchLoopRunning = false;
      this.searchAnimation.immediatelyOpacity = 0.8;
      this.searchAnimation.delayOpacity = 0.8;
      this.searchAnimation.immediatelyScale = { x: 1, y: 1 };
      this.searchAnimation.delayScale = { x: 1, y: 1 };
    }
  }

  private startCleanRippleLoop() {
    if (this._cleanLoopRunning) {
      return;
    }
    this._cleanLoopRunning = true;
    this._cleanAnimationCompleted = false;

    const loop = () => {
      if (!this._cleanLoopRunning) {
        return;
      }

      this.getUIContext().animateTo(
        {
          duration: this.ANIMATION_DURATION,
          curve: Curve.EaseInOut,
        },
        () => {
          this.cleanAnimation.immediatelyOpacity = 0;
          this.cleanAnimation.immediatelyScale = { x: 4, y: 4 };
        },
      );

      this.getUIContext().animateTo(
        {
          duration: this.ANIMATION_DURATION,
          delay: 200,
          curve: Curve.EaseInOut,
        },
        () => {
          this.cleanAnimation.delayOpacity = 0;
          this.cleanAnimation.delayScale = { x: 4, y: 4 };
        },
      );

      const total = this.ANIMATION_DURATION + 200 + 40;

      setTimeout(() => {
        this._cleanAnimationCompleted = true;

        if (!this._cleanLoopRunning) {
          this.cleanAnimation.immediatelyOpacity = 0.8;
          this.cleanAnimation.delayOpacity = 0.8;
          this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
          this.cleanAnimation.delayScale = { x: 1, y: 1 };
          return;
        }

        this.cleanAnimation.immediatelyOpacity = 0.8;
        this.cleanAnimation.delayOpacity = 0.8;
        this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
        this.cleanAnimation.delayScale = { x: 1, y: 1 };

        loop();
      }, total);
    };

    loop();
  }
  private stopCleanRippleLoop() {
    if (!this._cleanAnimationCompleted) {
      setTimeout(() => {
        this._cleanLoopRunning = false;
        this.cleanAnimation.immediatelyOpacity = 0.8;
        this.cleanAnimation.delayOpacity = 0.8;
        this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
        this.cleanAnimation.delayScale = { x: 1, y: 1 };
      }, 700);
    } else {
      this._cleanLoopRunning = false;
      this.cleanAnimation.immediatelyOpacity = 0.8;
      this.cleanAnimation.delayOpacity = 0.8;
      this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
      this.cleanAnimation.delayScale = { x: 1, y: 1 };
    }
  }


  build() {
    Row(){
      Stack() {
        Stack()
          .ripplesStyleClean()
          .opacity(this.cleanAnimation.immediatelyOpacity)
          .scale(this.cleanAnimation.immediatelyScale)
        Stack()
          .ripplesStyleClean()
          .opacity(this.cleanAnimation.delayOpacity)
          .scale(this.cleanAnimation.delayScale)
        Button(this.isCleaning ? "清空中..." : "清空", { type: ButtonType.Normal })
          .margin(2)
          .width(this.BUTTON_WIDTH)
          .height(this.BUTTON_HEIGHT)
          .backgroundColor(Color.Green)
          .borderRadius(this.BORDER_RADIUS)
          .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
          .onClick(() => {
            const now = Date.now();
            if (now - this._cleanLastClick < this.CLICK_INTERVAL) {
              return;
            }
            this._cleanLastClick = now;
            this.triggerVibration();
            this.clearForm();
          })
      }
      Stack() {
        Stack()
          .ripplesStyleSearch()
          .opacity(this.searchAnimation.immediatelyOpacity)
          .scale(this.searchAnimation.immediatelyScale)
        Stack()
          .ripplesStyleSearch()
          .opacity(this.searchAnimation.delayOpacity)
          .scale(this.searchAnimation.delayScale)
        Button(this.isSearching ? "查询中..." : "查询", { type: ButtonType.Normal })
          .margin(2)
          .width(this.BUTTON_WIDTH)
          .height(this.BUTTON_HEIGHT)
          .backgroundColor(Color.Blue)
          .borderRadius(this.BORDER_RADIUS)
          .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
          .onClick(() => {
            const now = Date.now();
            if (now - this._searchLastClick < this.CLICK_INTERVAL) {
              return;
            }
            this._searchLastClick = now;
            this.triggerVibration();
            this.queryForm();
          })
      }
    }
    .width("100%")
    .justifyContent(FlexAlign.SpaceEvenly)
    .margin({ top: 15 });
  }
}
