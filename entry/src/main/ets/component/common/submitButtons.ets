import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { prompt } from '@kit.ArkUI';
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
  clearForm(): void {
    setTimeout(() => {
      this.isCleaning = false;
      this.stopCleanRippleLoop();
      prompt.showToast({
        message: '表单已清空',
        duration: 1500
      });
    }, 500)
  }

  queryForm(): void {
    setTimeout(() => {
      this.isSearching = false;
      this.stopSearchRippleLoop();
      prompt.showToast({
        message: '敬请期待！',
        duration: 1500
      });
    }, 500)
  }

  submitForm(): void {
    setTimeout(() => {
      this.isSubmitting = false;
      this.stopSubmitRippleLoop();
      prompt.showToast({
        message: '提交成功，感谢您的投稿！',
        duration: 1500
      });
    }, 500)

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
    this._cleanLoopRunning = false;
  }
  private startSearchRippleLoop() {
    if (this._searchLoopRunning) return;
    this._searchLoopRunning = true;

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
    this._searchLoopRunning = false;
  }
  private startSubmitRippleLoop() {
    if (this._submitLoopRunning) return;
    this._submitLoopRunning = true;

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
    this._submitLoopRunning = false;
  }

  build() {
    Row(){
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
        Button(this.isCleaning? '清空中...':'清空', { type: ButtonType.Normal })
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
            this.isCleaning = !this.isCleaning;

            if (this.isCleaning) {
              this.startCleanRippleLoop();
            } else {
              this.stopCleanRippleLoop();
            }
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
        Button(this.isSearching? '查询中...':'查询', { type: ButtonType.Normal })
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
            this.isSearching = !this.isSearching;

            if (this.isSearching) {
              this.startSearchRippleLoop();
            } else {
              this.stopSearchRippleLoop();
            }
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
        Button(this.isSubmitting? '提交中...':'提交投稿', { type: ButtonType.Normal })
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
            this.isSubmitting = !this.isSubmitting;

            if (this.isSubmitting) {
              this.startSubmitRippleLoop();
            } else {
              this.stopSubmitRippleLoop();
            }
          })

      }
    }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 15 })
  }
}