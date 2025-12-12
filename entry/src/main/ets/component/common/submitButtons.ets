import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { prompt } from '@kit.ArkUI';
import type { FormData } from '../../common/types';
import { submit_app } from '../../common/api';

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

@Component
export struct submitButtons {
  @StorageLink('userName') userName: string = ''
  @StorageLink('inputText') inputText: string = ''
  @StorageLink('formData') formData: FormData = {
    appLink: '',
    packageName: '',
    appId: '',
    remark: ''
  };

  async clearForm(): Promise<void> {
    if (this.isCleaning) {
      return;
    }

    this.isCleaning = true;
    this.startCleanRippleLoop();

    this.formData = {
      appLink: '',
      packageName: '',
      appId: '',
      remark: ''
    };
    this.inputText = '';

    prompt.showToast({
      message: '表单已清空',
      duration: 1500
    });

    setTimeout(() => {
      this.isCleaning = false;
      this.stopCleanRippleLoop();
    }, this.ANIMATION_DURATION + 200);
  }

  queryForm(): void {
    if (this.isSearching) {
      return;
    }

    this.isSearching = true;
    this.startSearchRippleLoop();

    setTimeout(() => {
      this.isSearching = false;
      this.stopSearchRippleLoop();
      prompt.showToast({
        message: '敬请期待！',
        duration: 1500
      });
    }, this.ANIMATION_DURATION + 200);
  }

  async submitForm(): Promise<void> {
    if (this.isSubmitting) {
      return;
    }

    if (!this.formData.packageName.trim()) {
      prompt.showToast({
        message: '请输入包名',
        duration: 2000
      });
      return;
    }

    this.isSubmitting = true;
    this.startSubmitRippleLoop();

    try {
      const pkg = this.formData.packageName.trim();
      const appId = this.formData.appId.trim();

      await submit_app({
        pkg_name: pkg,
        app_id: appId,
        comment: {
          user: this.userName,
          note: this.formData.remark?.trim() || undefined
        }
      });

      prompt.showToast({
        message: '提交成功，感谢您的投稿！',
        duration: 1500
      });

      this.formData = {
        appLink: '',
        packageName: '',
        appId: '',
        remark: ''
      };
      this.inputText = '';

    } catch (error) {
      console.error('提交失败:', error);
      prompt.showToast({
        message: '提交失败，请稍后重试',
        duration: 2000
      });
    } finally {
      setTimeout(() => {
        this.isSubmitting = false;
        this.stopSubmitRippleLoop();
      }, this.ANIMATION_DURATION + 200);
    }
  }

  private triggerVibration(): void {
    vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
      if (err) {
        console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
        return;
      }
      console.info('Succeed in querying effect');
      if (state) {
        try {
          vibrator.startVibration({
            type: 'preset',
            effectId: 'haptic.effect.hard',
            count: 1,
            intensity: 50,
          }, { usage: 'touch' }, (error: BusinessError) => {
            if (error) {
              console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`);
            } else {
              console.info('Succeed in starting vibration');
            }
          });
        } catch (tryError) {
          console.error(`An unexpected error occurred in try block: ${tryError}`);
        }
      }
    });
  }

  @State isCleaning: boolean = false;
  @State isSearching: boolean = false;
  @State isSubmitting: boolean = false;

  private readonly BUTTON_WIDTH: string = '30%';
  private readonly BUTTON_HEIGHT: number = 44;
  private readonly BUTTON_CLICK_SCALE: number = 0.8;
  private readonly ANIMATION_DURATION: number = 1300;
  private readonly BORDER_RADIUS: number = 22;
  private readonly CLICK_INTERVAL = 800;

  private _cleanAnimationCompleted: boolean = false;
  private _searchAnimationCompleted: boolean = false;
  private _submitAnimationCompleted: boolean = false;

  @Styles
  ripplesStyleClean() {
    .width(this.BUTTON_WIDTH)
    .height(this.BUTTON_HEIGHT)
    .borderRadius(this.BORDER_RADIUS)
    .backgroundColor(Color.Green)
  }

  @Styles
  ripplesStyleSearch() {
    .width(this.BUTTON_WIDTH)
    .height(this.BUTTON_HEIGHT)
    .borderRadius(this.BORDER_RADIUS)
    .backgroundColor(Color.Blue)
  }

  @Styles
  ripplesStyleSubmit() {
    .width(this.BUTTON_WIDTH)
    .height(this.BUTTON_HEIGHT)
    .borderRadius(this.BORDER_RADIUS)
    .backgroundColor(Color.Red)
  }

  @State cleanAnimation: ButtonAnimationState = {
    immediatelyOpacity: 0.8,
    immediatelyScale: { x: 1, y: 1 },
    delayOpacity: 0.4,
    delayScale: { x: 1, y: 1 }
  };

  @State searchAnimation: ButtonAnimationState = {
    immediatelyOpacity: 0.8,
    immediatelyScale: { x: 1, y: 1 },
    delayOpacity: 0.4,
    delayScale: { x: 1, y: 1 }
  };

  @State submitAnimation: ButtonAnimationState = {
    immediatelyOpacity: 0.8,
    immediatelyScale: { x: 1, y: 1 },
    delayOpacity: 0.4,
    delayScale: { x: 1, y: 1 }
  };

  private _cleanLoopRunning: boolean = false;
  private _searchLoopRunning: boolean = false;
  private _submitLoopRunning: boolean = false;

  private _cleanLastClick: number = 0;
  private _searchLastClick: number = 0;
  private _submitLastClick: number = 0;

  private startCleanRippleLoop() {
    if (this._cleanLoopRunning) return;
    this._cleanLoopRunning = true;
    this._cleanAnimationCompleted = false;

    const loop = () => {
      if (!this._cleanLoopRunning) return;

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        curve: Curve.EaseInOut
      }, () => {
        this.cleanAnimation.immediatelyOpacity = 0;
        this.cleanAnimation.immediatelyScale = { x: 4, y: 4 };
      });

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        delay: 200,
        curve: Curve.EaseInOut
      }, () => {
        this.cleanAnimation.delayOpacity = 0;
        this.cleanAnimation.delayScale = { x: 4, y: 4 };
      });

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
      }, this.ANIMATION_DURATION + 200);
    } else {
      this._cleanLoopRunning = false;
      this.cleanAnimation.immediatelyOpacity = 0.8;
      this.cleanAnimation.delayOpacity = 0.8;
      this.cleanAnimation.immediatelyScale = { x: 1, y: 1 };
      this.cleanAnimation.delayScale = { x: 1, y: 1 };
    }
  }

  private startSearchRippleLoop() {
    if (this._searchLoopRunning) return;
    this._searchLoopRunning = true;
    this._searchAnimationCompleted = false;

    const loop = () => {
      if (!this._searchLoopRunning) return;

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        curve: Curve.EaseInOut
      }, () => {
        this.searchAnimation.immediatelyOpacity = 0;
        this.searchAnimation.immediatelyScale = { x: 4, y: 4 };
      });

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        delay: 200,
        curve: Curve.EaseInOut
      }, () => {
        this.searchAnimation.delayOpacity = 0;
        this.searchAnimation.delayScale = { x: 4, y: 4 };
      });

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
      }, this.ANIMATION_DURATION + 200);
    } else {
      this._searchLoopRunning = false;
      this.searchAnimation.immediatelyOpacity = 0.8;
      this.searchAnimation.delayOpacity = 0.8;
      this.searchAnimation.immediatelyScale = { x: 1, y: 1 };
      this.searchAnimation.delayScale = { x: 1, y: 1 };
    }
  }

  private startSubmitRippleLoop() {
    if (this._submitLoopRunning) return;
    this._submitLoopRunning = true;
    this._submitAnimationCompleted = false;

    const loop = () => {
      if (!this._submitLoopRunning) return;

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        curve: Curve.EaseInOut
      }, () => {
        this.submitAnimation.immediatelyOpacity = 0;
        this.submitAnimation.immediatelyScale = { x: 4, y: 4 };
      });

      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        delay: 200,
        curve: Curve.EaseInOut
      }, () => {
        this.submitAnimation.delayOpacity = 0;
        this.submitAnimation.delayScale = { x: 4, y: 4 };
      });

      const total = this.ANIMATION_DURATION + 200 + 40;

      setTimeout(() => {
        this._submitAnimationCompleted = true;

        if (!this._submitLoopRunning) {
          this.submitAnimation.immediatelyOpacity = 0.8;
          this.submitAnimation.delayOpacity = 0.8;
          this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
          this.submitAnimation.delayScale = { x: 1, y: 1 };
          return;
        }

        this.submitAnimation.immediatelyOpacity = 0.8;
        this.submitAnimation.delayOpacity = 0.8;
        this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
        this.submitAnimation.delayScale = { x: 1, y: 1 };

        loop();
      }, total);
    };

    loop();
  }

  private stopSubmitRippleLoop() {
    if (!this._submitAnimationCompleted) {
      setTimeout(() => {
        this._submitLoopRunning = false;
        this.submitAnimation.immediatelyOpacity = 0.8;
        this.submitAnimation.delayOpacity = 0.8;
        this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
        this.submitAnimation.delayScale = { x: 1, y: 1 };
      }, this.ANIMATION_DURATION + 200);
    } else {
      this._submitLoopRunning = false;
      this.submitAnimation.immediatelyOpacity = 0.8;
      this.submitAnimation.delayOpacity = 0.8;
      this.submitAnimation.immediatelyScale = { x: 1, y: 1 };
      this.submitAnimation.delayScale = { x: 1, y: 1 };
    }
  }

  build() {
    Row() {
      // 清空按钮
      Stack() {
        Stack()
          .ripplesStyleClean()
          .opacity(this.cleanAnimation.immediatelyOpacity)
          .scale(this.cleanAnimation.immediatelyScale)
        Stack()
          .ripplesStyleClean()
          .opacity(this.cleanAnimation.delayOpacity)
          .scale(this.cleanAnimation.delayScale)
        Button(this.isCleaning ? '清空中...' : '清空', { type: ButtonType.Normal })
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

      // 查询按钮
      Stack() {
        Stack()
          .ripplesStyleSearch()
          .opacity(this.searchAnimation.immediatelyOpacity)
          .scale(this.searchAnimation.immediatelyScale)
        Stack()
          .ripplesStyleSearch()
          .opacity(this.searchAnimation.delayOpacity)
          .scale(this.searchAnimation.delayScale)
        Button(this.isSearching ? '查询中...' : '查询', { type: ButtonType.Normal })
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

      // 提交按钮
      Stack() {
        Stack()
          .ripplesStyleSubmit()
          .opacity(this.submitAnimation.immediatelyOpacity)
          .scale(this.submitAnimation.immediatelyScale)
        Stack()
          .ripplesStyleSubmit()
          .opacity(this.submitAnimation.delayOpacity)
          .scale(this.submitAnimation.delayScale)
        Button(this.isSubmitting ? '提交中...' : '提交投稿', { type: ButtonType.Normal })
          .margin(2)
          .width(this.BUTTON_WIDTH)
          .height(this.BUTTON_HEIGHT)
          .backgroundColor(Color.Red)
          .borderRadius(this.BORDER_RADIUS)
          .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
          .onClick(() => {
            const now = Date.now();
            if (now - this._submitLastClick < this.CLICK_INTERVAL) {
              return;
            }
            this._submitLastClick = now;
            this.triggerVibration();
            this.submitForm();
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: 15 })
  }
}