import { router } from '@kit.ArkUI'


@Entry
@Component
struct tutorial {
  build() {
    Column() {
      Stack() {
        Scroll() {
          Column({ space: 20 }) {

            // 数据来源
            Column() {
              Text('📊 数据来源说明')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('本看板数据收集自华为应用市场（AppGallery）公开API，数据仅供参考，不保证来源的准确性、完整性和真实性。')
                .fontSize(15)
                .fontColor($r('app.color.diff_content'))
                .lineHeight(22)
            }
            .width('95%')
            .borderRadius(16)
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor($r('app.color.diff_background'))

            // 主要功能
            Column() {
              Text('🚀 主要功能')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 数据概览 - 显示已爬取总数、应用总数、元服务总数、开发者总数')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 总下载榜 - 展示应用下载量排行榜')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 评分分布 - 显示应用评分的分布情况')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 非华为应用下载榜 - 展示非华为应用和内置应用的下载排行')
                .fontSize(15)
                .margin({ bottom: 4 })
              Text('• 应用列表 - 详细应用信息表格，支持搜索、排序、筛选')
                .fontSize(15)
            }
            .width('95%')
            .borderRadius(16)
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor($r('app.color.diff_background'))

            // 使用说明
            Column() {
              Text('📝 使用说明')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 刷新数据 - 点击“刷新数据”按钮获取最新数据')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 搜索应用 - 支持按名称、包名、开发者等搜索')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 快速筛选 - 点击开发者名称可快速查看其全部应用')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 排序功能 - 按多列（评分、下载量、大小等）排序')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 查看详情 - 点击应用行查看详细信息')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 过滤选项 - 可排除华为/元服务应用')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 分页浏览 - 使用底部分页控件查看更多应用')
                .fontSize(15)
            }
            .width('95%')
            .borderRadius(16)
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor($r('app.color.diff_background'))

            // 注意事项
            Column() {
              Text('⚠️ 注意事项')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('• 部分功能仍在开发中，可能出现数据不完整或bug')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 数据更新可能延迟，请以官方数据为准')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 应用详情页面仍在开发，部分数据可能错误')
                .fontSize(15).margin({ bottom: 4 })
              Text('• 按 ESC 可快速关闭弹窗')
                .fontSize(15)
            }
            .width('95%')
            .borderRadius(16)
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor($r('app.color.diff_background'))

            // 技术支持
            Column() {
              Text('🔧 技术支持')
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 6 })

              Text('如遇到问题或需要技术支持，请联系相关开发人员。')
                .fontSize(15)
                .fontColor($r('app.color.diff_content'))
                .lineHeight(22)
            }
            .width('95%')
            .borderRadius(16)
            .padding({ top: 12, bottom: 12, left: 12, right: 12 })
            .backgroundColor($r('app.color.diff_background'))

          }
          .margin({ top: 100, bottom: 20 })
          .width('100%')
        }
        .width('100%')
        .height('100%')

        Column() {
          Column() { Text('\n').fontSize(14) }
          Row() {
            Text('使用说明')
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