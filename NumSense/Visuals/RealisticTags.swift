import SwiftUI

// MARK: - 逼真商品价格吊牌 (Realistic Retail Price Tag)

/// 逼真的零售商品价格标签 (带穿绳孔与条形码)
struct RealisticPriceTagView: View {
    let text: String
    var caption: String = "PRICE"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            // 吊牌顶端穿绳打孔 (Brass Grommet & String)
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.5))
                        .frame(width: 8, height: 8)
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color(white: 0.9), Color(white: 0.5)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: 8, height: 8)
                }
                Spacer()
            }
            .padding(.top, 5)

            // 价格标题
            Text(caption)
                .font(.system(size: 8, weight: .bold, design: .default))
                .tracking(1.2)
                .foregroundStyle(.secondary)

            // 鲜明加粗价格金额
            Text(text)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Color(red: 0.85, green: 0.15, blue: 0.15))
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 6)

            // 底部模拟商品条形码 (Barcode)
            HStack(spacing: 2) {
                ForEach(0..<14, id: \.self) { i in
                    Rectangle()
                        .fill(Color.primary.opacity(i % 3 == 0 ? 0.7 : 0.35))
                        .frame(width: i % 4 == 0 ? 2 : 1, height: 8)
                }
            }
            .padding(.bottom, 6)
        }
        .frame(width: 86, height: 76)
        // 象牙白/浅牛皮纸吊牌底色
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.22) : Color(white: 0.97))
        )
        // 吊牌微边框
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.16), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) \(text)")
    }
}

// MARK: - 逼真高速公路里程碑 (Realistic Highway Milepost)

/// 逼真的公路绿色里程标杆 (如 MILE 2.4 或 MILE 180)
struct RealisticMilePostView: View {
    let text: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            // 顶端安装螺栓
            MountingBoltView(size: 4.5, hasSlot: true, slotAngle: 10)
                .padding(.top, 4)

            Text("MILE")
                .font(.system(size: 9, weight: .black, design: .default))
                .tracking(1.2)
                .foregroundStyle(.white)

            Spacer()

            Text(text)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.horizontal, 4)

            Spacer()

            // 底端安装螺栓
            MountingBoltView(size: 4.5, hasSlot: true, slotAngle: -50)
                .padding(.bottom, 4)
        }
        .frame(width: 68, height: 96)
        // 公路标准深绿
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.05, green: 0.42, blue: 0.20),
                            Color(red: 0.03, green: 0.32, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        // 内嵌白色细边
        .overlay {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.2)
                .padding(2.5)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.18), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Mile \(text)")
    }
}

// MARK: - 逼真折扣 / 小费百分比勋章 (Realistic Percentage Badge)

/// 逼真的折扣/小费徽章 (percent)
struct RealisticPercentBadgeView: View {
    let percent: Int
    var caption: String = "PERCENT"

    var body: some View {
        VStack(spacing: 1) {
            Text(caption)
                .font(.system(size: 8, weight: .bold, design: .default))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.9))
                .padding(.top, 6)

            Spacer()

            Text("\(percent)%")
                .font(.system(size: 28, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
                .padding(.horizontal, 6)

            Spacer()
        }
        .frame(width: 82, height: 68)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.95, green: 0.30, blue: 0.25),
                            Color(red: 0.80, green: 0.15, blue: 0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.35), lineWidth: 1.5)
                .padding(2.5)
        }
        .shadow(color: Color.red.opacity(0.25), radius: 3, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(percent) percent")
    }
}
