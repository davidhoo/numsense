# 数字训练

自用 iOS App：在 iPhone 上做加减乘混合口算训练。当前仓库是可编译、可安装的第一版框架，后续在 Cursor 里继续补训练模式和统计。

## 目标环境

- Xcode 27 / iOS 27 SDK
- 真机：iPhone 17 Pro（iOS 27）
- 签名：个人开发团队 Automatic Signing（`DEVELOPMENT_TEAM = XLDSS978CT`）
- Bundle ID：`david.digit-training`

## 工程结构

```
DigitTraining/           SwiftUI 应用
  App/                   入口与 AppModel
  Models/                题型、会话、设置
  Services/              出题引擎与本地记录
  Views/                 首页、练习、结果、设置
DigitTrainingTests/      出题引擎测试
DigitTraining.xcodeproj  Xcode 工程
```

## 在 iPhone 17 Pro 上自签名安装

1. 用 USB 连接手机，首次信任这台电脑。
2. 打开 `DigitTraining.xcodeproj`，左上角 Scheme 选 **DigitTraining**，设备选你的 iPhone 17 Pro。
3. Signing & Capabilities 里 Team 选已有的个人团队（工程里已写入 `XLDSS978CT`）。
4. 菜单 Product → Run，或：

```bash
xcodebuild \
  -project DigitTraining.xcodeproj \
  -scheme DigitTraining \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=XLDSS978CT \
  CODE_SIGN_STYLE=Automatic
```

5. 手机首次安装时：设置 → 通用 → VPN 与设备管理 → 信任该开发者。

免费个人证书安装有效期通常约 7 天，到期后重新 Run 一次即可。付费 Apple Developer 账号可签一年。

模拟器可先用 iPhone 17 Pro：

```bash
xcodebuild \
  -project DigitTraining.xcodeproj \
  -scheme DigitTraining \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  test
```

## 当前能力

- 加法、减法、乘法、混合运算
- 可调每轮题数和运算范围
- 本地保存最近训练记录（UserDefaults）

下一步可以加限时模式、错题本、数字辨认和更完整的统计页。
