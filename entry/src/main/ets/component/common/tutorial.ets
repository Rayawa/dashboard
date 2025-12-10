import KnockShareGuideCard, { CardRes } from '../../common/KnockShareGuideCard';
import { vibrator } from '@kit.SensorServiceKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Component
export struct tutorial{
  @State handlePopupMenu: boolean = false;
  @State handlePopupShareMenu: boolean = false;
  @State handlePopupShareShare: boolean = false;
  @State handlePopupApi: boolean = false;
  @State handlePopupBack: boolean = false;
  @State handlePopupRefresh: boolean = false;
  @State handlePopupTop: boolean = false;
  @State handlePopupSwitch: boolean = false;
  @State handlePopupUser: boolean = false;
  @State handlePopupBackPage: boolean = false;
  private readonly cardSwiperResourcesPhone: CardRes[] = [
    {
      text: '对方手机需HarmonyOS 5及以上版本。',
      rawfilePrefix: 'knock_share_guide/knock_share_guide_phone_',
      framesCount: 128,
      startDelay: 50,
      stopDelay: 500,
    }]
  build() {
    Swiper() {
      // 欢迎页面
      Column() {
        Text('欢迎来到应用看板')
          .fontSize(24)
          .fontColor($r('app.color.diff_content'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: 20 })
        Text('本应用收集华为应用市场的公开数据，转化为直观的图表与报告。简单来说，您能在这里查看几乎所有鸿蒙应用的动态。\n\n' +
          ' 1. 数据总览与图表分析：\n   通过榜单、饼图与折线图，直观查看应用下载量、评分趋势与市场分布。\n\n' +
          ' 2. 搜索应用与查看详情：\n   支持按名称、评分等条件搜索排序，点击可查看应用详情与独立趋势图。\n\n' +
          ' 3. 数据定时自动更新：\n    后台每30分钟同步一次应用市场，确保您始终获取最新数据。\n\n' +
          ' 4. 交互式操作与分享：\n    点击图表可进行数据筛选，点击应用可进入详情页；您也可通过链接、隔空抓取或鸿蒙碰一碰便捷分享应用页面。\n\n' +
          ' 5. 投稿更新应用信息：\n    您可通过应用市场分享与“我的”页面向应用看板投稿，协助投稿新应用或更新应用信息。\n\n')
          .fontSize(14)
          .margin({ bottom: 10 })

        Text('重要提示：\n本应用的所有数据均来源于华为应用市场的公开信息，数据仅供参考，不保证来源的准确性、完整性和真实性。')
          .fontSize(16)
          .fontColor($r('app.color.diff_content'))
          .fontWeight(FontWeight.Medium)

      }.height('80%').width('95%').borderRadius(16).padding(20)
      // 主界面部分
      Column() {
        Text('主界面部分').fontSize(24).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
        Text('🚀 主要功能\n').fontSize(18).fontWeight(FontWeight.Bold)
        Column(){
          Text('• 数据统计 - 展示应用总数、元服务总数、开发者总数等关键指标的统计数据。\n').fontSize(14)
          Text('• 下载榜 - 提供下载量排名前20的应用列表，以及排除华为系应用后的下载量排名。\n').fontSize(14)
          Text('• 应用详情 - 点击任意应用相关图标查看应用的详细信息，包括下载量、评分、支持设备、版本信息等。\n').fontSize(14)
          Text('• 趋势分析 - 展示应用下载量的变化趋势和增量趋势图表。\n').fontSize(14)
          Text('• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选功能。\n').fontSize(14)
        }.alignItems(HorizontalAlign.Start)
        Text('📝 使用说明\n').fontSize(18).fontWeight(FontWeight.Bold)
        Column(){
          Text('• 刷新数据 - 点击“刷新数据”按钮获取最新数据\n').fontSize(14)
          Text('• 搜索应用 - 支持按名称、包名、开发者等搜索\n').fontSize(14)
          Text('• 快速筛选 - 点击组件可快速查看对应应用\n').fontSize(14)
          Text('• 排序功能 - 按评分、下载量、大小等排序\n').fontSize(14)
          Text('• 查看详情 - 点击应用行查看详细信息\n').fontSize(14)
          Text('• 过滤选项 - 可排除华为/元服务应用\n').fontSize(14)
        }.alignItems(HorizontalAlign.Start)

      }.height('80%').width('95%').borderRadius(16).padding(20)
      // 菜单栏
      Column() {
        Text('菜单栏').fontSize(24).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
        Text('* 点击图标以显示详情').fontSize(14).margin({ bottom: 10 }).fontColor(Color.Grey)
        Text('  1. 分享链接：在主页面或任意应用详情页点击分享按钮分享当前页面链接。\n').fontSize(14)
        Image($r('app.media.share')).width(28).height(28).margin({ bottom: 20 })
          .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
          });this.handlePopupShareMenu = !this.handlePopupShareMenu;})
          .bindPopup(this.handlePopupShareMenu, {
            message: '在主页面点击以分享当前页面链接',
            placement: Placement.Top,
            showInSubWindow: true,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.handlePopupShareMenu = false;
              }
            },
            transition: TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 500, curve: Curve.Ease })
                .combine(TransitionEffect.translate({ x: 0, y: 12 })),

              TransitionEffect.OPACITY
                .animation({ duration: 300, curve: Curve.EaseOut })
                .combine(TransitionEffect.translate({ x: 0, y: 12 }))
            )
          })
        Text('  2. 主界面按钮：主要用于操作网页内容，如返回上级、回到顶部、刷新与切换版本。\n' +
          '   按钮支持智感握姿功能，可根据您的握持姿势改变位置。').fontSize(14).margin({bottom:1})
        Text('    * 此功能当前仅支持部分机型。若设置菜单中存在“智感握姿”开关（可在“设置-系统”中查看），则表明该设备支持此功能。\n').fontSize(10).fontColor(Color.Grey)
        Row(){
          Image($r('app.media.arrow_back')).width(28).height(28)
            .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
            });this.handlePopupBack = !this.handlePopupBack;})
            .bindPopup(this.handlePopupBack, {
              message: '单击按钮以返回上一个网页',
              placement: Placement.Top,
              showInSubWindow: false,
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.handlePopupBack = false;
                }
              },
              transition: TransitionEffect.asymmetric(
                TransitionEffect.OPACITY
                  .animation({ duration: 500, curve: Curve.Ease })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 })),

                TransitionEffect.OPACITY
                  .animation({ duration: 300, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 }))
              )
            })
          Image($r('app.media.arrow_up')).width(28).height(28)
            .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
            });this.handlePopupTop = !this.handlePopupTop;})
            .bindPopup(this.handlePopupTop, {
              message: '单击按钮以回到顶部',
              placement: Placement.Top,
              showInSubWindow: false,
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.handlePopupTop = false;
                }
              },
              transition: TransitionEffect.asymmetric(
                TransitionEffect.OPACITY
                  .animation({ duration: 500, curve: Curve.Ease })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 })),

                TransitionEffect.OPACITY
                  .animation({ duration: 300, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 }))
              )
            })
          Image($r('app.media.refresh')).width(28).height(28)
            .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
            });this.handlePopupRefresh = !this.handlePopupRefresh;})
            .bindPopup(this.handlePopupRefresh, {
              message: '单击按钮以刷新当前网页',
              placement: Placement.Top,
              showInSubWindow: false,
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.handlePopupRefresh = false;
                }
              },
              transition: TransitionEffect.asymmetric(
                TransitionEffect.OPACITY
                  .animation({ duration: 500, curve: Curve.Ease })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 })),

                TransitionEffect.OPACITY
                  .animation({ duration: 300, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 }))
              )
            })
          Image($r('app.media.switch')).width(28).height(28)
            .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
            });this.handlePopupSwitch = !this.handlePopupSwitch;})
            .bindPopup(this.handlePopupSwitch, {
              message: '单击按钮以切换不同站点',
              placement: Placement.Top,
              showInSubWindow: false,
              onStateChange: (e) => {
                if (!e.isVisible) {
                  this.handlePopupSwitch = false;
                }
              },
              transition: TransitionEffect.asymmetric(
                TransitionEffect.OPACITY
                  .animation({ duration: 500, curve: Curve.Ease })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 })),

                TransitionEffect.OPACITY
                  .animation({ duration: 300, curve: Curve.EaseOut })
                  .combine(TransitionEffect.translate({ x: 0, y: 12 }))
              )
            })
        }.width('80%').justifyContent(FlexAlign.SpaceBetween).margin({ bottom: 20 })
        Text('  3. 我的页面：您的个人中心与一站式门户。\n' +
          '  您可以设置用户名、进行内容投稿、查看最新的更新日志、阅读API文档说明。\n' +
          '  同时，联系我们、使用教程和问题反馈也在我的页面中，确保您能随时获得所需的帮助与支持。\n').fontSize(14)
        Image($r('app.media.user')).width(28).height(28).margin({ bottom: 20 })
          .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
          });this.handlePopupUser = !this.handlePopupUser;})
          .bindPopup(this.handlePopupUser, {
            message: '在菜单栏点击以打开我的界面',
            placement: Placement.Top,
            showInSubWindow: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.handlePopupUser = false;
              }
            },
            transition: TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 500, curve: Curve.Ease })
                .combine(TransitionEffect.translate({ x: 0, y: 12 })),

              TransitionEffect.OPACITY
                .animation({ duration: 300, curve: Curve.EaseOut })
                .combine(TransitionEffect.translate({ x: 0, y: 12 }))
            )
          })
        Text('  4. 页面返回（不位于主页面时显示）：在其他界面点击时返回上一页。\n').fontSize(14)
        Image($r('app.media.arrow_back')).width(28).height(28)
          .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
          });this.handlePopupBackPage = !this.handlePopupBackPage;})
          .bindPopup(this.handlePopupBackPage, {
            message: '在菜单栏点击以返回上一个页面',
            placement: Placement.Top,
            showInSubWindow: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.handlePopupBackPage = false;
              }
            },
            transition: TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 500, curve: Curve.Ease })
                .combine(TransitionEffect.translate({ x: 0, y: 12 })),

              TransitionEffect.OPACITY
                .animation({ duration: 300, curve: Curve.EaseOut })
                .combine(TransitionEffect.translate({ x: 0, y: 12 }))
            )
          })
      }.height('80%').width('95%').borderRadius(16).padding(20)
      // 分享功能
      Column() {
        Text('分享功能').fontSize(24).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
        Text('* 目前分享功能仅支持手机设备').fontSize(14).margin({ bottom: 10 }).fontColor(Color.Grey)
        Text('  1. 链接分享：在主界面或任意应用详情页点击分享按钮分享当前页面链接。\n').fontSize(14)
        Image($r('app.media.share')).width(28).height(28).margin({ bottom: 20 })
          .onClick(() => {vibrator.isSupportEffect('haptic.effect.hard', (err: BusinessError, state: boolean) => {
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
          });this.handlePopupShareShare = !this.handlePopupShareShare;})
          .bindPopup(this.handlePopupShareShare, {
            message: '在主页面单击以分享当前页面链接',
            placement: Placement.Top,
            showInSubWindow: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.handlePopupShareShare = false;
              }
            },
            transition: TransitionEffect.asymmetric(
              TransitionEffect.OPACITY
                .animation({ duration: 500, curve: Curve.Ease })
                .combine(TransitionEffect.translate({ x: 0, y: 12 })),

              TransitionEffect.OPACITY
                .animation({ duration: 300, curve: Curve.EaseOut })
                .combine(TransitionEffect.translate({ x: 0, y: 12 }))
            )
          })
        Text('  2. 碰一碰分享：在任意界面使用碰一碰分享将当前页面链接分享给其他HarmonyOS设备。\n').fontSize(14)
        KnockShareGuideCard({ cardSwiperResources: this.cardSwiperResourcesPhone }).margin({ bottom: 20 })
        Text('  3. 隔空传送：在任意界面隔空传送将当前页面链接分享给其他HarmonyOS设备。\n').fontSize(14)
        Image($r('app.media.grasp')).width('70%').height(150).borderRadius(16).margin({ bottom: 10 }).borderWidth(1).borderColor($r('app.color.border'))
        Text('    * 使用前，请确保两台设备均在设置中开启“隔空传送”功能。\n' +
          '    * 当前版本仅支持从手机抓取内容并分享至其他手机、平板、PC或二合一设备，暂不支持从平板、PC或二合一设备发起抓取。').fontSize(10).fontColor(Color.Grey)
      }.height('80%').width('95%').borderRadius(16).padding(20)
      // 投稿功能
      Column() {
        Text('投稿功能').fontSize(24).fontColor($r('app.color.diff_content')).fontWeight(FontWeight.Bold).margin({ bottom: 20 })
        Text('  通过投稿功能可以实现App的抓取与更新，您可以通过投稿应用至应用看板来帮助我们获取新的App或更新App信息。\n').fontSize(14).margin({ bottom: 10 })
        Text('  您可以在“我的”界面里面设置您的用户名，初始用户名默认为机型型号。\n' +
          '  您的用户名将作为投稿作者标识，帮助我们准确记录并感谢您的每一次分享。\n').fontSize(14)
        Row(){Text('  投稿功能支持AI智能提取，将应用信息输入或粘贴进文本框即可自动提取！\n').fontSize(14).blendMode(BlendMode.DST_IN, BlendApplyType.OFFSCREEN)}
        .linearGradient({
          direction: GradientDirection.LeftBottom,
          colors: [[$r('app.color.gradient_start_color'), 0.0], [$r('app.color.gradient_end_color'), 1]]
        })
        .blendMode(BlendMode.SRC_OVER, BlendApplyType.OFFSCREEN)
        Row() {
          Column() {
            Text('1. 应用商店投稿：\n' +
              '  在任意App详情页点击分享并选择应用看板进行投稿。\n').fontSize(14).width('100%')
            Image($r('app.media.submit_store')).objectFit(ImageFit.Contain).borderRadius(16).margin({ bottom: 10 }).borderWidth(1).borderColor($r('app.color.border'))
          }.width('50%').padding(10)
          Column() {
            Text('2. 应用内投稿：\n' +
              '  在"我的"界面内投稿。\n\n').fontSize(14).width('100%')
            Image($r('app.media.submit_app')).objectFit(ImageFit.Contain).borderRadius(16).margin({ bottom: 10 }).borderWidth(1).borderColor($r('app.color.border'))
          }.width('50%').padding(10)

        }
        .width('100%')
        .height('44%')
        .justifyContent(FlexAlign.SpaceBetween)

      }.height('80%').width('95%').borderRadius(16).padding(20)
    }
    .loop(false)
    .effectMode(EdgeEffect.Spring)
    .margin({ top: 10, bottom: 10 })
    .width('90%')
    .borderRadius(20)
    .backgroundColor($r('app.color.backcolor'))
    .indicator(new DotIndicator()
      .itemWidth(6)
      .itemHeight(6)
      .selectedItemWidth(12)
      .selectedItemHeight(6)
      .color($r('sys.color.comp_background_secondary'))
      .selectedColor($r('sys.color.comp_background_emphasize')))
    .shadow({
      radius: 20,
      color: Color.Gray,
      offsetX: 0,
      offsetY: 4
    })
  }
}