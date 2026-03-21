import { arkWeb } from '../../component/arkWeb';
import {
  HdsSnackBar,
  SnackBarIconOptions,
  SnackBarMessageOptions,
  SnackBarOperationOptions,
  SnackBarOperationType,
  SnackBarStyleOptions
} from '@kit.UIDesignKit';
@Entry
@Component
struct AG {
  uiContext: UIContext = this.getUIContext();
  hdsSnackBar: HdsSnackBar = new HdsSnackBar(this.uiContext);
  icon: SnackBarIconOptions = {
    icon: $r('sys.symbol.exclamationmark_circle')
  }
  message: SnackBarMessageOptions = {
    title: "您正在访问友情链接站点",
    content: "该站点仅使用HmDashboard项目的数据库，网页内容与看板无关！",
  }
  operation: SnackBarOperationOptions = {
    operationType: SnackBarOperationType.TEXT_WITH_CLOSE,
  }
  style: SnackBarStyleOptions = {
    backgroundBlurStyle: BlurStyle.Thin,
    nextFocusId: 'button',
    duration: 7000
  }
  onPageShow(): void {
    setTimeout(() => {
      this.hdsSnackBar.show(this.icon, this.message, this.operation, this.style);
    },1000)
  }
  build() {
    Column() {
      arkWeb({
        url: 'https://appgallery.info/index.html',
        title: 'AppGallery 统计数据',
      }) }.width('100%').height('100%')
  }
}