# 调试与发布签名配置

工程已配置 `default` 与 `release` 两个 product，分别绑定现有的 `debug` 与 `release` 签名方案。两个 product 均关联 `entry@default`，目标 API 26、最低兼容 API 20。

## 日常切换

| 用途 | Product | Build Mode | 签名方案 |
| --- | --- | --- | --- |
| 调试、真机运行 | `default` | `debug` | `debug` |
| 构建发布 APP | `release` | `release` | `release` |

### DevEco Studio

1. 修改配置后先同步项目。
2. 打开顶部工具栏的 **Product 配置**下拉，选择表格中对应的 **Product** 与 **Build Mode（构建模式）**，`entry` 的 Target 均选择 `default`，应用保存。
3. 日常调试选择 `default / debug` 后正常运行或调试；发布选择 `release / release`，通过 **Build → Build HAP(s)/APP(s) → Build APP(s)** 构建发布 APP。不同语言／版本的菜单名称可能略有差异。
4. 回到开发时，将两个选项切回 `default / debug`。

`buildMode=release` 只选择构建模式，不会自动更改 product 的签名方案；切换时应按表格同时选择两个值。

### 命令行

在项目根目录执行：

```sh
./scripts/build.sh debug    # default product + debug 模式，生成调试 HAP
./scripts/build.sh release  # release product + release 模式，生成已签名发布 APP
```

不传参数时默认构建调试 HAP。脚本只选择本次命令的构建参数，不更改 IDE 中的选择；同时固定 product、构建模式和任务，减少漏切配置的情况。脚本自动查找本机用户 Applications 或系统 Applications 下的 DevEco；其他安装位置可设置 `DEVECO_STUDIO_HOME`。

产物位置：

- 调试 HAP：`entry/build/default/outputs/default/entry-default-signed.hap`
- 发布 APP：`build/outputs/release/dashboard-HarmonyOS-release-signed.app`
- 发布 HAP：`entry/build/release/outputs/default/entry-default-signed.hap`

## 当前 product 配置

根目录 `build-profile.json5` 已保留现有 `signingConfigs` 与 `buildModeSet`，并将 `app.products` 设置为：

```json5
"products": [
  {
    "name": "default",
    "signingConfig": "debug",
    "targetSdkVersion": "26.0.0",
    "compatibleSdkVersion": "6.0.0(20)",
    "runtimeOS": "HarmonyOS",
    "buildOption": {
      "strictMode": {
        "caseSensitiveCheck": true,
        "useNormalizedOHMUrl": true
      }
    }
  },
  {
    "name": "release",
    "signingConfig": "release",
    "targetSdkVersion": "26.0.0",
    "compatibleSdkVersion": "6.0.0(20)",
    "runtimeOS": "HarmonyOS",
    "buildOption": {
      "strictMode": {
        "caseSensitiveCheck": true,
        "useNormalizedOHMUrl": true
      }
    }
  }
]
```

同一文件中，`modules` 下 `entry` 的 target 已关联到两个 product：

```json5
"modules": [{
  "name": "entry",
  "srcPath": "./entry",
  "targets": [{
    "name": "default",
    "applyToProducts": ["default", "release"]
  }]
}]
```

product、buildMode 和 signingConfig 是三个独立选择；这里让发布 product 与发布签名使用相同名称，便于识别。保留必需的 `default` product。

## 维护签名材料

打开 **File → Project Structure**，在 Project/Product 的签名设置中选择发布 product 对应的 `release` 签名方案，配置：

| 字段 | 材料 |
| --- | --- |
| `storeFile` | 与发布证书匹配的密钥库 `.p12` |
| `keyAlias` | 该密钥库内的实际密钥别名 |
| `storePassword`、`keyPassword` | 在 IDE 内输入对应密码，由 IDE 保存为密文 |
| `certpath` | AGC 申请的发布证书 `.cer` |
| `profile` | 与发布证书及 `top.rayawa.dashboard` 匹配的发布 Profile `.p7b` |
| `signAlg` | `SHA256withECDSA` |

现有方案使用 `dashboard.cer`、`dashboardRelease.p7b` 和 `Rayawa.p12`，本次沿用原有证书、私钥、别名与密码配置。发布 Profile 已核对为 `release` 类型，包名是 `top.rayawa.dashboard`，有效期至 2029-04-20 19:06:58（北京时间）。已有发布应用应沿用对应的发布身份，避免无意重新生成密钥。

签名文件继续放在仓库外。不要把真实密码或密钥复制到文档，也不要将示例占位值覆盖到有效签名方案中。已被 Git 跟踪的配置不会因加入 `.gitignore` 而停止跟踪；若需要移除仓库中的签名材料字段，应另行实现本地配置注入，保留公共的 product 与 SDK 配置。

## Hvigor 原始命令

在 DevEco 的构建配置中选择 **Product = release、Build Mode = release**，构建用于发布的 APP。

`scripts/build.sh release` 的等价示例（按实际位置修改 DevEco 路径）：

```sh
export DEVECO_STUDIO_HOME="$HOME/Applications/DevEco-Studio.app"
export NODE_HOME="$DEVECO_STUDIO_HOME/Contents/tools/node"
export JAVA_HOME="$DEVECO_STUDIO_HOME/Contents/jbr"
export DEVECO_SDK_HOME="$DEVECO_STUDIO_HOME/Contents/sdk"
"$DEVECO_STUDIO_HOME/Contents/tools/hvigor/bin/hvigorw" \
  --mode project -p product=release -p buildMode=release assembleApp --no-daemon
```

本仓库没有随项目提交 `hvigorw` 启动脚本，上例使用 DevEco 自带版本。

## 验证记录（2026-10-17）

- `./scripts/build.sh debug`：调试 HAP 构建及签名通过，包内 `app.debug = true`。
- `./scripts/build.sh release`：发布 HAP 与 APP 构建及签名通过，包内 `app.debug = false`。
- 发布 APP 已在本地生成；此次未上传 AGC，也未安装到手机。
- 保留现有的两个 Web 组件 2in1 API 警告，以及发布构建的“未启用混淆”提示；未改变混淆策略。

## 官方参考

- [工程级 build-profile 配置：签名材料、products 与 signingConfig](https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-hmos-hvigor-build-profile-app)
- [配置多目标产物：target 与 product 关联](https://developer.huawei.com/consumer/cn/doc/doccenter-deveco-studio/ide-hmos-customized-multi-targets-and-products-guides)
- [自定义构建示例：分别选择 product 与 buildMode](https://developer.huawei.com/consumer/cn/doc/HarmonyOS-Guides/ide-hmos-hvigor-compilation-options-customizing-sample)
