import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        Form {
            Section("题目") {
                Stepper(value: $appModel.settings.questionCount, in: 5...50, step: 5) {
                    LabeledContent("每轮题数", value: "\(appModel.settings.questionCount)")
                }
                Stepper(value: $appModel.settings.minOperand, in: 0...appModel.settings.maxOperand) {
                    LabeledContent("最小加数/减数", value: "\(appModel.settings.minOperand)")
                }
                Stepper(value: $appModel.settings.maxOperand, in: appModel.settings.minOperand...99) {
                    LabeledContent("最大加数/减数", value: "\(appModel.settings.maxOperand)")
                }
                Stepper(value: $appModel.settings.multiplicationMax, in: 2...20) {
                    LabeledContent("乘法上限", value: "\(appModel.settings.multiplicationMax)")
                }
            }

            Section("设备") {
                LabeledContent("目标系统", value: "iOS 27")
                LabeledContent("目标机型", value: "iPhone 17 Pro")
                Text("使用个人开发团队自动签名后，可直接安装到手机。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("设置")
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environment(AppModel())
    }
}
