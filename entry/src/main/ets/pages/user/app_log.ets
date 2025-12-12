import { LengthMetrics, router } from '@kit.ArkUI';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { HdsNavigation, HdsNavigationTitleMode, ScrollEffectType } from '@kit.UIDesignKit';

class UpdateLog {
  version: string = '';
  date: string = '';
  isRelease?: boolean = false;
  type: string = '';
  items: string[] = [];
}

@Entry
@Component
struct app_log {
  @State updateLogs: UpdateLog[] = [
    {
      version: 'V1.1.0-rc.1',
      date: '2025-12-13',
      isRelease: false,
      type:'beta',
      items: ['重新设计所有页面顶部条，添加渐变模糊效果',
        '为主界面按钮添加了显示/隐藏和拖动改变位置功能并简化主界面按钮',
        '为所有页面添加了返回逻辑',
        '投稿页面按钮新增波纹动效',
        '为所有页面的交互添加了振动',
        '修复了应用商店“填写信息投稿”自动填充识别功能的异常',
        '为“填写信息投稿”增加了自动关闭的功能'
      ]
    },
    {
      version: 'V1.1.0-beta.4',
      date: '2025-12-9',
      isRelease: false,
      type:'beta',
      items: ['为投稿应用功能增加AI识别能力',
        '完善了应用市场填写信息分享功能',
        '增加了主界面的按钮，并可以基于左右手判断',
        '更新了教程页面的文字与图片'
      ]
    },
    {
      version: 'V1.1.0-beta.3',
      date: '2025-12-7',
      isRelease: false,
      type:'beta',
      items: ['完成按已有信息投稿到看板',
        '在user页面用户名边增加弹窗信息',
        '增加投稿应用功能，并增加蒙版动画',
        '将联系我们界面写为弹窗',
        '修复文本错误与更新图表',
        '删除问题反馈界面并与重写的联系我们合并',
        '修复V2底部与web_log底部存在文字遮挡问题',
        '制作教程界面',
      ]
    },
    {
      version: 'V1.1.0-beta.2',
      date: '2025-12-7',
      isRelease: false,
      type:'beta',
      items: ['增加shareAbility接口，现在可以通过应用市场投稿app添加信息',
        '网页页面支持一键分享链接',
        '现在可以在任意界面发起分隔空抓取或碰一碰给其他鸿蒙设备',
        '统一了所有web界面UA',
        '在我的界面增加了用户名，App更新日志，问题与反馈与使用教程界面',
        '将V1与V2页面合并，并重新设计导航条与按钮逻辑，优化多处界面',
        '融入原生API组件']
    },
    {
      version: 'V1.0.0',
      date: '2025-12-1',
      isRelease: true,
      type:'Release',
      items: ['为备案链接跳转添加了弹窗二次提示', '增加备案信息']
    },

    {
      version: 'V1.0.0-rc1',
      date: '2025-11-29',
      isRelease: false,
      type:'rc',
      items: [
        '#9 fixed，链接现在可以以正常字体大小显示并成功跳转。考虑在rc2添加确认跳转弹窗' ,
        '#8 fixed，统一了全部页面的margin，新增加color.json重制并统一所有颜色' ,
        '修改同步版本与版本号' ,
        '更新UA&删除不必要文件@shenjackyuanjie' ,
        '重新修改了原user界面至settings界面使其更加美观' ,
        '对于TopNavBar的图标进行重新排列和更改，删除了原user内ArkWeb页面的非必要MenuItem',
        '新增数据同步功能'
      ]
    },
    {
      version: 'V1.0.0-beta.1',
      date: '2025-11-29',
      isRelease: false,
      type:'Beta',
      items: ['添加V1与V2的web界面', '添加了user界面', '添加了顶部导航条和menu']
    }
  ];
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
  build() {
    HdsNavigation() {
      Scroll(){
        Column() {
          ForEach(this.updateLogs, (log: UpdateLog) => {
            Column() {
              Row() {
                Column() {
                  Row() {
                    Text(log.version)
                      .fontSize(18)
                      .fontWeight(FontWeight.Medium)
                    if (log.isRelease) {
                      Text('正式版')
                        .fontSize(12)
                        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                        .backgroundColor('#FF6A39')
                        .fontColor('#fff')
                        .borderRadius(6)
                        .margin({ left: 8 })
                    }
                  }
                  Text(log.date)
                    .fontSize(13)
                    .fontColor('#999')
                    .margin({ top: 4 })
                }
              }
              Column({ space: 5 }) {
                ForEach(log.items, (item: string) => {
                  Row() {
                    Text('•')
                      .fontSize(16)
                      .fontWeight(600)
                      .fontColor('#666')
                    Text(item)
                      .margin({ left: 5 })
                      .fontSize(15)
                      .lineHeight(20)
                      .flexShrink(1)
                  }
                  .justifyContent(FlexAlign.Start)
                  .width('100%')
                  .padding({right:5})
                })
              }
              .margin({ top: 10 })
            }
            .padding(16)
            .borderRadius(16)
            .backgroundColor($r('app.color.background'))
            .shadow({
              radius: 8,
              color: '#1a000000',
              offsetX: 0,
              offsetY: 2
            })
            .width('90%')
            .margin({ bottom: 16 })
          })
        }
        .margin({top:60,bottom:20})
        .width('100%')
        .alignItems(HorizontalAlign.Center)
      }
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.backcolor'))
    }
    .navBarWidth('100%')
    .titleMode(HdsNavigationTitleMode.MINI)
    .titleBar({
      style: {
        scrollEffectOpts: {
          enableScrollEffect: true,
          scrollEffectType: ScrollEffectType.GRADIENT_BLUR,
          blurEffectiveStartOffset: LengthMetrics.vp(0),
          blurEffectiveEndOffset: LengthMetrics.vp(20)
        },
        originalStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
              subTitleColor: $r('sys.color.font_secondary')
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary')
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary')
            }
          }
        },
        scrollEffectStyle: {
          backgroundStyle: {
            backgroundColor: $r('sys.color.ohos_id_color_background_transparent'),
          },
          contentStyle: {
            titleStyle: {
              mainTitleColor: $r('sys.color.font_primary'),
              subTitleColor: $r('sys.color.font_secondary')
            },
            menuStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary')
            },
            backIconStyle: {
              backgroundColor: $r('sys.color.comp_background_tertiary'),
              iconColor: $r('sys.color.icon_primary')
            }
          }
        }
      },
      content: {
        title: {
          mainTitle: 'App更新日志',
        },
        backIcon:{
          action:() => {
            this.triggerVibration();
            router.back();
          }
        }
      }
    })

  }
}