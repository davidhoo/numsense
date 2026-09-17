import SwiftUI

struct SlotOptionCard: View {
    let value: SlotValue
    let settings: AppSettings
    var question: SlotQuestion = .generic
    var isSelected: Bool
    var verdict: Verdict?

    enum Verdict {
        case correct
        case wrong
        case revealed
    }

    var body: some View {
        SlotValueView(value: value, settings: settings, question: question)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(10)
            .background(background, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(border, lineWidth: verdict == nil ? 1 : 3)
            }
    }

    private var background: Color {
        switch verdict {
        case .correct, .revealed: Color.green.opacity(0.18)
        case .wrong: Color.red.opacity(0.16)
        case nil: Color(.secondarySystemBackground)
        }
    }

    private var border: Color {
        switch verdict {
        case .correct, .revealed: .green
        case .wrong: .red
        case nil: isSelected ? .accentColor : Color(.separator)
        }
    }
}

struct SlotValueView: View {
    let value: SlotValue
    let settings: AppSettings
    var question: SlotQuestion = .generic

    var body: some View {
        switch value.type {
        case "clock":
            ClockValueView(value: value, settings: settings, caption: caption)
        case "duration":
            RealisticTimerView(minutes: value.minutes ?? 0)
        case "calendar":
            CalendarCardView(value: value, emphasizeWeekday: question.emphasizeWeekday)
        case "price":
            RealisticPriceTagView(text: Self.money(value.cents ?? 0), caption: caption)
        case "door":
            DoorPlateView(text: value.text ?? "", caption: caption)
        case "gate":
            GateSignView(letter: value.letter ?? "", number: value.number ?? 0)
        case "flight":
            RealisticFlightSignView(text: value.text ?? "")
        case "phone":
            PhoneChunkView(
                text: value.text ?? "",
                caption: caption,
                groupIndex: question.phoneGroupIndex,
                groupCount: question.phoneGroupCount
            )
        case "address":
            HouseNumberView(text: value.text ?? "", caption: caption)
        case "zip":
            labeled(value.text ?? "", caption: caption)
        case "quantity":
            labeled("\(value.number ?? 0)", caption: caption)
        case "percent":
            RealisticPercentBadgeView(percent: value.percent ?? 0, caption: caption)
        case "temperature":
            RealisticThermometerView(degrees: value.degrees ?? 0)
        case "weight":
            RealisticWeightScaleView(text: weightLabel, caption: weightCaption)
        case "fuelGallons":
            RealisticFuelPumpView(mode: .gallonsPumped, text: String(format: "%.1f", value.gallons ?? 0))
        case "fuelPrice":
            RealisticFuelPumpView(mode: .pricePerGallon, text: String(format: "$%.2f", Double(value.cents ?? 0) / 100.0))
        case "miles":
            RealisticMilePostView(text: mileLabel)
        case "mph":
            SpeedoView(mph: value.mph ?? 0)
        case "psi":
            RealisticTirePressureGaugeView(psi: value.psi ?? 0)
        case "highway":
            HighwayShieldView(text: value.text ?? "")
        case "exit":
            RealisticExitSignView(text: value.text ?? "")
        default:
            labeled(value.text ?? "?", caption: caption)
        }
    }

    private var caption: String { question.cardCaption }

    private var weightCaption: String {
        caption == "WEIGHT" ? (value.unit ?? "lb").uppercased() : caption
    }

    private var weightLabel: String {
        let amount = value.amount ?? 0
        if amount == floor(amount) {
            return String(format: "%.0f %@", amount, value.unit ?? "lb")
        }
        return String(format: "%.1f %@", amount, value.unit ?? "lb")
    }

    private var mileLabel: String {
        let miles = value.miles ?? 0
        if miles == floor(miles) {
            return String(format: "%.0f", miles)
        }
        return String(format: "%.1f", miles)
    }

    private func labeled(_ text: String, caption: String) -> some View {
        VStack(spacing: 6) {
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 28, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
    }

    static func money(_ cents: Int) -> String {
        let sign = cents < 0 ? "-" : ""
        let abs = abs(cents)
        return String(format: "%@$%d.%02d", sign, abs / 100, abs % 100)
    }
}

struct ClockValueView: View {
    let value: SlotValue
    let settings: AppSettings
    var caption: String = "TIME"

    var body: some View {
        VStack(spacing: 8) {
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            if settings.clockStyle == .analog {
                RealisticAnalogClockFace(hour: hour24, minute: minute, diameter: 84)
                Text(digital)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .monospacedDigit()
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            } else {
                RealisticDigitalClockFace(text: digital, ampm: value.ampm)
            }
        }
    }

    private var hour24: Int { value.hour ?? 0 }
    private var minute: Int { value.minute ?? 0 }

    private var digital: String {
        let minute = minute
        if settings.timeFormat == .twentyFour {
            return String(format: "%02d:%02d", normalized24, minute)
        }
        let h12 = ((normalized24 + 11) % 12) + 1
        let base = String(format: "%d:%02d", h12, minute)
        if let ampm = value.ampm {
            return base + " " + ampm.uppercased()
        }
        return base
    }

    private var normalized24: Int {
        if let ampm = value.ampm {
            let h = hour24 % 12
            return ampm == "pm" ? (h == 0 ? 12 : h + 12) : (hour24 == 12 ? 0 : h)
        }
        return hour24
    }
}

struct AnalogClockFace: View {
    let hour: Int
    let minute: Int

    var body: some View {
        RealisticAnalogClockFace(hour: hour, minute: minute, diameter: 84)
    }
}

struct CalendarCardView: View {
    let value: SlotValue
    var emphasizeWeekday: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // 顶部红色挂头 + 双金属打孔
            HStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.9), Color(white: 0.4)],
                            center: .center,
                            startRadius: 0.5,
                            endRadius: 3
                        )
                    )
                    .frame(width: 5, height: 5)
                Spacer()
                Text(emphasizeWeekday ? "DAY" : monthName)
                    .font(.system(size: 11, weight: .bold, design: .default))
                    .foregroundStyle(.white)
                    .textCase(.uppercase)
                Spacer()
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(white: 0.9), Color(white: 0.4)],
                            center: .center,
                            startRadius: 0.5,
                            endRadius: 3
                        )
                    )
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(
                    colors: [Color(red: 0.88, green: 0.18, blue: 0.18), Color(red: 0.72, green: 0.10, blue: 0.12)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            // 日历白纸主体
            VStack(spacing: 2) {
                if emphasizeWeekday {
                    Text(value.weekday ?? "—")
                        .font(.system(size: 19, weight: .bold, design: .rounded))
                        .textCase(.uppercase)
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    Text("\(monthName) \(value.day ?? 0)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text("\(value.day ?? 0)")
                        .font(.system(size: 32, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primary)
                        .monospacedDigit()
                    if let weekday = value.weekday {
                        Text(String(weekday.prefix(3)).uppercased())
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(colorScheme == .dark ? Color(white: 0.2) : Color(white: 0.98))
        }
        .frame(width: 84, height: 84)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.black.opacity(0.12), lineWidth: 1)
        }
        .shadow(color: .black.opacity(colorScheme == .dark ? 0.4 : 0.18), radius: 3, x: 0, y: 2)
    }

    private var monthName: String {
        let months = ["", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        let m = value.month ?? 0
        guard months.indices.contains(m) else { return "—" }
        return months[m]
    }
}

struct DoorPlateView: View {
    let text: String
    var caption: String = "ROOM"

    var body: some View {
        RealisticDoorPlateView(text: text, caption: caption)
    }
}

struct GateSignView: View {
    let letter: String
    let number: Int

    var body: some View {
        RealisticGateSignView(letter: letter, number: number)
    }
}

struct HouseNumberView: View {
    let text: String
    var caption: String = "HOUSE"

    var body: some View {
        RealisticHouseNumberView(text: text, caption: caption)
    }
}

struct PhoneChunkView: View {
    let text: String
    var caption: String = "NUMBER"
    var groupIndex: Int?
    var groupCount: Int?

    var body: some View {
        VStack(spacing: 6) {
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            groupRow
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var groupRow: some View {
        if let groupIndex, let groupCount, groupCount >= 2 {
            HStack(spacing: 2) {
                if groupCount == 3 {
                    masked(0, width: 3, grouped: true)
                    masked(1, width: 3)
                    Text("-").foregroundStyle(.tertiary)
                    masked(2, width: 4)
                } else {
                    masked(0, width: 3)
                    Text("-").foregroundStyle(.tertiary)
                    masked(1, width: 4)
                }
            }
        } else {
            Text(grouped(text))
        }
    }

    private func masked(_ index: Int, width: Int, grouped: Bool = false) -> some View {
        let filled = index == groupIndex
        let raw = filled ? text : String(repeating: "•", count: width)
        let shown = grouped ? "(\(raw))" : raw
        return Text(shown)
            .fontWeight(filled ? .bold : .regular)
            .foregroundStyle(filled ? .primary : .tertiary)
    }

    private func grouped(_ text: String) -> String {
        if text.count == 10 {
            let chars = Array(text)
            return "\(String(chars[0..<3]))-\(String(chars[3..<6]))-\(String(chars[6...]))"
        }
        if text.count == 7 {
            let chars = Array(text)
            return "\(String(chars[0..<3]))-\(String(chars[3...]))"
        }
        return text
    }
}

struct TemperatureView: View {
    let degrees: Int

    var body: some View {
        VStack(spacing: 4) {
            Text("°F")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(degrees)")
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
    }
}

struct SpeedoView: View {
    let mph: Int

    var body: some View {
        RealisticSpeedSignView(mph: mph)
    }
}

struct HighwayShieldView: View {
    let text: String

    var body: some View {
        RealisticHighwayShieldView(text: text)
    }
}
