import Foundation

public struct HarmonicOscillatorExperiment: Experiment {
    public let id = "harmonic-oscillator"
    public let title = "Harmonic Oscillator"
    public let category = ExperimentCategory.oneD
    public let summary = "A Gaussian packet moving in a quadratic potential."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5),
            ExperimentParameter(id: "omega", label: "Omega", value: 1, range: 0.1...4),
            ExperimentParameter(id: "center", label: "Initial Center", value: -3, range: -8...8)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "oscillation", title: "Oscillation", body: "The packet center oscillates in the quadratic trap."),
            StoryStep(id: "energy", title: "Energy", body: "Total energy should stay nearly flat for a fixed Hamiltonian.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let mass = parameters.value(for: "mass", default: 1)
        let omega = parameters.value(for: "omega", default: 1)
        let center = parameters.value(for: "center", default: -3)
        let potential = PotentialBuffer(values: grid.xValues.map { 0.5 * mass * omega * omega * $0 * $0 })
        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: center,
            width: 0.8,
            momentum: 0,
            potential: potential,
            mass: mass
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
