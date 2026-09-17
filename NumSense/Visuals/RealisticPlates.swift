import SwiftUI

// MARK: - 酒店/商务高档门牌 (Realistic Door Plate)

/// 逼真的酒店/行政客房拉丝黄铜门牌
struct RealisticDoorPlateView: View {
    let text: String
    var caption: String = "ROOM"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 2) {
            // 顶端两枚四角广告固定螺栓
            HStack {
                StandoffBoltView(size: 5.5, isBrass: true)
                Spacer()
                StandoffBoltView(size: 5.5, isBrass: true)
            }
            .padding(.horizontal, 4)
            .padding(.top, 4)

            // 标牌标题 (如 ROOM / FLOOR，微阴刻雕刻效果)
            Text(caption)
                .font(.system(size: 9, weight: .bold, design: .default))
                .tracking(1.5)
                .foregroundStyle(Color(red: 0.35, green: 0.25, blue: 0.10))
                .shadow(color: .white.opacity(0.4), radius: 0, x: 0, y: 0.8)

            // 立体浮雕门牌房间号
            Text(text)
                .font(.system(size: 27, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color(red: 0.28, green: 0.20, blue: 0.08),
                            Color(red: 0.16, green: 0.10, blue: 0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // 浮雕微高光与微投影
                .shadow(color: .white.opacity(0.55), radius: 0, x: 0, y: 1.0)
                .shadow(color: .black.opacity(0.35), radius: 1.5, x: 0, y: 1.5)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            // 酒店门牌底部无障碍微盲文点装饰 (ADA Braille Dots)
            HStack(spacing: 3) {
                ForEach(0..<6, id: \.self) { _ in
                    Circle()
                        .fill(Color(red: 0.50, green: 0.38, blue: 0.18))
                        .frame(width: 2.0, height: 2.0)
                }
            }
            .padding(.top, 1)

            // 底端两枚四角广告固定螺栓
            HStack {
                StandoffBoltView(size: 5.5, isBrass: true)
                Spacer()
                StandoffBoltView(size: 5.5, isBrass: true)
            }
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .frame(width: 96, height: 78)
        // 拉丝黄铜板底座
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(RealisticMaterials.brushedBrass(isDark: colorScheme == .dark))
        )
        // 金属倒角外框
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.65), Color.black.opacity(0.35)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        // 沉头浮雕物理微投影
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.45 : 0.22), radius: 3.5, x: 0, y: 2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) \(text)")
    }
}

// MARK: - 欧美街区住宅门牌 (Realistic House Number)

/// 逼真的欧式复古深蓝搪瓷门牌 (French Enamel Street Plaque 风格)
struct RealisticHouseNumberView: View {
    let text: String
    var caption: String = "HOUSE"

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 1) {
            // 顶端两个安装固定孔螺丝
            HStack {
                MountingBoltView(size: 4.5, hasSlot: true, slotAngle: 15)
                Spacer()
                MountingBoltView(size: 4.5, hasSlot: true, slotAngle: -60)
            }
            .padding(.horizontal, 6)
            .padding(.top, 5)

            Spacer(minLength: 0)

            // 经典复古衬线门牌号码
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.35), radius: 1, x: 0, y: 1)
                .minimumScaleFactor(0.4)
                .lineLimit(1)

            Spacer(minLength: 0)

            // 底部两个安装固定孔螺丝
            HStack {
                MountingBoltView(size: 4.5, hasSlot: true, slotAngle: 45)
                Spacer()
                MountingBoltView(size: 4.5, hasSlot: true, slotAngle: -30)
            }
            .padding(.horizontal, 6)
            .padding(.bottom, 5)
        }
        .frame(width: 96, height: 76)
        // 搪瓷深蓝烤漆底色
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(RealisticMaterials.vintageEnamelNavy(isDark: colorScheme == .dark))
        )
        // 搪瓷双层内凹白色圆角边框
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.85), lineWidth: 1.5)
                .padding(3)
        }
        // 外沿细白圈
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.8)
        }
        // 墙面立体投影
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.5 : 0.25), radius: 4, x: 0, y: 2.5)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(caption) number \(text)")
    }
}
