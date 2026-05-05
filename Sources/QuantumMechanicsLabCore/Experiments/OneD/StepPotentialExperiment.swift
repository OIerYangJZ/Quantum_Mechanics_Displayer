import Foundation

public struct StepPotentialExperiment: Experiment {
    public let id = "step-potential"
    public let title = "Step Potential"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket encountering a potential step, demonstrating reflection and transmission."






    public var explanation: String {
        """
        When a free particle encounters a sudden change in potential energy (a step), classic and quantum mechanics disagree. Classically, if the particle has more energy than the step height, it slows down but continues. Quantum mechanically, the wavepacket partially reflects and partially transmits. If the energy is lower than the step, it undergoes total internal reflection but still slightly penetrates the step before turning back.
        """
    }
    public var builtInPresets: [ExperimentPreset] {
        [
            ExperimentPreset(experimentID: "step-potential", name: "E > V (Partial Reflection)", parameters: [
                ExperimentParameter(id: "stepHeight", label: "Step Height", value: 5, range: -10...20),
                ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 6, range: 0...12),
                ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5)
            ]),
            ExperimentPreset(experimentID: "step-potential", name: "E < V (Total Reflection)", parameters: [
                ExperimentParameter(id: "stepHeight", label: "Step Height", value: 15, range: -10...20),
                ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 3, range: 0...12),
                ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5)
            ])
        ]
    }

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "stepHeight", label: "Step Height", value: 3, range: -10...10),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 5, range: 0...12),
            ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "scattering", title: "Scattering at the step", body: "The wavepacket splits into a reflected and a transmitted wave when the energy exceeds the step height.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let stepHeight = parameters.value(for: "stepHeight", default: 3)
        let momentum = parameters.value(for: "momentum", default: 5)
        let mass = parameters.value(for: "mass", default: 1)

        let potential = PotentialBuffer(values: grid.xValues.map { $0 > 0 ? stepHeight : 0 })

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -5,
            width: 0.8,
            momentum: momentum,
            potential: potential,
            mass: mass
        )
    }

    public func validate(parameters: [ExperimentParameter]) -> [ParameterIssue] {
        []
    }
}
