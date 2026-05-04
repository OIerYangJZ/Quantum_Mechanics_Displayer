import Foundation
import Observation
import QuantumMechanicsLabCore

@MainActor
@Observable
final class AppModel {
    let experiments: [AnyExperiment]
    var selectedExperimentID: String
    var parameters: [ExperimentParameter]
    var snapshot: SimulationSnapshot
    var isPlaying = false
    var playbackSpeed = 1.0
    var presets: [ExperimentPreset] = []

    private let store: LocalProjectStore
    @ObservationIgnored private var simulationActor: SimulationActor

    init(experiments: [AnyExperiment] = ExperimentCatalog.all, store: LocalProjectStore = UserDefaultsProjectStore()) {
        self.experiments = experiments
        self.store = store

        var initialExperimentID: String?

        if let state = try? store.load() {
            self.presets = state.presets
            initialExperimentID = state.selectedExperimentID
        }

        let initialExperiment = experiments.first { $0.id == initialExperimentID } ?? experiments.first ?? AnyExperiment(InfiniteSquareWellExperiment())
        self.parameters = initialExperiment.defaultParameters
        let initialSnapshot = initialExperiment.makeInitialSnapshot(parameters: initialExperiment.defaultParameters)
        self.selectedExperimentID = initialExperiment.id
        self.snapshot = initialSnapshot
        self.simulationActor = AppModel.makeSimulationActor(snapshot: initialSnapshot, parameters: initialExperiment.defaultParameters)
    }

    var selectedExperiment: AnyExperiment {
        experiments.first { $0.id == selectedExperimentID } ?? experiments[0]
    }

    var parameterIssues: [ParameterIssue] {
        selectedExperiment.validate(parameters: parameters)
    }

    var groupedExperiments: [(ExperimentCategory, [AnyExperiment])] {
        ExperimentCategory.allCases.map { category in
            (category, experiments.filter { $0.category == category })
        }
    }

    func select(_ experiment: AnyExperiment) {
        selectedExperimentID = experiment.id
        parameters = experiment.defaultParameters
        snapshot = experiment.makeInitialSnapshot(parameters: parameters)
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
        isPlaying = false
        saveState()
    }

    func saveState() {
        let state = LocalProjectState(selectedExperimentID: selectedExperimentID, presets: presets)
        try? store.save(state)
    }

    func savePreset(name: String) {
        let preset = ExperimentPreset(
            experimentID: selectedExperimentID,
            name: name,
            parameters: parameters,
            customPotentialValues: snapshot.potential?.values
        )
        presets.append(preset)
        saveState()
    }

    func deletePreset(id: UUID) {
        presets.removeAll { $0.id == id }
        saveState()
    }

    func loadPreset(_ preset: ExperimentPreset) {
        guard let experiment = experiments.first(where: { $0.id == preset.experimentID }) else { return }
        selectedExperimentID = experiment.id
        parameters = preset.parameters
        snapshot = experiment.makeInitialSnapshot(parameters: parameters)
        if let values = preset.customPotentialValues {
            let potential = PotentialBuffer(values: values)
            let mass = parameters.value(for: "mass", default: SimulationUnits.defaultMass)
            if case let .oneD(grid) = snapshot.grid, values.count == grid.pointCount {
                snapshot.potential = potential
                let observables = ObservablesCalculator.oneD(psi: snapshot.psi, grid: grid, potential: potential, mass: mass)
                let density = snapshot.psi.probabilityDensity()
                snapshot = SimulationSnapshot(
                    experimentID: snapshot.experimentID,
                    time: 0,
                    grid: snapshot.grid,
                    psi: snapshot.psi,
                    potential: potential,
                    observables: observables,
                    diagnostics: NumericalDiagnostics(
                        norm: observables.norm,
                        energy: observables.totalEnergy,
                        maxProbabilityDensity: density.max() ?? 0,
                        stepCount: 0
                    )
                )
            } else if case let .twoD(grid) = snapshot.grid, values.count == grid.pointCount {
                snapshot.potential = potential
                let observables = ObservablesCalculator.twoD(psi: snapshot.psi, grid: grid, potential: potential, mass: mass)
                let density = snapshot.psi.probabilityDensity()
                snapshot = SimulationSnapshot(
                    experimentID: snapshot.experimentID,
                    time: 0,
                    grid: snapshot.grid,
                    psi: snapshot.psi,
                    potential: potential,
                    observables: observables,
                    diagnostics: NumericalDiagnostics(
                        norm: observables.norm,
                        energy: observables.totalEnergy,
                        maxProbabilityDensity: density.max() ?? 0,
                        stepCount: 0
                    )
                )
            }
        }
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
        isPlaying = false
        saveState()
    }

    func reset() {
        snapshot = selectedExperiment.makeInitialSnapshot(parameters: parameters)
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
        isPlaying = false
    }

    func restoreDefaultParameters() {
        parameters = selectedExperiment.defaultParameters
        reset()
    }

    func applyParameterChange() {
        snapshot = selectedExperiment.makeInitialSnapshot(parameters: parameters)
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
        isPlaying = false
    }

    func togglePlayback() {
        isPlaying.toggle()
    }

    func stepOnce() async {
        let baseSteps: Double = switch snapshot.grid {
        case .oneD:
            6
        case .twoD:
            1
        case .orbital:
            1
        }
        let stepsPerFrame = max(1, Int((baseSteps * playbackSpeed).rounded()))
        snapshot = await simulationActor.step(count: stepsPerFrame)
    }

    func paintCustomPotential(horizontalPosition: Double, verticalPosition: Double) {
        guard selectedExperimentID == "custom-potential",
              case let .oneD(grid) = snapshot.grid
        else {
            return
        }

        let clampedX = min(max(horizontalPosition, 0), 1)
        let clampedY = min(max(verticalPosition, 0), 1)
        let targetIndex = min(max(Int(clampedX * Double(grid.pointCount - 1)), 0), grid.pointCount - 1)
        let heightScale = parameters.value(for: "heightScale", default: 5)
        let smoothing = parameters.value(for: "smoothing", default: 0.25)
        let brushSizeParam = parameters.value(for: "brushSize", default: 0.1)

        let brushRadius = max(2, Int((brushSizeParam + smoothing * 0.035) * Double(grid.pointCount)))
        let sigma = max(Double(brushRadius) / 2.2, 1)
        let targetPotential = (1 - clampedY) * heightScale

        var values = snapshot.potential?.values ?? Array(repeating: 0, count: grid.pointCount)
        if values.count != grid.pointCount {
            values = Array(repeating: 0, count: grid.pointCount)
        }

        let lower = max(0, targetIndex - brushRadius)
        let upper = min(grid.pointCount - 1, targetIndex + brushRadius)
        for index in lower...upper {
            let distance = Double(index - targetIndex)
            let blend = exp(-(distance * distance) / (2 * sigma * sigma))
            values[index] = values[index] * (1 - blend) + targetPotential * blend
        }

        applyCustomPotential(values)
    }

    func clearCustomPotential() {
        guard selectedExperimentID == "custom-potential",
              case let .oneD(grid) = snapshot.grid
        else {
            return
        }

        applyCustomPotential(Array(repeating: 0, count: grid.pointCount))
    }

    func moveWavepacket(horizontalPosition: Double, verticalPosition: Double) {
        guard !isPlaying else { return }

        let clampedX = min(max(horizontalPosition, 0), 1)
        let clampedY = min(max(verticalPosition, 0), 1)

        switch snapshot.grid {
        case let .oneD(grid):
            let x = grid.xValues[0] + clampedX * grid.length
            if let idx = parameters.firstIndex(where: { $0.id == "center" }) {
                parameters[idx].value = x
                applyParameterChange()
            }
        case let .twoD(grid):
            let x = grid.xValue(at: 0) + clampedX * grid.lengthX
            let y = grid.yValue(at: 0) + (1 - clampedY) * grid.lengthY

            var changed = false
            if let idx = parameters.firstIndex(where: { $0.id == "centerX" }) {
                parameters[idx].value = x
                changed = true
            }
            if let idx = parameters.firstIndex(where: { $0.id == "centerY" }) {
                parameters[idx].value = y
                changed = true
            }
            if changed { applyParameterChange() }
        default:
            break
        }
    }

    func collapseWavefunction(horizontalPosition: Double, verticalPosition: Double) {
        guard isPlaying else { return } // Collapse usually makes sense during evolution

        let clampedX = min(max(horizontalPosition, 0), 1)
        let clampedY = min(max(verticalPosition, 0), 1)

        var newPsi = snapshot.psi
        var newObservables = snapshot.observables
        let newGrid = snapshot.grid
        let mass = parameters.value(for: "mass", default: SimulationUnits.defaultMass)

        switch snapshot.grid {
        case let .oneD(grid):
            let targetIndex = min(max(Int(clampedX * Double(grid.pointCount - 1)), 0), grid.pointCount - 1)
            let x0 = grid.xValues[targetIndex]
            let sigma = grid.length / 100.0 // Narrow collapse width

            var norm: Double = 0
            for i in 0..<grid.pointCount {
                let x = grid.xValues[i]
                let dx = x - x0
                let envelope = exp(-(dx * dx) / (2 * sigma * sigma))
                newPsi[i] = newPsi[i] * ComplexValue(real: envelope, imaginary: 0)
                let sample = newPsi[i]
                norm += (sample.real * sample.real + sample.imaginary * sample.imaginary) * grid.spacing
            }
            if norm > 0 {
                let scale = 1 / sqrt(norm)
                for i in 0..<grid.pointCount {
                    newPsi[i] = newPsi[i] * ComplexValue(real: scale, imaginary: 0)
                }
            }
            newObservables = ObservablesCalculator.oneD(psi: newPsi, grid: grid, potential: snapshot.potential, mass: mass)

        case let .twoD(grid):
            let col = min(max(Int(clampedX * Double(grid.width - 1)), 0), grid.width - 1)
            let row = min(max(Int(clampedY * Double(grid.height - 1)), 0), grid.height - 1)
            let x0 = grid.xValue(at: col)
            let y0 = grid.yValue(at: row)
            let sigma = grid.lengthX / 50.0

            var norm: Double = 0
            let spacing = grid.spacingX * grid.spacingY
            for r in 0..<grid.height {
                for c in 0..<grid.width {
                    let index = grid.linearIndex(column: c, row: r)
                    let dx = grid.xValue(at: c) - x0
                    let dy = grid.yValue(at: r) - y0
                    let envelope = exp(-(dx * dx + dy * dy) / (2 * sigma * sigma))
                    newPsi[index] = newPsi[index] * ComplexValue(real: envelope, imaginary: 0)
                    let sample = newPsi[index]
                    norm += (sample.real * sample.real + sample.imaginary * sample.imaginary) * spacing
                }
            }
            if norm > 0 {
                let scale = 1 / sqrt(norm)
                for i in 0..<newPsi.count {
                    newPsi[i] = newPsi[i] * ComplexValue(real: scale, imaginary: 0)
                }
            }
            newObservables = ObservablesCalculator.twoD(psi: newPsi, grid: grid, potential: snapshot.potential, mass: mass)

        default:
            return
        }

        let density = newPsi.probabilityDensity()
        snapshot = SimulationSnapshot(
            experimentID: snapshot.experimentID,
            time: snapshot.time,
            grid: newGrid,
            psi: newPsi,
            potential: snapshot.potential,
            observables: newObservables,
            diagnostics: NumericalDiagnostics(
                norm: newObservables.norm,
                energy: newObservables.totalEnergy,
                energyDrift: nil,
                maxProbabilityDensity: density.max() ?? 0,
                stepCount: snapshot.diagnostics.stepCount
            )
        )

        // Reset solver with collapsed state
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
    }

    private static func makeSimulationActor(snapshot: SimulationSnapshot, parameters: [ExperimentParameter]) -> SimulationActor {
        switch snapshot.grid {
        case .oneD:
            let mass = parameters.value(for: "mass", default: SimulationUnits.defaultMass)
            return SimulationActor(solver: SchrodingerSolver1D(initialSnapshot: snapshot, mass: mass))
        case .twoD:
            return SimulationActor(solver: SchrodingerSolver2D(initialSnapshot: snapshot))
        case .orbital:
            return SimulationActor(solver: OrbitalSolver(initialSnapshot: snapshot))
        }
    }

    private func applyCustomPotential(_ values: [Double]) {
        guard case let .oneD(grid) = snapshot.grid, values.count == grid.pointCount else {
            return
        }

        isPlaying = false
        let potential = PotentialBuffer(values: values)
        let mass = parameters.value(for: "mass", default: SimulationUnits.defaultMass)
        let observables = ObservablesCalculator.oneD(
            psi: snapshot.psi,
            grid: grid,
            potential: potential,
            mass: mass
        )
        let density = snapshot.psi.probabilityDensity()
        snapshot = SimulationSnapshot(
            experimentID: snapshot.experimentID,
            time: 0,
            grid: snapshot.grid,
            psi: snapshot.psi,
            potential: potential,
            observables: observables,
            diagnostics: NumericalDiagnostics(
                norm: observables.norm,
                energy: observables.totalEnergy,
                maxProbabilityDensity: density.max() ?? 0,
                stepCount: 0
            )
        )
        simulationActor = AppModel.makeSimulationActor(snapshot: snapshot, parameters: parameters)
    }
}
