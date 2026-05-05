import Foundation

public struct HarmonicOscillatorExperiment: Experiment {
    public let id = "harmonic-oscillator"
    public let title = "Harmonic Oscillator"
    public let category = ExperimentCategory.oneD
    public let summary = "A Gaussian packet moving in a quadratic potential."


    public var explanation: String {
        """
        The Quantum Harmonic Oscillator is one of the most important models in physics because any smooth potential well looks harmonic near its minimum. A coherent state (a displaced Gaussian wavepacket) will oscillate back and forth perfectly without changing its shape, mimicking classical motion. However, if you "squeeze" or "stretch" the initial packet (by changing the mass or adding custom momentum), you will see the wavepacket "breathe" as it oscillates, trading spatial uncertainty for momentum uncertainty.
        """
    }

    public var builtInPresets: [ExperimentPreset] {
        [
            ExperimentPreset(experimentID: "harmonic-oscillator", name: "Standard Coherent State", parameters: [
                ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5),
                ExperimentParameter(id: "center", label: "Initial Center", value: -4, range: -8...8)
            ]),
            ExperimentPreset(experimentID: "harmonic-oscillator", name: "Heavy Particle (Less spread)", parameters: [
                ExperimentParameter(id: "mass", label: "Mass", value: 4, range: 0.1...5),
                ExperimentParameter(id: "center", label: "Initial Center", value: -6, range: -8...8)
            ])
        ]
    }

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
