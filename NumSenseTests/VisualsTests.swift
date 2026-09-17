import Foundation
import Testing
import SwiftUI
@testable import NumSense

struct VisualsTests {
    @Test func realisticViewsInstantiateSuccessfully() {
        let settings = AppSettings.default

        // 1. Clock views (Analog & Digital)
        let analogClockValue = SlotValue(type: "clock", hour: 9, minute: 45)
        _ = SlotValueView(value: analogClockValue, settings: settings)

        var digitalSettings = settings
        digitalSettings.clockStyle = .digital
        _ = SlotValueView(value: analogClockValue, settings: digitalSettings)

        // 2. Speed sign
        let speedValue = SlotValue(type: "mph", mph: 65)
        _ = SlotValueView(value: speedValue, settings: settings)

        // 3. Room plate
        let doorValue = SlotValue(type: "door", text: "402")
        _ = SlotValueView(value: doorValue, settings: settings)

        // 4. House number
        let addressValue = SlotValue(type: "address", text: "1420")
        _ = SlotValueView(value: addressValue, settings: settings)

        // 5. Highway shields (2-digit & 3-digit wide shield)
        let highway2Digit = SlotValue(type: "highway", text: "80")
        _ = SlotValueView(value: highway2Digit, settings: settings)

        let highway3Digit = SlotValue(type: "highway", text: "280")
        _ = SlotValueView(value: highway3Digit, settings: settings)

        // 6. Gate sign & Flight sign
        let gateValue = SlotValue(type: "gate", letter: "C", number: 22)
        _ = SlotValueView(value: gateValue, settings: settings)

        let flightValue = SlotValue(type: "flight", text: "412")
        _ = SlotValueView(value: flightValue, settings: settings)

        // 7. Calendar
        let calendarValue = SlotValue(type: "calendar", month: 7, day: 4, weekday: "Friday")
        _ = SlotValueView(value: calendarValue, settings: settings)

        // 8. Exit sign & Milepost
        let exitValue = SlotValue(type: "exit", text: "12B")
        _ = SlotValueView(value: exitValue, settings: settings)

        let milesValue = SlotValue(type: "miles", miles: 180)
        _ = SlotValueView(value: milesValue, settings: settings)

        // 9. Meters & Gauges (PSI, Temp, Timer, Scale, Fuel)
        let psiValue = SlotValue(type: "psi", psi: 32)
        _ = SlotValueView(value: psiValue, settings: settings)

        let tempValue = SlotValue(type: "temperature", degrees: 72)
        _ = SlotValueView(value: tempValue, settings: settings)

        let durationValue = SlotValue(type: "duration", minutes: 25)
        _ = SlotValueView(value: durationValue, settings: settings)

        let weightValue = SlotValue(type: "weight", amount: 2.5, unit: "lb")
        _ = SlotValueView(value: weightValue, settings: settings)

        let fuelPriceValue = SlotValue(type: "fuelPrice", cents: 349)
        _ = SlotValueView(value: fuelPriceValue, settings: settings)

        let fuelGalValue = SlotValue(type: "fuelGallons", gallons: 13.2)
        _ = SlotValueView(value: fuelGalValue, settings: settings)

        // 10. Tags & Badges (Price, Percent)
        let priceValue = SlotValue(type: "price", cents: 1450)
        _ = SlotValueView(value: priceValue, settings: settings)

        let percentValue = SlotValue(type: "percent", percent: 20)
        _ = SlotValueView(value: percentValue, settings: settings)

        #expect(true)
    }
}
