# NumSense · 数字语感

自用 iOS App：练的是对**英语口语数字**的敏感与记忆——听一遍，直接当成信息留住（几点、几号房、多少钱），而不是先译成中文再记，也不是听懂转眼就忘的一串音。

覆盖日常场景：时间、钱、日期、房号、登机口、**重量、加油量、里程车速**等。作答用视觉选项（时钟、日历牌、门牌、秤、油泵），不是打字听写。

这是听力编码训练，不是口算，也不是背数字单词。界面英文。音频是日常语速的 Generic American，预生成后打进 App。**读法按美国人习惯手写进稿**（four oh two、two fifty、two and a half pounds、thirteen point two gallons），禁止把 `402` / `3:15` / `13.2` 丢给 TTS 逐位念。

产品说明：[docs/PRD.md](docs/PRD.md)  
题库 / 干扰项规则：[docs/content-inventory.md](docs/content-inventory.md)

## 目标环境

- Xcode 27 / iOS 27 SDK
- 真机：iPhone 17 Pro（iOS 27），自签名
- 签名：个人开发团队 Automatic Signing（`DEVELOPMENT_TEAM = XLDSS978CT`）
- Bundle ID：`david.numsense`
- 主屏幕名称：数字语感
- App 内标题：NumSense

## 一题怎么练

1. 只播一句，作答前不能重听。
2. 停 1 秒，再出 2×2 **图像**选项（钟、日历、门牌、登机口、价签等）。
3. 一句里有多个数字，就按顺序分步问；每步四个选项（1 个正确 + 3 个真实易错干扰）。
4. 答错：立刻标出正确图，并再播一遍（这是反馈，不算第二次得分）。
5. 每一次作答都记在本地，用于统计、错题复习，以及导出 JSON / CSV。

## 仓库现状

听力训练已经能跑：168 句手写美式读法、图像四选一、本地统计、错题复习、JSON/CSV 导出。音频用 macOS `say`（Samantha）预生成打进包里，约 2.3MB；以后可换成 ElevenLabs，题库稿不用改。

```bash
python3 scripts/build_catalog.py
python3 scripts/generate_audio.py
```

```
NumSense/
  App/ Content/ Audio/ Visuals/ Stats/ Views/
  Content/catalog.json
NumSenseTests/
scripts/build_catalog.py
scripts/generate_audio.py
docs/PRD.md
docs/content-inventory.md
```

## 在 iPhone 17 Pro 上自签名安装

1. USB 连接手机，首次信任这台电脑。
2. 打开 `NumSense.xcodeproj`，Scheme 选 **NumSense**，设备选你的 iPhone。
3. Signing 使用个人团队 `XLDSS978CT`。
4. Product → Run，或：

```bash
xcodebuild \
  -project NumSense.xcodeproj \
  -scheme NumSense \
  -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=XLDSS978CT \
  CODE_SIGN_STYLE=Automatic
```

5. 首次安装：设置 → 通用 → VPN 与设备管理 → 信任该开发者。

免费个人证书大约 7 天，到期后重新 Run 即可。付费 Apple Developer 账号可签一年。

> Bundle ID 从 `david.digit-training` 改为 `david.numsense` 后，真机上是新 App；旧安装里的本地统计不会自动带过来。

本机 Xcode 27 的 CoreSimulator 可能偏旧，指定模拟器名的 `test` 可能失败。编译检查用：

```bash
xcodebuild \
  -project NumSense.xcodeproj \
  -scheme NumSense \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```
