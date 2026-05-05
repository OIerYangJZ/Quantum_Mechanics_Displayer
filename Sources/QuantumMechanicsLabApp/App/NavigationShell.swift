import QuantumMechanicsLabCore
import SwiftUI

struct NavigationShell: View {
    @Environment(AppModel.self) private var appModel

    @AppStorage("appLanguage") private var appLanguage: String = "system"

    var body: some View {
        NavigationSplitView {
            List {
                Picker("Language", selection: $appLanguage) {
                    Text("System").tag("system")
                    Text("English").tag("en")
                    Text("中文").tag("zh-Hans")
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 8)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 0, trailing: 16))

                ForEach(appModel.groupedExperiments, id: \.0) { category, experiments in
                    Section(category.title) {
                        ForEach(experiments) { experiment in
                            Button {
                                appModel.select(experiment)
                            } label: {
                                ExperimentRow(
                                    title: experiment.title,
                                    summary: experiment.summary,
                                    isSelected: experiment.id == appModel.selectedExperimentID
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("Experiments")
        } detail: {
            HStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    ExperimentViewport(snapshot: appModel.snapshot)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    TimelineControls()
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .shadow(color: .black.opacity(0.4), radius: 12, y: 6)
                        .padding(.bottom, 32)
                }

                InspectorPanel(
                    experiment: appModel.selectedExperiment,
                    snapshot: appModel.snapshot
                )
                .frame(width: 320)
                .background(.regularMaterial)
            }
            .background(Color(red: 0.05, green: 0.06, blue: 0.07))
            .navigationTitle(LocalizedStringKey(appModel.selectedExperiment.title))
        }
    }
}

private struct ExperimentRow: View {
    var title: String
    var summary: String
    var isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isSelected ? "atom" : "circle.dashed")
                .font(.title2)
                .foregroundStyle(isSelected ? .cyan : .secondary)
                .frame(width: 32)
                .symbolEffect(.pulse, options: .repeating, isActive: isSelected)

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedStringKey(title))
                    .font(.headline)
                    .foregroundStyle(isSelected ? .primary : .secondary)
                Text(LocalizedStringKey(summary))
                    .font(.caption)
                    .foregroundStyle(isSelected ? .secondary : .tertiary)
                    .lineLimit(2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(isSelected ? Color.cyan.opacity(0.12) : Color.clear)
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.cyan.opacity(0.3) : Color.clear, lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct ExperimentViewport: View {
    @Environment(AppModel.self) private var appModel
    var snapshot: SimulationSnapshot

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(red: 0.02, green: 0.025, blue: 0.03)

            GeometryReader { proxy in
                ZStack {
                    switch snapshot.grid {
                    case .oneD:
                        WavefunctionCanvas1D(snapshot: snapshot)
                    case let .twoD(grid):
                        MetalWavefunctionView2D(snapshot: snapshot)
                            .aspectRatio(CGFloat(grid.lengthX / grid.lengthY), contentMode: .fit)
                            .gesture(interactionGesture(size: proxy.size))
                    case .orbital:
                        MetalWavefunctionView2D(snapshot: snapshot)
                            .aspectRatio(1.0, contentMode: .fit)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            DebugOverlay(snapshot: snapshot)
                .padding()
        }
        .background(Color(red: 0.02, green: 0.025, blue: 0.03))
    }

    private func interactionGesture(size: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard size.width > 0, size.height > 0 else { return }
                if !appModel.isPlaying {
                    let hPos = value.location.x / size.width
                    let vPos = value.location.y / size.height
                    appModel.moveWavepacket(horizontalPosition: hPos, verticalPosition: vPos)
                }
            }
            .onEnded { value in
                guard size.width > 0, size.height > 0 else { return }
                let distance = hypot(value.translation.width, value.translation.height)
                if appModel.isPlaying && distance < 10 {
                    let hPos = value.location.x / size.width
                    let vPos = value.location.y / size.height
                    appModel.collapseWavefunction(horizontalPosition: hPos, verticalPosition: vPos)
                }
            }
    }
}
