import SwiftUI

// MARK: - 逼真机械胎压表 (Realistic Tire Pressure Gauge)

/// 逼真的圆形机械指针胎压表 (PSI)
struct RealisticTirePressureGaugeView: View {
    let psi: Int
    var diameter: CGFloat = 86

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. 金属外表圈
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(white: 0.70),
                            Color(white: 0.95),
                            Color(white: 0.65),
                            Color(white: 0.92),
                            Color(white: 0.70)
                        ],
                        center: .center
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.2), radius: 3.5, x: 0, y: 2.5)

            // 2. 凹陷表盘底板
            Circle()
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.96))
                .frame(width: diameter - 8, height: diameter - 8)

            // 3. 表盘三色安全/警告扇区圆弧 (Canvas 绘制)
            GaugeArcCanvas(psi: psi, radius: (diameter - 8) / 2, isDark: colorScheme == .dark)
                .frame(width: diameter - 8, height: diameter - 8)

            // 4. 数值文字与 "PSI" 铭牌
            VStack(spacing: 0) {
                Spacer()
                Text("\(psi)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))
                Text("PSI")
                    .font(.system(size: 8, weight: .bold, design: .default))
                    .tracking(1)
                    .foregroundStyle(.secondary)
                Spacer()
                    .frame(height: 6)
            }
            .frame(width: diameter - 8, height: diameter - 8)

            // 5. 玻璃微反光
            Circle()
                .fill(RealisticMaterials.glassHighlight)
                .frame(width: diameter - 8, height: diameter - 8)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(psi) PSI tire pressure gauge")
    }
}

private struct GaugeArcCanvas: View {
    let psi: Int
    let radius: CGFloat
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let arcRadius = radius * 0.76

            // 画低压黄、标准绿、高压红三色刻度环 (从 135° 到 405° 即顺时针 270 度)
            let startAngle: Double = .pi * 0.75
            let endAngle: Double = .pi * 2.25
            let totalSpan = endAngle - startAngle

            // 黄色区间 (0 ~ 26 PSI，对应前 30%)
            drawArc(context: context, center: center, radius: arcRadius, from: startAngle, to: startAngle + totalSpan * 0.32, color: .orange)
            // 绿色安全区间 (26 ~ 36 PSI，对应 32% ~ 70%)
            drawArc(context: context, center: center, radius: arcRadius, from: startAngle + totalSpan * 0.32, to: startAngle + totalSpan * 0.70, color: .green)
            // 红色过压区间 (>36 PSI，对应 70% ~ 100%)
            drawArc(context: context, center: center, radius: arcRadius, from: startAngle + totalSpan * 0.70, to: endAngle, color: .red)

            // 指针角度计算 (15 ~ 50 PSI 映射到整个圆弧)
            let clampedPsi = min(max(Double(psi), 15.0), 50.0)
            let progress = (clampedPsi - 15.0) / (50.0 - 15.0)
            let needleAngle = startAngle + totalSpan * progress

            // 指针真实落差阴影
            let shadowOffset = CGPoint(x: 1.2, y: 1.5)
            drawNeedle(context: context, center: CGPoint(x: center.x + shadowOffset.x, y: center.y + shadowOffset.y), angle: needleAngle, length: arcRadius * 0.95, color: .black.opacity(0.3))

            // 红色细指针本体
            drawNeedle(context: context, center: center, angle: needleAngle, length: arcRadius * 0.95, color: .red)

            // 中心金属铆钉圆盖
            let centerHub = Path(ellipseIn: CGRect(x: center.x - 3.5, y: center.y - 3.5, width: 7, height: 7))
            context.fill(centerHub, with: .color(isDark ? Color(white: 0.8) : Color(white: 0.25)))
        }
    }

    private func drawArc(context: GraphicsContext, center: CGPoint, radius: CGFloat, from: Double, to: Double, color: Color) {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: .radians(from), endAngle: .radians(to), clockwise: false)
        context.stroke(path, with: .color(color.opacity(0.85)), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
    }

    private func drawNeedle(context: GraphicsContext, center: CGPoint, angle: Double, length: CGFloat, color: Color) {
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
}

// MARK: - 逼真户外温度计表盘 (Realistic Thermometer View)

/// 逼真的室外圆形温度仪表盘 (°F)
struct RealisticThermometerView: View {
    let degrees: Int
    var diameter: CGFloat = 86

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            // 1. 金属外表圈
            Circle()
                .fill(
                    AngularGradient(
                        colors: [
                            Color(white: 0.72),
                            Color(white: 0.96),
                            Color(white: 0.68),
                            Color(white: 0.92),
                            Color(white: 0.72)
                        ],
                        center: .center
                    )
                )
                .frame(width: diameter, height: diameter)
                .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.2), radius: 3.5, x: 0, y: 2.5)

            // 2. 表盘底板
            Circle()
                .fill(colorScheme == .dark ? Color(white: 0.15) : Color(white: 0.96))
                .frame(width: diameter - 8, height: diameter - 8)

            // 3. 蓝红渐变冷暖环与指针 (Canvas)
            ThermometerArcCanvas(degrees: degrees, radius: (diameter - 8) / 2, isDark: colorScheme == .dark)
                .frame(width: diameter - 8, height: diameter - 8)

            // 4. 数字读数
            VStack(spacing: 0) {
                Spacer()
                Text("\(degrees)°F")
                    .font(.system(size: 19, weight: .heavy, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))
                Spacer()
                    .frame(height: 8)
            }
            .frame(width: diameter - 8, height: diameter - 8)

            // 5. 玻璃反光
            Circle()
                .fill(RealisticMaterials.glassHighlight)
                .frame(width: diameter - 8, height: diameter - 8)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(degrees) degrees Fahrenheit")
    }
}

private struct ThermometerArcCanvas: View {
    let degrees: Int
    let radius: CGFloat
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let arcRadius = radius * 0.76

            let startAngle: Double = .pi * 0.75
            let endAngle: Double = .pi * 2.25
            let totalSpan = endAngle - startAngle

            // 蓝到橙红渐变弧
            var arcPath = Path()
            arcPath.addArc(center: center, radius: arcRadius, startAngle: .radians(startAngle), endAngle: .radians(endAngle), clockwise: false)
            let arcGradient = Gradient(colors: [.blue, .cyan, .orange, .red])
            context.stroke(
                arcPath,
                with: .conicGradient(arcGradient, center: center, angle: .radians(startAngle)),
                style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
            )

            // 温度指针 (-10°F ~ 110°F 映射到刻度盘)
            let clamped = min(max(Double(degrees), -10.0), 110.0)
            let progress = (clamped - (-10.0)) / (110.0 - (-10.0))
            let needleAngle = startAngle + totalSpan * progress

            // 投影
            let shadowOffset = CGPoint(x: 1.2, y: 1.5)
            drawNeedle(context: context, center: CGPoint(x: center.x + shadowOffset.x, y: center.y + shadowOffset.y), angle: needleAngle, length: arcRadius * 0.95, color: .black.opacity(0.3))

            // 指针
            drawNeedle(context: context, center: center, angle: needleAngle, length: arcRadius * 0.95, color: .red)

            // 轴心
            let centerHub = Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            context.fill(centerHub, with: .color(isDark ? Color(white: 0.8) : Color(white: 0.25)))
        }
    }

    private func drawNeedle(context: GraphicsContext, center: CGPoint, angle: Double, length: CGFloat, color: Color) {
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
    }
}

// MARK: - 逼真加油机发光显示屏 (Realistic Gas Pump Display)

/// 逼真的加油站油价 (fuelPrice) 或加油量 (fuelGallons) 显示屏
struct RealisticFuelPumpView: View {
    let mode: Mode
    let text: String

    enum Mode {
        case pricePerGallon
        case gallonsPumped
    }

    var body: some View {
        VStack(spacing: 3) {
            // 顶部标签 (如 REGULAR UNLEADED 或 GALLONS)
            HStack {
                Text(mode == .pricePerGallon ? "REGULAR" : "GALLONS")
                    .font(.system(size: 8, weight: .bold, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(mode == .pricePerGallon ? Color(red: 0.3, green: 0.95, blue: 0.4) : Color(red: 1.0, green: 0.75, blue: 0.2))
                Spacer()
                Text(mode == .pricePerGallon ? "$/GAL" : "PUMP")
                    .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)

            // 发光点阵 / 数码管数字
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(text)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundStyle(mode == .pricePerGallon ? Color(red: 0.2, green: 0.98, blue: 0.4) : Color(red: 1.0, green: 0.8, blue: 0.2))
                    .shadow(color: (mode == .pricePerGallon ? Color.green : Color.orange).opacity(0.45), radius: 3, x: 0, y: 0)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if mode == .pricePerGallon {
                    Text("⁹/₁₀")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundStyle(Color(red: 0.2, green: 0.98, blue: 0.4).opacity(0.85))
                }
            }
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(Color.black.opacity(0.85))
            .overlay {
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 6)
        }
        .frame(width: 92, height: 68)
        // 加油机深色金属外壳
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.25), Color(white: 0.12)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(mode == .pricePerGallon ? "\(text) dollars per gallon" : "\(text) gallons")
    }
}

// MARK: - 逼真机械秒表 / 计时器 (Realistic Timer View)

/// 逼真的机械倒计时秒表/计时器 (duration)
struct RealisticTimerView: View {
    let minutes: Int

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 秒表顶端金属发条按钮
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.85), Color(white: 0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 14, height: 4)

            ZStack {
                // 圆形秒表外圈
                Circle()
                    .fill(
                        AngularGradient(
                            colors: [
                                Color(white: 0.75),
                                Color(white: 0.95),
                                Color(white: 0.65),
                                Color(white: 0.92),
                                Color(white: 0.75)
                            ],
                            center: .center
                        )
                    )
                    .frame(width: 78, height: 78)

                // 凹陷表盘
                Circle()
                    .fill(colorScheme == .dark ? Color(white: 0.16) : Color(white: 0.96))
                    .frame(width: 70, height: 70)

                // 倒计时扇区与分钟刻度
                TimerDialCanvas(minutes: minutes, radius: 35, isDark: colorScheme == .dark)
                    .frame(width: 70, height: 70)

                // 中心文字
                VStack(spacing: 0) {
                    Text("\(minutes)")
                        .font(.system(size: 22, weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .foregroundStyle(colorScheme == .dark ? .white : Color(white: 0.1))
                    Text("MIN")
                        .font(.system(size: 8, weight: .bold, design: .default))
                        .tracking(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.22), radius: 3.5, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(minutes) minutes timer")
    }
}

private struct TimerDialCanvas: View {
    let minutes: Int
    let radius: CGFloat
    let isDark: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            // 画橙色计时流逝扇形高光 (0 ~ 60 分钟)
            let fraction = min(max(Double(minutes) / 60.0, 0.05), 1.0)
            var wedge = Path()
            wedge.move(to: center)
            wedge.addArc(
                center: center,
                radius: radius * 0.88,
                startAngle: .radians(-.pi / 2),
                endAngle: .radians(-.pi / 2 + fraction * .pi * 2),
                clockwise: false
            )
            wedge.closeSubpath()
            context.fill(wedge, with: .color(Color.orange.opacity(0.18)))

            // 刻度
            for i in 0..<12 {
                let angle = Double(i) / 12.0 * .pi * 2.0 - .pi / 2.0
                let inner = radius * 0.78
                let outer = radius * 0.90
                var tick = Path()
                tick.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                tick.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(tick, with: .color(isDark ? Color.white.opacity(0.5) : Color.black.opacity(0.35)), lineWidth: 1.2)
            }
        }
    }
}

// MARK: - 逼真电子称重屏幕 (Realistic Weight Scale Display)

/// 逼真的超市/厨房电子秤读数屏幕 (weight)
struct RealisticWeightScaleView: View {
    let text: String
    var caption: String = "WEIGHT"

    var body: some View {
        VStack(spacing: 2) {
            HStack {
                Text(caption)
                    .font(.system(size: 8, weight: .bold, design: .default))
                    .tracking(1)
                    .foregroundStyle(Color.accentColor)
                Spacer()
                Text("NET")
                    .font(.system(size: 7, weight: .black, design: .monospaced))
                    .foregroundStyle(.green)
            }
            .padding(.horizontal, 8)
            .padding(.top, 5)

            Spacer()

            Text(text)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 6)

            Spacer()
        }
        .frame(width: 88, height: 66)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.15), radius: 2.5, x: 0, y: 1.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(text) \(caption)")
    }
}
