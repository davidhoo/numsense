<p align="center">
  <img src="design/AppIcon-preview-rounded.png" width="128" height="128" alt="NumSense"><br/>
  <a href="https://developer.apple.com/ios/"><img src="https://img.shields.io/badge/Platform-iOS%2017.0%2B-007AFF?style=flat-square&logo=apple&logoColor=white" alt="iOS 17+"></a>
  <a href="https://swift.org"><img src="https://img.shields.io/badge/Swift-5.9%2B-F05138?style=flat-square&logo=swift&logoColor=white" alt="Swift 5.9+"></a>
  <a href="https://developer.apple.com/xcode/swiftui/"><img src="https://img.shields.io/badge/SwiftUI-Charts-FF5A00?style=flat-square&logo=swift&logoColor=white" alt="SwiftUI & Swift Charts"></a>
  <a href="https://elevenlabs.io"><img src="https://img.shields.io/badge/Audio-ElevenLabs%20Speech-black?style=flat-square" alt="ElevenLabs Speech"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-34C759?style=flat-square" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/Privacy-100%25%20Offline%20%2F%20Zero%20Tracking-blueviolet?style=flat-square" alt="100% Offline">
</p>

# NumSense · 数字语感

听一遍美式口语里的数字，当场当成信息留下来——几点、几号房、多少钱、哪个登机口。

英语数字常常“听得懂，转眼忘”，或者必须在脑子里先翻成中文才能反应。**NumSense** 专为重塑**直觉数字语感**而生：跳过脑内中文转译，把听到的数字直接映射为真实生活场景中的画面，专项锻炼听觉短时工作记忆与毫秒级直觉反应力。

本 App **不上架 App Store**，用个人 Apple ID 自签名即可装到任意 iPhone。主屏幕名称为「数字语感」，界面为英文。

---

## 界面预览

| 主界面 | 钟面时间直觉反应 | 复合场景分步识别 |
| :---: | :---: | :---: |
| <img src="docs/screenshots/01-home.png" width="240" alt="主界面" /> | <img src="docs/screenshots/02-practice-clock.png" width="240" alt="钟面时间直觉反应" /> | <img src="docs/screenshots/03-practice-multistep.png" width="240" alt="复合场景分步识别" /> |
| 极简开始与 7 天连续训练打卡 | 真实拟物表盘与物理指针映射 | 航班号与登机口多信息留存 |

| 即时纠错与原句对照 | 训练小结与心流节奏 | 多维语感长期趋势 |
| :---: | :---: | :---: |
| <img src="docs/screenshots/04-feedback.png" width="240" alt="即时纠错与原句对照" /> | <img src="docs/screenshots/05-summary.png" width="240" alt="训练小结与心流节奏" /> | <img src="docs/screenshots/06-stats.png" width="240" alt="多维语感长期趋势" /> |
| 黄铜质感门牌与原句对比回放 | 每题反应时柱状图与语感等级徽章 | 每日反应时曲线（直指 1.5s 目标） |

---

## 核心特性

- 🎙️ **ElevenLabs 真人级自然美音**：基于 ElevenLabs 录制的纯正自然美式口语，保留生活语速中的真实连读、弱读与吞音，带来原汁原味的声音输入。
- 🎨 **沉浸式拟物化视觉（Skeuomorphic Design）**：
  - **金属拉丝指针钟表**：金属表圈、精细刻度与立体阴影，建立时间听觉与表盘画面的直觉反射。
  - **黄铜复古门牌**：金属拉丝纹理、立体雕刻数字与固定螺栓，逼真还原酒店与公寓门牌。
  - **机场航显与导向标牌**：经典黑底明黄 LED 航班牌与悬挂式登机口标识牌。
  - **真实质感标价签**：棉绳穿孔、条形码与标签纹理，模拟真实收银与商超价签。
  - **公路与行车路牌**：美国州际公路盾形路标（Interstate Shields）与高速绿色出口导向牌。
  - **汽车仪表盘与测量表**：红针测速表（Speedometer）、水银温度计、弹簧圆盘体重秤、加油机计量屏与机械胎压表等。
- 🧠 **短时听觉工作记忆训练（Working Memory Retention）**：
  - 支持单句包含多重数字的复合场景（如“Flight 218, gate C 18”、区号+电话分段、日期+时间等）。
  - 音频播放后依次分步提问，深度锻炼听觉短时工作记忆，彻底摆脱“听到后面忘了前面”的痛点。
- ⚡️ **毫秒级反应时与语感三境界（Reaction Time & Speed Tiers）**：
  - 精确采集每次作答的反应毫秒数（Response Time），将语感能力科学量化：
    - ⚡️ **直觉神速（Reflex, < 1.5s）**：条件反射，不经中英转换的真正“英语思维”。
    - 🐇 **顺畅反应（Fluent, 1.5s - 2.5s）**：流利反应，偶有极轻微心智迟疑。
    - 🐢 **思考心译（Deliberate, > 2.5s）**：在脑内先翻译成中文，尚未形成直觉联结。
- 📊 **Swift Charts 多维语感深度洞察**：
  - **答题心流小结（Pace & Rhythm）**：单次训练后以柱状图逐题展现反应速度波动，标出中位数基准线与错题。
  - **每日速度下潜趋势（Daily Speed Trend）**：以 Catmull-Rom 平滑曲线追踪每日中位数反应时，直观见证突破 1.5s 直觉目标。
  - **语感四象限分析（Fluency Quadrants）**：将各场景按「速度 × 正确率」绘制分布图（直觉区、转译区、冲动区、超载区）。
  - **连续多步记忆衰减（Sequential Memory Decay）**：对比多步槽位（Slot 1 vs Slot 2+）的耗时与正确率，量化听觉遗忘曲线。
- 💬 **即时纠错与原文对照（Spoken Transcript Review）**：
  - 答对丝滑流转；答错即时高亮正确选项并播音复盘。每题答完后弹出原句对照（“What was said”），支持一键点击重新听音。
- 🔒 **100% 本地与隐私安全（Privacy-First）**：
  - 零网络权限请求、零第三方 SDK、无任何埋点统计；全部训练记录离线保存于本地，随时支持一键导出标准 JSON 与 CSV 明细。

---

## 9 大日常场景覆盖

| 场景 | 核心体验 | 经典听觉表达 |
| :--- | :--- | :--- |
| 🕒 **时间 (Time)** | 拟物钟表盘、分秒时钟 | *a quarter after three*, *eight forty-five*, *half past seven* |
| 📅 **日期 (Date)** | 日历台历与翻页便签 | *October twenty-third*, *July fourth*, *the second of May* |
| 💵 **金钱 (Money)** | 美式价签与收银小票 | *twelve dollars and fifty cents*, *two-fifty*, *ninety-nine cents* |
| 🚪 **房号 (Room)** | 黄铜酒店门牌、公寓门号 | *room four oh two*, *suite three twelve*, *room five twenty-one* |
| ✈️ **出行 (Travel)** | 机场航显屏、登机口标牌、高速 Exit 牌 | *flight two eighteen, gate C eighteen*, *take exit fourteen B* |
| 📞 **电话 (Phone)** | 分段式电话键位显示 | *eight hundred, five five five*, *area code four one five* |
| 🏠 **地址 (Address)** | 欧美街道门牌号 | *seven forty-two Evergreen Terrace*, *fifteen thirty-six Elm St* |
| ⚖️ **计量 (Measures)** | 汽车仪表速度计、水银温度计、圆盘体重秤、加油机、胎压表 | *sixty-five mph*, *seventy-two degrees*, *thirty-two psi* |
| 🔀 **复合 (Mixed)** | 跨场景多数字组合输入 | 多信息连续留存，检验工作记忆负荷下的高压直觉反应 |

---

## 训练节奏与方式

1. **听一段**：每次播放一句日常语速的美式英语。
2. **留一秒**：音频结束后停顿 1 秒，让大脑在没有视觉干扰的前提下留存声音信息。
3. **选画面**：呈现 2×2 真实拟物化选项；若单句包含多个数字，按先后顺序逐步考查。
4. **即时反馈**：点对立即进入下一步；点错会红绿对比标出正误，并提示原句音频与文字对照。
5. **轻松无负担**：单次训练推荐 8、12 或 20 题，碎片化 2~3 分钟即可完成一次高效语感神经突触强化。

---

## 在 iPhone 上自签名安装

只需一台 Mac 电脑、[Xcode 15+](https://developer.apple.com/xcode/) 以及一台运行 **iOS 17.0 或更高版本** 的 iPhone。使用个人的普通 Apple ID 即可，**无需购买任何付费苹果开发者账号**。

1. 用数据线将 iPhone 连接至 Mac，手机上弹出提示时选择「信任此电脑」。
2. 双击打开项目根目录下的 `NumSense.xcodeproj`。
3. 在 Xcode 顶部导航栏，Scheme 选 **NumSense**，目标设备选择你连接的 iPhone。
4. 在工程设置的 **Signing & Capabilities** 中，Team 选中你的个人 Apple ID 团队（勾选 *Automatically manage signing*）。
5. 点击 Xcode 左上角的 **▶ (Run)** 按钮开始构建并安装至手机。
6. 首次安装完成后，在手机上前往：**设置 → 通用 → VPN 与设备管理 → 开发者 App**，点击信任你的个人证书即可打开使用。

> [!TIP]
> 免费个人开发者证书有效期通常为 7 天，到期后重新用 Xcode 点击 Run 安装即可自动续期；若拥有付费 Apple Developer 账号，自签名有效期可长达 1 年。

---

## 开源协议

本项目基于 [MIT 许可证](LICENSE) 开源。
