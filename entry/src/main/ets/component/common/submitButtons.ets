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

  @State isCleaning: boolean = false;
  @State isSearching: boolean = false;
  @State isSubmitting: boolean = false;

  private readonly BUTTON_WIDTH: string = '30%';
  private readonly BUTTON_HEIGHT: number = 44;
  private readonly BUTTON_CLICK_SCALE: number = 0.8;
  private readonly ANIMATION_DURATION: number = 1300;
  private readonly BORDER_RADIUS: number = 22;
  private readonly CLICK_INTERVAL = 800;

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

  // 统一动画控制方法
  private async playButtonAnimation(animationState: ButtonAnimationState, color: Color): Promise<void> {
    return new Promise<void>((resolve) => {
      // 立即开始动画
      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        curve: Curve.EaseInOut
      }, () => {
        animationState.immediatelyOpacity = 0;
        animationState.immediatelyScale = { x: 4, y: 4 };
      });

      // 延迟开始动画
      this.getUIContext().animateTo({
        duration: this.ANIMATION_DURATION,
        delay: 200,
        curve: Curve.EaseInOut
      }, () => {
        animationState.delayOpacity = 0;
        animationState.delayScale = { x: 4, y: 4 };
      });

      // 动画完成后重置
      setTimeout(() => {
        this.getUIContext().animateTo({
          duration: 300,
          curve: Curve.EaseOut
        }, () => {
          animationState.immediatelyOpacity = 0.8;
          animationState.delayOpacity = 0.8;
          animationState.immediatelyScale = { x: 1, y: 1 };
          animationState.delayScale = { x: 1, y: 1 };
          resolve();
        });
      }, this.ANIMATION_DURATION + 200);
    });
  }

  // 通用按钮样式
  @Builder
  RippleButton(content: string, isActive: boolean, color: Color,
    animationState: ButtonAnimationState, onClick: () => void) {
    Stack() {
      // 立即波纹层
      Stack()
        .width(this.BUTTON_WIDTH)
        .height(this.BUTTON_HEIGHT)
        .borderRadius(this.BORDER_RADIUS)
        .backgroundColor(color)
        .opacity(animationState.immediatelyOpacity)
        .scale(animationState.immediatelyScale)

      // 延迟波纹层
      Stack()
        .width(this.BUTTON_WIDTH)
        .height(this.BUTTON_HEIGHT)
        .borderRadius(this.BORDER_RADIUS)
        .backgroundColor(color)
        .opacity(animationState.delayOpacity)
        .scale(animationState.delayScale)

      // 按钮主体
      Button(isActive ? `${content}中...` : content, { type: ButtonType.Normal })
        .margin(2)
        .width(this.BUTTON_WIDTH)
        .height(this.BUTTON_HEIGHT)
        .backgroundColor(color)
        .borderRadius(this.BORDER_RADIUS)
        .clickEffect({ level: ClickEffectLevel.HEAVY, scale: this.BUTTON_CLICK_SCALE })
        .onClick(onClick)
    }
  }

  async clearForm(): Promise<void> {
    if (this.isCleaning) return;

    this.isCleaning = true;
    this.triggerVibration();

    // 播放动画并等待完成
    await this.playButtonAnimation(this.cleanAnimation, Color.Green);

    // 清空表单
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

    this.isCleaning = false;
  }

  async queryForm(): Promise<void> {
    if (this.isSearching) return;

    this.isSearching = true;
    this.triggerVibration();

    // 播放动画并等待完成
    await this.playButtonAnimation(this.searchAnimation, Color.Blue);

    prompt.showToast({
      message: '敬请期待！',
      duration: 1500
    });

    this.isSearching = false;
  }

  async submitForm(): Promise<void> {
    if (this.isSubmitting) return;

    // 表单验证
    if (!this.formData.packageName.trim()) {
      prompt.showToast({
        message: '请输入包名',
        duration: 2000
      });
      return;
    }

    if (!this.formData.appId.trim()) {
      prompt.showToast({
        message: '请输入app_id',
        duration: 2000
      });
      return;
    }

    this.isSubmitting = true;
    this.triggerVibration();

    // 播放动画
    const animationPromise = this.playButtonAnimation(this.submitAnimation, Color.Red);

    try {
      const pkg = this.formData.packageName.trim();
      const appId = this.formData.appId.trim();

      // 同时执行动画和提交，等待两者都完成
      await Promise.all([
        animationPromise,
        submit_app({
          pkg_name: pkg,
          app_id: appId,
          comment: {
            user: this.userName,
            note: this.formData.remark?.trim() || undefined
          }
        })
      ]);

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
      this.isSubmitting = false;
    }
  }

  private triggerVibration(): void {
    vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
      if (err) {
        console.error(`Failed to query effect. Code: ${err.code}, message: ${err.message}`);
        return;
      }
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
            }
          });
        } catch (tryError) {
          console.error(`An unexpected error occurred: ${tryError}`);
        }
      }
    });
  }

  build() {
    Row() {
      // 清空按钮
      this.RippleButton('清空', this.isCleaning, Color.Green, this.cleanAnimation, () => {
        const now = Date.now();
        if (now - this._cleanLastClick < this.CLICK_INTERVAL) return;
        this._cleanLastClick = now;
        this.clearForm();
      })

      // 查询按钮
      this.RippleButton('查询', this.isSearching, Color.Blue, this.searchAnimation, () => {
        const now = Date.now();
        if (now - this._searchLastClick < this.CLICK_INTERVAL) return;
        this._searchLastClick = now;
        this.queryForm();
      })

      // 提交按钮
      this.RippleButton('提交投稿', this.isSubmitting, Color.Red, this.submitAnimation, () => {
        const now = Date.now();
        if (now - this._submitLastClick < this.CLICK_INTERVAL) return;
        this._submitLastClick = now;
        this.submitForm();
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
    .margin({ top: 15 })
  }

  // 防止重复点击的时间戳记录
  private _cleanLastClick: number = 0;
  private _searchLastClick: number = 0;
  private _submitLastClick: number = 0;
}