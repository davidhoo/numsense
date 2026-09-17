import SwiftUI

// MARK: - 真实美国州际公路盾形徽章 (Realistic Interstate Highway Shield)

struct InterstateShieldShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // 顶端左角 (略带微圆倒角)
        path.move(to: CGPoint(x: 0, y: h * 0.12))
        // 顶端上沿双弧冠 (中间微凹的经典州际盾冠)
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.08),
            control: CGPoint(x: w * 0.25, y: 0)
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: h * 0.12),
            control: CGPoint(x: w * 0.75, y: 0)
        )
        // 右侧向外微鼓并向下收拢至盾尖
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h),
            control: CGPoint(x: w * 0.98, y: h * 0.56)
        )
        // 左侧由盾尖向上收拢至顶端左角
        path.addQuadCurve(
            to: CGPoint(x: 0, y: h * 0.12),
            control: CGPoint(x: w * 0.02, y: h * 0.56)
        )
        path.closeSubpath()
        return path
    }
}

/// 逼真的美国州际公路标志牌 (如 I-95, I-80, I-280)
/// 严格参照 AASHTO / FHWA 标准：3位数字采用加宽盾牌，且数字排版在蓝色区域的最宽处，绝不超出路牌
struct RealisticHighwayShieldView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    private var isThreeDigits: Bool {
        text.count >= 3
    }

    // 遵循美国规范：3位数字采用加宽比例 (宽90, 高72)，1~2位采用标准比例 (宽78, 高72)
    private var shieldWidth: CGFloat {
        isThreeDigits ? 90 : 78
    }

    private var shieldHeight: CGFloat { 72 }

    var body: some View {
        ZStack {
            // 1. 白色外层反光宽边 (White Retroreflective Margin)
            InterstateShieldShape()
                .fill(Color.white)
                .frame(width: shieldWidth, height: shieldHeight)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.2), radius: 3.5, x: 0, y: 2)

            // 2. 盾牌主体内衬 (比外框收进 3pt)
            ZStack(alignment: .top) {
                // 下半部分经典州际公路蓝 (Interstate Blue)
                InterstateShieldShape()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.05, green: 0.25, blue: 0.58),
                                Color(red: 0.02, green: 0.16, blue: 0.44)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                // 上半部分经典州际红 (Interstate Red Crown)
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.12, blue: 0.15),
                                Color(red: 0.72, green: 0.08, blue: 0.10)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 22)
                    .mask(InterstateShieldShape())

                // 顶部 "INTERSTATE" 文字
                Text("INTERSTATE")
                    .font(.system(size: isThreeDigits ? 6.0 : 6.5, weight: .black, design: .default))
                    .tracking(0.6)
                    .foregroundStyle(.white)
                    .padding(.top, 8)

                // 公路编号：定位于蓝色区域最宽处 (y: 22 到 54 之间)，留足两侧安全边距，自适应缩放，绝不越界
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 22) // 避开上方红色冠部

                    Text(text)
                        .font(.system(size: isThreeDigits ? 20 : 25, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                        .lineLimit(1)
                        .minimumScaleFactor(0.4) // 遇到极端长文本自动缩放
                        .padding(.horizontal, isThreeDigits ? 10 : 8)
                        .frame(maxWidth: shieldWidth - 10)

                    Spacer(minLength: 4)
                }
            }
            .frame(width: shieldWidth - 6, height: shieldHeight - 6)
        }
        .frame(width: shieldWidth, height: shieldHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Interstate \(text) highway shield")
    }
}

// MARK: - 逼真高速公路出口指示牌 (Realistic Highway Exit Sign)

/// 逼真的北美高速公路出口绿色路牌 (如 EXIT 12B)
struct RealisticExitSignView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            // 顶端居中金属固定螺栓
            MountingBoltView(size: 4.5, hasSlot: true, slotAngle: 25)
                .padding(.top, 3)

            Text("EXIT")
                .font(.system(size: 10, weight: .black, design: .default))
                .tracking(1.5)
                .foregroundStyle(.white)

            Text(text)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 6)

            // 底端居中金属固定螺栓
            MountingBoltView(size: 4.5, hasSlot: true, slotAngle: -35)
                .padding(.bottom, 3)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .frame(width: 86, height: 72)
        // 高速公路标准反光深绿 (Highway Green)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.06, green: 0.44, blue: 0.22),
                            Color(red: 0.04, green: 0.35, blue: 0.16)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // 标牌内嵌白色安全边线 (Inscribed White Margin)
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.white.opacity(0.88), lineWidth: 1.5)
                .padding(3)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.18), radius: 3.5, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Exit \(text)")
    }
}

// MARK: - 逼真机场航班状态牌 (Realistic Flight Information Board)

/// 逼真的机场翻页式/数字航班显示牌 (如 UA 412)
struct RealisticFlightSignView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 顶栏：飞机起飞图标与 "FLIGHT" 标识
            HStack(spacing: 4) {
                Image(systemName: "airplane")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
                Text("FLIGHT")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.2))
            }
            .padding(.top, 6)

            Spacer()

            // 航班号主体 (带翻牌中央水平切分线效果)
            ZStack {
                Text(text)
                    .font(.system(size: 26, weight: .heavy, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .shadow(color: Color.yellow.opacity(0.2), radius: 3, x: 0, y: 0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 6)

                // 翻页牌中间的水平细缝与微阴影
                Rectangle()
                    .fill(Color.black.opacity(0.45))
                    .frame(height: 1)
            }

            Spacer()
        }
        .frame(width: 88, height: 68)
        // 哑光深空炭黑塑料外壳
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.20), Color(white: 0.10)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        // 凹陷内框
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Flight \(text)")
    }
}

// MARK: - 逼真机场登机口发光灯箱 (Realistic Airport Gate Sign)

/// 逼真的机场吸顶悬挂式发光指示灯箱
struct RealisticGateSignView: View {
    let letter: String
    let number: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 顶端天花板双悬挂金属吊杆
            HStack(spacing: 36) {
                Rectangle()
                    .fill(Color(white: 0.4))
                    .frame(width: 2.5, height: 6)
                Rectangle()
                    .fill(Color(white: 0.4))
                    .frame(width: 2.5, height: 6)
            }

            // 灯箱主体
            VStack(spacing: 3) {
                Text("GATE")
                    .font(.system(size: 9, weight: .bold, design: .default))
                    .tracking(2.0)
                    .foregroundStyle(Color(red: 1.0, green: 0.85, blue: 0.15))

                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(letter)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                    Text("\(number)")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .monospacedDigit()
                }
                .foregroundStyle(Color(red: 1.0, green: 0.88, blue: 0.20))
                // 模拟机场灯箱内部黄色荧光漫反射 (Soft Glow)
                .shadow(color: Color(red: 1.0, green: 0.8, blue: 0.1).opacity(0.65), radius: 5, x: 0, y: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minWidth: 92)
            // 黑色亚克力哑光金属灯箱外壳
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(white: 0.18), Color(white: 0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            )
            // 外框金属包边
            .overlay {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.black.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: .black.opacity(0.35), radius: 3.5, x: 0, y: 2)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Gate \(letter)\(number)")
    }
}
