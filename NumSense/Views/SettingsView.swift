import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel
    @State private var confirmDelete = false

    var body: some View {
        @Bindable var appModel = appModel
        Form {
            Section("Clock") {
                Picker("Style", selection: $appModel.settings.clockStyle) {
                    Text("Digital").tag(ClockStyle.digital)
                    Text("Analog").tag(ClockStyle.analog)
                }
                Picker("Hour format", selection: $appModel.settings.timeFormat) {
                    Text("12-hour").tag(TimeHourFormat.twelve)
                    Text("24-hour").tag(TimeHourFormat.twentyFour)
                }
            }
            Section("Session") {
                Picker("Length", selection: $appModel.settings.sessionLength) {
                    Text("8").tag(8)
                    Text("12").tag(12)
                    Text("20").tag(20)
                }
                Toggle("Play in Silent Mode", isOn: $appModel.settings.playInSilentMode)
            }
            Section("History") {
                Button("Delete all training history", role: .destructive) {
                    confirmDelete = true
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete all history?", isPresented: $confirmDelete) {
            Button("Delete", role: .destructive) { appModel.log.deleteAll() }
            Button("Cancel", role: .cancel) {}
        }
    }
}
