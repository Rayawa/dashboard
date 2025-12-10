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
    // prompt.showToast({
    //   message: '表单已清空',
    //   duration: 1500
    // });
    // setTimeout(()=>{
    //   this.isCleaning = false;
    // },500)
  }

  queryForm(): void {
    // prompt.showToast({
    //   message: '敬请期待！',
    //   duration: 1500
    // });
    // setTimeout(()=>{
    //   this.isSearching = false;
    // },500)
  }

  submitForm(): void {
    // setTimeout(()=>{
    //   this.isSubmitting = false;
    // },500)
    // prompt.showToast({
    //   message: '提交成功，感谢您的投稿！',
    //   duration: 3000
    // });
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

  private readonly BUTTON_WIDTH: string = '30%';
  private readonly BUTTON_HEIGHT: number = 44;
  private readonly BUTTON_CLICK_SCALE: number = 0.8;
  private readonly ANIMATION_DURATION: number = 1300;
  private readonly BORDER_RADIUS: number = 22;

  @State isCleaning: boolean = false;
  @State isSearching: boolean = false;
  @State isSubmitting: boolean = false;

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
                    if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                    else { console.info('Succeed in starting vibration'); }
                  });
                } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
              }
            });
            this.clearForm();
            this.isCleaning = !this.isCleaning;
            if (this.isCleaning) {
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut
              }, () => {
                this.cleanAnimation.immediatelyOpacity = 0;
                this.cleanAnimation.immediatelyScale = {
                  x: 4,
                  y: 4
                };
              })
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut,
                delay: 200
              }, () => {
                this.cleanAnimation.delayOpacity = 0;
                this.cleanAnimation.delayScale = {
                  x: 4,
                  y: 4
                };
              })
            } else {
              this.getUIContext().animateTo({ duration: 0 }, () => {
                this.cleanAnimation.immediatelyOpacity = 0.8;
                this.cleanAnimation.delayOpacity = 0.8;
                this.cleanAnimation.immediatelyScale = {
                  x: 1,
                  y: 1
                };
                this.cleanAnimation.delayScale = {
                  x: 1,
                  y: 1
                };
              })
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
                    if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                    else { console.info('Succeed in starting vibration'); }
                  });
                } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
              }
            });
            this.queryForm();
            this.isSearching = !this.isSearching;
            if (this.isSearching) {
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut
              }, () => {
                this.searchAnimation.immediatelyOpacity = 0;
                this.searchAnimation.immediatelyScale = {
                  x: 4,
                  y: 4
                };
              })
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut,
                delay: 200
              }, () => {
                this.searchAnimation.delayOpacity = 0;
                this.searchAnimation.delayScale = {
                  x: 4,
                  y: 4
                };
              })
            } else {
              this.getUIContext().animateTo({ duration: 0 }, () => {
                this.searchAnimation.immediatelyOpacity = 0.8;
                this.searchAnimation.delayOpacity = 0.8;
                this.searchAnimation.immediatelyScale = {
                  x: 1,
                  y: 1
                };
                this.searchAnimation.delayScale = {
                  x: 1,
                  y: 1
                };
              })
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
        Button(this.isSubmitting? '提交中...':'提交投稿', { type: ButtonType.Normal }) // 这里修正了文字显示
          .margin(2)
          .width(this.BUTTON_WIDTH)
          .height(this.BUTTON_HEIGHT)
          .backgroundColor(Color.Red)
          .borderRadius(this.BORDER_RADIUS)
          .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
          .onClick(() => {
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
                    if (error) { console.error(`Failed to start vibration. Code: ${error.code}, message: ${error.message}`); }
                    else { console.info('Succeed in starting vibration'); }
                  });
                } catch (tryError) { console.error(`An unexpected error occurred in try block: ${tryError}`); }
              }
            });
            this.submitForm()
            this.isSubmitting = !this.isSubmitting; // 这里修正了状态变量
            if (this.isSubmitting) {
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut
              }, () => {
                this.submitAnimation.immediatelyOpacity = 0;
                this.submitAnimation.immediatelyScale = {
                  x: 4,
                  y: 4
                };
              })
              this.getUIContext().animateTo({
                duration: this.ANIMATION_DURATION,
                iterations: -1,
                curve: Curve.EaseInOut,
                delay: 200
              }, () => {
                this.submitAnimation.delayOpacity = 0;
                this.submitAnimation.delayScale = {
                  x: 4,
                  y: 4
                };
              })
            } else {
              this.getUIContext().animateTo({ duration: 0 }, () => {
                this.submitAnimation.immediatelyOpacity = 0.8;
                this.submitAnimation.delayOpacity = 0.8;
                this.submitAnimation.immediatelyScale = {
                  x: 1,
                  y: 1
                };
                this.submitAnimation.delayScale = {
                  x: 1,
                  y: 1
                };
              })
            }
          })
      }
    }.width('100%').justifyContent(FlexAlign.SpaceBetween).margin({ top: 15 })
  }
}