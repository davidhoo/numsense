import SwiftUI

/// 逼真的公路限速标牌 (参照北美 MUTCD R2-1 标准规制)
struct RealisticSpeedSignView: View {
    let mph: Int
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            // 标牌顶部固定金属螺栓
            MountingBoltView(size: 5.0, hasSlot: true, slotAngle: 30)
                .padding(.top, 4)

            VStack(spacing: 0) {
                Text("SPEED")
                    .font(.system(size: 11, weight: .black, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(.black)

                Text("LIMIT")
                    .font(.system(size: 11, weight: .black, design: .default))
                    .tracking(1.2)
                    .foregroundStyle(.black)
            }
            .padding(.top, 1)

            Spacer(minLength: 0)

            // 大号速度数字
            Text("\(mph)")
                .font(.system(size: 38, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Spacer(minLength: 0)

            // 标牌底部固定金属螺栓
            MountingBoltView(size: 5.0, hasSlot: true, slotAngle: -45)
                .padding(.bottom, 4)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .frame(width: 82, height: 110)
        // 铝合金微反光底板
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(RealisticMaterials.reflectiveRoadSign(isDark: colorScheme == .dark))
        )
        // 标牌内嵌黑色安全边框 (Margin Line)
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.black.opacity(0.88), lineWidth: 2)
                .padding(3)
        }
        // 标牌边缘极细微倒角光影
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5)
        }
        // 悬挂立体的微投影
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.16), radius: 3.5, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(mph) miles per hour speed limit sign")
    }
}
