import Foundation

public struct StepPotentialExperiment: Experiment {
    public let id = "step-potential"
    public let title = "Step Potential"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket encountering a potential step, demonstrating reflection and transmission."

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
