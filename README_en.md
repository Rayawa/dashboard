# Application Dashboard (Gallery Dashboard)

### [中文README](https://github.com/Rayawa/dashboard/master/README.md) | [French README](https://github.com/Rayawa/dashboard/master/README_fr.md)

This project implements a mobile embedded dashboard page with navigation bar, menu controls, page loading status, and back-to-top animations based on ArkTS and ArkWeb WebView.

Core features include:
- WebView page loading, refresh, stop loading, back navigation
- Custom navigation bar (title + user entry + menu button)
- Top menu functions (back, refresh, stop refresh, back to top, page switching)
- Page loading progress bar
- Scroll monitoring and back-to-top animation effects
- Dark mode control
- DOM storage authorization and WebView related configurations

## ArkWeb Internal Sites: [V2 Site](https://hmos.txit.top/dashboard) | [V1 Site](http://shenjack.top:10003/dashboard)
Acknowledgments: [shenjack](https://github.com/shenjackyuanjie), [2b2ttianxiu]()

## Project Structure Summary

Main page file: `entry/src/main/ets/pages/Index.ets`

Resource files: `AppScope/resources/base/media` | `AppScope/resources/dark/media` (dark mode)

Core components:
- V2: Main Dashboard page component
- WebviewController: Used to control ArkWeb behaviors (refresh, stop, scroll, navigation, etc.)
- TopNavBar: Provides globally unified navigation bar visual style and functionality, displaying page title, user button, and menu bar over Gaussian blur. Enhances page immersion and aesthetics while maintaining global functionality.
- Menu: Unified management component for TopNavBar's menu bar, called using `.bindMenu(this.Menu)`, facilitating maintenance and content addition/removal.

## Feature Description

### 1. Top Navigation Bar

Contains:
- Page title (Application Dashboard)
- User icon (navigates to user page)
- Menu button (top right corner)

Navigation bar features:
- Fixed positioning
- Blurred background
- Layered distinction from content when scrolling

### 2. WebView Container

- `domStorageAccess(true)`: Allows DOM Storage
- `darkMode(this.mode)`: WebView follows application dark mode
- `forceDarkAccess(this.access)`: Forces dark mode
- `onPageBegin`: Loading starts
- `onProgressChange`: Updates progress bar
- `onPageEnd`: Loading completed
- `onScroll`: Records scroll distance

### 3. Top Progress Bar

Uses Progress component synchronized with loading progress.

### 4. Menu Functions

- Back: `backward()`
- Refresh/Stop Refresh: `refresh()` / `stop()`
- Back to top animation: `setInterval` + cubic easing
- Page switching: `router.pushUrl`

## State Field Description

`url`: Loading URL  
`mode`: Dark mode  
`access`: Force dark mode  
`isLoading`: Whether loading  
`progress`: Loading percentage  
`scrollY`: Scroll position  
`NAV_HEIGHT`: Navigation bar height

## Back to Top Animation Logic

easing = 1 - (1 - progress)\^3\
newY = startY \* (1 - easing)

60 frames animation, 8.33ms per frame.
