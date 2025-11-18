# Dashboard (ArkTS + ArkWeb)

该项目基于 ArkTS 与 ArkWeb WebView
实现了一个带导航栏、菜单控制、页面加载状态与回到顶部动画的移动端嵌入式
Dashboard 页面。

核心功能包括： - WebView 页面加载、刷新、停止加载、返回 -
自定义导航栏（标题 + 用户入口 + 菜单按钮） -
顶部菜单功能（返回上级、刷新、停止刷新、回到顶部、页面切换） -
页面加载进度条 - 滚动监听与回到顶部的动画效果 - 深色模式控制 - DOM
存储授权与 WebView 相关配置

## 项目结构摘要

主要页面文件：

    entry/src/main/ets/pages/Index.ets

核心组件：

-   V2：Dashboard 主页面组件
-   WebviewController：用于控制 WebView
    的行为（刷新、停止、滚动、导航等）
-   自定义 Menu()：绑定到导航栏右侧菜单按钮

## 功能说明

### 1. 顶部导航栏

包含： - 页面标题（应用看板） - 用户图标（跳转到用户页面） -
菜单按钮（右上角）

导航栏具有： - 固定定位 - 模糊背景 - 滚动时与内容区分层

### 2. WebView 容器

-   domStorageAccess(true)：允许 DOM Storage
-   darkMode(this.mode)：WebView 跟随应用深色模式
-   forceDarkAccess(this.access)：强制深色模式
-   onPageBegin：开始加载
-   onProgressChange：更新进度条
-   onPageEnd：加载完毕
-   onScroll：记录滚动距离

### 3. 顶部进度条

使用 Progress 组件与加载进度联动。

### 4. 菜单功能

-   返回上级：backward()
-   刷新/停止刷新：refresh() / stop()
-   回到顶部动画：setInterval + cubic easing
-   切换页面：router.pushUrl

## 状态字段说明

url：加载网址\
mode：深色模式\
access：强制深色\
isLoading：是否加载中\
progress：加载百分比\
scrollY：滚动位置\
NAV_HEIGHT：导航栏高度

## 回到顶部动画逻辑

基于 cubic ease-out：

easing = 1 - (1 - progress)\^3\
newY = startY \* (1 - easing)

60 帧动画，每帧 8.33ms。

## License

MIT
