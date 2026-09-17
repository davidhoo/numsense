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
            labeled("\(value.minutes ?? 0) min", caption: caption)
        case "calendar":
            CalendarCardView(value: value, emphasizeWeekday: question.emphasizeWeekday)
        case "price":
            labeled(Self.money(value.cents ?? 0), caption: caption)
        case "door":
            DoorPlateView(text: value.text ?? "", caption: caption)
        case "gate":
            GateSignView(letter: value.letter ?? "", number: value.number ?? 0)
        case "flight":
            labeled(value.text ?? "", caption: caption)
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
            labeled("\(value.percent ?? 0)%", caption: caption)
        case "temperature":
            TemperatureView(degrees: value.degrees ?? 0)
        case "weight":
            labeled(weightLabel, caption: weightCaption)
        case "fuelGallons":
            labeled(String(format: "%.1f gal", value.gallons ?? 0), caption: caption)
        case "fuelPrice":
            labeled("\(Self.money(value.cents ?? 0))/gal", caption: caption)
        case "miles":
            labeled(mileLabel, caption: caption)
        case "mph":
            SpeedoView(mph: value.mph ?? 0)
        case "psi":
            labeled("\(value.psi ?? 0) PSI", caption: caption)
        case "highway":
            HighwayShieldView(text: value.text ?? "")
        case "exit":
            labeled(value.text ?? "", caption: caption)
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
                AnalogClockFace(hour: hour24, minute: minute)
                    .frame(width: 84, height: 84)
            }
            Text(digital)
                .font(.system(size: settings.clockStyle == .digital ? 32 : 18, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.5)
                .lineLimit(1)
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
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - 2
            var face = Path()
            face.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
            context.stroke(face, with: .color(.primary), lineWidth: 2)

            for i in 0..<12 {
                let angle = Double(i) / 12 * .pi * 2 - .pi / 2
                let inner = radius * 0.82
                let outer = radius * 0.94
                var tick = Path()
                tick.move(to: CGPoint(x: center.x + cos(angle) * inner, y: center.y + sin(angle) * inner))
                tick.addLine(to: CGPoint(x: center.x + cos(angle) * outer, y: center.y + sin(angle) * outer))
                context.stroke(tick, with: .color(.primary), lineWidth: i % 3 == 0 ? 2.5 : 1)
            }

            let hourAngle = (Double(hour % 12) + Double(minute) / 60) / 12 * .pi * 2 - .pi / 2
            let minuteAngle = Double(minute) / 60 * .pi * 2 - .pi / 2
            drawHand(context: context, center: center, angle: hourAngle, length: radius * 0.5, width: 3.5)
            drawHand(context: context, center: center, angle: minuteAngle, length: radius * 0.72, width: 2)
            let cap = Path(ellipseIn: CGRect(x: center.x - 3, y: center.y - 3, width: 6, height: 6))
            context.fill(cap, with: .color(.primary))
        }
        .accessibilityLabel(Text("\(hour % 12 == 0 ? 12 : hour % 12):\(String(format: "%02d", minute))"))
    }

    private func drawHand(context: GraphicsContext, center: CGPoint, angle: Double, length: Double, width: CGFloat) {
        var path = Path()
        path.move(to: center)
        path.addLine(to: CGPoint(x: center.x + cos(angle) * length, y: center.y + sin(angle) * length))
        context.stroke(path, with: .color(.primary), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}

struct CalendarCardView: View {
    let value: SlotValue
    var emphasizeWeekday: Bool = false

    var body: some View {
        if emphasizeWeekday {
            VStack(spacing: 4) {
                Text("DAY")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(value.weekday ?? "—")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .textCase(.uppercase)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("\(monthName) \(value.day ?? 0)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } else {
            VStack(spacing: 2) {
                Text(monthName)
                    .font(.caption.weight(.semibold))
                    .textCase(.uppercase)
                Text("\(value.day ?? 0)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .monospacedDigit()
                if let weekday = value.weekday {
                    Text(String(weekday.prefix(3)).uppercased())
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.secondary.opacity(0.25))
                .frame(height: 10)
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .monospacedDigit()
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
    }
}

struct GateSignView: View {
    let letter: String
    let number: Int

    var body: some View {
        VStack(spacing: 2) {
            Text("GATE")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(letter)
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                Text("\(number)")
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }
        }
    }
}

struct HouseNumberView: View {
    let text: String
    var caption: String = "HOUSE"

    var body: some View {
        VStack(spacing: 6) {
            Text(caption)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .minimumScaleFactor(0.4)
                .lineLimit(1)
        }
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
        VStack(spacing: 4) {
            Text("MPH")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("\(mph)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
    }
}

struct HighwayShieldView: View {
    let text: String

    var body: some View {
        VStack(spacing: 6) {
            Text("I")
                .font(.caption.weight(.bold))
            Text(text)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 72, height: 72)
        .overlay {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(.primary, lineWidth: 2)
        }
    }
}
