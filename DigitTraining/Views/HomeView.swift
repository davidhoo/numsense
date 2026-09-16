import SwiftUI

struct HomeView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        NavigationStack {
            List {
                Section("开始训练") {
                    ForEach(DrillKind.allCases) { kind in
                        NavigationLink {
                            DrillView(kind: kind)
                        } label: {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(kind.title)
                                        .font(.headline)
                                    Text(kind.subtitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            } icon: {
                                Image(systemName: kind.systemImage)
                            }
                        }
                    }
                }

                Section("最近记录") {
                    if appModel.records.isEmpty {
                        Text("还没有完成过训练。")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(appModel.records.prefix(8)) { record in
                            RecordRow(record: record)
                        }
                    }
                }
            }
            .navigationTitle("数字训练")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("设置")
                }
            }
        }
    }
}

private struct RecordRow: View {
    let record: DrillRecord

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.kind.title)
                    .font(.headline)
                Text(record.finishedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(record.correctCount)/\(record.questionCount)")
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    HomeView()
        .environment(AppModel())
}
