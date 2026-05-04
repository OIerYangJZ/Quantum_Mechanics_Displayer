import Foundation

public struct FiniteSquareWellExperiment: Experiment {
    public let id = "finite-square-well"
    public let title = "Finite Square Well"
    public let category = ExperimentCategory.oneD
    public let summary = "A wavepacket interacting with an attractive finite square well potential."

    public var defaultParameters: [ExperimentParameter] {
        [
            ExperimentParameter(id: "depth", label: "Well Depth", value: 6, range: 0...15),
            ExperimentParameter(id: "width", label: "Well Width", value: 2, range: 0.5...8),
            ExperimentParameter(id: "momentum", label: "Initial Momentum", value: 4, range: 0...10),
            ExperimentParameter(id: "mass", label: "Mass", value: 1, range: 0.1...5)
        ]
    }

    public var story: [StoryStep] {
        [
            StoryStep(id: "trapping", title: "Temporary trapping", body: "The attractive well can temporarily capture parts of the wavepacket or cause multiple internal reflections.")
        ]
    }

    public init() {}

    public func makeInitialSnapshot() -> SimulationSnapshot {
        makeInitialSnapshot(parameters: defaultParameters)
    }

    public func makeInitialSnapshot(parameters: [ExperimentParameter]) -> SimulationSnapshot {
        let grid = Grid1D()
        let depth = parameters.value(for: "depth", default: 6)
        let wellWidth = parameters.value(for: "width", default: 2)
        let momentum = parameters.value(for: "momentum", default: 4)
        let mass = parameters.value(for: "mass", default: 1)

        let potential = PotentialBuffer(values: grid.xValues.map { abs($0) < wellWidth / 2 ? -depth : 0 })

        return OneDInitialStates.snapshot(
            experimentID: id,
            grid: grid,
            center: -6,
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
