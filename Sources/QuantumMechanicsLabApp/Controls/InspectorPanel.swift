import QuantumMechanicsLabCore
import SwiftUI

struct InspectorPanel: View {
    @Environment(AppModel.self) private var appModel
    var experiment: AnyExperiment
    var snapshot: SimulationSnapshot

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizedStringKey(experiment.title))
                        .font(.title2.weight(.bold))
                    Text(LocalizedStringKey(experiment.summary))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(2)
                    
                    if !experiment.explanation.isEmpty {
                        Text(LocalizedStringKey(experiment.explanation))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(12)
                            .background(Color.cyan.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                            .padding(.top, 4)
                    }
                }
                .padding(.bottom, 4)

                if !experiment.builtInPresets.isEmpty {
                    BuiltInPresetsSection(presets: experiment.builtInPresets)
                }

                ParameterSection()
                if !appModel.parameterIssues.isEmpty {
                    ParameterIssuesSection(issues: appModel.parameterIssues)
                }
                ExportSection(snapshot: snapshot)
                ObservablesSection(snapshot: snapshot)
                StorySection(story: experiment.story)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct BuiltInPresetsSection: View {
    @Environment(AppModel.self) private var appModel
    var presets: [ExperimentPreset]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Presets")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(presets) { preset in
                    Button {
                        appModel.loadPreset(preset)
                    } label: {
                        HStack {
                            Text(LocalizedStringKey(preset.name))
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.regular)
                    .tint(.cyan)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

private struct ExportSection: View {
    @Environment(AppModel.self) private var appModel
    var snapshot: SimulationSnapshot
    @State private var exportingJSON = false
    @State private var exportingCSV = false
    @State private var sharingConfig = false
    @State private var importingConfig = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export Data")
                .font(.headline)

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Button {
                        sharingConfig = true
                    } label: {
                        Label("Share Config", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(.cyan)

                    Button {
                        importingConfig = true
                    } label: {
                        Label("Import", systemImage: "square.and.arrow.down")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }

                HStack(spacing: 8) {
                    Button {
                        exportingJSON = true
                    } label: {
                        Label("JSON", systemImage: "doc.text.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if case .oneD = snapshot.grid {
                        Button {
                            exportingCSV = true
                        } label: {
                            Label("1D CSV", systemImage: "tablecells")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
        .fileExporter(
            isPresented: $exportingJSON,
            document: JSONSnapshotDocument(snapshot: snapshot),
            contentType: .json,
            defaultFilename: "snapshot_\(snapshot.experimentID).json"
        ) { _ in }
        .fileExporter(
            isPresented: $exportingCSV,
            document: CSVDataDocument(snapshot: snapshot),
            contentType: .commaSeparatedText,
            defaultFilename: "data_\(snapshot.experimentID).csv"
        ) { _ in }
        .fileExporter(
            isPresented: $sharingConfig,
            document: SharedConfigDocument(config: appModel.exportConfig()),
            contentType: .json,
            defaultFilename: "experiment_\(snapshot.experimentID).lab"
        ) { _ in }
        .fileImporter(
            isPresented: $importingConfig,
            allowedContentTypes: [.json, .content]
        ) { result in
            if case let .success(url) = result {
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    if let data = try? Data(contentsOf: url),
                       let config = try? JSONDecoder().decode(SharedExperimentConfig.self, from: data) {
                        appModel.importConfig(config)
                    }
                }
            }
        }
    }
}
private struct ParameterSection: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Parameters")
                    .font(.headline)
                Spacer()
                Button("Defaults") {
                    appModel.restoreDefaultParameters()
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            VStack(alignment: .leading, spacing: 16) {
                ForEach(appModel.parameters.indices, id: \.self) { index in
                    let parameter = appModel.parameters[index]
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(parameter.label)
                            Spacer()
                            Text(appModel.parameters[index].value, format: .number.precision(.fractionLength(2)))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }

                        Slider(
                            value: $appModel.parameters[index].value,
                            in: parameter.range,
                            onEditingChanged: { editing in
                                if !editing {
                                    appModel.applyParameterChange()
                                }
                            }
                        )
                    }

                    if index < appModel.parameters.count - 1 {
                        Divider()
                    }
                }

                if appModel.selectedExperimentID == "custom-potential" {
                    Divider()
                        .padding(.vertical, 2)
                    
                    HStack(spacing: 8) {
                        Button {
                            appModel.undoPotential()
                        } label: {
                            Label("Undo Draw", systemImage: "arrow.uturn.backward")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .disabled(!appModel.canUndoPotential)
                        
                        Button {
                            appModel.clearCustomPotential()
                        } label: {
                            Label("Clear", systemImage: "eraser")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

private struct ParameterIssuesSection: View {
    var issues: [ParameterIssue]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Parameter Check", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            ForEach(issues) { issue in
                Text(issue.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct ObservablesSection: View {
    var snapshot: SimulationSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Observables")
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                DiagnosticRow(label: "Norm", value: snapshot.observables.norm)
                if let expectedX = snapshot.observables.expectedX {
                    Divider()
                    DiagnosticRow(label: "<x>", value: expectedX)
                }
                if let expectedP = snapshot.observables.expectedP {
                    Divider()
                    DiagnosticRow(label: "<p>", value: expectedP)
                }
                if let deltaX = snapshot.observables.deltaX {
                    Divider()
                    DiagnosticRow(label: "Delta x", value: deltaX)
                }
                if let energy = snapshot.observables.totalEnergy {
                    Divider()
                    DiagnosticRow(label: "Energy", value: energy)
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

private struct DiagnosticRow: View {
    var label: String
    var value: Double

    var body: some View {
        HStack {
            Text(LocalizedStringKey(label))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value, format: .number.precision(.fractionLength(4)))
                .monospacedDigit()
                .foregroundStyle(.primary)
        }
        .font(.subheadline)
    }
}

private struct StorySection: View {
    var story: [StoryStep]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Story")
                .font(.headline)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(story.enumerated()), id: \.element.id) { index, step in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(step.title))
                            .font(.subheadline.weight(.semibold))
                        Text(LocalizedStringKey(step.body))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineSpacing(2)
                    }
                    if index < story.count - 1 {
                        Divider()
                    }
                }
            }
            .padding(14)
            .background(Color.white.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}
