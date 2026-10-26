import type { UpdateLog } from '../../models/updateLogTypes';
import { curves } from '@kit.ArkUI';
import { hdsEffect } from '@kit.UIDesignKit';
import { pressLightFieldFilter, pressVisualEffect } from '../../ui/theme/visualEffects';

@Component
export struct UpdateLogCard {
    @Prop log: UpdateLog = { version: '', date: '', type: 'release', items: [] };
    @Prop animStep: number = 0;
    @Prop enterStep: number = 1;
    @State private pressed: boolean = false;

    build() {
        Column() {
            Row() {
                Column() {
                    Row() {
                        Text(this.log.version)
                            .fontSize(18)
                            .fontWeight(FontWeight.Medium)
                        if (this.log.isRelease) {
                            Text('正式版')
                                .fontSize(12)
                                .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                                .backgroundColor($r('app.color.v3_accent_orange'))
                                .fontColor($r('app.color.v3_surface'))
                                .borderRadius(6)
                                .margin({ left: 8 })
                        }
                    }
                    Text(this.log.date)
                        .fontSize(13)
                        .fontColor($r('app.color.v3_text_secondary'))
                        .margin({ top: 4 })
                }
            }
            Column({ space: 5 }) {
                ForEach(this.log.items, (item: string) => {
                    Row() {
                        Text('•')
                            .fontSize(16)
                            .fontWeight(600)
                            .fontColor($r('app.color.v3_text_secondary'))
                        Text(item)
                            .margin({ left: 5 })
                            .fontSize(15)
                            .lineHeight(20)
                            .flexShrink(1)
                    }
                    .justifyContent(FlexAlign.Start)
                    .width('100%')
                    .padding({ right: 5 })
                })
            }
            .margin({ top: 10 })
        }
        .padding(16)
        .borderRadius(16)
        .backgroundColor($r('app.color.background'))
        .shadow({ radius: 8, color: $r('app.color.v3_shadow'), offsetX: 0, offsetY: 2 })
        .width('90%')
        .margin({ bottom: 16 })
        .scale({ x: this.pressed ? 0.985 : 1, y: this.pressed ? 0.985 : 1 })
        .animation({ duration: 130, curve: curves.springMotion(0.35, 0.9) })
        .visualEffect(pressVisualEffect(this.pressed, hdsEffect.PointLightIlluminatedType.BORDER))
        .compositingFilter(pressLightFieldFilter(this.pressed))
        .onTouch((event: TouchEvent): void => {
            if (event.type === TouchType.Down) this.pressed = true;
            else if (event.type === TouchType.Up || event.type === TouchType.Cancel) this.pressed = false;
        })
        .opacity(this.animStep >= this.enterStep ? 1 : 0)
        .translate({ y: this.animStep >= this.enterStep ? 0 : 20 })
        .accessibilityGroup(true)
        .accessibilityText(`${this.log.version}，${this.log.date}，${this.log.isRelease ? '正式版，' : ''}${this.log.items.join('；')}`)
    }
}
