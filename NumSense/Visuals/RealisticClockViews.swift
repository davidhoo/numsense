import SwiftUI

/// 高保真拟物化机械挂钟
struct RealisticAnalogClockFace: View {
    let hour: Int
    let minute: Int
    var diameter: CGFloat = 88

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. 金属外表圈 (双层立体倒角拉丝效果)
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(white: 0.75),
                            Color(white: 0.95),
                            Color(white: 0.65),
                            Color(white: 0.92),
                            Color(white: 0.70),
                            Color(white: 0.95),
                            Color(white: 0.75)
                        ],
                        center: .center
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.22), radius: 4, x: 0, y: 3)

            // 2. 表盘内部凹陷过渡圈
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.black.opacity(0.4), Color.black.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 2
                )
                .frame(width: diameter - 4, height: diameter - 4)

            // 3. 表盘底板 (细腻暖白或暗夜哑光灰)
            Circle()
                .fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.96))
                .frame(width: diameter - 8, height: diameter - 8)

            // 4. 表盘刻度、指针与阴影
            ClockDialCanvas(
                hour: hour,
                minute: minute,
                radius: (diameter - 8) / 2,
                isDark: colorScheme == .dark
            )
            .frame(width: diameter - 8, height: diameter - 8)

            // 5. 表盘弧形玻璃高光反光 (Glass Glare)
            Circle()
                .fill(RealisticMaterials.glassHighlight)
                .frame(width: diameter - 8, height: diameter - 8)
                .allowsHitTesting(false)
        }
        .accessibilityLabel(Text("\(hour % 12 == 0 ? 12 : hour % 12):\(String(format: "%02d", minute))"))
    }
}

/// 负责高保真表盘刻度、立体投射指针阴影、以及指针本体的 Canvas 绘制
private struct ClockDialCanvas: View {
    let hour: Int
    let minute: Int
    let radius: CGFloat
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let markColor = isDark ? Color.white : Color(white: 0.12)
            let subMarkColor = isDark ? Color.white.opacity(0.4) : Color.black.opacity(0.35)

            // --- A. 刻度绘制 (60 分钟刻度 + 12 小时刻度) ---
            for i in 0..<60 {
                let angle = Double(i) / 60.0 * .pi * 2.0 - .pi / 2.0
                let isHourTick = i % 5 == 0
                let isQuarterTick = i % 15 == 0

                let innerDist = isQuarterTick ? radius * 0.74 : (isHourTick ? radius * 0.78 : radius * 0.88)
                let outerDist = radius * 0.92

                var path = Path()
                path.move(to: CGPoint(x: center.x + cos(angle) * innerDist, y: center.y + sin(angle) * innerDist))
                path.addLine(to: CGPoint(x: center.x + cos(angle) * outerDist, y: center.y + sin(angle) * outerDist))

                let strokeColor = isHourTick ? markColor : subMarkColor
                let width: CGFloat = isQuarterTick ? 2.5 : (isHourTick ? 1.8 : 0.9)
                context.stroke(path, with: .color(strokeColor), style: StrokeStyle(lineWidth: width, lineCap: .round))
            }

            // --- B. 指针角度计算 ---
            let hourNorm = Double(hour % 12) + Double(minute) / 60.0
            let hourAngle = hourNorm / 12.0 * .pi * 2.0 - .pi / 2.0
            let minuteAngle = Double(minute) / 60.0 * .pi * 2.0 - .pi / 2.0

            let hourLength = radius * 0.50
            let minuteLength = radius * 0.75
            let tailLength = radius * 0.14

            // --- C. 指针真实落差投影 (Shadow Cast on Dial) ---
            // 模拟顶部左侧光源：向右下方 (x: 1.5, y: 2.0) 投下半透明黑色阴影
            let shadowOffset = CGPoint(x: 1.5, y: 2.0)
            let shadowCenter = CGPoint(x: center.x + shadowOffset.x, y: center.y + shadowOffset.y)
            let shadowColor = Color.black.opacity(isDark ? 0.45 : 0.25)

            drawHand(context: context, center: shadowCenter, angle: hourAngle, length: hourLength, tail: tailLength, width: 3.2, color: shadowColor)
            drawHand(context: context, center: shadowCenter, angle: minuteAngle, length: minuteLength, tail: tailLength, width: 2.2, color: shadowColor)

            // --- D. 指针本体绘制 (深色表针带金属微质感) ---
            let handColor = isDark ? Color(white: 0.95) : Color(white: 0.10)
            drawHand(context: context, center: center, angle: hourAngle, length: hourLength, tail: tailLength, width: 3.2, color: handColor)
            drawHand(context: context, center: center, angle: minuteAngle, length: minuteLength, tail: tailLength, width: 2.2, color: handColor)

            // --- E. 中心金属同心铆钉固定帽 (Center Pin Cap) ---
            let pinOuter = Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7.0, height: 7.0))
            context.fill(pinOuter, with: .color(isDark ? .white : Color(white: 0.2)))

            let pinInner = Path(ellipseIn: CGRect(x: center.x - 1.5, y: center.y - 1.5, width: 3.0, height: 3.0))
            context.fill(pinInner, with: .color(isDark ? Color(white: 0.6) : Color(white: 0.85)))
        }
    }

    private func drawHand(context: GraphicsContext, center: CGPoint, angle: Double, length: CGFloat, tail: CGFloat, width: CGFloat, color: Color) {
        var path = Path()
        // 从尾部配重起点开始
        let tailX = center.x - cos(angle) * tail
        let tailY = center.y - sin(angle) * tail
        path.move(to: CGPoint(x: tailX, y: tailY))

        // 画到针尖
        let tipX = center.x + cos(angle) * length
        let tipY = center.y + sin(angle) * length
        path.addLine(to: CGPoint(x: tipX, y: tipY))

        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

// MARK: - 高保真液晶/电子时钟 (Realistic Digital Clock)

/// 仿真实液晶数显闹钟/车载时钟屏幕
struct RealisticDigitalClockFace: View {
    let text: String
    var ampm: String? = nil

    var body: some View {
        VStack(spacing: 3) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                // 主时间显示 (叠加微弱幽灵底纹)
                ZStack {
                    // 幽灵液晶底纹 (Ghost 88:88)
                    Text("88:88")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color.green.opacity(0.08))

                    // 真实点亮的液晶绿色发光数字
                    Text(timeOnly)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .monospacedDigit()
                        .foregroundStyle(Color(red: 0.2, green: 0.95, blue: 0.35))
                        .shadow(color: Color.green.opacity(0.45), radius: 4, x: 0, y: 0)
                }

                // AM / PM 状态标识
                if let ampmText = ampmFormatted {
                    Text(ampmText)
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.2, green: 0.95, blue: 0.35).opacity(0.85))
                        .offset(y: -4)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            // 凹陷液晶深色玻璃底座
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.10, blue: 0.06),
                            Color(red: 0.02, green: 0.05, blue: 0.03)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            // 凹陷内框高光
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.15), Color.black.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.25), radius: 2, x: 0, y: 1)
    }

    private var timeOnly: String {
        let parts = text.split(separator: " ")
        return String(parts.first ?? "")
    }

    private var ampmFormatted: String? {
        if let ampm { return ampm.uppercased() }
        let parts = text.split(separator: " ")
        if parts.count > 1 {
            return String(parts[1]).uppercased()
        }
        return nil
    }
}
