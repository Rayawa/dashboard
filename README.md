# 应用看板 (Gallery Dashboard)

### [English README](https://github.com/Rayawa/dashboard/master/README_en.md) | [README Français](https://github.com/Rayawa/dashboard/master/README_fr.md)

该项目基于 ArkTS 与 ArkWeb WebView 实现了一个带导航栏、菜单控制、页面加载状态与回到顶部动画的移动端嵌入式 Dashboard 页面。

核心功能包括： - WebView 页面加载、刷新、停止加载、返回 -
自定义导航栏（标题 + 用户入口 + 菜单按钮） -
顶部菜单功能（返回上级、刷新、停止刷新、回到顶部、页面切换） -
页面加载进度条 - 滚动监听与回到顶部的动画效果 - 深色模式控制 - DOM
存储授权与 WebView 相关配置

## ArkWeb内网站：[V2站](https://hmos.txit.top/dashboard) ｜ [V1站](http://shenjack.top:10003/dashboard)
鸣谢：[shenjack](https://github.com/shenjackyuanjie)、[2b2ttianxiu]()

## 项目结构摘要

主要页面文件：`entry/src/main/ets/pages/Index.ets`

资源文件：`AppScope/resources/base/media` | `AppScope/resources/dark/media`（深色模式）

    

核心组件：

-   V2：Dashboard 主页面组件
-   WebviewController：用于控制ArkWeb行为为（刷新、停止、滚动、导航等）
-   TopNavBar：提供全局统一的导航栏视觉样式与功能，在高斯模糊之上显示页面标题，我的按钮和菜单栏。在保留全局功能的情况下增加页面沉浸感与美感。
-   Menu：TopNavBar的菜单栏统一管理组件，使用.bindMenu(this.Menu)调用，便于维护与增删内容。


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

easing = 1 - (1 - progress)\^3\
newY = startY \* (1 - easing)

60 帧动画，每帧 8.33ms。


