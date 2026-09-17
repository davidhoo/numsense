import SwiftUI

/// 各种逼真物理材质的渐变与颜色定义
enum RealisticMaterials {
    // MARK: - 金属质感 (Metals)

    /// 拉丝铝合金 / 银色金属 (横向或环形高光)
    static func brushedAluminum(isDark: Bool = false) -> LinearGradient {
        LinearGradient(
            colors: isDark ? [
                Color(white: 0.35),
                Color(white: 0.50),
                Color(white: 0.38),
                Color(white: 0.55),
                Color(white: 0.32)
            ] : [
                Color(white: 0.82),
                Color(white: 0.94),
                Color(white: 0.85),
                Color(white: 0.98),
                Color(white: 0.80)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 拉丝黄铜 / 贵金属 (用于酒店高档门牌)
    static func brushedBrass(isDark: Bool = false) -> LinearGradient {
        LinearGradient(
            colors: isDark ? [
                Color(red: 0.55, green: 0.42, blue: 0.18),
                Color(red: 0.72, green: 0.58, blue: 0.28),
                Color(red: 0.58, green: 0.45, blue: 0.20),
                Color(red: 0.78, green: 0.65, blue: 0.32),
                Color(red: 0.50, green: 0.38, blue: 0.15)
            ] : [
                Color(red: 0.76, green: 0.62, blue: 0.32),
                Color(red: 0.92, green: 0.81, blue: 0.52),
                Color(red: 0.82, green: 0.68, blue: 0.38),
                Color(red: 0.96, green: 0.86, blue: 0.58),
                Color(red: 0.72, green: 0.58, blue: 0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 公路反光金属铝板 (用于限速牌底板)
    static func reflectiveRoadSign(isDark: Bool = false) -> LinearGradient {
        LinearGradient(
            colors: isDark ? [
                Color(white: 0.82),
                Color(white: 0.90),
                Color(white: 0.85)
            ] : [
                Color(white: 0.96),
                Color(white: 1.00),
                Color(white: 0.94)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 欧式复古搪瓷深蓝 (用于住宅门牌)
    static func vintageEnamelNavy(isDark: Bool = false) -> LinearGradient {
        LinearGradient(
            colors: isDark ? [
                Color(red: 0.08, green: 0.16, blue: 0.32),
                Color(red: 0.12, green: 0.24, blue: 0.45),
                Color(red: 0.06, green: 0.12, blue: 0.28)
            ] : [
                Color(red: 0.10, green: 0.22, blue: 0.46),
                Color(red: 0.16, green: 0.32, blue: 0.60),
                Color(red: 0.08, green: 0.18, blue: 0.40)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// 弧形玻璃表层反光高光 (用于时钟罩)
    static var glassHighlight: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white.opacity(0.35), location: 0.0),
                .init(color: .white.opacity(0.08), location: 0.45),
                .init(color: .clear, location: 0.50),
                .init(color: .white.opacity(0.12), location: 0.90),
                .init(color: .clear, location: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - 逼真金属螺栓 (Mounting Bolt)

/// 标准公路路标 / 铭牌上的金属紧固螺栓
struct MountingBoltView: View {
    var size: CGFloat = 6.0
    var hasSlot: Bool = true
    var slotAngle: Double = 35.0

    var body: some View {
        ZStack {
            // 外圈深色沉头孔阴影
            Circle()
                .fill(Color.black.opacity(0.4))
                .frame(width: size + 1.2, height: size + 1.2)
                .offset(y: 0.5)

            // 螺栓金属圆头 (径向金属高光)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(white: 0.95),
                            Color(white: 0.70),
                            Color(white: 0.40)
                        ],
                        center: .init(x: 0.4, y: 0.35),
                        startRadius: 0.5,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // 螺丝刀十字/一字凹槽
            if hasSlot {
                Rectangle()
                    .fill(Color.black.opacity(0.65))
                    .frame(width: size * 0.65, height: max(1.0, size * 0.18))
                    .rotationEffect(.degrees(slotAngle))
            }
        }
    }
}

// MARK: - 广告固定螺钉 / 门牌黄铜铆钉 (Standoff Bolt)

/// 高档门牌四角使用的黄铜/镀铬圆柱形广告固定钉
struct StandoffBoltView: View {
    var size: CGFloat = 7.0
    var isBrass: Bool = true

    var body: some View {
        ZStack {
            // 边缘阴影
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: size + 1.5, height: size + 1.5)
                .offset(y: 0.6)

            // 铆钉主体
            Circle()
                .fill(
                    RadialGradient(
                        colors: isBrass ? [
                            Color(red: 0.98, green: 0.90, blue: 0.65),
                            Color(red: 0.85, green: 0.70, blue: 0.38),
                            Color(red: 0.55, green: 0.42, blue: 0.20)
                        ] : [
                            Color(white: 0.96),
                            Color(white: 0.75),
                            Color(white: 0.45)
                        ],
                        center: .init(x: 0.35, y: 0.35),
                        startRadius: 0.5,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // 中心微小沉孔
            Circle()
                .fill(Color.black.opacity(0.45))
                .frame(width: size * 0.3, height: size * 0.3)
        }
    }
}
