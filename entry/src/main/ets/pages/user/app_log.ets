import { router } from '@kit.ArkUI'

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
      version: 'V1.1.0-beta.1',
      date: '2025-12-?',
      isRelease: false,
      type:'beta',
      items: ['增加shareAbility接口，现在可以通过应用市场投稿app添加信息', '统一了所有web界面UA', '在我的界面增加了用户名，App更新日志，问题与反馈与使用教程界面', '将V1与V2页面合并，并重新设计导航条与按钮逻辑']
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

  build() {
    Column() {
      Stack() {
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
          .margin({top:100,bottom:20})
          .width('100%')
          .alignItems(HorizontalAlign.Center)
        }
        .width('100%')
        .height('100%')

        Column() {
          Column() { Text('\n').fontSize(14) }
          Row() {
            Text('App更新日志')
              .fontSize(23)
              .fontWeight(FontWeight.Bold)
              .margin({ left: 20 })

            Image($r('app.media.arrow_back'))
              .height(28)
              .width(28)
              .margin({ right: 25 })
              .onClick(() => router.back())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .height(55)

          Rect()
            .width('100%')
            .height(0.5)
            .fill($r('app.color.border'))
            .position({ x: 0, y: 87 })

        }
        .backgroundBlurStyle(BlurStyle.Thin)
        .position({ x: 0, y: 0 })
        .width('100%')
      }
      .backgroundColor($r('app.color.backcolor'))
    }
    .width('100%')
    .height('100%')
  }
}